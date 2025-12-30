import sys
import os
import xml.etree.ElementTree as ET


def generate_badge(line_rate, output_path="assets/coverage.svg"):
    coverage = float(line_rate) * 100
    color = "#e05d44" # red
    if coverage >= 95:
        color = "#4c1" # brightgreen
    elif coverage >= 90:
         color = "#97ca00" # green
    elif coverage >= 75:
        color = "#dfb317" # yellow
    elif coverage >= 50:
        color = "#fe7d37" # orange

    coverage_str = f"{int(coverage)}%"
    
    # Calculate widths based on text length
    # Heuristic: ~7.5px per character for Verdana 11px
    # "Coverage": ~59-61px
    
    label_text = "Coverage"
    value_text = coverage_str
    
    # Estimate widths
    # 6px approx per char + padding
    label_width = 61 
    value_width = int(len(value_text) * 8.5) + 10 # 4 chars (100%) -> 34+10=44px. 3 chars -> 25+10=35px
    
    total_width = label_width + value_width
    
    # Center positions
    label_x = label_width / 2.0 * 10
    value_x = (label_width + value_width / 2.0) * 10
    
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="{total_width}" height="20" role="img" aria-label="{label_text}: {value_text}">
    <title>{label_text}: {value_text}</title>
    <linearGradient id="s" x2="0" y2="100%">
        <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
        <stop offset="1" stop-opacity=".1"/>
    </linearGradient>
    <clipPath id="r">
        <rect width="{total_width}" height="20" rx="3" fill="#fff"/>
    </clipPath>
    <g clip-path="url(#r)">
        <rect width="{label_width}" height="20" fill="#555"/>
        <rect x="{label_width}" width="{value_width}" height="20" fill="{color}"/>
        <rect width="{total_width}" height="20" fill="url(#s)"/>
    </g>
    <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110">
        <text aria-hidden="true" x="{int(label_x)}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="{label_width*10 - 100}">{label_text}</text>
        <text x="{int(label_x)}" y="140" transform="scale(.1)" fill="#fff" textLength="{label_width*10 - 100}">{label_text}</text>
        <text aria-hidden="true" x="{int(value_x)}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="{value_width*10 - 100}">{value_text}</text>
        <text x="{int(value_x)}" y="140" transform="scale(.1)" fill="#fff" textLength="{value_width*10 - 100}">{value_text}</text>
    </g>
</svg>"""
    
    with open(output_path, "w") as f:
        f.write(svg)
    print(f"Generated badge: {output_path} ({coverage_str})")

def transform_coverage(input_file):
    print(f"Transforming coverage report: {input_file}")
    
    try:
        tree = ET.parse(input_file)
        root = tree.getroot()
        
        # Extract total line-rate for badge before flattening complicates things (or after, root rate should be same/calculated?)
        # Cobertura root usually has overall line-rate. It might be an attribute of <coverage> root element.
        # But wait, python's getroot returns the root element.
        root_line_rate = root.get("line-rate", "0")
        generate_badge(root_line_rate)

        packages_el = root.find("packages")
        
        if packages_el is None:
            packages_el = ET.SubElement(root, "packages")
            
        # 1. Flatten packages: Move all classes to a temporary list and remove original packages
        all_classes = []
        original_packages = packages_el.findall("package")
        
        for pkg in original_packages:
            classes_el = pkg.find("classes")
            if classes_el is not None:
                all_classes.extend(classes_el.findall("class"))
            packages_el.remove(pkg) # Remove the consolidated package
            
        print(f"Found {len(all_classes)} classes/files to convert into packages.")

        # 2. Create a new package for EACH class (file)
        # This tricks irongut/CodeCoverageSummary into listing each file as a row
        for cls in all_classes:
            filename = cls.get("filename")
            line_rate = cls.get("line-rate")
            branch_rate = cls.get("branch-rate") or "0"
            complexity = cls.get("complexity") or "0"
            
            # Create new package element
            new_pkg = ET.SubElement(packages_el, "package")
            
            # Clean up filename (remove /app/ prefix if present)
            clean_name = filename.replace("/app/", "")
            new_pkg.set("name", clean_name) # Name the package after the file
            new_pkg.set("line-rate", line_rate)
            new_pkg.set("branch-rate", branch_rate)
            new_pkg.set("complexity", complexity)
            
            # Add the classes element and append the class
            new_classes = ET.SubElement(new_pkg, "classes")
            new_classes.append(cls)
            
        # 3. Save back to the same file
        tree.write(input_file)
        print("Transformation complete. Cobertura XML is now granular.")
        
    except Exception as e:
        print(f"Error transforming XML: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 transform_coverage.py <path_to_cobertura_xml>")
        sys.exit(1)
        
    transform_coverage(sys.argv[1])

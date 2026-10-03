"""Convert a kcov Cobertura report into SonarQube generic test coverage XML.

SonarQube Cloud cannot import kcov shell coverage directly, so CI converts the
merged Cobertura report into the generic format consumed via
``sonar.coverageReportPaths``. File paths are rewritten to be repository-relative.
"""

import argparse
import os
import sys
import xml.etree.ElementTree as ET


def _candidate_paths(filename, sources):
    yield filename
    for source in sources:
        yield os.path.join(source, filename)


def to_repo_relative(filename, sources, repo_root):
    """Map a Cobertura filename to a path relative to ``repo_root`` (or None)."""
    repo_root = os.path.abspath(repo_root)
    for candidate in _candidate_paths(filename, sources):
        normalized = candidate.replace("\\", "/")
        for prefix in ("/app/", "/home/pi/"):
            if normalized.startswith(prefix):
                normalized = normalized[len(prefix) :]
        if os.path.isabs(normalized):
            normalized = os.path.relpath(normalized, repo_root)
        if not normalized.startswith("..") and os.path.isfile(os.path.join(repo_root, normalized)):
            return normalized.replace(os.sep, "/")
    return None


def collect_lines(root, repo_root):
    """Return {repo_relative_path: {line_number: covered}} merged across classes."""
    sources = [s.text.strip() for s in root.iter("source") if s.text and s.text.strip()]
    files = {}
    for cls in root.iter("class"):
        path = to_repo_relative(cls.get("filename", ""), sources, repo_root)
        if path is None:
            print(f"Skipping unresolved file: {cls.get('filename')}", file=sys.stderr)
            continue
        lines = files.setdefault(path, {})
        for line in cls.iter("line"):
            number = int(line.get("number", "0"))
            if number > 0:
                lines[number] = lines.get(number, False) or int(line.get("hits", "0")) > 0
    return files


def build_generic_report(files):
    coverage = ET.Element("coverage", version="1")
    for path in sorted(files):
        file_el = ET.SubElement(coverage, "file", path=path)
        for number in sorted(files[path]):
            ET.SubElement(
                file_el,
                "lineToCover",
                lineNumber=str(number),
                covered="true" if files[path][number] else "false",
            )
    return ET.ElementTree(coverage)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Cobertura XML from kcov")
    parser.add_argument("--output", required=True, help="SonarQube generic coverage XML to write")
    parser.add_argument("--repo-root", default=".", help="Repository root for relative paths")
    args = parser.parse_args(argv)

    files = collect_lines(ET.parse(args.input).getroot(), args.repo_root)
    if not files:
        print("Error: no repository files resolved from Cobertura report", file=sys.stderr)
        return 1
    build_generic_report(files).write(args.output, encoding="utf-8", xml_declaration=True)
    total = sum(len(v) for v in files.values())
    covered = sum(sum(v.values()) for v in files.values())
    print(f"Wrote {args.output}: {len(files)} files, {covered}/{total} lines covered")
    return 0


if __name__ == "__main__":
    sys.exit(main())

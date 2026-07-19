#!/usr/bin/env python3
"""Generate per-file and overall coverage + complexity summaries from Cobertura XML."""

from __future__ import annotations

import argparse
import re
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path


@dataclass(slots=True)
class FileMetrics:
    filename: str
    covered: int
    valid: int
    coverage_rate: float
    complexity: float


SHELL_DECISION_PATTERN = re.compile(r"\b(if|elif|for|while|until|case)\b|&&|\|\|")

DEFAULT_TARGET_PER_FILE = 15.0
DEFAULT_HARD_MAX_PER_FILE = 35.0
DEFAULT_TARGET_AVG = 10.0
DEFAULT_HARD_MAX_AVG = 25.0


def _to_float(value: str | None, default: float = 0.0) -> float:
    if value is None:
        return default
    try:
        return float(value)
    except ValueError:
        return default


def _to_int(value: str | None, default: int = 0) -> int:
    if value is None:
        return default
    try:
        return int(value)
    except ValueError:
        return default


def _line_counts_from_class(class_el: ET.Element) -> tuple[int, int]:
    lines_el = class_el.find("lines")
    if lines_el is None:
        return 0, 0

    valid = 0
    covered = 0

    for line_el in lines_el.findall("line"):
        valid += 1
        hits = _to_int(line_el.get("hits"), 0)
        if hits > 0:
            covered += 1

    return covered, valid


def _estimated_shell_complexity(file_path: Path) -> float:
    """Estimate shell cyclomatic complexity from decision points in source."""
    complexity = 1

    with file_path.open("r", encoding="utf-8", errors="strict") as handle:
        for raw_line in handle:
            line = raw_line.split("#", maxsplit=1)[0]
            complexity += len(SHELL_DECISION_PATTERN.findall(line))

    return float(complexity)


def parse_metrics(cobertura_path: Path) -> tuple[list[FileMetrics], dict[str, float]]:
    tree = ET.parse(cobertura_path)
    root = tree.getroot()

    file_metrics: list[FileMetrics] = []
    raw_complexities: list[float] = []
    for class_el in root.findall(".//class"):
        filename = class_el.get("filename", "unknown")
        raw_complexity = _to_float(class_el.get("complexity"), 0.0)
        raw_complexities.append(raw_complexity)
        complexity = raw_complexity

        source_path = Path(filename)
        if source_path.suffix == ".sh" and source_path.exists():
            complexity = _estimated_shell_complexity(source_path)

        covered, valid = _line_counts_from_class(class_el)

        if valid == 0:
            covered = _to_int(class_el.get("lines-covered"), 0)
            valid = _to_int(class_el.get("lines-valid"), 0)

        if valid > 0:
            coverage_rate = covered / valid
        else:
            coverage_rate = _to_float(class_el.get("line-rate"), 0.0)

        file_metrics.append(
            FileMetrics(
                filename=filename,
                covered=covered,
                valid=valid,
                coverage_rate=coverage_rate,
                complexity=complexity,
            )
        )

    file_metrics.sort(key=lambda item: item.filename)

    total_covered = sum(item.covered for item in file_metrics)
    total_valid = sum(item.valid for item in file_metrics)
    total_complexity = sum(item.complexity for item in file_metrics)
    file_count = len(file_metrics)

    overall_rate = _to_float(root.get("line-rate"), -1.0)
    if overall_rate < 0.0:
        overall_rate = (total_covered / total_valid) if total_valid > 0 else 0.0

    overall_covered = _to_int(root.get("lines-covered"), total_covered)
    overall_valid = _to_int(root.get("lines-valid"), total_valid)

    root_complexity = _to_float(root.get("complexity"), -1.0)
    all_placeholder_complexity = bool(raw_complexities) and all(value == 1.0 for value in raw_complexities)
    if all_placeholder_complexity:
        root_complexity = total_complexity
    if root_complexity < 0.0:
        root_complexity = total_complexity

    average_complexity = (total_complexity / file_count) if file_count > 0 else 0.0

    overall = {
        "overall_rate": overall_rate,
        "overall_covered": float(overall_covered),
        "overall_valid": float(overall_valid),
        "overall_complexity": root_complexity,
        "total_complexity": total_complexity,
        "average_complexity": average_complexity,
        "file_count": float(file_count),
    }

    return file_metrics, overall


def evaluate_complexity(
    file_metrics: list[FileMetrics],
    overall: dict[str, float],
    target_per_file: float,
    hard_max_per_file: float,
    target_avg: float,
    hard_max_avg: float,
) -> tuple[list[str], list[str]]:
    warnings: list[str] = []
    violations: list[str] = []

    for item in file_metrics:
        if item.complexity > hard_max_per_file:
            violations.append(f"{item.filename} complexity {item.complexity:.2f} exceeds hard max {hard_max_per_file:.2f}")
        elif item.complexity > target_per_file:
            warnings.append(f"{item.filename} complexity {item.complexity:.2f} exceeds target {target_per_file:.2f}")

    avg_complexity = overall["average_complexity"]
    if avg_complexity > hard_max_avg:
        violations.append(f"Average complexity {avg_complexity:.2f} exceeds hard max {hard_max_avg:.2f}")
    elif avg_complexity > target_avg:
        warnings.append(f"Average complexity {avg_complexity:.2f} exceeds target {target_avg:.2f}")

    return warnings, violations


def build_markdown(
    file_metrics: list[FileMetrics],
    overall: dict[str, float],
    target_per_file: float,
    hard_max_per_file: float,
    target_avg: float,
    hard_max_avg: float,
    warnings: list[str],
    violations: list[str],
) -> str:
    lines: list[str] = []
    lines.append("## Coverage and Complexity Summary")
    lines.append("")
    lines.append("### Overall")
    lines.append("")
    lines.append("| Metric | Value |")
    lines.append("| --- | ---: |")
    lines.append(f"| Coverage | {overall['overall_rate'] * 100:.2f}% ({int(overall['overall_covered'])}/{int(overall['overall_valid'])}) |")
    lines.append(f"| Complexity (Overall) | {overall['overall_complexity']:.2f} |")
    lines.append(f"| Complexity (Total Files) | {overall['total_complexity']:.2f} |")
    lines.append(f"| Complexity (Avg/File) | {overall['average_complexity']:.2f} |")
    lines.append(f"| Files | {int(overall['file_count'])} |")
    lines.append("")
    lines.append("### Complexity Policy")
    lines.append("")
    lines.append("| Policy | Threshold |")
    lines.append("| --- | ---: |")
    lines.append(f"| Target Complexity Per File | <= {target_per_file:.2f} |")
    lines.append(f"| Hard Max Complexity Per File | <= {hard_max_per_file:.2f} |")
    lines.append(f"| Target Avg Complexity | <= {target_avg:.2f} |")
    lines.append(f"| Hard Max Avg Complexity | <= {hard_max_avg:.2f} |")
    lines.append("")

    if warnings:
        lines.append("### Complexity Warnings")
        lines.append("")
        for warning in warnings:
            lines.append(f"- {warning}")
        lines.append("")

    if violations:
        lines.append("### Complexity Violations")
        lines.append("")
        for violation in violations:
            lines.append(f"- {violation}")
        lines.append("")

    lines.append("### Per-file")
    lines.append("")
    lines.append("| File | Coverage | Complexity |")
    lines.append("| --- | ---: | ---: |")

    for item in file_metrics:
        lines.append(f"| {item.filename} | {item.coverage_rate * 100:.2f}% ({item.covered}/{item.valid}) | {item.complexity:.2f} |")

    return "\n".join(lines) + "\n"


def build_text(file_metrics: list[FileMetrics], overall: dict[str, float]) -> str:
    lines: list[str] = []
    lines.append("Coverage and complexity summary")
    lines.append(
        "Overall: "
        f"coverage {overall['overall_rate'] * 100:.2f}% "
        f"({int(overall['overall_covered'])}/{int(overall['overall_valid'])}), "
        f"complexity {overall['overall_complexity']:.2f}, "
        f"avg/file {overall['average_complexity']:.2f}, files {int(overall['file_count'])}"
    )
    lines.append("Per-file:")

    for item in file_metrics:
        lines.append(
            f"  {item.filename}: coverage {item.coverage_rate * 100:.2f}% ({item.covered}/{item.valid}), complexity {item.complexity:.2f}"
        )

    return "\n".join(lines) + "\n"


def build_text_with_policy(
    file_metrics: list[FileMetrics],
    overall: dict[str, float],
    target_per_file: float,
    hard_max_per_file: float,
    target_avg: float,
    hard_max_avg: float,
    warnings: list[str],
    violations: list[str],
) -> str:
    file_label = "File"
    coverage_label = "Coverage"
    complexity_label = "Complexity"

    file_width = len(file_label)
    for item in file_metrics:
        if len(item.filename) > file_width:
            file_width = len(item.filename)
    if len("OVERALL") > file_width:
        file_width = len("OVERALL")

    coverage_values = [f"{item.coverage_rate * 100:.2f}% ({item.covered}/{item.valid})" for item in file_metrics]
    overall_coverage = f"{overall['overall_rate'] * 100:.2f}% ({int(overall['overall_covered'])}/{int(overall['overall_valid'])})"

    coverage_width = len(coverage_label)
    for value in coverage_values:
        if len(value) > coverage_width:
            coverage_width = len(value)
    if len(overall_coverage) > coverage_width:
        coverage_width = len(overall_coverage)

    complexity_values = [f"{item.complexity:.2f}" for item in file_metrics]
    overall_complexity = f"{overall['overall_complexity']:.2f}"

    complexity_width = len(complexity_label)
    for value in complexity_values:
        if len(value) > complexity_width:
            complexity_width = len(value)
    if len(overall_complexity) > complexity_width:
        complexity_width = len(overall_complexity)

    separator = "+" + "-" * (file_width + 2) + "+" + "-" * (coverage_width + 2) + "+" + "-" * (complexity_width + 2) + "+"

    lines: list[str] = []
    lines.append("Coverage and complexity summary")
    lines.append(separator)
    lines.append(
        f"| {file_label.ljust(file_width)} | {coverage_label.ljust(coverage_width)} | {complexity_label.ljust(complexity_width)} |"
    )
    lines.append(separator)

    for index, item in enumerate(file_metrics):
        lines.append(
            f"| {item.filename.ljust(file_width)} | {coverage_values[index].ljust(coverage_width)} | "
            f"{complexity_values[index].rjust(complexity_width)} |"
        )

    lines.append(separator)
    lines.append(
        f"| {'OVERALL'.ljust(file_width)} | {overall_coverage.ljust(coverage_width)} | {overall_complexity.rjust(complexity_width)} |"
    )
    lines.append(separator)

    lines.append("Complexity policy:")
    lines.append(f"  Target per file: <= {target_per_file:.2f}")
    lines.append(f"  Hard max per file: <= {hard_max_per_file:.2f}")
    lines.append(f"  Target average: <= {target_avg:.2f}")
    lines.append(f"  Hard max average: <= {hard_max_avg:.2f}")

    if warnings:
        lines.append("Complexity warnings:")
        for warning in warnings:
            lines.append(f"  - {warning}")

    if violations:
        lines.append("Complexity violations:")
        for violation in violations:
            lines.append(f"  - {violation}")

    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Path to Cobertura XML file")
    parser.add_argument(
        "--format",
        choices=["text", "markdown"],
        default="text",
        help="Output format",
    )
    parser.add_argument("--output", help="Optional output file path")
    parser.add_argument(
        "--target-per-file",
        type=float,
        default=DEFAULT_TARGET_PER_FILE,
        help="Target complexity per file",
    )
    parser.add_argument(
        "--hard-max-per-file",
        type=float,
        default=DEFAULT_HARD_MAX_PER_FILE,
        help="Hard max complexity per file (enforced)",
    )
    parser.add_argument(
        "--target-avg",
        type=float,
        default=DEFAULT_TARGET_AVG,
        help="Target average complexity across files",
    )
    parser.add_argument(
        "--hard-max-avg",
        type=float,
        default=DEFAULT_HARD_MAX_AVG,
        help="Hard max average complexity across files (enforced)",
    )
    parser.add_argument(
        "--enforce-complexity",
        action="store_true",
        help="Exit non-zero when hard complexity thresholds are exceeded",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    input_path = Path(args.input)

    if not input_path.exists():
        print(f"Coverage metrics error: file not found: {input_path}")
        return 1

    file_metrics, overall = parse_metrics(input_path)
    warnings, violations = evaluate_complexity(
        file_metrics,
        overall,
        args.target_per_file,
        args.hard_max_per_file,
        args.target_avg,
        args.hard_max_avg,
    )

    if args.format == "markdown":
        result = build_markdown(
            file_metrics,
            overall,
            args.target_per_file,
            args.hard_max_per_file,
            args.target_avg,
            args.hard_max_avg,
            warnings,
            violations,
        )
    else:
        result = build_text_with_policy(
            file_metrics,
            overall,
            args.target_per_file,
            args.hard_max_per_file,
            args.target_avg,
            args.hard_max_avg,
            warnings,
            violations,
        )

    print(result, end="")

    if args.output:
        Path(args.output).write_text(result, encoding="utf-8")

    if args.enforce_complexity and violations:
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())

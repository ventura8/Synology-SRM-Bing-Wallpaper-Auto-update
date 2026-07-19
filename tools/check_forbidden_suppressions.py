#!/usr/bin/env python3
"""Fail if tracked files contain lint-suppression directives."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

PATTERN = re.compile(
    r"shellcheck\s+disable|noqa|pylint:\s*disable|eslint-disable|pragma:\s*no\s*cover|fmt:\s*off",
    re.IGNORECASE,
)


def tracked_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files"],
        check=True,
        capture_output=True,
        text=True,
    )
    return [Path(line) for line in result.stdout.splitlines() if line.strip()]


def should_scan(path: Path) -> bool:
    if path.is_dir():
        return False
    if path.as_posix().startswith("node_modules/"):
        return False
    if path.name == "check_forbidden_suppressions.py":
        return False
    if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico", ".pdf"}:
        return False
    if path.suffix.lower() not in {".sh", ".bats", ".ps1", ".py", ".yml", ".yaml", ".json", ".toml"}:
        return False
    return True


def main() -> int:
    failures: list[tuple[Path, int, str]] = []

    for path in tracked_files():
        if not should_scan(path):
            continue
        if not path.exists():
            continue

        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        for lineno, line in enumerate(content.splitlines(), start=1):
            if PATTERN.search(line):
                failures.append((path, lineno, line.strip()))

    if failures:
        print("Forbidden lint suppression directive(s) found:")
        for path, lineno, line in failures:
            print(f"  {path}:{lineno}: {line}")
        return 1

    print("No forbidden lint suppression directives found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

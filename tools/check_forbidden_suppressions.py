#!/usr/bin/env python3
"""Fail if tracked files contain lint-suppression directives."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

PATTERN = re.compile(
    r"shellcheck\s+disable|noqa|pylint:\s*disable|eslint-disable|pragma:\s*no\s*cover|fmt:\s*off|NOSONAR",
    re.IGNORECASE,
)
# Markdown prose may name forbidden directives, so only match real HTML-comment directives there.
MARKDOWN_PATTERN = re.compile(r"^\s*<!--\s*markdownlint-(disable|capture|configure-file)", re.IGNORECASE)

CODE_SUFFIXES = {".sh", ".bats", ".ps1", ".py", ".yml", ".yaml", ".json", ".toml"}


def tracked_files() -> list[Path]:
    """List files tracked by git in the current repository."""
    result = subprocess.run(
        ["git", "ls-files"],
        check=True,
        capture_output=True,
        text=True,
    )
    return [Path(line) for line in result.stdout.splitlines() if line.strip()]


def pattern_for(path: Path) -> re.Pattern[str] | None:
    """Return the directive pattern to apply to ``path``, or None to skip it."""
    if path.as_posix().startswith("node_modules/") or path.name == "check_forbidden_suppressions.py":
        return None
    suffix = path.suffix.lower()
    if suffix == ".md":
        return MARKDOWN_PATTERN
    if suffix in CODE_SUFFIXES:
        return PATTERN
    return None


def main() -> int:
    """Scan tracked files and return non-zero when a suppression directive is found."""
    failures: list[tuple[Path, int, str]] = []

    for path in tracked_files():
        pattern = pattern_for(path)
        if pattern is None or not path.is_file():
            continue

        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        for lineno, line in enumerate(content.splitlines(), start=1):
            if pattern.search(line):
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

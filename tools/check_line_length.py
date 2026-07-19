#!/usr/bin/env python3
"""Fail when non-Markdown tracked files contain lines longer than max length."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

MAX_LENGTH = 140


def tracked_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files"],
        check=True,
        capture_output=True,
        text=True,
    )
    return [Path(line) for line in result.stdout.splitlines() if line.strip()]


def is_markdown(path: Path) -> bool:
    return path.suffix.lower() in {".md", ".markdown"}


def should_check(path: Path) -> bool:
    if path.is_dir() or is_markdown(path):
        return False
    if path.as_posix().startswith("node_modules/"):
        return False
    if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico", ".pdf"}:
        return False
    return True


def scan_file(path: Path) -> list[tuple[int, int]]:
    violations: list[tuple[int, int]] = []
    with path.open("r", encoding="utf-8", errors="strict") as handle:
        for lineno, raw_line in enumerate(handle, start=1):
            line = raw_line.rstrip("\n")
            if len(line) > MAX_LENGTH:
                violations.append((lineno, len(line)))
    return violations


def main() -> int:
    failures: list[tuple[Path, int, int]] = []

    for path in tracked_files():
        if not should_check(path):
            continue
        if not path.exists():
            continue

        try:
            violations = scan_file(path)
        except UnicodeDecodeError:
            continue

        for lineno, length in violations:
            failures.append((path, lineno, length))

    if failures:
        print(f"Line-length check failed (max {MAX_LENGTH}) for non-Markdown files:")
        for path, lineno, length in failures:
            print(f"  {path}:{lineno} ({length})")
        return 1

    print(f"Line-length check passed (max {MAX_LENGTH}) for non-Markdown files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

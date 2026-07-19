---
name: quality-gate
description: "Run and enforce the repository quality gate: formatters, linters, line-length, and suppression policy checks."
---

# Quality Gate Skill

## Use When

- User asks to lint, format, or enforce standards.
- User asks to fix CI quality failures.
- User asks to verify local and CI parity.

## Workflow

1. Run tools/runners/quality.sh in a controlled environment.
2. Fix all violations in source, not by suppression.
3. Re-run checks until clean.
4. Report changed files and policy impacts.

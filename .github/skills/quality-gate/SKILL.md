---
name: quality-gate
description: "Run and enforce the repository quality gate: formatters, linters, line-length, and suppression policy checks."
---

# Quality Gate Skill

Canonical skill text: [`.agents/skills/quality-gate/SKILL.md`](../../../.agents/skills/quality-gate/SKILL.md).

## Use When

- User asks to lint, format, or enforce standards.
- User asks to fix CI quality failures.
- User asks to verify local and CI parity.

## Workflow

1. Autofix owned source first when safe, then re-run the gate:
   - Safe autofix (mutating, local only), matching check flags:
     `shfmt -i 4 -ci -w` on changed `*.sh`/`*.bats`,
     `ruff check --fix` + `ruff format` on Python under `tests/`/`tools/`,
     and `markdownlint --fix` when available.
   - Safe means: only repository-owned files you are changing; do not autofix
     third-party or generated trees; always follow with a clean
     `./tools/runners/quality.sh` (check-only; uses `shfmt -i 4 -ci -d`).
2. CI quality job stays **non-mutating** (formatter/lint `--check` / dry-run
   equivalents only — never rely on CI to rewrite files).
3. Fix all remaining violations in source, not by suppression.
4. Re-run checks until clean.
5. Report changed files and policy impacts.

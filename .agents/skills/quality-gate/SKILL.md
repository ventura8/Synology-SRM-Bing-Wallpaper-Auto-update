---
name: quality-gate
description: >-
  Run and enforce repository quality gates: shfmt, shellcheck, yamllint, jq,
  ruff, markdownlint, line-length, and forbidden-suppression checks via
  tools/runners/quality.sh. Use when linting, formatting, fixing CI quality
  failures, or verifying local/CI parity.
---

# Quality Gate Skill

## Use when

- User asks to lint, format, or enforce standards
- CI quality job fails
- Verifying local checks match `.github/workflows/ci.yml`

## Hard rules

1. Follow order: format → lint/policy (never suppress).
2. Auto-fix first on owned source when safe (`shfmt -i 4 -ci -w`,
   `ruff check --fix`, `ruff format`, `markdownlint --fix` when available),
   then re-run the gate. Safe means repository-owned files under change only;
   CI quality stays check-only / non-mutating (`shfmt -i 4 -ci -d`).
3. Non-Markdown ≤140 columns; no `# shellcheck disable` / `# noqa` / equivalents.
4. Prefer `./tools/runners/quality.sh` over one-off tool invocations.

## Workflow

```bash
set -euo pipefail
mkdir -p coverage/logs
./tools/runners/quality.sh 2>&1 | tee coverage/logs/quality.log
exit "${PIPESTATUS[0]}"
```

Inside Docker (matches Windows `run_tests.ps1` quality step):

```bash
docker build -t srm-mock -f tests/Dockerfile .
docker run --rm -v "$PWD:/app" -w /app srm-mock ./tools/runners/quality.sh
```

Fix every failure in source, re-run until clean, then summarize changed files.

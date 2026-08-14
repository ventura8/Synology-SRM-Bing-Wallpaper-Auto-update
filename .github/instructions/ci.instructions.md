---
applyTo: ".github/workflows/**/*.yml"
description: "Use when updating workflow design, CI dependencies, and pipeline reliability rules."
---

- Pin actions using immutable commit SHAs with version comments.
- Keep quality checks blocking and early in the workflow graph.
- Keep workflow triggers updated when standards or quality scripts change.
- Prefer deterministic dependency installation paths.
- Align job steps with `tools/runners/quality.sh` and `tools/runners/run_tests.sh`.
- Preserve kcov requirements (`seccomp=unconfined`, `SYS_PTRACE`) and ≥90% coverage gate.
- See root `AGENTS.md` section **CI & Dependency Pinning**.

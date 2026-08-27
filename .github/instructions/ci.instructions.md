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
- `release.yml`: pin the `gh` CLI version and use `gh release create --verify-tag`
  so a missing remote tag fails closed instead of being created from the default branch.
  Validate release notes: H1 must start with the tag and the body must be non-empty.
- See root `AGENTS.md` section **CI & Dependency Pinning**.

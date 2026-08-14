---
applyTo: "**/*"
description: "Use when working on repository-wide quality standards, lint/formatter policy, and CI check enforcement."
---

- Run format checks before lint checks, and lint checks before tests.
- Treat every quality check as mandatory for local and CI execution.
- Keep non-Markdown files at max 140 columns.
- Reject changes that introduce lint suppressions.
- Prefer explicit version pinning for tools and CI dependencies.
- Prefer `./tools/runners/quality.sh` and Dockerized `run_tests.sh`.
- Update `AGENTS.md` when gates or invariants change.

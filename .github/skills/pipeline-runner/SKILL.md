---
name: pipeline-runner
description: "Run the full local quality + Docker test + coverage pipeline."
---

# Pipeline Runner Skill

Canonical skill text:
[`.agents/skills/pipeline-runner/SKILL.md`](../../../.agents/skills/pipeline-runner/SKILL.md).

## Use When

- Pre-commit / pre-PR validation
- Reproducing CI locally

## Workflow

1. Run `./tools/runners/quality.sh`.
2. Build `srm-mock:latest` and run covered `./tools/runners/run_tests.sh`
   with `$PWD` mounted so `assets/coverage.svg` can persist on the host
   (or `./tools/runners/run_tests.ps1` on Windows).
3. Enforce total repository coverage ≥90% and complexity policy on the host
   (see canonical skill). `quality.sh` does not perform these gates.
4. Refresh `assets/coverage.svg` when coverage-affecting changes land.

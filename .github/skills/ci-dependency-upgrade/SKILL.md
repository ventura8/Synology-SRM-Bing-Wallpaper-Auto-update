---
name: ci-dependency-upgrade
description: "Upgrade CI dependencies to latest stable releases with Action SHAs and explicit version pins."
---

# CI Dependency Upgrade Skill

Canonical skill text:
[`.agents/skills/ci-dependency-upgrade/SKILL.md`](../../../.agents/skills/ci-dependency-upgrade/SKILL.md).

## Use When

- User asks to update workflow dependencies.
- User requests Action SHAs or explicit tool/image version pins.
- CI broke due upstream dependency drift.

## Workflow

1. Discover current action/tool versions.
2. Resolve latest stable tags/SHAs upstream.
3. Update workflow and tooling pins together.
4. Validate with `tools/runners/quality.sh` (format/lint/policy only — it does
   **not** run tests or coverage).
5. Run Dockerized `bash ./tools/runners/run_tests.sh` with coverage enabled.
   Representative/partial suites are smoke checks only; require the full unit +
   e2e pipeline to verify total repository coverage ≥90%.

---
name: ci-dependency-upgrade
description: >-
  Upgrade CI and local tooling dependencies to latest stable releases and pin
  them appropriately: immutable GitHub Action commit SHAs, plus explicit version
  pins for images/pip/npm (tags remain mutable vs digests). Use when updating
  workflow pins or repairing upstream dependency drift.
---

# CI Dependency Upgrade Skill

## Use when

- User asks to bump Actions, linters, or test image tool pins
- CI breaks due to upstream drift
- Aligning `quality.sh` tool expectations with `.github/workflows/ci.yml`

## Hard rules

1. Pin GitHub Actions to **immutable commit SHAs**; keep the version comment.
2. Pin tools with **explicit version selectors** (`ruff==…`, `yamllint==…`,
   `markdownlint-cli@…`, `shfmt`/`shellcheck` image tags,
   `PSScriptAnalyzer` RequiredVersion). Image tags and package versions are
   not content-addressed digests unless the file already uses `@sha256:…`
   (e.g. `tests/Dockerfile` base image)—do not treat version tags as immutable.
3. Prefer deterministic apt/pip/npm installs; avoid floating `@latest` in CI.
4. After bumps, run quality **and** the Dockerized test suite with coverage
   (see Workflow). `quality.sh` does **not** run tests or the ≥90% coverage gate.

## Workflow

1. Inventory pins in `.github/workflows/ci.yml`, runners, and docs.
2. Resolve current stable upstream versions/tags/SHAs.
3. Update workflow and any mirrored local install instructions together.
4. Run `./tools/runners/quality.sh`.
5. Run Dockerized `bash ./tools/runners/run_tests.sh` with coverage enabled.
   Representative/partial suites are smoke checks only. To verify **total
   repository coverage ≥90%**, run the full unit + e2e pipeline (default
   `run_tests.sh` with no slice flags, as in pipeline-runner).
6. Note any intentional version skew between local Docker image and CI host tools.

## Done criteria

- All actionable pins updated or explicitly left with a reason
- CI-equivalent quality + tests + coverage checks pass locally
- `AGENTS.md` / skills mention of versions updated only when guidance would rot

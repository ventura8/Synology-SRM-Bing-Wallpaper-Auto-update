# AI Agent Instructions

Canonical project rules live in the repository root [`AGENTS.md`](../AGENTS.md).
Task skills live under [`.agents/skills/`](../.agents/skills/).

These short instructions apply to any automated coding assistant working here.

## 1. Quality Assurance Workflow

### Priority Order

1. **Formatting First**: Run and pass formatter checks before linting.
2. **Linting Second**: Resolve all lint/policy errors before tests.
3. **Testing Third**: Run the BATS suite (Docker image `srm-mock:latest` built
   from `tests/Dockerfile`).
4. **Coverage Verification Fourth**: Total repository coverage must be at least 90%.
5. **Complexity Enforcement Fifth**: Run `tools/coverage_metrics.py` with
   `--target-per-file 15 --hard-max-per-file 35 --target-avg 10 --hard-max-avg 25
   --enforce-complexity` (same gates as `AGENTS.md` / pipeline-runner).

### Efficiency

- Prefer repository runners: `./tools/runners/quality.sh` and
  `./tools/runners/run_tests.sh` (or `./tools/runners/run_tests.ps1` on Windows).
- When fixing issues, combine lint and test fixes in one pass when practical.

## 2. Code Coverage Standards

- Maintain **≥90%** merged kcov coverage.
- Refresh `assets/coverage.svg` after successful local covered runs
  (`tests/transform_coverage.py`).
- CI validates coverage; it does not commit the badge.

## 3. Cross-Platform Compatibility

- Keep mocks deterministic and free of live Bing network calls in tests.
- Support Linux-primary Docker workflows and Windows-hosted `run_tests.ps1`.
- Respect LF vs CRLF via `.gitattributes` / `.editorconfig`.

## 4. Keep Agent Docs Current

When behavior or gates change, update `AGENTS.md` and affected
`.agents/skills/*/SKILL.md` in the same change set (see **Always Update Agent
Docs** in `AGENTS.md`).

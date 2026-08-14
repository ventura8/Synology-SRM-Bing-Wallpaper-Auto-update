---
name: test-runner
description: >-
  Execute BATS unit, component, and e2e suites in the srm-mock Docker image with
  optional kcov, enforce ≥90% merged coverage, and refresh assets/coverage.svg.
  Use when running tests, expanding coverage, or debugging failing suites.
---

# Test Runner Skill

## Use when

- Running or debugging BATS suites
- Adding tests / raising coverage
- Validating coverage badge and complexity policy locally

## Hard rules

1. Exercise real product scripts; mock only Bing/network and privileged SRM edges.
2. Keep fixtures under `tests/mocks/` and deterministic.
3. Merged coverage must stay ≥90%; update `assets/coverage.svg` on full local runs.
4. Use `seccomp=unconfined` + `SYS_PTRACE` for kcov.

## Suites

| Flag | Suite |
| --- | --- |
| (default) | unit + component + e2e |
| `--unit-only` / `--unit-install` / `--unit-uninstall` / `--unit-wallpaper` | unit slices |
| `--component-only` | `tests/component.bats` |
| `--e2e-only` | `tests/e2e_tests.bats` |

## Workflow

```bash
set -euo pipefail
docker build -t srm-mock -f tests/Dockerfile .
mkdir -p coverage
docker run --rm \
  --security-opt seccomp=unconfined \
  --cap-add SYS_PTRACE \
  -v "$PWD/coverage:/home/pi/coverage" \
  -e COVERAGE=1 \
  -e COVERAGE_OUTPUT=/home/pi/coverage \
  srm-mock bash ./tools/runners/run_tests.sh
```

On Windows hosts prefer:

```powershell
./tools/runners/run_tests.ps1
```

After a full covered run, confirm Cobertura under `coverage/final/`, badge
`assets/coverage.svg`, and complexity via:

```bash
python3 tools/coverage_metrics.py \
  --input coverage/final/cobertura.xml \
  --format text \
  --target-per-file 15 --hard-max-per-file 35 \
  --target-avg 10 --hard-max-avg 25 \
  --enforce-complexity
```

(Adjust the Cobertura path if nested under `coverage/final/**/cobertura.xml`.)

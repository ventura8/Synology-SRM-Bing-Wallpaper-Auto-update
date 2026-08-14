---
name: pipeline-runner
description: >-
  Run the full local pipeline matching CI: quality gate, Dockerized BATS suites,
  kcov merge expectations, and coverage/complexity enforcement. Use before
  commits/PRs or when validating end-to-end repo health.
---

# Pipeline Runner Skill

## Use when

- Pre-commit / pre-PR validation
- Reproducing the CI sequence locally
- Confirming quality + tests + coverage together

## Hard rules

1. Order is mandatory: quality → tests → coverage ≥90% → complexity policy.
2. Live-stream output; capture logs under `coverage/logs/` when useful.
3. Do not ship with a stale `assets/coverage.svg` after coverage-affecting changes.
4. Keep tool pins and checks aligned with `.github/workflows/ci.yml`.
5. Use the locally built image tag `srm-mock:latest` (built from `tests/Dockerfile`);
   this is not an external registry pin.

## Workflow (Linux)

```bash
set -euo pipefail
mkdir -p coverage/logs

./tools/runners/quality.sh 2>&1 | tee coverage/logs/quality.log

docker build -t srm-mock:latest -f tests/Dockerfile .
docker run --rm \
  --security-opt seccomp=unconfined \
  --cap-add SYS_PTRACE \
  -v "$PWD:/app" \
  -v "$PWD/coverage:/home/pi/coverage" \
  -w /app \
  -e COVERAGE=1 \
  -e COVERAGE_OUTPUT=/home/pi/coverage \
  srm-mock:latest bash ./tools/runners/run_tests.sh \
  2>&1 | tee coverage/logs/tests.log

# Enforce coverage + complexity on the host (run_tests.sh merges kcov only;
# quality.sh does not gate coverage/complexity). Mounting $PWD persists
# assets/coverage.svg when transform_coverage.py runs below.
COB=coverage/final/kcov-merged/cobertura.xml
python3 - <<'PY'
import xml.etree.ElementTree as ET, sys
from pathlib import Path
root = ET.parse(Path("coverage/final/kcov-merged/cobertura.xml")).getroot()
pct = round(float(root.attrib.get("line-rate", 0)) * 100, 2)
print(f"Coverage: {pct}%")
sys.exit(0 if pct >= 90 else 1)
PY
python3 tests/transform_coverage.py "$COB"
python3 tools/coverage_metrics.py --input "$COB" --format text \
  --target-per-file 15 --hard-max-per-file 35 \
  --target-avg 10 --hard-max-avg 25 \
  --enforce-complexity
```

## Workflow (Windows host)

```powershell
./tools/runners/run_tests.ps1
```

That script builds `srm-mock:latest`, runs quality inside the image, runs covered
tests, gates coverage at 90%, refreshes the badge, and enforces complexity.

## Done criteria

- Quality exit 0
- All requested suites exit 0
- Total repository coverage ≥90%
- Complexity policy passes
- `assets/coverage.svg` updated on the host when coverage changed
- Summary of failures fixed (no suppressions)

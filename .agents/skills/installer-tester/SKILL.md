---
name: installer-tester
description: >-
  Validate install.sh and uninstall.sh wizard, env overrides, crontab scheduling,
  and first-run wallpaper apply using BATS and SRM-compatible shell constraints.
  Use when changing install/uninstall flows or cron behavior.
---

# Installer Tester Skill

## Use when

- Editing `install.sh` or `uninstall.sh`
- Changing cron scheduling, interactive prompts, or config `sed` writes
- Debugging install/uninstall BATS failures

## Hard rules

1. Keep product installers POSIX `sh` friendly for SRM; avoid new bashisms.
2. Fail closed when not root, or when download/copy yields empty files.
3. Human README one-liners stay interactive; do not advertise `NON_INTERACTIVE`
   as the primary install path.
4. Cover both interactive (`FORCE_INTERACTIVE`) and env-preset paths in tests.
5. Retain deterministic non-root fail-closed BATS for both `install.sh` and
   `uninstall.sh` (reject non-root without weakening POSIX `sh` compatibility).
6. When knobs or cron fallbacks change, sync `AGENTS.md`, this canonical skill,
   and the `.github/skills/installer-tester/` mirror in the same change set.

## Important env knobs

| Variable | Purpose |
| --- | --- |
| `LOCAL_INSTALL_PATH` | Copy local script instead of wget |
| `NON_INTERACTIVE` | Skip prompts |
| `FORCE_INTERACTIVE` / `FORCE_STDIN` | Force prompt path under pipes |
| `BING_RESOLUTION` / `BING_MARKET` / `BURN_TEXT_OVERLAY` | Pre-seed answers |
| `CRON_HOUR` / `CRON_MIN` | Schedule overrides |
| `TEST_MODE=1` | Test harness control of `main` |

## Cron behavior to preserve

- Backup `/etc/crontab` to `.bak`
- Remove existing lines for the install path
- Append `MIN HOUR * * * root INSTALL_PATH` (tab-separated as implemented)
- Reload via `synoservicectl` → `synoservice` → `systemctl` → `killall -HUP crond`
- Run wallpaper script once after install

## Workflow

```bash
set -euo pipefail
docker build -t srm-mock -f tests/Dockerfile .
docker run --rm \
  --security-opt seccomp=unconfined \
  --cap-add SYS_PTRACE \
  -v "$PWD/coverage:/home/pi/coverage" \
  -e COVERAGE=1 \
  -e COVERAGE_OUTPUT=/home/pi/coverage \
  srm-mock bash ./tools/runners/run_tests.sh --unit-install

docker run --rm \
  --security-opt seccomp=unconfined \
  --cap-add SYS_PTRACE \
  -v "$PWD/coverage:/home/pi/coverage" \
  -e COVERAGE=1 \
  -e COVERAGE_OUTPUT=/home/pi/coverage \
  srm-mock bash ./tools/runners/run_tests.sh --unit-uninstall
```

Also run `--e2e-only` when install↔run↔uninstall composition may have changed.
When knobs or cron fallbacks change, sync `AGENTS.md`, this skill, and the
`.github/skills/installer-tester/` mirror together.

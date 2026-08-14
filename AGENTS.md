# Project Agent Rules & Development Guidelines

## Project Overview

`Synology-SRM-Bing-Wallpaper-Auto-update` is a shell automation suite for Synology
Router Manager (SRM) 1.3. It downloads the daily Bing wallpaper and applies it to
the router's login background and default desktop wallpaper resources.

Primary product scripts (POSIX `sh`, root-required on device):

- `bing_wallpaper_auto_update.sh` — fetch, optional overlay, deploy, optional archive
- `install.sh` — download/copy script, interactive config, cron schedule, first run
- `uninstall.sh` — remove installed script and crontab entry

Local/CI tooling is bash/Python/PowerShell around Dockerized BATS + kcov:

- `tools/runners/quality.sh` — formatters, linters, policy checks
- `tools/runners/run_tests.sh` — in-container BATS suites (+ optional kcov)
- `tools/runners/run_tests.ps1` — Windows host orchestration (build image, quality, tests)

Human docs live under `README.md` and `docs/`. Agent guidance lives in this file and
under `.agents/skills/`, with Copilot-oriented mirrors under `.github/`.

## Agent Surface Map

| Path | Role |
| --- | --- |
| `AGENTS.md` | Canonical project rules for any coding agent |
| `.agents/skills/*/SKILL.md` | Task skills (quality, tests, install, PR review) |
| `.agent/instructions.md` | Short AI-agnostic pointer into this file |
| `.github/AGENTS.md` | Specialist mode index for GitHub Copilot agents |
| `.github/agents/*.agent.md` | Copilot specialist personas |
| `.github/skills/*/SKILL.md` | Copilot skill mirrors (keep aligned with `.agents/skills`) |
| `.github/instructions/*.instructions.md` | Path-scoped Copilot instructions |
| `.github/prompts/*.prompt.md` | Invokable Copilot prompts |
| `.github/copilot-instructions.md` | Repo-wide Copilot baseline |
| `docs/Instructions.md` | Human/AI docs index into `docs/` |

When behavior or gates change, update **this file** and any affected skill in the
same change set. Keep `.github/` mirrors consistent when the Copilot surface would
otherwise drift.

## Code Style & Testing Enforcement

- **Mandatory order**: format → lint/policy → tests → coverage (≥90%). Never skip a
  gate or reorder to hide failures.
- **No suppressions**: never add `# shellcheck disable`, `# noqa`, `# type: ignore`,
  `eslint-disable`, markdownlint disables, or equivalent. Fix the root cause.
  `tools/check_forbidden_suppressions.py` enforces this.
- **Line length**: non-Markdown files ≤ **140** characters
  (`tools/check_line_length.py`). Markdown MD013 is intentionally off in
  `.markdownlint.json`; prefer readable wraps anyway for shell/docs snippets.
- **Shell formatting**: `shfmt -i 4 -ci` on `*.sh` and `*.bats`.
- **Shell lint**: `shellcheck --severity=style --external-sources` on `*.sh`
  (see `.shellcheckrc`).
- **Python tooling** (`tests/transform_coverage.py`, `tools/*.py`): clean `ruff`
  format + check (`pyproject.toml`, line-length 140, LF endings).
- **YAML / JSON / Markdown**: `yamllint`, `jq empty`, `markdownlint` with
  `.markdownlint.json`.
- **PowerShell**: `PSScriptAnalyzer` on `tools/runners/run_tests.ps1` with
  `tools/config/PSScriptAnalyzerSettings.psd1` (RequiredVersion 1.25.0 in CI).
- **Auto-fix first**: run safe autofix (`shfmt -w`, `ruff check --fix`,
  `ruff format`, `markdownlint --fix` when available) before hand-editing lint
  failures.
- **Failure handling**: do not hide, suppress, or downgrade real failures. Install,
  wallpaper, and cron steps must report the real error and exit nonzero on failure.
- **Coverage**: merged kcov Cobertura total ≥ **90%**. Local runners update
  `assets/coverage.svg` via `tests/transform_coverage.py`. CI validates coverage
  and complexity but does not commit the badge — refresh the badge locally before
  shipping coverage-affecting changes.
- **Complexity policy**: `tools/coverage_metrics.py` with
  `--target-per-file 15 --hard-max-per-file 35 --target-avg 10 --hard-max-avg 25
  --enforce-complexity`. Prefer splitting helpers over gaming metrics.

Local entrypoints:

```sh
./tools/runners/quality.sh
./tools/runners/run_tests.sh          # inside srm-mock container, or via docker
```

Windows / full host orchestration:

```powershell
./tools/runners/run_tests.ps1
```

## Dependency & Mocking Policy

- Prefer real tools in the test image (`wget`, ImageMagick `convert`, cron helpers)
  over inventing fake owned APIs.
- **Never mock owned product scripts** (`install.sh`, `uninstall.sh`,
  `bing_wallpaper_auto_update.sh`). Tests must exercise the real scripts.
- Mock only external boundaries that cannot run safely in CI: live Bing HTTP,
  privileged SRM paths, and host-specific Synology services. Keep fixtures under
  `tests/mocks/` (for example `bing_response.json`) and deterministic PATH stubs.
- Avoid network dependency in unit/component/e2e suites; use local responses and
  filesystem fixtures.
- Keep mocks portable across Linux (primary) and Windows-hosted Docker workflows
  (`run_tests.ps1`). Prefer `os.path` / path helpers in Python; respect LF vs CRLF
  via `.gitattributes` / `.editorconfig`.

## Test Suite Structure

| Suite | Files | Focus |
| --- | --- | --- |
| Unit install | `tests/install.bats` | Wizard, env overrides, cron write, sed config |
| Unit uninstall | `tests/uninstall.bats` | Script + crontab removal |
| Unit wallpaper | `tests/wallpaper.bats` | Fetch/parse/deploy/overlay paths |
| Component | `tests/component.bats` | Multi-step composition without full E2E |
| E2E | `tests/e2e_tests.bats` | Install → run → uninstall style flows |

Runner flags (`tools/runners/run_tests.sh`):

- default (no flags): unit + component + e2e
- `--unit-only`, `--component-only`, `--e2e-only`
- `--unit-install`, `--unit-uninstall`, `--unit-wallpaper`
- `COVERAGE=1` enables kcov; merge requires unit + e2e together for the local
  full-suite badge path

Image: `tests/Dockerfile` tagged `srm-mock`. CI and local runners need
`--security-opt seccomp=unconfined` and `--cap-add SYS_PTRACE` for kcov.

## Command Execution & Live Reporting

- Stream command output live (`tee` when capturing logs). Do not swallow stdout/stderr
  of quality or test runs.
- Prefer repository runners over ad-hoc one-off lint/test commands so local and CI
  stay aligned.
- Example quality capture:

  ```bash
  set -euo pipefail
  mkdir -p coverage/logs
  ./tools/runners/quality.sh 2>&1 | tee coverage/logs/quality.log
  exit "${PIPESTATUS[0]}"
  ```

- Example full Docker test + coverage (Linux host):

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

## Always Update Agent Docs

- On bug fixes and features, update agent markdown in the **same change set** when
  rules, commands, invariants, or workflows change.
- Update root `AGENTS.md` and relevant `.agents/skills/*/SKILL.md` files.
- Mirror material changes into `.github/` agent/skill/instruction files when those
  surfaces would otherwise be wrong.
- Capture invariants and do/don't lessons — not a changelog dump.
- Treat stale agent docs as incomplete work (same as missing tests).

## SRM Shell Invariants

- Target **Synology SRM 1.3** (BusyBox/ash-oriented environment with some GNU tools).
  Prefer POSIX `sh` constructs in product scripts; avoid bashisms in
  `install.sh`, `uninstall.sh`, and `bing_wallpaper_auto_update.sh`.
- Product scripts must run as **root** on device (`id -u` check). Fail closed with a
  clear message when not root.
- Discover or tolerate layout variance for wallpaper resources; known paths include:
  - `/usr/syno/etc/login_background.jpg`
  - `/usr/syno/synoman/webman/resources/images/default_wallpaper`
  - `/usr/syno/synoman/webman/resources/images/theme/router/default_wallpaper`
- Clean up temp downloads via a private `mktemp -d` workdir and `trap` (never
  predictable world-writable `/tmp` paths).
- `SET_WELCOME_MSG` is DSM-oriented and **not supported on SRM**; do not document it
  as an SRM feature. Prefer `BURN_TEXT_OVERLAY` for login-screen metadata on SRM.
- Overlay text applies to the **login** image path only; keep the desktop/default
  wallpaper assets clean when overlay is enabled.
- ImageMagick `convert` is optional for overlay; when missing, skip overlay safely
  rather than crashing if the product path already guards with `which convert`.
- Bing/GitHub fetches use `wget` **with TLS verification** (never
  `--no-check-certificate`). Keep retries intentional and cover downloads with mocks
  in tests (do not call the live Bing API from CI tests). Cache overlay fonts under
  root-owned `/usr/local/share/bing-wallpaper/`, not `/tmp`.

## Install / Uninstall Invariants

- Human README one-liners stay interactive pasteable installs
  (`wget … | sudo sh`). Do not put `NON_INTERACTIVE=1` in human quick-start blocks.
- Automation/test knobs (keep working and documented for agents/tests, not as the
  primary human install story):
  - `LOCAL_INSTALL_PATH` — install from a local script copy (tests)
  - `NON_INTERACTIVE` — disable prompts
  - `FORCE_INTERACTIVE` / `FORCE_STDIN` — force prompt path under pipes
  - `BING_RESOLUTION`, `BING_MARKET`, `BURN_TEXT_OVERLAY` — pre-seed wizard answers
  - `CRON_HOUR`, `CRON_MIN` — schedule overrides
  - `TEST_MODE=1` — source/install without always entering `main` (test harness)
- Install writes to `/usr/local/bin/bing_wallpaper_auto_update.sh`, updates config via
  `sed`, manages `/etc/crontab` (backup `.bak`, remove old path lines, append new job
  as `root`), then reloads cron via `synoservicectl` → `synoservice` → `systemctl` →
  `killall -HUP crond` fallbacks.
- After scheduling, install runs the wallpaper script once (“apply now”).
- Uninstall removes the installed script path and matching crontab lines; keep
  behavior covered by `tests/uninstall.bats`.
- Fail closed on empty/missing download or copy targets.

## Wallpaper Pipeline Invariants

Pipeline order (keep docs and tests aligned):

1. Root / environment checks
2. Configuration (script defaults + installer-applied values)
3. Bing metadata fetch (`HPImageArchive` JSON) for `BING_MARKET`
4. Resolution suffix (`_UHD.jpg` vs `_1920x1080.jpg`)
5. Download image to temp path
6. Optional text overlay (`BURN_TEXT_OVERLAY`)
7. Deploy login + default wallpaper resources
8. Optional archive (`ENABLE_ARCHIVE` / `SAVE_PATH`)

Metadata parsing must remain resilient to title/copyright shapes used in tests.
Do not require `jq` on the router path if the product currently uses `grep`/`cut`
POSIX parsing — changing parsers requires SRM compatibility review and tests.

## CI & Dependency Pinning

- Workflow: `.github/workflows/ci.yml`
  - `quality` job first
  - Docker `srm-mock` build/cache
  - parallel unit / component / e2e
  - merge coverage + ≥90% gate + complexity summary
- Pin GitHub Actions to **immutable commit SHAs** with version comments.
- Pin external tools to explicit versions (examples currently used in CI):
  `ruff`, `yamllint`, `markdownlint-cli`, `shfmt` image tags, `shellcheck` image
  tags, `PSScriptAnalyzer` RequiredVersion, pip bootstrap version.
- Keep CI steps aligned with `tools/runners/quality.sh` and `run_tests.sh`.
  A local-only check that CI does not run (or the reverse) is incomplete work.
- Prefer deterministic installs (`apt-get` packages, pinned pip/npm versions).

## Specialist Modes (quick router)

- **Quality Guardian** — lint/format/policy/CI gate changes → skill `quality-gate`
- **SRM Shell Maintainer** — product shell / cron / wallpaper behavior
- **Test Expansion** — new or refactored BATS coverage → skill `test-runner` /
  `.github/skills/test-expansion`
- **Installer focus** — wizard and cron install paths → skill `installer-tester`
- **Full local pipeline** — skill `pipeline-runner`
- **Prepare release** — skill `prepare-release` (version from branch; sync
  `VERSION`, script headers, `docs/releases/`, README/docs pointers)
- **PR comment resolution** — skill `resolve-pr-comments` (user-requested)
- **CodeRabbit review/findings** — skill `review-with-coderabbit` (user-gated only)

# Development & Standards

Canonical agent rules and skill workflows: [`../AGENTS.md`](../AGENTS.md).

**Current release:** [v1.0.2](releases/v1.0.2.md)

## Mandatory Quality Flow

Every change must pass this order, locally and in CI:

1. Format checks.
2. Lint checks.
3. Tests.
4. Coverage verification.

Pre-test quality gate command (formatting, linting, and policy checks):

```sh
./tools/runners/quality.sh
```

Complete required Windows workflow (quality gate, tests, and coverage flow):

```powershell
./tools/runners/run_tests.ps1
```

Complete required Linux/container workflow (quality gate, tests, and coverage flow):

```sh
./tools/runners/run_tests.sh
```

CI must follow the same mandatory order and gates.

## Lint and Formatter Policy

- All quality checks are mandatory.
- Do not use lint suppression directives.
- Non-Markdown files must stay at 140 characters or fewer per line.
- Markdown is intentionally excluded from max line-length enforcement.
- CI and local checks must remain aligned.

## Testing & Coverage

- **Mandatory Coverage**: A minimum of **90% code coverage** is mandatory for all PRs.
- **Local Testing**: Run tests locally using `tools/runners/run_tests.ps1` (Windows) or `tools/runners/run_tests.sh` (Linux/Docker).
- **Badge Mandatory**: Always update the `assets/coverage.svg` badge before committing code. This is handled automatically by the test runners if coverage is enabled.
- **CI Enforcement**: The CI pipeline (`ci.yml`) validates coverage but **does not** update the badge. If coverage falls below 90%, the CI will fail.

## Coding Standards

- **Shell Scripting**: Follow `ShellCheck` recommendations.
- **Compatibility**: Ensure scripts are compatible with the restricted shell environment of Synology SRM (mostly BusyBox/Ash based, but some GNU tools are available).
- **Paths**: Use dynamic path discovery for SRM resource locations as they may vary between minor versions.
- **Cleanup**: Temp downloads must use a private `mktemp -d` workdir with trap cleanup (never predictable world-writable `/tmp` paths).
- **Downloads**: Keep TLS certificate verification enabled on all `wget` calls; never use `--no-check-certificate`.
- **Content validation**: Reject non-JPEG payloads (SOI magic) before ImageMagick or system wallpaper writes.
- **Archive safety**: Sanitize archive dates to exactly eight digits (`YYYYMMDD`) before building archive paths.
- **Documentation**: Update `README.md` and documentation in `docs/` when introducing new features or changing logic.

## CI and Dependency Pinning

- Pin GitHub Actions to immutable commit SHAs.
- Pin external tools to explicit stable versions.
- Prefer deterministic installs and reproducible builds.

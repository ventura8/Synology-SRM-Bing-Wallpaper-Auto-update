# Development & Standards

## Testing & Coverage

- **Mandatory Coverage**: A minimum of **90% code coverage** is mandatory for all PRs.
- **Local Testing**: Run tests locally using `run_tests.ps1` (Windows) or `run_tests.sh` (Linux/Docker).
- **Badge Mandatory**: Always update the `assets/coverage.svg` badge before committing code. This is handled automatically by the test runners if coverage is enabled.
- **CI Enforcement**: The CI pipeline (`ci.yml`) validates coverage but **does not** update the badge. If coverage falls below 90%, the CI will fail.

## Coding Standards

- **Shell Scripting**: Follow `ShellCheck` recommendations.
- **Compatibility**: Ensure scripts are compatible with the restricted shell environment of Synology SRM (mostly BusyBox/Ash based, but some GNU tools are available).
- **Paths**: Use dynamic path discovery for SRM resource locations as they may vary between minor versions.
- **Cleanup**: Ensure temporary downloaded files are cleaned up after processing.
- **Documentation**: Update `README.md` and documentation in `docs/` when introducing new features or changing logic.

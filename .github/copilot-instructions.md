# Copilot Instructions

## Project Focus

- Maintain compatibility with Synology SRM 1.3 shell environments.
- Prioritize deterministic automation and reproducible CI behavior.
- Keep coverage at 90% or higher.

## Mandatory Engineering Order

1. Run formatting checks.
2. Run linting checks.
3. Run tests.
4. Verify coverage outputs.

## Quality Gates

- All repository quality checks are mandatory locally and in CI.
- Do not add lint suppression directives such as shellcheck disable, noqa, or eslint-disable.
- Keep non-Markdown files at a maximum of 140 characters per line.

## Shell and Test Practices

- Prefer portable shell patterns and defensive quoting.
- Keep behavior in install and wallpaper flows verified by BATS tests.
- Keep mocks deterministic and avoid external network dependency in tests.

## CI and Dependency Practices

- Pin GitHub actions to immutable SHAs.
- Pin external tools to explicit stable versions.
- Keep CI changes aligned with local quality commands.

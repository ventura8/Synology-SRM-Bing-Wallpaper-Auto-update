# AGENTS

Canonical rules: [`../AGENTS.md`](../AGENTS.md)

Project skills: [`.agents/skills/`](../.agents/skills/) (mirrored under
`.github/skills/` for Copilot).

## Available Specialist Modes

### Quality Guardian

Use when asking for lint, formatter, static analysis, policy, and CI gate
enforcement changes. Skill: `quality-gate`.

### SRM Shell Maintainer

Use when changing shell script logic for SRM compatibility, install flow,
wallpaper flow, or cron behavior. Skill: `installer-tester` when install/uninstall
focused.

### Test Expansion Engineer

Use when adding or refactoring BATS unit, component, and E2E tests. Skill:
`test-runner` / `test-expansion`.

### Pipeline Runner

Use when validating full local health before a PR. Skill: `pipeline-runner`.

### Prepare Release

Use when bumping version everywhere and writing release notes. Skill:
`prepare-release`.

## Shared Rules

- Preserve reproducibility and pinned dependencies.
- Keep non-Markdown line length at 140 or fewer characters.
- Do not add lint suppression directives.
- Keep CI and local checks aligned.
- On every task, update all relevant markdown in the same change set (see **Always
  Update Relevant Markdown** in `AGENTS.md`).

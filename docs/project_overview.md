# Project Overview

A shell-based automation suite for Synology SRM 1.3 that synchronizes the daily Bing wallpaper to the router's login screen and desktop.

**Current release:** [v1.0.2](releases/v1.0.2.md)

## Directory Structure

- `/`: Public SRM entrypoint scripts (`install.sh`, `uninstall.sh`, `bing_wallpaper_auto_update.sh`).
- `/VERSION`: Release version single source of truth (`vMAJOR.MINOR.PATCH`).
- `/AGENTS.md`: Canonical AI/agent development rules.
- `/.agents/skills/`: Project agent skills (quality, tests, install, PR workflows).
- `/tests/`: BATS unit, component, and E2E tests + Dockerfile for testing.
- `/assets/`: Project assets (screenshots, coverage badge).
- `/docs/`: Technical documentation and AI instructions.
- `/docs/releases/`: Versioned release notes (GitHub Release body source).
- `/tools/runners/`: Local quality and test runner entrypoints.
- `/tools/config/`: Tool-specific configuration files used by local and CI runners.
- `/.github/`: CI workflows plus Copilot agents, skills, prompts, and instructions.
- `/coverage/`: Local coverage reports (gitignored).

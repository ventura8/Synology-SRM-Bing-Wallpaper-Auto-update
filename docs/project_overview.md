# Project Overview

A shell-based automation suite for Synology SRM 1.3 that synchronizes the daily Bing wallpaper to the router's login screen and desktop.

## Directory Structure

- `/`: Public SRM entrypoint scripts (`install.sh`, `uninstall.sh`, `bing_wallpaper_auto_update.sh`).
- `/tests/`: BATS unit, component, and E2E tests + Dockerfile for testing.
- `/assets/`: Project assets (screenshots, coverage badge).
- `/docs/`: Technical documentation and AI instructions.
- `/tools/runners/`: Local quality and test runner entrypoints.
- `/tools/config/`: Tool-specific configuration files used by local and CI runners.
- `/.github/workflows/`: CI/CD pipeline configuration.
- `/coverage/`: Local coverage reports (gitignored).

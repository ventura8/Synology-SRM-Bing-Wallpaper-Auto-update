---
applyTo: "**/*.{sh,bats}"
description: "Use when editing shell scripts and BATS tests for SRM workflows."
---

- Prefer POSIX `sh` in product scripts (`install.sh`, `uninstall.sh`,
  `bing_wallpaper_auto_update.sh`); avoid new bashisms on the router path.
- Use robust quoting and avoid word-splitting bugs.
- Keep test mocks deterministic and local-file based (`tests/mocks/`).
- Keep script behavior compatible with constrained SRM environments.
- Avoid assumptions about optional binaries when fallbacks are required
  (e.g. ImageMagick `convert`, cron reload helpers).
- Fail closed on missing root or empty download/install targets.
- See root `AGENTS.md` for install/cron/wallpaper invariants.

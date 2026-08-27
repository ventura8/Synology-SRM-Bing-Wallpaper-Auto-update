# Gemini CLI — Synology SRM Bing Wallpaper Auto-Update

Canonical agent rules for this repository: **[AGENTS.md](AGENTS.md)**.

This file is a thin project entrypoint for Gemini CLI context. Prefer `AGENTS.md`
over duplicating rules here.

Also load as needed:

- [docs/Instructions.md](docs/Instructions.md)
- [docs/project_overview.md](docs/project_overview.md)
- [docs/pipeline_logic.md](docs/pipeline_logic.md)
- [docs/development_standards.md](docs/development_standards.md)
- [`.agents/skills/`](.agents/skills/)

Optional import (if using Gemini `@` imports in your local setup):

```text
@./AGENTS.md
```

Quality/test gate order and SRM shell invariants live once in `AGENTS.md`.

**Every task:** update all relevant markdown in the same change set (see **Always Update
Relevant Markdown** in `AGENTS.md`).

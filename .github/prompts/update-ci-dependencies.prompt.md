---
mode: ask
description: "Upgrade CI dependencies with immutable pins and validate the pipeline."
---

Follow root `AGENTS.md` and `.agents/skills/ci-dependency-upgrade/SKILL.md`.

1. Inventory pins in `.github/workflows/ci.yml` and related runners.
2. Resolve latest stable SHAs/tags/versions upstream.
3. Update pins with version comments; keep local/CI alignment.
4. Run quality checks and representative Docker tests.
5. Summarize bumps and any intentional skew left behind.

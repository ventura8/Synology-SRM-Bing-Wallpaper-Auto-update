---
mode: ask
description: "Add or strengthen deterministic BATS coverage for shell behavior."
---

Follow root `AGENTS.md` and `.agents/skills/test-runner/SKILL.md`.

1. Identify uncovered or weakly asserted behavior in install, uninstall, or wallpaper flows.
2. Add deterministic BATS tests with local mocks only (no live Bing network).
   Cover accepted inputs, fallback behavior, and rejected/failure inputs.
3. Do not mock owned product scripts.
4. Re-run quality and the relevant test slices; keep total repository coverage ≥90%.
5. Update all relevant markdown in the same change set when tests or behavior change
   (see **Always Update Relevant Markdown** in `AGENTS.md`).

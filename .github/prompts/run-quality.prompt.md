---
mode: ask
description: "Run the full mandatory quality suite and fix findings without suppressions."
---

Follow root `AGENTS.md` and `.agents/skills/pipeline-runner/SKILL.md`.

Run the project quality pipeline end-to-end:

1. Run formatting checks first.
2. Run linting and validation checks second (including line-length and suppression policy checks).
3. Run the full test suite third.
4. Verify total coverage is at least 90% fourth.
5. Summarize changed files and remaining risks last.

All repository quality checks are mandatory both locally and in CI, including tests and coverage enforcement.
Do not add lint suppressions.

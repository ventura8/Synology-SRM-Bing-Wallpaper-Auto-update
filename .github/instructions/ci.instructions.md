---
applyTo: ".github/workflows/**/*.yml"
description: "Use when updating workflow design, CI dependencies, and pipeline reliability rules."
---

- Pin actions using immutable commit SHAs.
- Keep quality checks blocking and early in the workflow graph.
- Keep workflow triggers updated when standards or quality scripts change.
- Prefer deterministic dependency installation paths.

---
applyTo: "**/*.{sh,bats}"
description: "Use when editing shell scripts and BATS tests for SRM workflows."
---

- Use robust quoting and avoid word-splitting bugs.
- Keep test mocks deterministic and local-file based.
- Keep script behavior compatible with constrained shell environments.
- Avoid assumptions about optional binaries when fallbacks are required.

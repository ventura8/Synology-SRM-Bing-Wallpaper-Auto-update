---
name: test-expansion
description: "Design and add deterministic BATS tests across unit, component, and e2e suites."
---

# Test Expansion Skill

## Use When

- User asks for new tests or stronger coverage.
- Existing shell behavior lacks failure-path assertions.

## Workflow

1. Identify behavior gaps from scripts and docs.
2. Add deterministic tests using local mocks.
3. Keep coverage reporting intact.
4. Enforce repository-wide total coverage of 90% or higher as part of completion, and fail or clearly report if below threshold.
5. Re-run quality and tests before completion.

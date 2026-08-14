---
name: test-expansion
description: "Design and add deterministic BATS tests across unit, component, and e2e suites."
---

# Test Expansion Skill

Canonical runner guidance: [`.agents/skills/test-runner/SKILL.md`](../../../.agents/skills/test-runner/SKILL.md).

## Use When

- User asks for new tests or stronger coverage.
- Existing shell behavior lacks failure-path assertions.

## Workflow

1. Identify behavior gaps from scripts and docs.
2. Add deterministic tests using local mocks (`tests/mocks/`).
3. Never mock owned product scripts; stub only external boundaries.
4. Keep coverage reporting intact; enforce ≥90% merged coverage.
5. Re-run quality and relevant BATS slices before completion.

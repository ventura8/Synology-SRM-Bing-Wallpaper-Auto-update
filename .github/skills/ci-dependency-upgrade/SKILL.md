---
name: ci-dependency-upgrade
description: "Upgrade CI dependencies to latest stable releases and pin immutable references."
---

# CI Dependency Upgrade Skill

## Use When

- User asks to update workflow dependencies.
- User requests immutable pins.
- CI broke due upstream dependency drift.

## Workflow

1. Discover current action/tool versions.
2. Resolve latest stable tags upstream.
3. Update workflow and tooling pins.
4. Validate pipeline behavior after updates.

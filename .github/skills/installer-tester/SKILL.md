---
name: installer-tester
description: "Validate install.sh and uninstall.sh wizard, cron, and env-override behavior."
---

# Installer Tester Skill

Canonical skill text:
[`.agents/skills/installer-tester/SKILL.md`](../../../.agents/skills/installer-tester/SKILL.md).

## Use When

- Changing `install.sh` / `uninstall.sh`
- Changing cron scheduling or wizard prompts

## Workflow

1. Preserve POSIX `sh` + root fail-closed behavior.
2. Cover interactive and env-preset paths in BATS.
3. Retain deterministic non-root fail-closed BATS for both `install.sh` and
   `uninstall.sh`.
4. Run `--unit-install`, `--unit-uninstall`, and e2e when composition changes.
5. When knobs or fallbacks change, sync `AGENTS.md`, the canonical
   `.agents/skills/installer-tester/SKILL.md`, and this `.github/skills/` mirror.

---
name: review-with-coderabbit
description: >-
  Run a CodeRabbit CLI review on local changes, or fix stored plugin/CLI
  findings. Verify each finding, fix only valid ones, end with a summary report.
  User-gated only — do not auto-invoke.
disable-model-invocation: true
---

# Review with CodeRabbit

User-gated modes:

| Mode | When asked | What runs |
| --- | --- | --- |
| **Review** | CodeRabbit review / review-with-coderabbit | New CLI review on chosen diff |
| **Findings** | Findings / fix plugin findings | Replay/fix stored findings |

## Hard rules

1. Run only when the user explicitly invokes this skill.
2. Classify each finding: valid / not valid / blocked / unsure.
3. Fix only valid items with the smallest safe change; ask on blocked/unsure.
4. Cover main issues and nitpicks unless the user narrows scope.
5. End with a summary: fixed how / skipped why + counts.
6. Respect repo gates: no suppressions, ≤140 non-Markdown columns, SRM POSIX
   constraints, tests for behavior changes.

## After fixes

```bash
./tools/runners/quality.sh
# then relevant Docker BATS slice or full pipeline
```

Update `AGENTS.md` when a valid finding reveals a lasting invariant.

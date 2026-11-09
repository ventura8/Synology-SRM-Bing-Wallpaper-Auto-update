---
name: review-with-greptile
description: >-
  Handle Greptile PR reviews: read its findings, verify and fix valid ones, and
  request a re-review only when it is worth a credit. Use when a Greptile
  review lands on a PR or the user asks for a Greptile review.
---

# Review with Greptile

Greptile is the hosted PR reviewer for this repository, configured in
[`.greptile/config.json`](../../../.greptile/config.json).

## Budget

The plan includes **50 reviews per month**. Each completed review spends one.

- Greptile auto-reviews **once, when a PR is opened** (`"autoReview": ["open"]`).
  Pushes do not trigger a new review.
- Draft PRs are not reviewed. Open PRs as drafts while iterating, then mark
  them ready for review to spend one review on the finished change.
- Request a re-review (`@greptileai` comment on the PR) only after a large or
  risky follow-up push, and at most once per PR unless the user asks.
  Never re-request just to clear a resolved finding.

## Handling findings

1. Read the review and every inline comment on the current head.
2. Classify each finding: valid / not valid / blocked / unsure.
3. Fix valid items with the smallest safe change and push.
4. Reply once per thread: the fixing commit, or why it stays as is. Resolve it.
5. Ask the user about blocked or unsure items.
6. Respect repo gates: no suppressions, ≤140 non-Markdown columns, SRM POSIX
   constraints, tests for behavior changes (see `AGENTS.md`).

## After fixes

```bash
./tools/runners/quality.sh
# then the relevant Dockerized BATS slice or the full pipeline
```

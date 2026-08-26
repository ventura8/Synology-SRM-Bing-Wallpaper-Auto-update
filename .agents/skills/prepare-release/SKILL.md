---
name: prepare-release
description: >-
  Prepare a versioned release from the current branch: set VERSION, write
  docs/releases notes, sync README/docs version badges and pointers, and align
  script Version headers. Use when releasing, cutting release notes, or bumping
  version across the repo.
---

# Prepare Release Skill

Use when the user asks to prepare a release, cut release notes, bump version
everywhere, or finalize the current versioned branch for tagging/GitHub Release.

## Goals

1. Derive the release version from the **current git branch name**.
2. Set root [`VERSION`](../../../VERSION) to that version (repo **SSOT**).
3. Sync script headers, README badge, and docs that cite the current release.
4. Create/update `docs/releases/vX.Y.Z.md` (GitHub Release body source).
5. Do **not** commit, amend, tag, push, or `gh release create` unless the user
   explicitly asks in the same turn.

## Version from branch

Parse `git branch --show-current`:

| Branch example | Version |
| ---------------- | ------- |
| `feature/v1.0.2` | `v1.0.2` |
| `release/v1.0.2` | `v1.0.2` |
| `v1.0.2` | `v1.0.2` |
| `feature/1.0.2` | `v1.0.2` |

Rules:

1. Extract the first semver-like token `MAJOR.MINOR.PATCH` (optional leading `v`).
2. Normalize to **`vMAJOR.MINOR.PATCH`** for `VERSION`, tags, badges, and docs.
3. Script header form is **`Version: MAJOR.MINOR.PATCH`** (no leading `v`).
4. If no version can be parsed, **stop** and ask the user.

## Version touchpoints (keep in sync)

| Path | Form |
| ---- | ---- |
| `VERSION` | `vX.Y.Z` + newline |
| `bing_wallpaper_auto_update.sh` header | `Version: X.Y.Z` |
| `install.sh` / `uninstall.sh` headers | `Version: X.Y.Z` |
| `README.md` release badge | `release-vX.Y.Z` → `docs/releases/vX.Y.Z.md` |
| `docs/project_overview.md` | **Current release:** link |
| `docs/development_standards.md` | **Current release:** link |
| `docs/Instructions.md` | Release notes index entry |
| `docs/releases/vX.Y.Z.md` | Full release notes |

Leave historical `docs/releases/vPREV.md` unchanged.

## Workflow

### 1) Inspect

```bash
git branch --show-current
git status -sb
git log --oneline main..HEAD
git diff --stat main...HEAD
git diff --stat HEAD
```

### 2) Draft notes from the full branch delta

Cover product, security, tests, coverage, and docs/agent changes that actually
land in the release. Mirror tone of the latest prior file under `docs/releases/`.
Include compare link `vPREV...vX.Y.Z` when useful.

### 3) Write version + docs

1. Write `VERSION`.
2. Update the three public script Version headers.
3. Write `docs/releases/vX.Y.Z.md`.
4. Sync README badge + docs current-release pointers.
5. Update all relevant markdown touched by the release (see **Always Update Relevant
   Markdown** in `AGENTS.md`), including pipeline/standards docs when product
   invariants changed.

### 4) Hygiene checklist (release-hygiene)

- Coverage floor still stated as **90%** where mentioned.
- Badge rule: local update of `assets/coverage.svg`; CI does not refresh it.
- TLS / temp-file / archive safety notes match the product scripts.
- `AGENTS.md` skill index lists skills that exist.
- No contradictory install/quality commands across README and runners.

### 5) Verify (no commit unless asked)

```bash
test "$(tr -d '[:space:]' < VERSION)" = "vX.Y.Z"
test -f docs/releases/vX.Y.Z.md
grep -n "Version: X.Y.Z" install.sh uninstall.sh bing_wallpaper_auto_update.sh
grep -n "vX.Y.Z" README.md docs/project_overview.md docs/development_standards.md docs/Instructions.md
```

## Hard rules

1. Version comes from the **branch name**, written to root **`VERSION`**.
2. GitHub description path is always `docs/releases/vX.Y.Z.md`.
3. Do not invent features absent from the branch diff.
4. Do not amend/commit/tag/push/`gh release create` without an explicit ask.
5. Prefer running `pipeline-runner` before tagging if tests were not just validated.

## Tagging triggers the GitHub Release (automated, do not hand-run `gh release create`)

Once `VERSION` and `docs/releases/vX.Y.Z.md` are committed on the branch that will
become `main`, the only remaining step to publish is creating and pushing the tag:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

`.github/workflows/release.yml` fires on that `v*` tag push, verifies `VERSION`
matches the tag and `docs/releases/vX.Y.Z.md` exists with a non-empty H1 that
starts with the tag plus a non-empty body, installs a pinned `gh` CLI, then runs
`gh release create --verify-tag` with the notes file's H1 as the title and the rest
as the body (`--verify-tag` fails closed if the remote tag is gone). Only tag/push
when the user explicitly asks — this publishes a public release.

## Output to the user

1. Parsed version + branch + `VERSION` contents
2. Paths updated
3. Whether commit / tag+push is still pending (tagging publishes automatically via
   `release.yml` — no manual `gh release create`)

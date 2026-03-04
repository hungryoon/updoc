---
slug: improve-up-workflow
created: 2026-03-04
status: done
completed: 2026-03-04
branch: feat/improve-up-workflow
---

# improve-up-workflow

## Background

After running `/updoc:up` and committing the results, the next `/updoc:up` detects updoc's own output files (overview.md, updoc.config.json) as "changed code" and unnecessarily regenerates documentation — creating a sync loop. Additionally, completed missions remain at `status: draft` with no notification mechanism.

## AS-IS

1. **Sync loop**: `up.sh` diff calculation (`git diff --name-only $last_sync_commit HEAD`) does not filter out updoc-managed files. Each `/updoc:up` → commit → `/updoc:up` cycle detects changes.

2. **No mission status notification**: `up.md` Step 5 only handles missions with `merged: true`. Missions committed directly to main or without a branch are not detected. Completed work is left stale.

## TO-BE

1. **Sync loop resolved**: Exclude updoc-managed paths (`updocs/`, `updoc.config.json`) from diff calculation. When only updoc files have changed, set `mode: no_change` and skip documentation update.

2. **Mission completion notification**: During `/updoc:up`, notify user of all non-done missions. Offer to close merged missions; display others for awareness.

## Impact Scope

- **updoc** (scripts): `scripts/up.sh` — add diff filtering logic, introduce `no_change` mode
- **updoc** (commands): `commands/up.md` — Step 4: `no_change` handling, Step 5: full mission notification, Step 6: conditional sync state update, Step 7: `no_change` report

## API Contracts

N/A — internal logic change. `up.sh` JSON output gains `mode: "no_change"` value.

## Tasks

- updoc-1: `scripts/up.sh` diff filtering — exclude updoc-managed files (`docs_path/`, `updoc.config.json`), introduce `no_change` mode
- updoc-2: `commands/up.md` Step 4 — add `no_change` mode handling case
- updoc-3: `commands/up.md` Step 5 — notify all non-done missions (merged → offer to close, others → display for awareness)
- updoc-4: `commands/up.md` Step 6, 7 — skip sync state update for `no_change` projects, add `no_change` report example

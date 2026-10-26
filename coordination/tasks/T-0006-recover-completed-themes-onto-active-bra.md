---
id: T-0006
title: Recover completed themes onto active branch
milestone: M0
status: in-progress
priority: P0
owner: "codex-r9v2"
claimed: "2026-10-26T12:02"
depends: [T-0005]
human: [HR-0019]
updated: 2026-10-26
---
# T-0006 · Recover completed themes onto active branch

## Goal
Bring the intact October 24 theme, HUD, reference-art and dynamic-background commits from local main into istiaque_leon while preserving the startup fix and all existing history.

## Context and references
- Owner reports October 24 work appears lost after launching the older istiaque_leon branch.
- Local main still points to adf7c84 with T-0314/T-0315/T-0316; all ten LFS background assets and previews verified by size and SHA-256.
- GitHub Desktop stash contains reversions of T-0316 and must remain preserved without application.

## Acceptance criteria
- [ ] Preserve backup references and merge completed October 24 history into istiaque_leon.
- [ ] Retain the startup fix, compiled translations and all theme/motion checks when resolving conflicts.
- [ ] Verify ten theme assets, actual theme selection, HUD and dynamic environments render again.
- [ ] Document branch cause and recovery; leave stash and shared history intact.
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-26 created by codex-r9v2
- 2026-10-26 claimed by codex-r9v2

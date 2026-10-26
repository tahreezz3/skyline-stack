---
id: T-0315
title: Match bright reference backgrounds for all themes
milestone: M3
status: done
priority: P1
owner: "codex-r6b2"
claimed: "2026-10-24T06:28"
depends: [T-0314]
human: [HR-0019]
updated: 2026-10-24
---
# T-0315 · Match bright reference backgrounds for all themes

## Goal
Replace shared lo-fi scenery with distinct bright background-only environments based on all ten owner references; preserve tower art, HUD and gameplay.

## Context and references
- Owner correction: each supplied reference has distinct bright scenery; reject the shared purple sun, generic hills and dull palette.
- `docs/art/BACKGROUND_REVISION.md`, owner reference folder and exact asset prompts/manifest.

## Acceptance criteria
- [x] Ten distinct environment-only art assets preserve each owner reference setting and brightness.
- [x] Shared purple sun, hills, skyline overlays and height-driven dull tint removed.
- [x] Live tower/crane/HUD remain independent; gameplay/config balance and saves unchanged.
- [x] Aspect-cover rendering verified across all ten themes and narrow/tall portrait layouts.
- [x] Asset provenance/prompts recorded, import and background contracts validated.
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-24 created by codex-r6b2
- 2026-10-24 claimed by codex-r6b2
- 2026-10-24 done by codex-r6b2: Ten reference-matched environment-only artworks integrated; generic purple sun/hills and height tint removed. 1169 checks, native background gallery and portrait layouts verified; prompts/provenance/session recorded.

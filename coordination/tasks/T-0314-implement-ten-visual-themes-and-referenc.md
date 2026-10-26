---
id: T-0314
title: Implement ten visual themes and reference HUD
milestone: M3
status: done
priority: P1
owner: "codex-p8m4"
claimed: "2026-10-24T05:42"
depends: []
human: [HR-0019]
updated: 2026-10-24
---
# T-0314 · Implement ten visual themes and reference HUD

## Goal
Implement the supplied v001-v010 theme package as procedural presentation with theme selection and compact HUD; preserve authoritative hybrid rules and save compatibility.

## Context and references
- Owner-supplied v001-v010 package; hybrid master prompt and Word brief take precedence over stale precision-only text.
- Implementation notes: `docs/art/THEME_IMPLEMENTATION.md`.

## Acceptance criteria
- [x] All ten themes selectable with distinct architecture, scenery and matching active/placed modules.
- [x] Compact viewport-anchored hearts, floor meter and population HUD; existing controls/restart preserved.
- [x] Core rules/config/fixtures/progression/save schema unchanged; live hybrid boundaries covered.
- [x] Real-click theme integration tour passes, including single resolution and narrow/tall HUD bounds.
- [x] Rendered gallery reviewed for all themes and portrait layouts.
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes
- GitHub synchronization needs authentication (HR-0019); local implementation and validation are complete.

## Log
- 2026-10-24 created by codex-p8m4
- 2026-10-24 claimed by codex-p8m4
- 2026-10-24 done by codex-p8m4: Ten procedural themes, session selector, compact responsive HUD; hybrid rules and saves preserved. 1069 checks, real-click theme tour and rendered galleries verified. See session log.

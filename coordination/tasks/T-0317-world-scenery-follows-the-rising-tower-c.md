---
id: T-0317
title: World scenery follows the rising tower camera
milestone: M3
status: in-progress
priority: P1
owner: "codex-w2h7"
claimed: "2026-10-26T12:18"
depends: [T-0316, T-0006]
human: []
updated: 2026-10-26
---
# T-0317 · World scenery follows the rising tower camera

## Goal
Replace the camera-attached scenic image with bright, distinct world-space environments; ground, landmarks, water and activity must leave the view naturally as the tower camera rises, revealing higher skyline and sky.

## Context and references
- Owner rejects full scenic still images: the environment must change naturally as the tower/camera rises.
- Preserve ten individual reference settings and bright palettes; ground/landmarks must be world anchored.

## Acceptance criteria
- [ ] Replace scenic-image background with distinct 3D world environments and procedural sky.
- [ ] Ground, water and landmarks remain fixed in world space while the camera climbs and descends.
- [ ] Higher skyline/cloud bands enter naturally; activity and theme lighting respect pause/Reduced Motion.
- [ ] Verify rendered ground/medium/high tower progression for all themes and export an ascent preview.
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-26 created by codex-w2h7
- 2026-10-26 claimed by codex-w2h7

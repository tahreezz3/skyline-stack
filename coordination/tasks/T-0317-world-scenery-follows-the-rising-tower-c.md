---
id: T-0317
title: World scenery follows the rising tower camera
milestone: M3
status: done
priority: P1
owner: "codex-w2h7"
claimed: "2026-10-26T12:18"
depends: [T-0316, T-0006]
human: [HR-0019]
updated: 2026-10-26
---
# T-0317 · World scenery follows the rising tower camera

## Goal
Replace the camera-attached scenic image with bright, distinct world-space environments; ground, landmarks, water and activity must leave the view naturally as the tower camera rises, revealing higher skyline and sky.

## Context and references
- Owner rejects full scenic still images: the environment must change naturally as the tower/camera rises.
- Preserve ten individual reference settings and bright palettes; ground/landmarks must be world anchored.

## Acceptance criteria
- [x] Replace scenic-image background with distinct 3D world environments and procedural sky.
- [x] Ground, water and landmarks remain fixed in world space while the camera climbs and descends.
- [x] Higher skyline/cloud bands enter naturally; activity and theme lighting respect pause/Reduced Motion.
- [x] Verify rendered ground/medium/high tower progression for all themes and export an ascent preview.
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes
- Active scenery is original 3D world geometry; only infinite atmosphere follows the camera. The old paintings are retained as reference/provenance.
- 259 world contracts cover distinct geometry, fixed landmarks, altitude continuity and visible cloud identity. Full suite: 1,846 checks, zero failures.
- Native ascent exports cover all ten worlds at 0/6/12/20/40 floors and 24-floor climb clips. Native world-activity/pause/Reduced Motion pixel checks pass for all ten.
- docs/art/previews/world-ascent.mp4 and .webp show actual world/camera progression.
- Recovery of the earlier work is complete separately in merge 9aedf10; Git synchronization still needs HR-0019.

## Log
- 2026-10-26 created by codex-w2h7
- 2026-10-26 claimed by codex-w2h7
- 2026-10-26 codex-w2h7: replaced the fixed image composition with world-space geometry and independent activity, procedural atmosphere and bounded height-band clouds. Added ascent/descent and cloud-continuity verification, ADR-0007, configuration documentation, original-asset provenance and rendered climb previews.

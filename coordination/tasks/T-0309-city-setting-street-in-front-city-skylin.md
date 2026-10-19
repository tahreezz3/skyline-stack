---
id: T-0309
title: City setting: street in front, city skyline behind, lower camera
milestone: M3
status: done
priority: P0
owner: "opus55-a7k2"
claimed: "2026-10-19T14:46"
depends: []
human: []
updated: 2026-10-19
---
# T-0309 · City setting: street in front, city skyline behind, lower camera

## Goal
Owner feedback 2026-10-19: the game should feel like it is in a city; the background is boring. Add a road in front, a lively city behind, and lower the camera angle so there is much less grass and trees in the foreground.

## Context and references
-

## Acceptance criteria
- [x] Camera lowered to 6° pitch; ground line low on screen; only the street shows in the foreground (no grass/trees)
- [x] Street in front: sidewalks, curbs, asphalt, dashed centre and edge lines, zebra crossing, street lights
- [x] Cars drive both ways (decoration only)
- [x] Neighbouring buildings frame the tower; three city rows behind with shop fronts, window grids and rooftop props
- [x] Background kept low, hazy (depth fog) and blurred so the tower stays readable; city windows light up at night
- [x] City rows rise slower than the camera (parallax): the player climbs above the city
- [x] Tests: street has no overlapping top faces, the space behind the tower stays clear, rows deterministic
- [x] Style frames, art spec section 2.1b, HR-0006 updated
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-19 created by opus55-a7k2
- 2026-10-19 claimed by opus55-a7k2
- 2026-10-19 done by opus55-a7k2: city_kit.gd (street, city rows with vertex colours, cars, street lights), 6° camera, ground lower on screen, depth fog + DOF for readability, night windows; verified day/dusk frames

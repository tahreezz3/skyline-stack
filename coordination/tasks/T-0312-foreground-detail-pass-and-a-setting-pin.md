---
id: T-0312
title: Foreground detail pass and a setting pink sun
milestone: M3
status: done
priority: P1
owner: "opus55-a7k2"
claimed: "2026-10-19T15:41"
depends: []
human: []
updated: 2026-10-19
---
# T-0312 · Foreground detail pass and a setting pink sun

## Goal
Owner feedback 2026-10-19: more graphic detail on foreground objects (street lights, bench, planter, cars, cat, sidewalk, road props); add a pinkish lo-fi sun that slowly fades as the tower climbs into night.

## Context and references
-

## Acceptance criteria
- [x] Detailed street lamps (lanterns glow, warm light pools at night), slatted bench, wooden flower planter, café sign, hydrant, trash bin, manhole, storm drain
- [x] Three car models with real silhouettes (hatchback, retro car, van): bumpers, lights, mirrors, hubcaps
- [x] Tiled sidewalk with grout lines near the tower (no overlapping faces, tested)
- [x] Cat detail: cheek tufts, whiskers, four-segment tail with cream tip
- [x] Pink lo-fi sun with glow and retro bands, sinking and fading towards night; pink rim light from the sun's side
- [x] Tests for props; style frames and art spec §2.1d updated
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-19 created by opus55-a7k2
- 2026-10-19 claimed by opus55-a7k2
- 2026-10-19 done by opus55-a7k2: street_props.gd + Builder.extrude, tiled sidewalk, lamp light pools, cat detail, lo-fi sun + rim light; verified day/dusk/night frames

---
id: T-0401
title: City map grid and placement
milestone: M4
status: done
priority: P1
owner: "opus55-a7k2"
claimed: "2026-10-13T15:44"
depends: [T-0202]
human: []
updated: 2026-10-13
---
# T-0401 · City map grid and placement

## Goal
City map scene: grid of plots, place a completed tower on a free plot, persist it in the save.

## Context and references
- docs/01_GDD.md §5

## Acceptance criteria
- [x] Placed towers saved and restored
- [x] Core placement logic tested
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 done by opus55-a7k2: city_state.gd (place/validate/population) + city_map.json + save schema v3 with migration; city_map screen with tower tray and tap-to-place; menu City button and results 'Place it in your city'; 13 tests + tour step that simulates a placement through the UI

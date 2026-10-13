---
id: T-0102
title: Juice pass with placeholder effects
milestone: M1
status: done
priority: P1
owner: "opus55-a7k2"
claimed: "2026-10-13T15:15"
depends: [T-0003]
human: []
updated: 2026-10-13
---
# T-0102 · Juice pass with placeholder effects

## Goal
Add screen shake (scaled by blocks lost), camera kick on perfect, squash on land, dust puffs, sparkle on perfect, tumbling debris polish, combo bar pulse. Use simple shapes until HR-0007 lands.

## Context and references
- game/scripts/game/tower_game.gd
- docs/01_GDD.md §8

## Acceptance criteria
- [x] Each event type in GDD §8 has visible feedback
- [x] No rule code changed
- [x] Effects can be toggled off in a config flag for accessibility (reduced motion)
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 done by opus55-a7k2: feel.json + shake (scaled by blocks lost), camera kick, squash, dust and sparkle particles, combo bar pulse/red warning, stacked popups; reduced_motion setting with a new Settings screen; verified from captured frames

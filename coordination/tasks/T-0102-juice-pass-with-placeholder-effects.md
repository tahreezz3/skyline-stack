---
id: T-0102
title: Juice pass with placeholder effects
milestone: M1
status: todo
priority: P1
owner: ""
claimed: ""
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
- [ ] Each event type in GDD §8 has visible feedback
- [ ] No rule code changed
- [ ] Effects can be toggled off in a config flag for accessibility (reduced motion)
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner

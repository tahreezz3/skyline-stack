---
id: T-0106
title: First block on the foundation never wobbles
milestone: M1
status: done
priority: P0
owner: "opus55-a7k2"
claimed: "2026-10-19T14:02"
depends: []
human: []
updated: 2026-10-19
---
# T-0106 · First block on the foundation never wobbles

## Goal
Owner bug 2026-10-19: the first block placed anywhere inside the building zone must not make the tower wiggle; off-centre first blocks currently feed the wobble window.

## Context and references
-

## Acceptance criteria
- [x] Inside the building zone (first_block_zone 0.62) the first block adds no wobble and is stable
- [x] Outside the zone it topples (collapse) or misses as before
- [x] Perfect snap and residents unchanged
- [x] 4 new tests
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-19 created by opus55-a7k2
- 2026-10-19 claimed by opus55-a7k2
- 2026-10-19 done by opus55-a7k2: first_block_zone rule in TowerState; config, docs, tuning log, 4 tests

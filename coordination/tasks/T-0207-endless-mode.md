---
id: T-0207
title: Endless mode
milestone: M2
status: done
priority: P2
owner: "opus55-a7k2"
claimed: "2026-10-13T15:12"
depends: [T-0201]
human: []
updated: 2026-10-13
---
# T-0207 · Endless mode

## Goal
Round with target_height 0, increasing difficulty, best-height tracking.

## Context and references
- docs/01_GDD.md §3.4

## Acceptance criteria
- [x] Selectable from menu
- [x] Best height saved
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 done by opus55-a7k2: Endless button on menu, target_height 0, best under best_by_type.endless (+ test)

---
id: T-0203
title: Player level and progression rules
milestone: M2
status: done
priority: P1
owner: "opus55-a7k2"
claimed: "2026-10-13T15:08"
depends: [T-0002]
human: []
updated: 2026-10-13
---
# T-0203 · Player level and progression rules

## Goal
Core script that turns lifetime population into level and unlocked types (levels.json). Pure and tested.

## Context and references
- game/config/levels.json
- docs/01_GDD.md §4

## Acceptance criteria
- [x] Progression script in scripts/core with tests
- [x] Level-up event on GameEvents
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 done by opus55-a7k2: scripts/core/progression.gd + tests/test_progression.gd (10 checks); levels.json no longer duplicates unlocks; level_up and block_type_unlocked signals

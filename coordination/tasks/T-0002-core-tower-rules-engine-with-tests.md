---
id: T-0002
title: Core tower rules engine with tests
milestone: M0
status: done
priority: P0
owner: "opus55-planner"
claimed: ""
depends: [T-0001]
human: []
updated: 2026-10-13
---
# T-0002 · Core tower rules engine with tests

## Goal
Implement TowerState (perfect snap, stack, collapse-until-stable, miss and lives, wobble, combo, roof) with headless tests.

## Context and references
- game/scripts/core/tower_state.gd
- game/tests/run_tests.gd
- docs/01_GDD.md §3

## Acceptance criteria
- [x] 38 tests pass headless
- [x] All numbers read from config/tower_rules.json
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner and completed in the foundation session

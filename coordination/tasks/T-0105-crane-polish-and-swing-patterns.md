---
id: T-0105
title: Crane polish and swing patterns
milestone: M1
status: todo
priority: P2
owner: ""
claimed: ""
depends: [T-0101]
human: []
updated: 2026-10-13
---
# T-0105 · Crane polish and swing patterns

## Goal
Pendulum-style rope, hook, and swing patterns that vary with height (pauses, small amplitude changes). Keep patterns data-driven.

## Context and references
- docs/01_GDD.md §3.5

## Acceptance criteria
- [ ] Swing patterns configured in tower_rules.json
- [ ] Deterministic for a given seed
- [ ] Documented in 03_DATA_SPEC.md
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes
- Uses placeholders so it can start now. Final sign-off or integration needs [HR-0005] (see HUMAN_NEEDED.md); if that is not delivered when the work is done, set status `review` and say so in the Log.

## Log
- 2026-10-13 created by opus55-planner

---
id: T-0101
title: Tune core stacking constants
milestone: M1
status: todo
priority: P0
owner: ""
claimed: ""
depends: [T-0003]
human: []
updated: 2026-10-13
---
# T-0101 · Tune core stacking constants

## Goal
Make the drop feel great: tune snap window, max/stable offsets, crane speed curve, gravity, sway, combo timing. Evaluate the team's alternative combo idea (next N blocks score double) against the current pool formula.

## Context and references
- game/config/tower_rules.json
- docs/01_GDD.md §3
- docs/08_TESTING.md §4

## Acceptance criteria
- [ ] A config change log in this task's Log with before/after values and why
- [ ] Human playtest answers (HR-0017) addressed
- [ ] Tests updated for changed invariants
- [ ] GDD §3 updated with final values and the chosen combo variant
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes
- Uses placeholders so it can start now. Final sign-off or integration needs [HR-0017] (see HUMAN_NEEDED.md); if that is not delivered when the work is done, set status `review` and say so in the Log.

## Log
- 2026-10-13 created by opus55-planner

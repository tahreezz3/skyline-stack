---
id: T-0101
title: Tune core stacking constants
milestone: M1
status: review
priority: P0
owner: "opus55-a7k2"
claimed: "2026-10-13T15:26"
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
- [x] A config change log (docs/balance/TUNING_LOG.md) with before/after values and why
- [ ] Human playtest answers (HR-0017) addressed
- [x] Tests updated for changed invariants
- [x] GDD §3 updated with final values and the chosen combo variant
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes
- Uses placeholders so it can start now. Final sign-off or integration needs [HR-0017] (see HUMAN_NEEDED.md); if that is not delivered when the work is done, set status `review` and say so in the Log.

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 review by opus55-a7k2: Built game/tools/sim_balance.gd; found no-one-can-lose, combo dominance, endless never ends, trivial trophies; added collapse_costs_life + combo caps, retuned roofs/trophies; fixed trophy-after-roof bug (TowerState.is_star). Evidence in docs/balance/. Waiting on HR-0017 device playtest for feel sign-off (needs T-0104).

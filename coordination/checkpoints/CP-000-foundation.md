# CP-000 · Foundation

- Date: 2026-10-13
- Author: opus55-planner (first planning session)
- Git tag: cp-000
- Milestone: M0 (complete)

## State
- Godot 4.7 project in `game/`, portrait 720×1280, mobile renderer.
- `TowerState` (pure rules): perfect snap, stack, collapse-until-stable, miss and lives, wobble window, combo
  bar with pool, round completion with roof and trophy roof. All numbers from `game/config/*.json`.
- 38 headless rule tests pass.
- Placeholder round scene: swinging crane, falling block, real sway (landings measured against the swaying top),
  collapse debris, popups, HUD with combo bar, results with tap-to-restart, local save of stats.
- Headless autoplay smoke test completes a 10-storey tower.
- Docs: vision, GDD, architecture, data spec, roadmap, reference analysis, art/audio spec, legal clean room, testing, 5 ADRs.
- Coordination: 32 task files (4 done, 28 todo across M1–M6), `HUMAN_NEEDED.md` with 17 requests, asset inbox,
  dashboard generator, check script, clean-room check.

## How to verify
```bash
tools/check.sh          # expect: config OK, RESULT: 38 passed, 0 failed, AUTOPLAY_SUMMARY ..., clean-room OK, dashboard written
godot --path game       # play: click or space to drop
```

## Known issues and gaps
- Visuals are placeholder rectangles; no audio yet.
- Only the blue block type is used in the round (selection arrives in T-0202).
- Never run on a phone yet (T-0104).
- Constants are starting values from the reference analysis and must be retuned (T-0101).

## Next
Milestone M1. Ready in parallel now: T-0101, T-0102, T-0103, T-0104, T-0110, T-0201, T-0203, T-0204.
Humans: please answer HR-0002 (art direction) early, since all art waits on it; start HR-0013 (Play account) early because verification takes days.

# 08 · Testing and definition of done

## 1. Automated checks (`tools/check.sh`)
1. `tools/validate_config.py`: config files parse; required keys exist; thresholds are ordered.
2. Rule tests: `godot --headless --path game --script res://tests/run_tests.gd` (exit 0 = pass).
3. Smoke test: `godot --headless --path game -- --autoplay --seconds=60`: a bot plays a round; it must print
   `AUTOPLAY_SUMMARY` or `AUTOPLAY_TIMEOUT` with no `SCRIPT ERROR` lines.
4. `tools/cleanroom_check.py`.
5. `tools/dashboard.py` regenerates the dashboard and records the check result.

## 2. Writing tests
- One `test_*` method per behaviour in `game/tests/run_tests.gd`, using `check(cond, label)`.
- Drive `TowerState` directly with chosen x positions; never depend on frame timing.
- When you change a rule or a default, update or add the test in the same task.

## 3. Looking at the game without a screen
`godot --path game --write-movie /tmp/frames/f.png --fixed-fps 30 --quit-after 600 -- --autoplay`
writes PNG frames you can inspect (it opens a window briefly).

## 4. Human playtest questions (HR-0017)
1. Is the perfect window too tight, too loose, or right? (Try 20 drops, count perfects.)
2. Does the crane speed-up feel fair at height 10, 20, 30?
3. When the tower collapses, does it feel fair and understandable?
4. Is the combo exciting? Do you notice the bar draining faster?
5. Does the sway make you change your timing, or just look nice?
6. Anything confusing on screen?

## 5. Definition of done (every task)
- Acceptance criteria in the task file are ticked.
- `tools/check.sh` passes.
- Docs updated if behaviour, data or architecture changed.
- Session log written; dashboard regenerated.

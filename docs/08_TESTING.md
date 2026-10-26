# 08 · Testing and definition of done

## 1. Automated checks (`tools/check.sh`)

Before importing, run a direct headless launch (`godot --headless --path game --quit-after 2`). Any resource or script error fails, even when Godot exits zero. This catches missing shipped translations before the import step can regenerate them.

1. `tools/validate_config.py`: config files parse; required keys exist; thresholds are ordered.
2. Rule tests: `godot --headless --path game --script res://tests/run_tests.gd` (exit 0 = pass).
3. Smoke test: `godot --headless --path game -- --autoplay --seconds=60`: a bot plays a round; it must print
   `AUTOPLAY_SUMMARY` or `AUTOPLAY_TIMEOUT` with no `SCRIPT ERROR` lines, and `AUTOPLAY_FRAMING violations=0`
   (crane hook and tower top stayed on screen every frame). Long check: add `--endless --seconds=200`.
4. UI tour: `godot --headless --path game -- --tour` visits menu, select, round, pause, results; must print `TOUR_DONE`
   with no script errors.
5. `tools/cleanroom_check.py`.
6. Generated EN/ES/DE translation resources must be staged/tracked and current after import. The localisation suite checks every compiled message against the CSV and exercises menu format strings through TranslationServer in each language.
7. `tools/dashboard.py` regenerates the dashboard and records the check result.

## 2. Writing tests
- Suites are files named `game/tests/test_<area>.gd` that extend `res://tests/test_case.gd`; the runner finds them
  automatically. Prefer a new suite file per area so parallel sessions don't edit the same file.
- One `test_*` method per behaviour, using `check(cond, label)`; optional `before_all()` for setup.
- Tests that touch files must use their own `user://test_*` paths (see `test_save_io.gd`).
- Drive `TowerState` directly with chosen x positions; never depend on frame timing.
- When you change a rule or a default, update or add the test in the same task.

### UI tests must click, not emit
Test buttons with a real click: `SceneRouter._click(button.get_global_rect().get_center())` pushes a mouse press and
release through the viewport (canvas coordinates). Emitting `button.pressed` directly skips input handling and
missed a real bug (T-0507: the "No thanks" button froze after a focus loss paused the game under the prompt). Tour
steps `decline` and `decline_real` cover that flow with real clicks and a simulated app switch.

## 3. Balance simulation
`godot --headless --path game --script res://tools/sim_balance.gd -- --rounds=500 [--set=combo.count_cap=6]`
plays thousands of rounds with simulated players of five skill levels and prints completion, trophy, collapse,
score and combo-share tables. Use it before and after any balance change; log the change in
`docs/balance/TUNING_LOG.md`.

## 4. Looking at the game without a screen
`tools/capture.sh <out_dir> <frames> -- --autoplay` (or `-- --tour`, `-- --autoplay --endless` for the night sky)
writes full-resolution 720×1280 PNG frames. Look at them after any visual change.

`godot --path game --write-movie /tmp/frames/f.png --fixed-fps 30 --quit-after 600 -- --autoplay`
writes PNG frames you can inspect (it opens a window briefly). Use `-- --tour` instead of `-- --autoplay` to
capture every screen. Always look at frames after UI changes: a headless run cannot catch layout bugs.

## 5. Human playtest questions (HR-0017)
1. Is the perfect window too tight, too loose, or right? (Try 20 drops, count perfects.)
2. Does the crane speed-up feel fair at height 10, 20, 30?
3. When the tower collapses, does it feel fair and understandable?
4. Is the combo exciting? Do you notice the bar draining faster?
5. Does the sway make you change your timing, or just look nice?
6. Anything confusing on screen?

## 6. Definition of done (every task)
- Acceptance criteria in the task file are ticked.
- `tools/check.sh` passes.
- Docs updated if behaviour, data or architecture changed.
- Session log written; dashboard regenerated.


## Translation resources and direct startup

`game/localisation/strings.csv` is the source catalogue. Godot generates `strings.en.translation`, `strings.es.translation` and `strings.de.translation`; all three are committed because `godot --path game` does not run the editor importer. Missing translations make `tr("LEVEL_N")` return its raw key, which cannot be formatted with a level number.

After editing the CSV, regenerate and stage the compiled resources before checking:

```bash
godot --headless --path game --editor --import --quit
git add game/localisation/strings.csv game/localisation/*.translation
tools/check.sh
```

To reproduce a fresh checkout without removing your working cache, copy the staged/tracked tree with `git checkout-index --all --prefix=/tmp/skyline-startup-check/`, then run `godot --headless --path /tmp/skyline-startup-check/game --quit-after 2` before importing. Verify all three languages with `-- --lang=en`, `-- --lang=es` and `-- --lang=de`. A zero exit code alone is insufficient; logs must contain no `ERROR:` or `SCRIPT ERROR` lines.

## Theme integration and gallery (T-0314)

`tools/check.sh` also runs `godot --headless --path game --script res://tools/theme_tour.gd`. Expect all ten IDs and `THEME_TOUR_DONE failures=0`. This checks actual theme-selection/start clicks, matching active/placed modules, one landing resolution per release, narrow/tall HUD bounds and restart reset without persisting player data.

For visual review, run the same script without `--headless`, adding `-- --screenshots=/tmp/skyline-themes`. It captures the selection screen, all ten ground-level settings and six-floor towers and Lighthouse at narrow and tall logical portrait sizes (600×1280 and 720×1600). The tall preview uses a half-size native window so it fits laptop displays. Review the actual images; the headless checks alone cannot validate rendering quality.

T-0315 adds `test_background_art.gd` and selected-background/height-independent-lighting assertions to the theme tour. For native visual review with large artwork, pass `--gallery-only` alongside `--screenshots=...`; this runs rendering/layout contracts while the standard headless tour keeps input checks. Review all ten backgrounds against the owner references, including day/sunset lighting and absence of baked UI/crane/tower elements.


### Living backgrounds (T-0316)

`tools/check.sh` includes `background-motion`: `godot --headless --path game --script res://tools/background_motion_tour.gd`. It opens all ten actual rounds, advances the environment independently, exercises round pause, checks frozen time/depth, enables Reduced Motion and checks resume without wall-clock jumps. Unit contracts additionally cover deterministic route loops, timing across frame rates, bounded depth and per-theme masks.

For actual pixel checks and six-second clips, use `godot --path game --script res://tools/background_motion_tour.gd -- --screenshots=/tmp/motion --frames=72`. Native mode compares changing live pixels with pixel-identical Reduced Motion frames; each per-theme frame directory is a 12 fps sequence with gameplay frozen. Inspect water masks against bridges/shorelines, boats against islands/piers, steam sources and all portrait crops. The actor texture redraws only as the explicit clock changes. See `art/BACKGROUND_REVISION.md` and the animated previews. Device/mobile GPU performance remains a separate QA task.

## World camera ascent (T-0317)

`tools/check.sh` runs `environment_climb_tour.gd`: all ten actual rounds are tested at 0/6/12/20/40 floors, with projected world anchors leaving the screen on ascent and returning to their original framing after descent. Theme-tour assertions also reject camera-parented world scenery. Unit contracts cover original mesh bounds, distinct world layouts, fixed landmark positions, bounded altitude cloud pools and unchanged visible cloud identity across a recycling boundary.

For native proof, run `godot --path game --script res://tools/environment_climb_tour.gd -- --screenshots=/tmp/ascent --frames=96`. Optional `--themes=v001,v009,v010` limits exports. It records real geometry at each height and an eight-second 12 fps climb using the round's actual desired camera height; gameplay is deterministic and saves are disabled. The motion tour checks actual actor transforms and changing rendered world pixels instead of the retired offscreen sprite texture. Review shorelines, horizon, landmark placement, ascent/descent and upper sky. See ADR-0007 and `art/WORLD_ENVIRONMENTS.md`.

Native climb exports dismiss OS-focus pause overlays inside the frozen, manually stepped preview harness, so switching desktop apps cannot contaminate the footage. Actual pause/focus lifecycle behavior remains tested separately by the UI and world-activity tours.

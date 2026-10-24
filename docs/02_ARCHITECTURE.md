# 02 · Architecture

Engine: **Godot 4.7, GDScript**, mobile renderer, portrait 720×1280 logical (stretch `canvas_items`).
Why Godot: `docs/adr/ADR-0001-engine-godot.md`.

## Folder layout (`game/`)

```
game/
  project.godot            engine settings, autoload list
  config/                  ALL tunable numbers (JSON). See 03_DATA_SPEC.md
  scenes/                  .tscn scenes (thin: a root node + script)
  scripts/
    autoload/              global singletons (see below)
    core/                  pure rules: no Node, no rendering, deterministic, unit-tested
    game/                  scene scripts: input, rendering, animation, HUD
  tests/run_tests.gd       headless runner: executes every tests/test_*.gd suite
  tests/test_case.gd       base class for suites (check(), near())
  assets/                  integrated art/audio/fonts (copied from ../assets_inbox by integration tasks)
```

## Layers

```
input ─► scene script (scripts/game) ─► TowerState.land(x) (scripts/core) ─► event dict
                    ▲                                                        │
                    └────── render state / play feedback ◄───────────────────┘
                                         │
                                         └─► GameEvents (signal bus) ─► audio, analytics, save, achievements
```

1. **Core (rules)**: `TowerState` holds the round's state and implements every rule. It returns plain dictionaries
   (events). It never touches nodes, time or randomness, so tests can drive it directly.
2. **Presentation**: `tower_game.gd` moves the crane, simulates the falling block, applies visual sway, draws,
   and shows feedback for each event.
3. **Services (autoloads)**: config, events, save. Later: audio, ads, IAP, analytics, localisation.

Rule of thumb: if it changes the score, lives or what counts as a hit, it belongs in `core/` with a test.

## Autoloads

| Name | Script | Purpose |
|---|---|---|
| `GameConfig` | `scripts/autoload/game_config.gd` | Loads `config/*.json` at startup; `table(name)`, `block_type(id)` |
| `GameEvents` | `scripts/autoload/game_events.gd` | Signal bus |
| `SaveData` | `scripts/autoload/save_data.gd` | `user://save.json`: stats, bests, settings (schema in `core/save_schema.gd`) |
| `SceneRouter` | `scripts/autoload/scene_router.gd` | Screen changes with fade, params, back button, `--autoplay`/`--tour` flags |
| `AudioDirector` | `scripts/autoload/audio_director.gd` | Only place that plays sound. Listens to GameEvents; buses Music/SFX/UI; real files from `res://assets/audio/<name>.wav/.ogg` or procedural placeholders (`scripts/game/placeholder_synth.gd`) |
| `Analytics` | `scripts/autoload/analytics.gd` | GameEvents → schema-validated events (`core/analytics_events.gd`), consent-gated; `log` backend for development (docs/ANALYTICS.md) |
| `Ads` | `scripts/autoload/ads.gd` | `await show_rewarded(placement)`, `on_round_finished()` (interstitial pacing via `core/ad_policy.gd`, `config/economy.json`); `fake` backend shows a 2 s TEST AD overlay; AdMob backend in T-0506 |
| `Store` [planned T-0502] | | Remove-ads purchase; sets `purchases.remove_ads` |

## Signals on `GameEvents`

| Signal | Payload | Emitted by |
|---|---|---|
| `block_released` | none | tower_game |
| `block_resolved(ev)` | event dict from `TowerState.land()`: `result` = perfect/stack/collapse/miss, plus `x`, `offset`, `residents`, `height`, `removed`, `fallen`, `lost_residents`, `banked`, `lives`, `complete`, `star`, `roof_people` | tower_game |
| `block_toppled` | none (one per falling block in a collapse) | tower_game |
| `combo_progress(count, drain_rate)` | int, float (count 0 = combo over) | tower_game |
| `combo_banked(amount)` | int | tower_game |
| `round_ended(summary)` | `{complete, star, population, height, max_combo, block_type, endless}` | tower_game |
| `level_up(from, to)` | ints | SaveData.record_round |
| `block_type_unlocked(id)` | String | SaveData.record_round |
| `setting_changed(key, value)` | String, Variant | SaveData.set_setting |
| `round_started(block_type, endless)` | String, bool | tower_game |
| `city_tower_placed(tower, city_population)` | Dictionary, int | city_map |
| `ad_finished(format, placement, completed)` | String, String, bool | Ads |
| `screen_changing(to)` | String | SceneRouter.go, before the fade (AudioDirector stops gameplay loops) |
| `ui_pressed` | none | UI buttons |

Add new signals here when you add them to `game_events.gd`.

## Rendering (ADR-0006)
The round is drawn by `scripts/game/tower_view_3d.gd` under a fixed orthographic camera pitched 6° down. The selected architecture comes from `theme_kit.gd`, using the existing `building_kit.gd` triangle builder. The renderer reads `tower_game` state each frame and never changes it. Gameplay objects sit on z = 0 in rules units, keeping the picture aligned with placement centres.

A camera-parented unshaded background quad (`scripts/game/shaders/sky_backdrop.gdshader`) displays the selected theme’s environment-only artwork. `themes.json` supplies its local texture and reference-specific neutral/daylight or golden-hour lighting. The shader uses aspect-cover cropping anchored at bottom centre. T-0316 adds a living 2.5D layer: vector shoreline/sky/cloth masks, masked water/cloud/flag animation and bounded camera depth. `background_motion.gd` owns an explicit pause-aware/accessibility-aware clock; `living_background.gd` renders independent boats, birds, traffic, steam, floes, fountain and beacon details into one transparent SubViewport texture. Tunables and per-reference masks/routes live in `background_motion.json`. This presentation never mutates rules; no shader `TIME` is used, so pause and Reduced Motion freeze the entire environment. Camera height never replaces the reference sky/lighting with generic dusk. There are no shared procedural sun, mountain or skyline overlays (T-0315). Popups and the HUD stay 2D; `view3d.world_to_screen()` positions popups. `feel.json` `"view": "2d"` retains the simple debug renderer with the chosen palette. The earlier city/cafe kits remain available for other screens and final artist integration.

## Coordinates
- Rules use world units: 1.0 = one block width; y up; the foundation top is y = 0.
- Block i (i ≥ 1) sits with its bottom at `(i − 1) × block.height`.
- The scene converts with `UNIT = 160` px per unit and a camera offset `view_y` that follows the tower top.

## Localisation
All user-facing text goes through `tr("KEY")` with keys in `game/localisation/strings.csv` (see 03_DATA_SPEC.md).
`SaveData.apply_language()` sets the locale from `settings.language` (or the device language), falling back to
English. Screens build their text in `_ready()`, so changing language reloads the current screen.

## Conventions
- GDScript style: Godot official style guide, static types where the type is known, `snake_case`.
- Scripts that other scripts use are referenced with `preload()` constants (not `class_name`) to keep headless
  tests independent of the editor's class cache.
- No magic numbers in gameplay code: read from `GameConfig`.
- Exports: JSON configs are not resources; the export preset must include `*.json` (T-0601).

## Scene flow (implemented in M2)
`main_menu → (settings | city_map) → tower_select → tower_game → results → (tower_game | tower_select | main_menu)`; the menu's
Endless button goes straight to `tower_game` with `{endless: true}`. `SceneRouter.go(name, params)` fades and
switches; the next screen reads `SceneRouter.params`. Every screen implements `on_back()` (Android back / Escape).
In a round, back or focus loss opens the pause overlay (`get_tree().paused`); resuming counts down 3 s. Pausing is
refused while the "Out of lives" continue prompt or the results are up (`tower_game.can_pause()`); the prompt's
layer runs with `PROCESS_MODE_ALWAYS`, and back on the prompt means "No thanks".

Screens are built in code with `scripts/game/ui_kit.gd` (placeholder styling until T-0303).
Debug modes (user args after `--`): `--autoplay [--seconds=N]` plays a round and quits on the results screen;
`--tour` visits every screen and quits (combine with `--write-movie` to see them).

## Cosmetic themes and compact round HUD (T-0314)

The tower selection screen offers ten cosmetics independently of the four progression families. `SceneRouter.selected_theme` carries the session choice through round/restart/menu/Endless without changing save schema v3. `theme_catalog.gd` resolves IDs from `config/themes.json`; `tower_game.visual_theme` is a read-only presentation choice. `tower_view_3d.gd` uses `theme_kit.gd` for matching active, fallen and placed modules and completion crowns. T-0315 adds independent reference-matched background artwork and lighting. It reuses `building_kit.gd`'s mesh builder. Core rules never receive a theme.

`round_hud.gd` owns viewport-anchored pixel hearts, floor badge/segmented meter, population digits/icon, combo strip and pause button. It only reads round state and forwards pause input. Layout parameters live in `config/round_hud.json`; the existing popups and pause/results overlays remain in `tower_game.gd`. Full implementation notes: `art/THEME_IMPLEMENTATION.md`.

Background art assets, exact prompts and verification notes: `art/BACKGROUND_REVISION.md`.

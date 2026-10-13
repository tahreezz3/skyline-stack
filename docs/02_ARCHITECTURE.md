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
| `SaveData` | `scripts/autoload/save_data.gd` | `user://save.json`, lifetime stats |
| `AudioDirector` [planned T-0103] | | Listens to GameEvents, plays SFX/music |
| `Ads`, `Store`, `Analytics` [planned M5] | | Behind interfaces, with a fake implementation for desktop/tests |

## Signals on `GameEvents`

| Signal | Payload | Emitted by |
|---|---|---|
| `block_released` | none | tower_game |
| `block_resolved(ev)` | event dict from `TowerState.land()`: `result` = perfect/stack/collapse/miss, plus `x`, `offset`, `residents`, `height`, `removed`, `fallen`, `lost_residents`, `banked`, `lives`, `complete`, `star`, `roof_people` | tower_game |
| `block_toppled` | none (one per falling block in a collapse) | tower_game |
| `combo_banked(amount)` | int | tower_game |
| `round_ended(summary)` | `{complete, star, population, height, max_combo, block_type, endless}` | tower_game |
| `level_up(from, to)` | ints | SaveData.record_round |
| `block_type_unlocked(id)` | String | SaveData.record_round |
| `setting_changed(key, value)` | String, Variant | SaveData.set_setting |
| `ui_pressed` | none | UI buttons |

Add new signals here when you add them to `game_events.gd`.

## Coordinates
- Rules use world units: 1.0 = one block width; y up; the foundation top is y = 0.
- Block i (i ≥ 1) sits with its bottom at `(i − 1) × block.height`.
- The scene converts with `UNIT = 160` px per unit and a camera offset `view_y` that follows the tower top.

## Conventions
- GDScript style: Godot official style guide, static types where the type is known, `snake_case`.
- Scripts that other scripts use are referenced with `preload()` constants (not `class_name`) to keep headless
  tests independent of the editor's class cache.
- No magic numbers in gameplay code: read from `GameConfig`.
- Exports: JSON configs are not resources; the export preset must include `*.json` (T-0601).

## Planned scene flow [M2]
`boot → main_menu → tower_select → tower_game → results → (main_menu | city_map)`, managed by a
`SceneRouter` autoload with fade transitions.

# 03 · Data specification (`game/config/*.json`)

All gameplay numbers live here. `tools/check.sh` validates that the files parse and that required keys exist
(`tools/validate_config.py`). When you add a key: document it here, add it to the validator, and use it via `GameConfig`.

## `tower_rules.json`

| Key | Type | Meaning |
|---|---|---|
| `snap_window` | float | \|offset\| below this is a perfect snap |
| `max_offset` | float | \|offset\| above this collapses; also the scale for residents |
| `miss_offset` | float | \|offset\| at or above this misses the tower (no overlap) |
| `first_block_zone` | float | first storey: landings this close to the foundation centre are stable (no wobble, never collapse) |
| `stable_offset` | float | during a collapse, blocks with \|diff\| below this stop the collapse |
| `collapse_interval_s` | float | visual delay between toppling blocks |
| `residents_max` | int | residents for a perfect block |
| `wobble_window` | int | number of recent offsets that make up the wobble |
| `wobble_gain` | float | multiplier on the sum of recent offsets |
| `lives` | int | lives per round |
| `collapse_costs_life` | bool | a collapse also costs a life (misses always do) |
| `fall_kill_depth` | float | how far below the top a missed block falls before it counts |
| `block.width`, `block.height` | float | block size in world units |
| `combo.bar_seconds` | float | bar length after a perfect |
| `combo.drain_base`, `combo.drain_extra`, `combo.drain_full_at` | float, float, int | drain rate = base + extra × min(1, count / full_at) |
| `combo.height_step`, `combo.bonus_factor` | int, int | pool += min(count, count_cap) × bonus_factor × min(ceil(height / height_step), height_mult_cap) |
| `combo.count_cap`, `combo.height_mult_cap` | int, int | caps that keep the combo from dominating long runs |
| `crane.amplitude`, `crane.speed`, `crane.speed_per_block`, `crane.speed_max` | float | swing |
| `crane.gap_blocks` | float | drop height above the top, in block heights |
| `crane.follow_speed` | float | units/s the crane's swing centre glides towards the tower top (keeps a drifting tower on screen) |
| `crane.gravity` | float | world units / s² |
| `sway.speed`, `sway.scale`, `sway.max` | float | visual and hit-test sway |

Invariant (tested): `snap_window < stable_offset < max_offset < miss_offset`.

Rule tests use a frozen copy (`game/tests/fixtures/tower_rules_v0.json`), so retuning this file never breaks
them. Check balance changes with `game/tools/sim_balance.gd` and record them in `docs/balance/TUNING_LOG.md`.

## `block_types.json`
`types[]`: `id`, `name_key` (localisation key), `colour` (placeholder), `target_height`, `roof_people`,
`star_population`, `star_roof_people`, `unlock_population`.

## `levels.json`
`levels[]`: `level`, `population` (lifetime population needed; must strictly increase).
Block types unlock **only** through `block_types[].unlock_population` (single source of truth).

## `feel.json` (presentation only; never affects scoring)

| Key | Meaning |
|---|---|
| `view` | `"3d"` (low-poly renderer, ADR-0006) or `"2d"` (debug fallback) |
| `shake.land`, `shake.land_sloppy`, `shake.perfect`, `shake.miss` | screen-shake amount (px) added per event |
| `shake.frequency` | speed multiplier for the smooth shake wobble |
| `shake.collapse_per_block`, `shake.max`, `shake.decay` | collapse shake per fallen block; cap; decay rate per second |
| `camera_kick.perfect`, `camera_kick.decay` | downward camera nudge on a perfect (px) and its decay |
| `squash.amount`, `squash.time` | newest block squash ratio and duration |
| `particles.dust_count`, `particles.dust_life`, `particles.sparkle_count`, `particles.sparkle_life` | landing dust and perfect sparkles |
| `combo_bar.pulse_hz`, `combo_bar.warn_below` | HUD bar pulse speed; ratio below which it turns red |
| `audio.perfect_pitch_step`, `audio.perfect_pitch_max_steps` | perfect chime rises by step per combo level, capped |
| `audio.combo_tick_pitch_min`, `audio.combo_tick_pitch_max` | combo ticking pitch range, mapped from drain rate 1x..4x |

Shake and camera kick are skipped when `settings.reduced_motion` is true.

## Save file (`user://save.json`, schema in `scripts/core/save_schema.gd`)
Current version **3** (v3 added `city`):

| Key | Meaning |
|---|---|
| `version` | schema version; older saves are migrated on load (`SaveSchema.migrate`) |
| `stats.lifetime_population` | total population ever earned (drives level and unlocks) |
| `stats.best_height`, `stats.best_population`, `stats.best_combo` | personal bests |
| `stats.rounds_played`, `stats.towers_completed`, `stats.trophy_roofs` | counters |
| `best_by_type.<id>` | `{population, height, star}` per block type |
| `city.plots` | `"x,y" -> {type, population, height, star}` placed towers |
| `city.unplaced` | completed towers waiting to be placed |
| `settings.music_volume`, `settings.sfx_volume` | 0..1 |
| `settings.reduced_motion` | disables screen shake and camera kick |
| `settings.language` | locale code, `""` = device language |
| `settings.analytics_consent` | `unknown` (default) / `granted` / `denied`; analytics only sends when `granted` |

Additive keys with defaults (like `analytics_consent`) don't need a version bump: `SaveSchema.migrate()` fills
missing keys from `defaults()`. Bump `VERSION` when data moves, is renamed, or changes meaning.

Writes are atomic (`save.tmp.json` then rename); the previous file is kept as `save.bak.json`;
an unreadable file is moved to `save.corrupt.json` and the game starts fresh.

## `city_map.json`
`width`, `height` (grid size), `disabled` (list of `[x, y]` plots that can't be built on), `rules` (empty until
T-0402 designs our placement rules). Completed non-endless towers go to the save's `city.unplaced` tray; placing one
moves it to `city.plots["x,y"]` (`scripts/core/city_state.gd`).

## `economy.json`
| Key | Meaning |
|---|---|
| `interstitial.min_rounds_before_first` | no interstitial until this many rounds have been played |
| `interstitial.every_n_rounds`, `interstitial.min_seconds_between` | cadence limits |
| `rewarded.continue_per_round`, `rewarded.continue_lives` | rewarded continue: how often per round, lives restored |
| `rewarded.double_reward_multiplier` | results "double reward": lifetime population gets `population × (multiplier − 1)` more |

Save keys: `ads.rounds_since_interstitial`, `ads.last_interstitial_unix`, `purchases.remove_ads`.

## Planned tables

## `localisation/strings.csv`
Godot translation CSV: header `keys,en,es,de`, one row per UI string. Code uses `tr("KEY")`; block names use
`block_types[].name_key`. Godot imports it into `strings.<lang>.translation` (generated but committed, so fresh clones show text; see 08_TESTING) listed in
`project.godot` `[internationalization]`. To add a language: add a column, add the generated file to that list,
add the code to `SaveData.LANGUAGES`, and request a native review in HUMAN_NEEDED.
`tests/test_localisation.gd` fails on missing keys, empty cells, mismatched `%d/%s` placeholders, or literal text
passed to `UI.label`/`UI.button`. Preview: `godot --path game -- --lang=de`.

## `themes.json` (presentation only)

`default` is a valid theme ID; `themes[]` contains exactly v001-v010. Each entry has `id`, localized `name_key` and `description_key`, `architecture`, `scenery`, a six-color `palette` (`body`, `shadow`, `trim`, `glass`, `accent`, `gold`), `sky_top`, `sky_bottom` and `landscape` hex colors. These fields cannot override tower rules or block families.

`geometry`: `half_width` and `cornice_width` are square facade/ledge half-widths; `round_radius` and integer `round_sides` define round modules; `roof_height` defines completion crowns; integer `window_columns` controls glass grids; `yaw_degrees` turns architecture around the vertical axis; `rope_width` and `sling_height` define suspension geometry. Distances use block-width units. Storey height always comes from `tower_rules.block.height`; decorations do not change placement dimensions.

`scenery_layout`: `row_depths`, `row_scales`, `row_parallax`, `row_horizons` and `haze` each contain three numbers for the background rows. `row_spacing` spaces buildings; integer `row_extent` sets the number on each side; `floor_counts` is a repeating positive integer height pattern. Rendering batches each row by material.

`SceneRouter.selected_theme` holds the session's cosmetic ID; empty/unknown IDs fall back to `default`. It is not saved or used by progression, city bookkeeping or analytics. See `art/THEME_IMPLEMENTATION.md` for source conflicts and theme inventory.

## `round_hud.json` (presentation only)

All dimensions are logical canvas pixels: `margin`, `heart_pixel`, `heart_spacing`, `meter_width`, `meter_height`, `badge_height`, `bottom_clearance`, `pause_size`, `combo_width` and `combo_height`. `population_font_size` controls counter text size; `counter_digits` is its minimum zero-padded digit count. `meter_segments` is the vertical blue segment count. The badge displays completed floors; meter fill is height / target height, or height modulo `endless_page_floors` in Endless. None of these fields change rules or rewards.

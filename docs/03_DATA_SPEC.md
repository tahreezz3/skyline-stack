# 03 · Data specification (`game/config/*.json`)

All gameplay numbers live here. `tools/check.sh` validates that the files parse and that required keys exist
(`tools/validate_config.py`). When you add a key: document it here, add it to the validator, and use it via `GameConfig`.

## `tower_rules.json`

| Key | Type | Meaning |
|---|---|---|
| `snap_window` | float | \|offset\| below this is a perfect snap |
| `max_offset` | float | \|offset\| above this collapses; also the scale for residents |
| `miss_offset` | float | \|offset\| at or above this misses the tower (no overlap) |
| `stable_offset` | float | during a collapse, blocks with \|diff\| below this stop the collapse |
| `collapse_interval_s` | float | visual delay between toppling blocks |
| `residents_max` | int | residents for a perfect block |
| `wobble_window` | int | number of recent offsets that make up the wobble |
| `wobble_gain` | float | multiplier on the sum of recent offsets |
| `lives` | int | misses allowed per round |
| `fall_kill_depth` | float | how far below the top a missed block falls before it counts |
| `block.width`, `block.height` | float | block size in world units |
| `combo.bar_seconds` | float | bar length after a perfect |
| `combo.drain_base`, `combo.drain_extra`, `combo.drain_full_at` | float, float, int | drain rate = base + extra × min(1, count / full_at) |
| `combo.height_step`, `combo.bonus_factor` | int, int | pool += count × bonus_factor × ceil(height / height_step) |
| `crane.amplitude`, `crane.speed`, `crane.speed_per_block`, `crane.speed_max` | float | swing |
| `crane.gap_blocks` | float | drop height above the top, in block heights |
| `crane.gravity` | float | world units / s² |
| `sway.speed`, `sway.scale`, `sway.max` | float | visual and hit-test sway |

Invariant (tested): `snap_window < stable_offset < max_offset < miss_offset`.

## `block_types.json`
`types[]`: `id`, `name_key` (localisation key), `colour` (placeholder), `target_height`, `roof_people`,
`star_population`, `star_roof_people`, `unlock_population`.

## `levels.json`
`levels[]`: `level`, `population` (lifetime population needed; must strictly increase).
Block types unlock **only** through `block_types[].unlock_population` (single source of truth).

## `feel.json` (presentation only; never affects scoring)

| Key | Meaning |
|---|---|
| `shake.land`, `shake.land_sloppy`, `shake.perfect`, `shake.miss` | screen-shake amount (px) added per event |
| `shake.collapse_per_block`, `shake.max`, `shake.decay` | collapse shake per fallen block; cap; decay rate per second |
| `camera_kick.perfect`, `camera_kick.decay` | downward camera nudge on a perfect (px) and its decay |
| `squash.amount`, `squash.time` | newest block squash ratio and duration |
| `particles.dust_count`, `particles.dust_life`, `particles.sparkle_count`, `particles.sparkle_life` | landing dust and perfect sparkles |
| `combo_bar.pulse_hz`, `combo_bar.warn_below` | HUD bar pulse speed; ratio below which it turns red |
| `audio.perfect_pitch_step`, `audio.perfect_pitch_max_steps` | perfect chime rises by step per combo level, capped |
| `audio.combo_tick_pitch_min`, `audio.combo_tick_pitch_max` | combo ticking pitch range, mapped from drain rate 1x..4x |

Shake and camera kick are skipped when `settings.reduced_motion` is true.

## Save file (`user://save.json`, schema in `scripts/core/save_schema.gd`)
Current version **2**:

| Key | Meaning |
|---|---|
| `version` | schema version; older saves are migrated on load (`SaveSchema.migrate`) |
| `stats.lifetime_population` | total population ever earned (drives level and unlocks) |
| `stats.best_height`, `stats.best_population`, `stats.best_combo` | personal bests |
| `stats.rounds_played`, `stats.towers_completed`, `stats.trophy_roofs` | counters |
| `best_by_type.<id>` | `{population, height, star}` per block type |
| `settings.music_volume`, `settings.sfx_volume` | 0..1 |
| `settings.reduced_motion` | disables screen shake and camera kick |
| `settings.language` | locale code, `""` = device language |

Writes are atomic (`save.tmp.json` then rename); the previous file is kept as `save.bak.json`;
an unreadable file is moved to `save.corrupt.json` and the game starts fresh.

## Planned tables
- `city_map.json` (M4): grid size, plots, district unlock thresholds, placement rules.
- `economy.json` (M5): population → coins rate, ad reward amounts, interstitial cadence.
- `localisation/*.csv` (M3): Godot translation CSVs, keys like `block_blue`.

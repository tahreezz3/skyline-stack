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
`levels[]`: `level`, `population` (lifetime population needed), `unlocks` (block type ids).

## Planned tables
- `city_map.json` (M4): grid size, plots, district unlock thresholds, placement rules.
- `economy.json` (M5): population → coins rate, ad reward amounts, interstitial cadence.
- `localisation/*.csv` (M3): Godot translation CSVs, keys like `block_blue`.

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
| `settings.reduced_motion` | disables screen shake, camera kick and living-background motion |
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
`block_types[].name_key`. Godot imports it into `strings.<lang>.translation` (generated but committed so direct launches work before editor import) listed in
`project.godot` `[internationalization]`. To add a language: add a column, add the generated file to that list,
add the code to `SaveData.LANGUAGES`, and request a native review in HUMAN_NEEDED.
`tests/test_localisation.gd` fails on missing keys, empty cells, mismatched `%d/%s` placeholders, or literal text
passed to `UI.label`/`UI.button`. Preview: `godot --path game -- --lang=de`.

## `themes.json` (presentation only)

`default` is a valid theme ID; `themes[]` contains exactly v001-v010. Each entry has `id`, localized `name_key`/`description_key`, `architecture`, `scenery`, a six-color `palette` (`body`, `shadow`, `trim`, `glass`, `accent`, `gold`) and `background`. Themes cannot override tower rules or progression families.

`geometry`: `half_width` and `cornice_width` are square facade/ledge half-widths; `round_radius` and integer `round_sides` define round modules; `roof_height` defines completion crowns; integer `window_columns` controls glass grids; `yaw_degrees` turns architecture around the vertical axis; `rope_width` and `sling_height` define suspension geometry. Distances use block-width units. Storey height always comes from `tower_rules.block.height`.

T-0317 keeps `background.texture` as an archived reference, not a runtime scenic panel. The active world layout is `environment_world.json`. The reference texture is a local `res://assets/backgrounds/*.png` resource; `reference` records its owner reference filename. `sun_style` documents `none` for daytime art or `natural_gold` for v003/v009/v010 sunset art. This metadata never adds another sun to the image. `lighting` defines `key_color`, `ambient_color`, `rim_color` hex colors; nonnegative `key_energy`, `ambient_energy`, `rim_energy`, `window_glow`; and nonzero three-number `key_position`/`rim_position` direction vectors for directional lights. Lighting remains fixed to the reference as camera height changes.

`backdrop.overscan` (1..1.1) prevents edge seams. `backdrop.distance` places the camera-parented quad inside the camera's far plane. Background texture dimensions and viewport aspect determine cover cropping without distortion, anchored at bottom centre.

`SceneRouter.selected_theme` holds the session's cosmetic ID; empty/unknown IDs fall back to `default`. It is not saved or used by progression, city bookkeeping or analytics. See `art/THEME_IMPLEMENTATION.md` for theme inventory and `art/BACKGROUND_REVISION.md` for the current background implementation and provenance.

## `round_hud.json` (presentation only)

All dimensions are logical canvas pixels: `margin`, `heart_pixel`, `heart_spacing`, `meter_width`, `meter_height`, `badge_height`, `bottom_clearance`, `pause_size`, `combo_width` and `combo_height`. `population_font_size` controls counter text size; `counter_digits` is its minimum zero-padded digit count. `meter_segments` is the vertical blue segment count. The badge displays completed floors; meter fill is height / target height, or height modulo `endless_page_floors` in Endless. None of these fields change rules or rewards.


## `background_motion.json` (presentation only)

`shared.canvas_size` is the two-number offscreen actor canvas size in pixels; `mask_scale` (0.1..1) scales the one-time vector mask raster. `environments` has exactly v001-v010. All coordinates below use original artwork UVs (top-left 0,0; bottom-right 1,1), so responsive cover cropping keeps actors and masks aligned.

- `shared.parallax`: `x_per_unit`/`y_per_unit` convert round camera units to UV offsets; `max_x`/`max_y` bound them; `far_factor`/`near_factor` control relative scenery depth; `follow_rate` is exponential easing per second. This excludes shake/kick and never changes rules.
- `shared.sky`: `amplitude` and `angular_speed` control cloud drift in UVs and radians/second; `edge_pin` fixes texture edges. `shared.wind` supplies existing cloth `amplitude`, `speed` and `spatial_frequency`.
- `shared.water`: `uv_amplitude` is two-axis refraction; `speed` is phase/second; `glint_strength` blends highlights; `refraction_frequency`, `glint_frequency`, `glint_sharpness` are two-number spatial/detail controls; `glint_drift`, `cross_wave_speed`, `cross_wave_bend` set traveling highlight behavior. Values preserve the reference base color.
- `shared.actor_fade` (0..0.5) is the fraction faded at each moving route endpoint. `bird_wing_hz`, `boat_bob_hz`, `floe_bob_hz` and `flag_flutter_hz` set motion rates; `boat_bob` is vertical bob amplitude in UVs. `steam_puffs`, `steam_rise`, `steam_drift`, `steam_radius` set plume count, UV travel and size. `fountain_drops`, `fountain_height`, `fountain_spread` set fountain detail and UV extents. `beacon_period` documents the default beacon loop; an actor's `period` is authoritative.
- Each environment's `sky` is an ordered horizon polyline covering x=0..1. `water`, `water_exclusions` and `wind` are lists of polygons; water must have at least one region. The raster uses red sky, green open water, blue fluttering cloth. Exclusions clear water over solid objects.
- `actors[]`: `kind` is birds/sailboat/ferry/floe/car/steam/mist/fountain/flag/beacon/pollen; `start`/`end` are two-number UV route endpoints (x may extend -0.2..1.2 for offscreen entry); `size` is a positive vector-art scale (fraction of canvas width for ordinary actors, multiplier of shared plume dimensions for steam/mist); `period` is loop duration in seconds; `phase` is 0..1; `color` is hex RGB. Static emitters use matching start/end; their contents still animate. No actor participates in collisions, population or scores.

Pause freezes elapsed time and depth. Reduced Motion retains a stationary time-zero composition and resumes the retained clock when disabled. Shader uniforms use this explicit clock, never global `TIME`.


## `environment_world.json` (active presentation)

Each `environments.v001`..`v010` defines `scenery`, `sky_top`, `sky_bottom`, natural sunset `sun` boolean, named RGB `colors`, `water` layout (`river`/`sea`), `patches`, `features` and `actors`. The game does not sample a complete reference painting as a background.

- `features[]`: original mesh `kind`, world-unit `position` and `size` vectors, and `rotation` about Y in degrees. Kinds include manor, office, palace, pagoda, fort, prison/watchtower, igloo, cottage/lighthouse, refinery/tank/stack/crane, bridge, terrain, tree and garden details. Features remain at these coordinates at every tower height.
- `patches[]`: named `material`, world-space box `lo`/`hi` bounds for plazas, paths, roads and markings. These use the same fixed-world rule.
- `actors[]`: `kind`, world-unit route `start`/`end`, positive `size`, loop `period` in seconds and initial `phase` (0..1). Supported kinds: birds, car, sailboat, ferry, floe, flag, fountain, steam, beacon. Routes and emitters never enter game rules.

`shared` world geometry: `ground_bounds`/`river_bounds` are six-number min/max XYZ boxes; `water_size` is XZ plane size, `water_center` its XYZ position; `foundation_size` and `foundation_y` set the build pad. `mesh_sides` controls radial topology. Artistic normalized model vertices/fractions are in the kit.

`shared` sky/clouds: `cloud_gap` is vertical world-unit band spacing; integer `cloud_bands` and `clouds_per_band` bound the pool; `cloud_width` is horizontal wrap span; `cloud_depth`, `cloud_projection_bias` and `cloud_depth_step` compose the orthographic distance layers; `cloud_size` is XYZ model scale; `cloud_speed` is horizontal world units/second. `sky_height_range` and `sky_horizon` shape the infinite atmosphere gradient. `sun_position` is viewport UV and `sun_radius` its normalized radius, active only for the three natural sunset themes.

`shared` ambient motion: `water_wave_amplitude`, `water_wave_speed`, `water_glint`; `boat_bob`, `boat_bob_speed`, `boat_roll_amplitude`; `bird_flap_speed`, `bird_roll_amplitude`; `steam_rise`, `steam_drift`, `steam_puffs`, `steam_radius`, `steam_wobble`; `fountain_drops`, `fountain_height`; `flag_speed`, `flag_amplitude`. Distances are world units, rates are phase/second; mesh-scaled particle counts/sizes are bounded by their emitter. All shader animation uses the explicit paused scene clock.

Camera height never changes the position of ground/landmarks. Reduced Motion disables ambient animation, while ordinary gameplay camera ascent/descent remains spatially correct. Old `background_motion.json` describes the retired plate experiment and is retained alongside the archived art for reference.


## `atmosphere.json` (T-0318, presentation only)

- `altitude`: ordered `upper_start/end`, `space_start/end`, `weather_fade_start/end` in camera world units. Each pair uses smoothstep; weather finishes before full space. No game height/goal is changed.
- `sky`: `upper_color`, `space_top`, `space_bottom` hex colors; positive `star_grid`, `star_size`, `star_density`, `star_parallax`. Density and size are fractions below 1. Stars are procedural and altitude-relative.
- `effects`: positive `depth` (camera-local weather plane distance), `overscan`, two-component `rain_grid`/`snow_grid`, `rain_length`, `rain_width`, `rain_speed`, `snow_size`, `snow_speed`, `wind_speed`, `wind_opacity`, `fog_speed`, `lightning_period`, `lightning_duration`, `lightning_strength`. Time is explicit paused presentation time, never shader TIME. The plane sits behind gameplay geometry; no atmospheric effect is drawn over the HUD.
- `cyclone`: finite world `position`; positive three-component `tornado_size`, `hurricane_size`; `hurricane_tilt` degrees, `rotation_speed` radians/second, integer `segments` (8–48), `bands` (4–48), and hex `color`. Only the selected distant cyclone is built.
- `planets`: `kind` (`earth`, `gas`, `moon`), fixed world `position`, positive `radius`, hex `color`/`accent`, positive `rotation_speed` and boolean `ring`. These are background meshes, with no collision or gravity.
- `planet_mesh`: integer `segments` (8–96), `rings` (4–48); positive `ring_inner`/`ring_outer` radius multiples, `ring_tilt` degrees and hex `ring_color`. Normalized mesh topology and procedural surface patterns remain original art in code/shaders.
- `weather`: ten unique entries. Each has an `id`, positive random `weight`, `clouds` coverage, positive `cloud_speed` multiplier, hex `tint`, `tint_amount`, boolean `sun`, `rain`, `snow`, `wind`, `fog`, `storm`, and `cyclone` (`none`, `tornado`, `hurricane`). Coverage, tint and effect strengths are 0–1. IDs: `sunny`, `clear`, `cloudy`, `rainy`, `snowy`, `windy`, `foggy`, `thunderstorms`, `tornadoes`, `hurricanes`.

A private RNG chooses one profile per round; `--visual-seed=<integer>` reproduces selection and `--weather=<id>` overrides it for developer previews. Neither is saved or forwarded to core rules. Altitude, weather and mesh parameters cannot alter crane speed, collision, scoring, lives, residents, gravity or landing classification. See `art/WEATHER_AND_SPACE.md`.

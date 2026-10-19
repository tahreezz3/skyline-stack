# 06 · Art and audio specification

Concrete deliverables with exact file names are in `HUMAN_NEEDED.md` (HR-0004 to HR-0012).
This document holds the shared direction those requests follow.

## 1. Constraints
- Portrait, 720×1280 logical. The **playfield is 2D and fixed**: no camera rotation, the camera only moves up with
  the tower. It is *drawn* in real-time 3D through a locked orthographic camera (ADR-0006), so it looks 3D.
- One block = 1 world unit wide, 0.6 units tall, about 0.9 deep. One world unit is 160 logical px on screen.
- The tower is the hero: high contrast and saturated. Backgrounds are lower contrast and hazier with distance.
- Colour-blind safe: tower families also differ by shape details (window pattern, roof form), not only by hue.

## 2. Art direction: Modern low-poly 2.5D (chosen by the owner, HR-0002)
> "Modern simple shapes with good details; looks 3D, with effects, animation and design; the level itself is 2D
> and fixed; details in low-poly simple shapes with a good modern aesthetic."

**Visual reference (owner, 2026-10-19):** `docs/art/references/owner_reference_corner_building.webp`: a corner
view of a pastel building with white pilasters and stepped cornices, board siding, mullioned windows with terracotta
frames and sills, flower pots on ledges, and a shop-front ground floor (panelled plinth, arched doors, striped
awning), under a pastel sky with warm painterly clouds and a soft background blur. *Mood and detail reference only:
never trace it or copy it into the game.* The current in-game placeholders follow it: `docs/art/style_frame_building_detail.png`.

### 2.1 Shape language
- Simple, chunky, readable silhouettes built from boxes, prisms, cylinders with 6–8 sides, and pyramids.
- **Buildings are shown at an angle:** every block is turned 38° about its vertical axis so two faces show (a corner
  view). Footprints are square (core 0.66 units) so the turned block spans the gameplay width on screen.
- **The ground storey is different:** shop front with plinth panels, arched doors, corner columns and a striped
  awning wrapping the corners. Upper storeys repeat: siding, pilasters, cornice, framed windows, flower pots.
- **Flat-shaded facets** (no smooth normals): light catches individual faces, which is what makes low-poly look crisp.
- Detail comes from a few well-placed extras (cornice bands, window insets, rooftop antennas, awnings, balconies),
  not from texture noise. Slight bevels or chamfers on major edges only.
- No outlines and no cartoon ink lines.

### 2.1b Setting: a city street (owner feedback, T-0309)
- The tower stands on the sidewalk of a city street. In front: curb, asphalt road with dashed centre line and edge
  lines, a zebra crossing in front of the tower, cars driving both ways, street lights. Neighbouring buildings frame
  the tower at the screen edges.
- Behind: three rows of city buildings (near shop fronts with awnings, a middle row, a far skyline) kept **low and
  hazy** (depth fog + background blur) so the sky shows and the tower stays the brightest, sharpest thing on screen.
  As the tower climbs, the rows rise slower than the camera, so the player climbs above the city.
- Camera: low street-level angle (6° pitch); the ground line sits low on screen, so the foreground is just the street.
  No grass or trees in the foreground.

### 2.2 Colour and materials
- Flat colour per material (no photo textures). One small palette texture or vertex colours are fine.
- Tower families: **blue** `#4a90d9`, **red** `#d9534a`, **green** `#5cb85c`, **gold** `#e6b800`. Siding is a pastel
  of the family colour (+42% lightness), trim is off-white `#e6e9f0`, and each family has an **accent** for window
  frames, awning stripes and the shop wall tint (`accent` in `block_types.json`: terracotta on blue and green, teal on
  red, blue on gold). Glass is dark navy `#2b3a57`.
- Glass is **emissive at night**: windows glow warm (`#ffd27a`) as the sky darkens with height.
- Trophy roofs use gold with emissive edges, so they bloom.
- Background layers are desaturated and pushed towards the sky colour with distance (atmospheric perspective).

### 2.3 Lighting and atmosphere
- One key light from the upper left and slightly in front (warm by day, orange at dusk, cool moonlight at night),
  with soft shadows. Sky-coloured ambient fill. Filmic tonemapping. Gentle **glow/bloom** on emissive parts only.
- Time of day follows tower height: day at the ground, **dusk** in the middle, **night with stars** near the top
  of tall towers and in endless mode.

### 2.4 Effects and animation (principles)
- Every event has a readable, physical-feeling response: squash on landing, dust shards on sloppy landings, a gold
  sparkle burst plus an expanding ring on a perfect, blocks tumbling in 3D during a collapse, and a soft camera kick.
- Particles are tiny low-poly shards (tetrahedra and cubes), not soft sprites.
- The carried block swings slightly on its rope (secondary motion). Idle elements drift: clouds, blinking antenna lights.
- Motion is snappy (ease-out, under 0.3 s) for feedback, slow and floaty for ambience.
- **Never switch a visible property instantly** (glow, colour, camera position): always ease it, even over 0.1 s.
  Instant switches on gameplay events read as flicker (T-0307). Reduced-motion setting
  disables shake and kick.

### 2.5 UI aesthetic
- Clean, rounded, flat panels with soft drop shadows; generous spacing; one bold rounded font (HR-0010).
- Accent gold for rewards, the tower family colours for buttons, dark navy backgrounds that match the night sky.

### 2.6 3D asset specs for artists (Blender → `.glb`)
| Asset | File | Budget | Notes |
|---|---|---|---|
| Storey (per family) | `block_<family>_floor.glb` | ≤ 900 tris | square: core 0.66 × 0.66, cornice ≤ 0.76; 0.6 tall; origin at bottom centre; all four sides detailed (the game turns it 38°, and debris tumbles) |
| Ground storey | `block_<family>_base.glb` | ≤ 1200 tris | same footprint and height; shop front on all four sides |
| Roof / trophy roof | `block_<family>_roof.glb`, `..._roof_trophy.glb` | ≤ 600 tris | sits on top of the last storey; trophy version has emissive parts |
| Crane hook | `crane_hook.glb` | ≤ 200 tris | attachment point at origin |
| Street | `env_street_tile.glb` | ≤ 500 tris | 4-unit tileable strip: sidewalk, curb, road, markings |
| City buildings, shop fronts | `env_city_building_*.glb`, `env_shopfront_*.glb` | ≤ 1500 tris each | front +Z; vary 1–7 units tall |
| Cars | `env_car_*.glb` | ≤ 400 tris | front +x |
| Street light | `env_street_light.glb` | ≤ 150 tris | arm over +Z |

Conventions: 1 Blender unit = 1 world unit; Y up in Godot (Blender's glTF export converts Z up); apply all
transforms; flat shading; materials named `body`, `body_dark`, `body2`, `wall2`, `trim`, `accent`, `glass`, `pot`,
`plant`, `emissive` so the game can recolour and light them (see `scripts/game/building_kit.gd` for what each is).
Export glTF binary with no cameras or lights. Until delivered, `scripts/game/building_kit.gd` (buildings) and `scripts/game/low_poly.gd` (environment) generate placeholders with
the same names and dimensions. Use them as the size and style reference.

## 3. Placeholder policy
The procedural meshes in `scripts/game/low_poly.gd` follow this guide and are meant to look decent, not final.
Integration (T-0301) swaps in delivered `.glb` files without changing rules. The 2D rectangle renderer stays as a
debug fallback (`feel.json` `"view": "2d"`).

## 4. Audio direction
Warm, playful, slightly toy-like. Feedback sounds rise in pitch with the combo. Music adapts in layers (base
loop, plus a combo layer). Mix: SFX bus, Music bus, UI bus, each with a settings slider.

### Event → sound mapping (implemented in `AudioDirector.SFX`)
| Event | Sound |
|---|---|
| block released | `sfx_block_release` |
| stack, \|offset\| < stable_offset | `sfx_block_land` |
| stack, \|offset\| ≥ stable_offset | `sfx_block_land_sloppy` |
| perfect (pitch +6% per combo level, max 12) | `sfx_perfect`; plus `sfx_combo_start` on the first |
| combo running (pitch follows drain speed) | `sfx_combo_tick_loop` |
| combo paid out | `sfx_combo_bank` |
| collapse | `sfx_collapse` |
| miss | `sfx_miss_fall` + `sfx_life_lost` |
| tower complete | `sfx_tower_complete` |
| any UI button | `sfx_ui_tap` |

Pause and screen changes: gameplay sounds (SFX pool, combo ticking) use pausable players, so they freeze while
paused and resume with the game; leaving a screen stops them. Music and UI clicks keep playing in the pause menu.

Until files exist in `game/assets/audio/`, each plays a procedural placeholder. `tests/test_audio.gd` fails if this
list and HR-0008 drift apart.

## 5. Naming convention
`<category>_<thing>[_<variant>].<ext>`, lowercase snake_case.
Categories: `block_`, `bg_`, `fx_`, `ui_`, `icon_`, `sfx_`, `music_`.

## 6. Integration
Integration tasks copy accepted files from `assets_inbox/` into `game/assets/<category>/` and wire them in.
The inbox remains the human-owned source.

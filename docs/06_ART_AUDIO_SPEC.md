# 06 · Art and audio specification

Concrete deliverables with exact file names are in `HUMAN_NEEDED.md` (HR-0004 to HR-0012).
This document holds the shared direction those requests follow.

## 1. Constraints
- Portrait, 720×1280 logical, assets authored at 1.5× (1080×1920 reference) and scaled down.
- One block = 1 world unit = 160 logical px wide; storey height 0.6 units = 96 logical px.
  Authoring: block canvas 480×288 px.
- Must read at small sizes; the tower is the hero; backgrounds stay low contrast.
- Colour-blind safe: block families also differ by shape/pattern, not only hue.

## 2. Direction candidates (HR-0002 picks one)
- **A. Flat pastel vector**: clean shapes, soft gradients, gentle shadows. Cheapest to produce, scales well.
- **B. Chunky low-poly look rendered to 2D sprites**: toy-like depth. Needs a 3D artist, then renders.
- **C. Hand-drawn storybook**: textured, warm, most distinctive, slowest to produce.

## 3. Placeholder policy
Until art lands, the game draws coloured rectangles (`tower_game.gd::_draw_block`). Integration tasks swap in
sprites without changing rules. Keep placeholders functional, not pretty.

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

Until files exist in `game/assets/audio/`, each plays a procedural placeholder. `tests/test_audio.gd` fails if this
list and HR-0008 drift apart.

## 5. Naming convention
`<category>_<thing>[_<variant>].<ext>`, lowercase snake_case.
Categories: `block_`, `bg_`, `fx_`, `ui_`, `icon_`, `sfx_`, `music_`.

## 6. Integration
Integration tasks copy accepted files from `assets_inbox/` into `game/assets/<category>/` and wire them in.
The inbox remains the human-owned source.

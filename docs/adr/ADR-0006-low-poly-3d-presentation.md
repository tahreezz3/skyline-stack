# ADR-0006 · Low-poly 3D presentation with a fixed 2D playfield

- Status: accepted
- Date: 2026-10-19
- Author: opus55-a7k2 (implements the owner's art direction, HR-0002)

## Context
The owner chose a modern low-poly look that "looks 3D, with effects, animation and design", while the level stays
2D and fixed (no camera rotation). We can get that look two ways:
1. **Pre-rendered sprites**: artists model in 3D and render PNGs; the game stays 2D.
2. **Real-time 3D**: low-poly meshes drawn by Godot through a locked orthographic camera; the game logic stays 2D.

## Decision
Real-time 3D (option 2) for the playfield; 2D for the UI.
- `scripts/game/tower_view_3d.gd` draws the round. Camera: orthographic, fixed, pitched about 14° down so the top
  faces of blocks show. The camera only follows the tower upwards and never rotates.
- All blocks sit on z = 0 and use the same world units as the rules (1 unit = one block width), so what the player
  sees lines up exactly with the 2D rules in `TowerState`. Rules, input and tests are unchanged (ADR-0004).
- HUD, popups and menus remain 2D Control/canvas drawing on top.
- The old 2D renderer remains as a fallback, selected by `feel.json` `"view": "2d"`.

## Consequences
- Real lighting and shadows, glow, emissive windows at night, and tumbling 3D debris come almost for free, with no
  per-angle sprite sheets.
- Artists deliver low-poly models (`.glb`, Blender), not sprite sheets. Asset specs in `docs/06_ART_AUDIO_SPEC.md`.
- Until art arrives, meshes are generated in code (`scripts/game/low_poly.gd`) in the target style, so the game
  already looks like the direction and artists have a style reference.
- More GPU work than 2D. Budget: under 60k triangles on screen, one shadowed directional light, glow on, no SSAO
  (not available on the mobile renderer). Check on a low-end phone during T-0602.

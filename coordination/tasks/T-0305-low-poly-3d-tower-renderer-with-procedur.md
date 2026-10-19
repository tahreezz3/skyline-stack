---
id: T-0305
title: Low-poly 3D tower renderer with procedural placeholders
milestone: M3
status: done
priority: P0
owner: "opus55-a7k2"
claimed: "2026-10-19T13:32"
depends: []
human: []
updated: 2026-10-19
---
# T-0305 · Low-poly 3D tower renderer with procedural placeholders

## Goal
Render the tower round in real-time low-poly 3D through a fixed orthographic camera (ADR-0006): procedural storey/roof/crane meshes, directional light with shadows, glow, emissive windows, tumbling 3D debris, low-poly particle shards. Rules and input unchanged; the 2D renderer stays as a fallback (feel.view).

## Context and references
-

## Acceptance criteria
- [x] Rendered in low-poly 3D through a fixed orthographic camera; rules and input unchanged
- [x] Procedural storey, roof, trophy roof, crane, debris and particle meshes in the chosen style
- [x] Light, shadows, glow, emissive night windows
- [x] 2D fallback via feel.view
- [x] Mesh tests (surfaces, size, outward flat faces)
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-19 created by opus55-a7k2
- 2026-10-19 claimed by opus55-a7k2
- 2026-10-19 done by opus55-a7k2: tower_view_3d.gd + low_poly.gd: ortho camera pitched 14°, flat-shaded storeys with trim/glass, roof and trophy roof on completion, crane with tilt-only swing, 3D tumbling debris, shard particles via MultiMesh, perfect ring flash, glow + emissive windows; 2D fallback kept; 13 mesh tests; verified visually across day/dusk/night

---
id: T-0308
title: Detailed angled buildings: shop-front ground storey, richer storeys, painterly sky
milestone: M3
status: done
priority: P0
owner: "opus55-a7k2"
claimed: "2026-10-19T14:10"
depends: []
human: []
updated: 2026-10-19
---
# T-0308 · Detailed angled buildings: shop-front ground storey, richer storeys, painterly sky

## Goal
Owner reference (docs/art/references/owner_reference_corner_building.webp): buildings shown at an angle (corner view) with much more low-poly detail; the bottom block is a distinct shop front (plinth panels, arched doors, striped awning); pastel palette with white trim and accent colours; painterly warm clouds, sea horizon, background blur.

## Context and references
-

## Acceptance criteria
- [x] Buildings turned 38° (corner view); footprint sized so the turned block matches gameplay width (tested)
- [x] Distinct shop-front ground storey: plinth panels, arched doors, corner columns, striped awning wrapping the corners
- [x] Richer storeys: siding battens, pilasters, stepped cornice, mullioned framed windows with sills, flower pots
- [x] Detailed roof (parapet, water tank, AC, antenna) and trophy spire
- [x] Pastel palette with off-white trim and per-family accent colour (block_types.json accent)
- [x] Painterly warm clouds, sea horizon, low hazy city, background depth-of-field blur
- [x] No coplanar overlapping top faces (automatic test); 702 checks green
- [x] Owner reference stored in docs/art/references/; style frames and artist specs updated
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-19 created by opus55-a7k2
- 2026-10-19 claimed by opus55-a7k2
- 2026-10-19 done by opus55-a7k2: building_kit.gd (facade builder repeated on 4 sides), angled blocks, base storey, roof, painterly sky shader, sea, DOF, accent palette; coplanar-face test found and fixed 4 z-fighting spots; tools/capture.sh for full-res frames

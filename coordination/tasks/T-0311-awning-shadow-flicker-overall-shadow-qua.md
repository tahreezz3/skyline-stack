---
id: T-0311
title: Awning shadow flicker; overall shadow quality
milestone: M3
status: done
priority: P0
owner: "opus55-a7k2"
claimed: "2026-10-19T15:31"
depends: []
human: []
updated: 2026-10-19
---
# T-0311 · Awning shadow flicker; overall shadow quality

## Goal
Owner bug 2026-10-19: the shop-front awning's shadow flickers; improve shadow quality overall.

## Context and references
-

## Acceptance criteria
- [x] Awning strips are closed slabs (top, underside, valance front/back) instead of one-sided surfaces
- [x] Building parts cast shadows double-sided
- [x] Shadow settings: stabilised 2 splits over 30 units, 4096 map, Soft High (desktop) / Soft Medium (mobile), small biases: no acne or saw-tooth on the awning, no grain
- [x] 4× MSAA removes sub-pixel slivers (dotted cornice lines) and jagged edges
- [x] Storey ledge overhangs the cornice below so no sub-pixel ring remains
- [x] Verified with zoomed before/after frames; quiet frames show zero flicker; remaining frame-to-frame change is the intended landing shake/squash and camera climb
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes
- Performance: MSAA 4× plus a 4096 Soft Medium shadow map on phones must be profiled in T-0602; first fallback if needed is size.mobile=2048 with max distance 22.

## Log
- 2026-10-19 created by opus55-a7k2
- 2026-10-19 claimed by opus55-a7k2
- 2026-10-19 done by opus55-a7k2: closed awning slabs, double-sided casting, stabilised soft high-res shadows with small bias, 4x MSAA; before/after zoom comparisons

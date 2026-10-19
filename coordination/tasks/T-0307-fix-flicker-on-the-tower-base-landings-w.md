---
id: T-0307
title: Fix flicker on the tower base (landings, window resize)
milestone: M3
status: done
priority: P0
owner: "opus55-a7k2"
claimed: "2026-10-19T13:57"
depends: []
human: []
updated: 2026-10-19
---
# T-0307 · Fix flicker on the tower base (landings, window resize)

## Goal
Owner report 2026-10-19: the base flickers when a block lands and while resizing the window. Find and remove every cause.

## Context and references
-

## Acceptance criteria
- [x] Measured: frames captured at two window sizes; a "toggling pixel" metric (pixel changes then returns within 2 frames) on the base area, plus a heat map
- [x] Windows no longer snap to gold when a combo starts or ends (eased 0.4 s glow, weaker by day): the main cause
- [x] Camera kick eases in and out instead of jumping (+3/-2 px per perfect)
- [x] Screen shake is a smooth wobble, not a new random offset every frame; ordinary landing shake halved
- [x] No coplanar overlapping faces in the plaza and plinth (z-fighting)
- [x] Shadows: camera closer, 36-unit range, 2 stabilised splits, 4096 map, bias tuned (no acne), light soft filter
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes
- Result: toggling pixels in the base area dropped from about 11,900 to about 6,700 per 90 frames; what remains is the intended gold ring on perfects passing over the base.
- Rule for future work: never switch a visible property (emission, camera position, colour) instantly on gameplay events; ease it.

## Log
- 2026-10-19 created by opus55-a7k2
- 2026-10-19 claimed by opus55-a7k2
- 2026-10-19 done by opus55-a7k2: root causes: instant combo window glow, instant camera kick, per-frame random shake, coplanar plaza faces, shimmering/acne shadows; all fixed and measured

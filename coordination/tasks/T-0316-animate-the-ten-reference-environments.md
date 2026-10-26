---
id: T-0316
title: Animate the ten reference environments
milestone: M3
status: done
priority: P1
owner: "codex-d7q5"
claimed: "2026-10-24T07:27"
depends: [T-0315]
human: [HR-0019]
updated: 2026-10-24
---
# T-0316 · Animate the ten reference environments

## Goal
Replace static scenic presentation with distinct living environments: cloud drift, masked water/reflections, independent scene actors, and camera depth, while preserving bright owner-reference art and gameplay.

## Context and references
- Owner: the matched backgrounds must be dynamic, with the bright individual reference settings retained.
- Follows T-0315 environment-only artwork; live modules, HUD and hybrid rules stay independent.

## Acceptance criteria
- [x] Each environment visibly animates sky, water and distinct live details; depth follows the round camera.
- [x] Masked effects stay off buildings, preserve reference colors and fit portrait crops.
- [x] Pause freezes environment animation and Reduced Motion suppresses motion.
- [x] Deterministic animation contracts and rendered motion previews cover all ten themes.
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes
- Living 2.5D illustration: reference plates remain the scenic foundation, with masked sky/water/cloth motion, bounded camera depth and independent vector actors behind gameplay.
- Native checks confirm changing actor/scenery pixels with a stationary camera and pixel-identical Reduced Motion output.
- Preview: `docs/art/previews/living-environments.mp4` (all ten) and `.webp` (three representative themes).
- HR-0019 tracks Git synchronization only; no authenticated remote access is available.

## Log
- 2026-10-24 created by codex-d7q5
- 2026-10-24 claimed by codex-d7q5
- 2026-10-24 codex-d7q5: implemented ten living environments, explicit pause/reduced-motion clock, data validation and 96 animation contracts. Full check: 1,267 checks and all smoke/UI/theme/motion tours pass. Native all-ten pixel checks and six-second previews verified; session log written.

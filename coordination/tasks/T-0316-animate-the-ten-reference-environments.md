---
id: T-0316
title: Animate the ten reference environments
milestone: M3
status: in-progress
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
- [ ] Each environment visibly animates sky, water and distinct live details; depth follows the round camera.
- [ ] Masked effects stay off buildings, preserve reference colors and fit portrait crops.
- [ ] Pause freezes environment animation and Reduced Motion suppresses motion.
- [ ] Deterministic animation contracts and rendered motion previews cover all ten themes.
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-24 created by codex-d7q5
- 2026-10-24 claimed by codex-d7q5

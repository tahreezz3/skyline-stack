---
id: T-0201
title: Scene flow: boot, menu, select, round, results
milestone: M2
status: done
priority: P1
owner: "opus55-a7k2"
claimed: "2026-10-13T15:11"
depends: [T-0003]
human: []
updated: 2026-10-13
---
# T-0201 · Scene flow: boot, menu, select, round, results

## Goal
Add a SceneRouter autoload with fade transitions and placeholder screens: main menu, tower select, tower round, results.

## Context and references
- docs/02_ARCHITECTURE.md 'Planned scene flow'

## Acceptance criteria
- [x] Full loop playable without restarting the app
- [x] Back button (Android) handled on every screen
- [x] Autoplay smoke test still passes
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 done by opus55-a7k2: SceneRouter autoload (fade, params, back button), main menu, tower select, results; --tour debug mode; all screens verified visually from --write-movie frames

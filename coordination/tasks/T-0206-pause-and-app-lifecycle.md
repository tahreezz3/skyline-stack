---
id: T-0206
title: Pause and app lifecycle
milestone: M2
status: done
priority: P2
owner: "opus55-a7k2"
claimed: "2026-10-13T15:12"
depends: [T-0201]
human: []
updated: 2026-10-13
---
# T-0206 · Pause and app lifecycle

## Goal
Pause button and auto-pause when the app loses focus; resume countdown; save on background.

## Context and references
- (see milestone in docs/04_ROADMAP.md)

## Acceptance criteria
- [x] Falling block and combo bar freeze while paused
- [x] Save written on focus loss
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 done by opus55-a7k2: pause button + back + focus-loss pause, 3 s resume countdown, save on focus loss; overlay layout bug found via frames and fixed in ui_kit

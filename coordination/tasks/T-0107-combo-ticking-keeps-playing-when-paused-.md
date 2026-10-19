---
id: T-0107
title: Combo ticking keeps playing when paused or after leaving the round
milestone: M1
status: done
priority: P0
owner: "opus55-a7k2"
claimed: "2026-10-19T14:02"
depends: []
human: []
updated: 2026-10-19
---
# T-0107 · Combo ticking keeps playing when paused or after leaving the round

## Goal
Owner bug 2026-10-19: the combo tick loop continues in the pause menu and after quitting to the main menu.

## Context and references
-

## Acceptance criteria
- [x] Combo ticking and gameplay SFX freeze while paused and resume after
- [x] Leaving a screen (quit to menu, restart) stops gameplay loops via GameEvents.screen_changing
- [x] Music and UI clicks still play in the pause menu
- [x] Tour step combo_audio reproduces the bug (fails on the old code, passes now)
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-19 created by opus55-a7k2
- 2026-10-19 claimed by opus55-a7k2
- 2026-10-19 done by opus55-a7k2: pausable gameplay players, stop on screen_changing, tour regression step verified against the old code

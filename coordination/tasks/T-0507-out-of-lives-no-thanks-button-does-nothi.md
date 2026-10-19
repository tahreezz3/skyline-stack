---
id: T-0507
title: Out-of-lives 'No thanks' button does nothing
milestone: M5
status: done
priority: P0
owner: "opus55-a7k2"
claimed: "2026-10-19T16:17"
depends: []
human: []
updated: 2026-10-19
---
# T-0507 · Out-of-lives 'No thanks' button does nothing

## Goal
Owner bug 2026-10-19: after running out of lives, the continue-ad prompt's 'No thanks' button does not work and the game never returns to the menu/results.

## Context and references
-

## Acceptance criteria
- [x] Root cause: losing focus (or pressing pause) while the continue prompt was up paused the tree underneath it, freezing its buttons; the pause menu was hidden behind the prompt
- [x] Prompt layer runs PROCESS_MODE_ALWAYS; no pausing during the prompt or after the round (can_pause); pause button hidden during the prompt, back again after a continue
- [x] Back on the prompt = No thanks; results timer runs even if paused
- [x] Regression tour steps with real clicks: decline, decline_real (real misses + simulated app switch); verified failing before, passing after
- [x] Testing doc: UI tests must click, not emit
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-19 created by opus55-a7k2
- 2026-10-19 claimed by opus55-a7k2
- 2026-10-19 done by opus55-a7k2: focus-loss pause froze the prompt; fixed + real-click regression steps

---
id: T-0108
title: Keep crane and tower on screen as the tower grows
milestone: M1
status: done
priority: P0
owner: "opus55-a7k2"
claimed: "2026-10-19T16:01"
depends: []
human: []
updated: 2026-10-19
---
# T-0108 · Keep crane and tower on screen as the tower grows

## Goal
Owner bug 2026-10-19: as you progress the crane and the building go out of the window (top cut off; tower drifting sideways off the narrower zoomed view).

## Context and references
-

## Acceptance criteria
- [x] Camera height framed from the crane hook (just below the HUD), follows faster
- [x] Crane swing centre glides after the tower top (crane.follow_speed); camera follows sideways
- [x] Shake/kick pixel scale fixed for the zoomed view
- [x] Autoplay framing check fails check.sh if the crane hook or tower top leaves the screen; old behaviour: 6946 violations in a 250-storey endless run, now 0
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-19 created by opus55-a7k2
- 2026-10-19 claimed by opus55-a7k2
- 2026-10-19 done by opus55-a7k2: camera framed from crane hook, crane centre + camera follow tower top, framing check in smoke test

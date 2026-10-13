---
id: T-0503
title: Analytics events
milestone: M5
status: done
priority: P2
owner: "opus55-a7k2"
claimed: "2026-10-13T15:47"
depends: [T-0201]
human: []
updated: 2026-10-13
---
# T-0503 · Analytics events

## Goal
Analytics service listening to GameEvents; event taxonomy doc; respects consent.

## Context and references
- (see milestone in docs/04_ROADMAP.md)

## Acceptance criteria
- [x] docs/ANALYTICS.md with every event
- [x] No events before consent where required
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes
- Uses placeholders so it can start now. Final sign-off or integration needs [HR-0015] (see HUMAN_NEEDED.md); if that is not delivered when the work is done, set status `review` and say so in the Log.

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 done by opus55-a7k2: Analytics autoload + analytics_events.gd schema/validation, docs/ANALYTICS.md (test keeps them in sync), consent gate (unknown/denied drop events) verified by tour step, opt-in toggle in Settings, log backend. Provider SDK split into T-... (needs HR-0015).

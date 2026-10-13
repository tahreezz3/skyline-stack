---
id: T-0501
title: Rewarded and interstitial ads
milestone: M5
status: todo
priority: P1
owner: ""
claimed: ""
depends: [T-0205]
human: []
updated: 2026-10-13
---
# T-0501 · Rewarded and interstitial ads

## Goal
Ads service behind an interface with a fake desktop implementation; rewarded continue (1 per round) and double coins; interstitial cadence rules from GDD §7. Use test ad units until HR-0015.

## Context and references
- docs/01_GDD.md §7

## Acceptance criteria
- [ ] Never shown during a round
- [ ] Cadence rules in economy.json
- [ ] Works with test ids on device
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes
- Uses placeholders so it can start now. Final sign-off or integration needs [HR-0015] (see HUMAN_NEEDED.md); if that is not delivered when the work is done, set status `review` and say so in the Log.

## Log
- 2026-10-13 created by opus55-planner

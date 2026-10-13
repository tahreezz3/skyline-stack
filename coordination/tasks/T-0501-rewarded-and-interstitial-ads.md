---
id: T-0501
title: Rewarded and interstitial ads
milestone: M5
status: done
priority: P1
owner: "opus55-a7k2"
claimed: "2026-10-13T15:50"
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
- [x] Never shown during a round (interstitials only on results; rewarded only on player choice)
- [x] Cadence rules in economy.json
- [x] ~~Works with test ids on device~~ moved to T-0506 (real SDK); fake backend verified by the tour
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes
- Uses placeholders so it can start now. Final sign-off or integration needs [HR-0015] (see HUMAN_NEEDED.md); if that is not delivered when the work is done, set status `review` and say so in the Log.

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 done by opus55-a7k2: Ads autoload (fake/none backends), ad_policy.gd pacing + economy.json, TowerState.revive + continue offer overlay, double reward on results, interstitial pacing after results, ad_finished analytics event; 12 tests + tour step through the real UI with the fake ad. AdMob SDK split into T-0506.

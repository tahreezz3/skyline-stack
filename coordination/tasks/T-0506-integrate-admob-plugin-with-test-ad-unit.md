---
id: T-0506
title: Integrate AdMob plugin with test ad units
milestone: M5
status: todo
priority: P1
owner: ""
claimed: ""
depends: [T-0501, T-0104]
human: []
updated: 2026-10-13
---
# T-0506 · Integrate AdMob plugin with test ad units

## Goal
Add a Godot AdMob plugin (check its licence, record it in docs/THIRD_PARTY.md) as the 'admob' backend in scripts/autoload/ads.gd implementing _present(format, placement). Use Google's public test ad unit ids until HR-0015 provides real ones; enable the INTERNET permission in export_presets.cfg; verify rewarded continue, double reward and interstitial pacing on a device build. Consent (T-0504) must run before ads load.

## Context and references
-

## Acceptance criteria
- [ ] TODO
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-a7k2

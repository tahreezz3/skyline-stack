---
id: T-0304
title: Localisation framework
milestone: M3
status: done
priority: P2
owner: "opus55-a7k2"
claimed: "2026-10-13T15:35"
depends: [T-0201]
human: []
updated: 2026-10-13
---
# T-0304 · Localisation framework

## Goal
Godot translation CSVs, all UI text through tr() keys, language setting; EN first, then 2 more languages.

## Context and references
- docs/03_DATA_SPEC.md 'Planned tables'

## Acceptance criteria
- [x] No hard-coded user-facing strings
- [x] Language switch at runtime
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 done by opus55-a7k2: strings.csv (EN + ES/DE drafts, 57 keys), all UI through tr(), language setting with runtime switch, --lang= preview flag, test_localisation.gd guard; native review requested as HR-0018

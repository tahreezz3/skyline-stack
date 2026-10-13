---
id: T-0202
title: Block type selection and unlocks
milestone: M2
status: in-progress
priority: P1
owner: "opus55-a7k2"
claimed: "2026-10-13T15:11"
depends: [T-0201, T-0203]
human: []
updated: 2026-10-13
---
# T-0202 · Block type selection and unlocks

## Goal
Tower select screen lists block types from block_types.json; locked types show their unlock population; the round uses the chosen type.

## Context and references
- game/config/block_types.json

## Acceptance criteria
- [ ] Selecting a type changes target height, roof and colour
- [ ] Locked types cannot start
- [ ] Tests for unlock logic in core
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2

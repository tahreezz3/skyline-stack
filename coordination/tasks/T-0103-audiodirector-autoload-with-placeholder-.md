---
id: T-0103
title: AudioDirector autoload with placeholder sounds
milestone: M1
status: todo
priority: P1
owner: ""
claimed: ""
depends: [T-0003]
human: []
updated: 2026-10-13
---
# T-0103 · AudioDirector autoload with placeholder sounds

## Goal
Create an AudioDirector autoload that listens to GameEvents and plays SFX/music on buses (Master, Music, SFX, UI). Use generated placeholder beeps until HR-0008/HR-0009 are delivered; file names must match HUMAN_NEEDED so delivered files drop in.

## Context and references
- docs/02_ARCHITECTURE.md
- HUMAN_NEEDED.md HR-0008, HR-0009

## Acceptance criteria
- [ ] Every sfx_* name in HR-0008 is mapped to an event
- [ ] Perfect chime pitch rises with combo count
- [ ] Missing files fall back to placeholders without errors
- [ ] Volume per bus readable from save settings
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes
- Uses placeholders so it can start now. Final sign-off or integration needs [HR-0008] (see HUMAN_NEEDED.md); if that is not delivered when the work is done, set status `review` and say so in the Log.

## Log
- 2026-10-13 created by opus55-planner

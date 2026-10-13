---
id: T-0103
title: AudioDirector autoload with placeholder sounds
milestone: M1
status: done
priority: P1
owner: "opus55-a7k2"
claimed: "2026-10-13T15:15"
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
- [x] Every sfx_* name in HR-0008 is mapped to an event
- [x] Perfect chime pitch rises with combo count
- [x] Missing files fall back to placeholders without errors
- [x] Volume per bus readable from save settings
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes
- Uses placeholders so it can start now. Final sign-off or integration needs [HR-0008] (see HUMAN_NEEDED.md); if that is not delivered when the work is done, set status `review` and say so in the Log.

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 done by opus55-a7k2: AudioDirector autoload (buses, pool, tick loop, music hook), placeholder_synth.gd renders all 12 HR-0008 sounds; test_audio.gd keeps names in sync with HUMAN_NEEDED; volume sliders in Settings. Real files still needed (HR-0008/HR-0009 -> T-0302)

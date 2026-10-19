---
id: T-0301
title: Integrate final block, background and crane art
milestone: M3
status: todo
priority: P1
owner: ""
claimed: ""
depends: [T-0102]
human: [HR-0002, HR-0004, HR-0006]
updated: 2026-10-13
---
# T-0301 · Integrate final block, background and crane art

## Goal
Swap the procedural low-poly placeholders (scripts/game/low_poly.gd) for the delivered .glb models from assets_inbox (HR-0004 storeys and roofs, HR-0006 environment): load them by the names in docs/06_ART_AUDIO_SPEC.md §2.6, keep the body/trim/glass/emissive material slots so family colours and night glow still work, use the base storey for block 1, and fall back to the procedural mesh when a file is missing.

## Context and references
- docs/06_ART_AUDIO_SPEC.md
- HUMAN_NEEDED.md

## Acceptance criteria
- [ ] All block types use the delivered models (base, floor, roof, trophy roof)
- [ ] Environment layers use the delivered models; time-of-day tint still applies
- [ ] Licences recorded in assets_inbox/LICENSES.md
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner

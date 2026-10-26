---
id: T-0318
title: Visual weather and orbital ascent
milestone: M3
status: done
priority: P1
owner: "codex-s8p4"
claimed: "2026-10-27T03:57"
depends: [T-0317]
human: [HR-0019]
updated: 2026-10-27
---
# T-0318 · Visual weather and orbital ascent

## Goal
Add ten random visual-only weather conditions and a continuous atmosphere-to-space ascent with stars and planets, preserving all gameplay and world anchors.

## Context and references
- Owner requests a dynamic climb to space/planets and ten random visual-only weather conditions.
- Preserve the approved T-0317 world-space scenery and all placement/crane/scoring/life rules.

## Acceptance criteria
- [x] All ten weather conditions can be selected randomly per round, across all themes, without gameplay effects.
- [x] Continuous upper-atmosphere/space transition with stars, an Earth-like planet, ringed gas giant and moon; original world anchors survive ascent/descent.
- [x] Weather/clouds disappear above the atmosphere; pause/Reduced Motion freeze activity and suppress lightning as appropriate.
- [x] Verify identical landing/tick outcomes and unchanged gameplay during rendering; native weather/space/pause/Reduced Motion exports pass.
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes
- Tunable presentation-only `atmosphere.json`; private RNG never consumes global/gameplay randomness. One condition persists within a round, with uncommon severe storms weighted lower.
- Default space transition: camera height 22–42 world units, approximately floors 40–75 in Endless. Weather fades out at heights 18–30; descent restores the same condition.
- Unit suite: 3,191 checks, zero failures. Actual-round/native tests cover all ten conditions, unchanged gameplay, clock/pause/Reduced Motion including space pixels, anchors and portrait resize.
- Original procedural shaders/meshes only; module lighting and core gameplay/config remain unchanged.
- Previews: docs/art/previews/weather.webp and space-ascent.webp/.mp4. Documentation: docs/art/WEATHER_AND_SPACE.md.
- Local implementation complete; GitHub synchronization is tracked separately by existing HR-0019.

## Log
- 2026-10-27 created by codex-s8p4
- 2026-10-27 claimed by codex-s8p4
- 2026-10-27 codex-s8p4: added random cosmetic weather and reversible orbital ascent, explicit-clock effects and original planets/cyclones; verified native rendering, matching gameplay outcomes and all project checks.

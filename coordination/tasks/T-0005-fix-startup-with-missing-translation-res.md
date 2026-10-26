---
id: T-0005
title: Fix startup with missing translation resources
milestone: M0
status: done
priority: P0
owner: "codex-s4n8"
claimed: "2026-10-26T11:53"
depends: []
human: [HR-0019]
updated: 2026-10-26
---
# T-0005 · Fix startup with missing translation resources

## Goal
Make direct Godot launch from a fresh checkout load EN/ES/DE translations and build the menu without format errors; catch missing runtime resources before editor import.

## Context and references
- Owner reported direct `godot --path game` on branch `istiaque_leon` cannot open three translation resources and crashes formatting LEVEL_N.
- Generated translations are git-ignored; the existing full check imports first and masks their absence.

## Acceptance criteria
- [x] Ship the generated EN/ES/DE translation resources and document regeneration.
- [x] Check direct startup before import and verify loaded translation content against the CSV.
- [x] A clean tracked-file checkout launches directly without resource or formatting errors.
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes
- Includes generated translation resources in Git; no menu formatting workaround is needed once actual localized messages load.
- Startup validation now precedes import and rejects resource errors even when Godot exits zero.
- HR-0019 covers GitHub authentication for remote sync only.

## Log
- 2026-10-26 created by codex-s4n8
- 2026-10-26 claimed by codex-s4n8
- 2026-10-26 codex-s4n8: reproduced the exact report in a tracked-file snapshot, shipped all three compiled catalogues, added runtime catalogue/menu checks and pre-import startup validation. Fresh-cache launches pass for EN/ES/DE; native menu renders correctly. Full check: 996 passed, zero failures, autoplay/UI tour pass.

---
id: T-0005
title: Fix startup with missing translation resources
milestone: M0
status: in-progress
priority: P0
owner: "codex-s4n8"
claimed: "2026-10-26T11:53"
depends: []
human: []
updated: 2026-10-26
---
# T-0005 · Fix startup with missing translation resources

## Goal
Make direct Godot launch from a fresh checkout load EN/ES/DE translations and build the menu without format errors; catch missing runtime resources before editor import.

## Context and references
- Owner reported direct `godot --path game` on branch `istiaque_leon` cannot open three translation resources and crashes formatting LEVEL_N.
- Generated translations are git-ignored; the existing full check imports first and masks their absence.

## Acceptance criteria
- [ ] Ship the generated EN/ES/DE translation resources and document regeneration.
- [ ] Check direct startup before import and verify loaded translation content against the CSV.
- [ ] A clean tracked-file checkout launches directly without resource or formatting errors.
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-26 created by codex-s4n8
- 2026-10-26 claimed by codex-s4n8

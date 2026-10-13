---
id: T-0204
title: Save system v2
milestone: M2
status: in-progress
priority: P1
owner: "opus55-a7k2"
claimed: "2026-10-13T15:08"
depends: [T-0002]
human: []
updated: 2026-10-13
---
# T-0204 · Save system v2

## Goal
Versioned save schema with migrations, settings (volumes, reduced motion, language), atomic writes (write temp then rename), corruption fallback.

## Context and references
- game/scripts/autoload/save_data.gd

## Acceptance criteria
- [ ] Schema version and migration path documented
- [ ] Corrupted file does not crash and keeps a backup
- [ ] Tests for migration
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2

---
id: T-0204
title: Save system v2
milestone: M2
status: done
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
- [x] Schema version and migration path documented
- [x] Corrupted file does not crash and keeps a backup
- [x] Tests for migration
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 done by opus55-a7k2: save_schema.gd v2 with v1 migration, atomic write + backup + corrupt recovery in save_data.gd, settings API; 20 checks in test_save_schema.gd and test_save_io.gd

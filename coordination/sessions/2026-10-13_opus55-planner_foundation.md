# Session 2026-10-13 · opus55-planner · foundation

- Model / person: Claude Opus 5.5 (first planner), with the project owner
- Tasks: T-0001, T-0002, T-0003, T-0004 (all done)
- Checkpoint at start: none; at end: CP-000

## Done
- Analysed the reference game (outside the repo, `../extracted/`), verified the stacking rules from its disassembly,
  and recorded the findings in `docs/05_REFERENCE_ANALYSIS.md`.
- Chose Godot 4.7 (owner approved) and installed it with Homebrew.
- Built the rules engine, tests, placeholder round, docs, coordination system and dashboard.

## Decisions made (and where they are recorded)
- Engine: ADR-0001. Data-driven config: ADR-0002. Coordination: ADR-0003. Rules/presentation split: ADR-0004. Clean room: ADR-0005.
- Sway is real: landings are measured against the swaying top (GDD §3.2).
- A landed block always houses at least 1 resident (GDD §3.1).
- The combo pool and count reset whenever the pool is banked (GDD §3.3; the reference may differ).
- Misses and collapses both bank the combo pool rather than discarding it.
- Owner's alternative combo idea ("next 5 blocks double") is kept as a tuning option in T-0101.

## Gotchas for the next session
- Don't name a preload constant the same as an autoload (e.g. `GameConfig`) in test scripts; it's a parse error. Tests use `ConfigLoader`.
- Untyped values from Dictionaries need explicit types (`var x: bool = ...`) where `:=` can't infer.
- `--write-movie` opens a window briefly; use it only when you need to see frames.

## Next suggested steps
- M1 tasks in parallel (see CP-000 "Next").

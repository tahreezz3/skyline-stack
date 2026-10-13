# ADR-0004 · Deterministic rules separated from presentation

- Status: accepted
- Date: 2026-10-13
- Author: opus55-planner

## Context
Feel tuning changes visuals often; rules must stay correct and testable without a screen.

## Decision
Rules live in `game/scripts/core/` as node-free, deterministic `RefCounted` scripts that return event dictionaries.
Scene scripts in `game/scripts/game/` only render, animate and forward input. Randomness, if ever needed in rules, is
passed in as a seeded RNG.

## Consequences
- Rules are covered by fast headless tests.
- Visual changes cannot break scoring.
- The "real sway" rule is applied by the scene (landing x is measured against the swaying top), which is documented in GDD §3.2.

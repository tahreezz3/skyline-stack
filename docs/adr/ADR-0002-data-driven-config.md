# ADR-0002 · Gameplay numbers live in JSON config

- Status: accepted
- Date: 2026-10-13
- Author: opus55-planner

## Context
Balancing needs many quick iterations by designers and agents, ideally without touching code.

## Decision
All tunable numbers live in `game/config/*.json`, loaded by the `GameConfig` autoload. Each key is documented in
`docs/03_DATA_SPEC.md` and checked by `tools/validate_config.py`.

## Consequences
- Rebalancing is a data-only change and easy to review.
- Every new key must be documented and validated.
- Exports must include `*.json` (non-resource files).

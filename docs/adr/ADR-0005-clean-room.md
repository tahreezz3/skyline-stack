# ADR-0005 · Clean-room development

- Status: accepted
- Date: 2026-10-13
- Author: opus55-planner

## Context
The design was informed by analysing an existing commercial game.

## Decision
Behaviour may be studied; no code, data files, art, audio, text or names are copied. Enforced by policy
(`docs/07_LEGAL_CLEANROOM.md`) and partly by `tools/cleanroom_check.py`.

## Consequences
- All assets come from humans via `HUMAN_NEEDED.md` with recorded licences.
- Numbers taken as starting points must be retuned by playtesting.

# ADR-0001 · Engine: Godot 4 with GDScript

- Status: accepted
- Date: 2026-10-13
- Author: opus55-planner (approved by project owner)

## Context
The reference game used Unity. This project is built largely by AI agents working in parallel sessions,
plus a small human team. Agents need to read, edit, run and test the project from a terminal.

## Decision
Godot 4.7 (installed via `brew install --cask godot`), GDScript, mobile renderer, portrait.

## Consequences
- Scenes (`.tscn`) and settings are plain text: diffable, mergeable, agent-editable.
- Headless tests and smoke runs work from the command line (`tools/check.sh`).
- No licence fees or revenue share.
- Ads and IAP need community or official plugins (evaluate licences in M5).
- Team members who know only Unity need a short ramp-up.

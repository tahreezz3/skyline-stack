# Skyline Stack (working title)

A one-tap tower-stacking game for mobile (portrait, Android first, then iOS).
A crane swings a building block; tap to drop it. Land it dead-centre for a
**perfect** snap and a combo bar; land it sloppily and the tower sways; land it
badly and the top of the tower topples until it is stable again. Completed
towers grow your city.

The design was informed by a clean-room analysis of an existing game in the
genre (see `docs/05_REFERENCE_ANALYSIS.md` and `docs/07_LEGAL_CLEANROOM.md`).
**Nothing from that game is used in this project: all code, art, audio and text
here are original.**

## Status at a glance

Open `coordination/dashboard.html` in a browser (or read `coordination/DASHBOARD.md`).
Regenerate it any time with `python3 tools/dashboard.py`.

## Quick start

```bash
# requirements: Godot 4.7+ (brew install --cask godot), Python 3.9+
tools/check.sh                      # config validation + rule tests + smoke test + dashboard
godot --path game                   # play it (click / space to drop)
godot --path game -e                # open in the editor
```

EN/ES/DE translation resources are included, so direct launch works without first opening the editor. If updating an older checkout that is missing them, run `godot --headless --path game --editor --import --quit` once. After changing `game/localisation/strings.csv`, regenerate and commit the three `.translation` files; see `docs/08_TESTING.md`.

## Where things are

| Path | What |
|---|---|
| `docs/COLLABORATION.md` | **Start here if you are an artist or a new human teammate**: setup, where files go, Git workflow. |
| `AGENTS.md` | **Start here if you are an AI agent.** Onboarding and working protocol. |
| `art_source/` | Artists' working files (`.blend`, `.psd`), stored with Git LFS. |
| `HUMAN_NEEDED.md` | Everything that needs a human: art, audio, decisions, accounts. Exact file names and drop folders. |
| `assets_inbox/` | Where humans drop requested files. |
| `docs/` | Vision, game design, architecture, data spec, roadmap, art/audio spec, legal, testing, ADRs. |
| `coordination/` | Tasks (one file each), checkpoints, session logs, the generated dashboard. |
| `game/` | The Godot project. Rules in `game/scripts/core`, scene code in `game/scripts/game`, numbers in `game/config`. |
| `tools/` | `check.sh`, `dashboard.py`, `new_task.py`, `cleanroom_check.py`. |

## Current state

Last checkpoint: **CP-000 Foundation** (`coordination/checkpoints/CP-000-foundation.md`).
Since then: the full game loop (menu, tower select, round, results, city map, settings, pause, endless), progression
and saves, juice and placeholder audio, EN/ES/DE localisation, analytics and ads against test backends, a balance
simulator with a first tuning pass, and an Android debug build. 656 automated checks. Remaining work waits on
humans; see `HUMAN_NEEDED.md` and the dashboard. Latest session log: `coordination/sessions/`.

The current environment renderer (T-0317/T-0318) builds ten world-space 3D settings with random cosmetic weather and a continuous climb into space, stars and planets in Endless. As the tower camera climbs, the ground and landmarks leave the view and higher cloud bands appear. See `docs/art/WORLD_ENVIRONMENTS.md`, `docs/art/WEATHER_AND_SPACE.md` and `docs/art/previews/space-ascent.mp4`. The earlier work was recovered onto `istiaque_leon` on October 26; branch/history details are in `docs/RECOVERY_2026-10-26.md`.

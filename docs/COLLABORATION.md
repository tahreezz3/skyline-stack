# Collaborating on Skyline Stack (for artists and new teammates)

Welcome! This repo is the whole game: Godot project, design docs, task board and the list of art we need.
You don't need to be a programmer to contribute. This page walks you through it.

## 1. One-time setup (about 15 minutes)

1. **Accept the GitHub invite** you received by email (the repository is private).
2. **Install the tools:**
   - [GitHub Desktop](https://desktop.github.com) (easiest; handles Git LFS automatically), *or* command-line git
     plus Git LFS: `brew install git git-lfs` (macOS) or the installers from git-scm.com and git-lfs.com, then run
     `git lfs install` once.
   - [Godot 4.7](https://godotengine.org/download) (standard version, not .NET) to see your art in the game.
   - [Blender](https://www.blender.org) 4.x for the 3D models.
3. **Clone the repository:** GitHub Desktop → *File → Clone repository* → `skyline-stack`; or
   `git clone https://github.com/tahreezz3/skyline-stack.git`.

Large files (models, images, audio, fonts) are stored with **Git LFS**. GitHub Desktop does this for you. With
command-line git, make sure you ran `git lfs install` before cloning.

## 2. What to make

Everything we need from a human is listed in **`HUMAN_NEEDED.md`**, one entry per request (`HR-0004`, `HR-0006`, ...),
with exact file names, sizes, triangle budgets and material names. The art direction lives in
**`docs/06_ART_AUDIO_SPEC.md`** §2. Look at the style frames in `docs/art/`: they show the game as it looks today,
with placeholder models generated in code. Your models replace those placeholders.

Key rules (details in the spec):
- Low-poly and flat-shaded, with good detail, in the cozy lo-fi pastel palette.
- 1 Blender unit = 1 game unit; a building storey is 0.6 tall with a square 0.66 core; origin at bottom centre.
- Name materials exactly as listed (`body`, `trim`, `accent`, `glass`, ...): the game recolours them per tower family.
- No single-sided planes (they cast flickering shadows) and no ledges thinner than about 0.02 units.
- Original work only. Never trace or copy another game's art (`docs/07_LEGAL_CLEANROOM.md`).

## 3. Where files go

| Folder | What | Who |
|---|---|---|
| `art_source/` | Your working files: `.blend`, `.psd`, `.kra`, reference sheets | artist |
| `assets_inbox/art/...`, `assets_inbox/audio/...` | The **exported** deliverable with the exact name from HUMAN_NEEDED (e.g. `assets_inbox/art/blocks/block_blue_floor.glb`) | artist |
| `assets_inbox/LICENSES.md` | One line per delivered file: author, "original work" or licence | artist |
| `game/assets/...` | Integrated copies used by the game | programmers / AI agents (task T-0301) |

Keep sources and exports separate: the game never reads `art_source/`.

## 4. Day-to-day workflow

1. **Pull** the latest changes first (GitHub Desktop: *Fetch origin → Pull*).
2. **Create a branch** for each request: `art/hr-0004-blue-storeys` (GitHub Desktop: *Branch → New branch*).
3. Make the asset, save the source in `art_source/`, export into the exact `assets_inbox/...` path.
4. **Preview in the game** (optional but encouraged): open `game/project.godot` in Godot and press F5.
   Integrated models appear once wired in (T-0301); until then, open the `.glb` in Godot's file browser to check
   scale and materials.
5. In `HUMAN_NEEDED.md`, set that request's `status:` to `delivered` and add a short note. Add your
   `LICENSES.md` line.
6. **Commit** with the request id in the message, e.g. `HR-0004: blue floor storey v1`, and **push**.
7. **Open a pull request** to `main` on GitHub. Mention anything you're unsure about. The owner reviews it, and an
   integration task brings it into the game.

Small fixes later? Same branch, new commit, push: the pull request updates automatically.

## 5. Checking progress

- `coordination/dashboard.html` (open it in a browser) shows open requests and which files have arrived. It detects
  files at the exact paths, so a typo in a file name shows up as "missing".
- Comment on the pull request, or ask the owner, for feedback.

## 6. Please don't

- Commit passwords, keystores, API keys or contracts.
- Rename or move files listed in `HUMAN_NEEDED.md` (the game and dashboard look for those exact paths).
- Edit `coordination/DASHBOARD.md` or `dashboard.html` by hand (they're generated).
- Force-push to `main`.

## For the owner

- Repository: https://github.com/tahreezz3/skyline-stack (private). Clone URL:
  `https://github.com/tahreezz3/skyline-stack.git`.
- Branch protection on `main` isn't available for private repos on a free GitHub plan (it needs GitHub Pro). Until
  then the team agreement is: **humans work on branches and open pull requests; nobody force-pushes `main`**. With Pro:
  Settings → Branches → protect `main`, require a pull request before merging.
- The reverse-engineering workspace (`../extracted/`) is outside this repository and must never be added to it.
  `tools/cleanroom_check.py` (run by `tools/check.sh`) fails if any file here matches a file there.
- AI agent sessions keep following `AGENTS.md`; they should pull before starting and push their commits so the artist
  sees them.

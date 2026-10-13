# assets_inbox: drop zone for human-made files

Put requested files here with the **exact path and name** given in `HUMAN_NEEDED.md`.
The dashboard detects them automatically.

| Folder | Contents |
|---|---|
| `art/` | Sprites and backgrounds (`art/blocks`, `art/crane`, `art/background`, `art/fx`) |
| `audio/` | Sound effects, `sfx_*.wav` |
| `music/` | Music loops, `music_*.ogg` |
| `fonts/` | Fonts with their licence files |
| `design/` | Mockups, sketches, design notes from humans |
| `store/` | App icon, store graphics |
| `docs/` | Anything else (contracts and secrets do NOT go here) |

Rules:
- Names: lowercase, `snake_case`, no spaces, as specified. Versions: overwrite the file; git keeps history.
- Record where each file came from in `LICENSES.md` (original work by X, or licence and source URL).
- Agents move accepted files into `game/assets/...` during integration tasks; the inbox copy stays as the source of truth.
- Never put keystores, passwords, API secrets or contracts here.

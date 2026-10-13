# coordination/

How parallel sessions share work without interrupting each other. The full protocol is in `../AGENTS.md`;
the reasoning is in `../docs/adr/ADR-0003-coordination-protocol.md`.

| Path | Who writes | What |
|---|---|---|
| `tasks/T-XXXX-slug.md` | the claiming session only | One task each. Frontmatter is parsed by tools. |
| `checkpoints/CP-XXX-name.md` | the session that completes a milestone | Verified project states to start from. |
| `sessions/YYYY-MM-DD_<handle>_<slug>.md` | each session, its own file | What was done, what is next, gotchas. |
| `DASHBOARD.md`, `dashboard.html` | `tools/dashboard.py` only | Generated overview. Never edit by hand. |
| `.last_check.json` | `tools/check.sh` | Result of the last full check, shown on the dashboard. |

## Task frontmatter contract

```yaml
---
id: T-0101                 # unique; use tools/new_task.py to get the next free one
title: Short imperative title
milestone: M1              # M0..M6, see docs/04_ROADMAP.md
status: todo               # todo | in-progress | review | done | blocked
priority: P1               # P0 (blocks milestone) | P1 | P2
owner: ""                  # handle of the claiming session
claimed: ""                # ISO date-time of claim
depends: [T-0003]          # tasks that must be done first
human: []                  # HR ids the task waits on (not ones it can placeholder)
updated: 2026-10-13
---
```

Status meanings: **todo** free to claim when ready; **in-progress** claimed; **review** work done, a human must
look or a human input is still pending; **done** accepted; **blocked** cannot proceed (say why in Notes).

The dashboard calls a task **Ready** when it is `todo`, all `depends` are `done`, and all `human` requests are
delivered, answered or accepted.

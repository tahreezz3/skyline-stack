# ADR-0003 · File-based coordination for parallel sessions

- Status: accepted
- Date: 2026-10-13
- Author: opus55-planner

## Context
Several AI sessions and humans work at the same time and must never block or overwrite each other.
Sessions start cold and need to catch up quickly.

## Decision
- One file per task (`coordination/tasks/`), claimed by editing its frontmatter. Stale after 48 h.
- One file per session log (`coordination/sessions/`); never shared files.
- Checkpoints (`coordination/checkpoints/`) mark verified states, tagged in git.
- Human needs in one parseable file (`HUMAN_NEEDED.md`) with exact drop paths in `assets_inbox/`.
- The dashboard (`coordination/DASHBOARD.md`, `dashboard.html`) is generated from those files and never edited by hand.

## Consequences
- No central file that everyone writes to, so far fewer merge conflicts.
- The dashboard is always derivable; nobody has to "update the status page".
- Agents must follow AGENTS.md precisely; the frontmatter format is a contract parsed by tools.

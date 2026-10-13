# 04 · Roadmap and checkpoints

Each milestone ends with a **checkpoint** (`coordination/checkpoints/CP-XXX-*.md`, git tag `cp-XXX`).
A checkpoint is a verified, documented state any new session can start from.
Tasks for each milestone are in `coordination/tasks/` (the `milestone` field).

| Milestone | Checkpoint | Goal | Exit criteria |
|---|---|---|---|
| **M0 Foundation** | CP-000 ✅ | Rules engine, placeholder round, docs, coordination | `tools/check.sh` green; round playable on desktop |
| **M1 Core feel** | CP-001 | The tap-drop-land loop feels great | Tuned constants signed off by a human playtest (HR-0017); juice pass; placeholder audio hooks; runs on an Android phone |
| **M2 Game loop** | CP-002 | Menu → select → round → results → progression, saved | New player can unlock all 4 types; save survives restart; hook chosen (HR-0003) and designed |
| **M3 Art and audio** | CP-003 | Final look and sound | All P1 art/audio HRs delivered and integrated; EN + 2 languages |
| **M4 City meta** | CP-004 | Finished towers build a city | Place towers on the map with our rules; district unlocks; city view |
| **M5 Services** | CP-005 | Ads, IAP, analytics, consent | Rewarded continue and remove-ads work in test mode; consent flow; events verified |
| **M6 Release** | CP-006 | Store-ready build | Signed AAB, store listing, QA pass on 5 devices, soft launch |

## Parallel work map
After CP-000 these can run in parallel without touching the same files:
- Track A (feel): T-0101, T-0102, T-0105 (scene script and config)
- Track B (flow): T-0201, T-0205, T-0206 (new scenes, `SceneRouter`)
- Track C (data/progression): T-0202, T-0203, T-0204 (core + save)
- Track D (audio plumbing): T-0103 (new autoload, listens to signals only)
- Track E (design): T-0110, T-0402 (docs only until approved)

## Later (post-1.0 backlog)
- Idle city management mode (shops, tourists, tips, offline income) like the reference game's second mode.
- Puzzle mini-games.
- Online leaderboards and cloud save.

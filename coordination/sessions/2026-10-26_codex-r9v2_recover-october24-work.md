# Session 2026-10-26 · codex-r9v2 · recover October 24 work

- Model / person: Codex, with the project owner
- Tasks: T-0006 (done)
- Checkpoint at start/end: CP-000; no new milestone exit criteria
- Active branch: istiaque_leon

## Done

- Investigated the owner's report that the October 24 work appeared lost. Reflog shows GitHub Desktop switched from main to the older istiaque_leon branch at 08:06 that day. All completed commits remain reachable on local main at adf7c84.
- Verified all ten reference-background LFS objects and three preview LFS objects by file size and SHA-256 before merging.
- Preserved branch tips as codex/backup-main-before-recovery-20261026 (adf7c84) and codex/backup-istiaque-before-recovery-20261026 (6156c50).
- Merged local main into istiaque_leon. Restored ten theme geometries/selector, compact HUD, bright reference backgrounds, fixed lighting and dynamic sky/water/cloth/actors, plus all original docs, tests and previews.
- Retained startup fix T-0005, compiled translation files and runtime catalogue/menu tests. Combined startup-before-import, theme and background-motion checks. CSV row comparison found no actual message changes on the older branch; only line-ending changes, so the complete theme catalogue was preserved.
- Resolved documentation/human-request conflicts by retaining both scopes; regenerated dashboard with its generator. Added docs/RECOVERY_2026-10-26.md and branch-recovery guidance in COLLABORATION.md.
- Verified game scripts, config and background assets exactly match preserved main. Newer localisation tests are the only difference under game/ relative to main.
- Full check: 1,585 checks, zero failures; 20-floor autoplay with zero framing violations; startup, UI/theme/motion, translation and clean-room checks pass.
- Native Metal gallery checks all ten environments and portrait layouts; inspected restored Manor/Lighthouse and selection screen. Native motion tour verifies changing scenery/actor-layer pixels, pause, stable Reduced Motion frames and resume in every theme.
- Clean tracked-file snapshot (no .godot cache/import) starts successfully with the merged translations.

## Decisions made (and where they are recorded)

- Recover by merging preserved history into the user's active branch, retaining both feature work and the startup fix. No reset or force-push.
- Leave GitHub Desktop stash 07736ed untouched. Its diff removes the dynamic-background feature and must not be applied as a recovery step. See docs/RECOVERY_2026-10-26.md.
- Local branch recovery is complete. HTTPS CLI pull/push still needs credentials (HR-0019); do not represent local commits as uploaded until remote sync succeeds.

## Gotchas for the next session

- The recovered source is on istiaque_leon; local main still preserves the October 24 source tip. Backup refs remain available.
- Inspect branch/log/stash diffs before assuming missing work was deleted. The raw media remain in local Git LFS storage.
- GitHub Desktop automation was attempted as a sync fallback, but its control tool timed out before returning UI state. No UI changes were made.
- Android/device QA and original art/audio human requests remain separate.

## Next suggested steps

- Owner: run godot --path game; choose the architecture theme on tower selection.
- Authenticate Git or publish the recovered istiaque_leon branch via an already signed-in GitHub Desktop session. Open the normal PR to main when ready.

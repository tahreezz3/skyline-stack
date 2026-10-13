---
id: T-0601
title: Release build pipeline
milestone: M6
status: todo
priority: P0
owner: ""
claimed: ""
depends: [T-0104]
human: [HR-0013, HR-0014, HR-0011]
updated: 2026-10-13
---
# T-0601 · Release build pipeline

## Goal
Release export preset, signed AAB from the command line using keystore env vars, version code scheme, icon.

## Context and references
- (see milestone in docs/04_ROADMAP.md)

## Acceptance criteria
- [ ] tools/build_release.sh produces a signed AAB
- [ ] Keystore never in repo
- [ ] docs/BUILD_ANDROID.md updated
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner

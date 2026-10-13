---
id: T-0104
title: Android debug build on a real device
milestone: M1
status: review
priority: P0
owner: "opus55-a7k2"
claimed: "2026-10-13T15:35"
depends: [T-0003]
human: []
updated: 2026-10-13
---
# T-0104 · Android debug build on a real device

## Goal
Set up Android export templates and a debug export preset, produce a debug APK, and document the steps so a human can install it for HR-0017.

## Context and references
- Godot docs: Exporting for Android
- docs/02_ARCHITECTURE.md (export must include *.json)

## Acceptance criteria
- [x] docs/BUILD_ANDROID.md written
- [x] Debug APK builds from the command line
- [ ] Touch input works (tap = drop): needs a real device (HR-0017); Godot's emulate-mouse-from-touch default maps taps to the click handler
- [x] HR-0017 updated with install instructions
- [x] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- 2026-10-13 created by opus55-planner
- 2026-10-13 claimed by opus55-a7k2
- 2026-10-13 review by opus55-a7k2: Installed JDK 17, Android cmdline tools + platform 35/build-tools 35.0.1/platform-tools, Godot 4.7.2 Android templates (SHA-512 verified), debug keystore; export_presets.cfg + tools/build_android.sh produce a signed 56 MB debug APK with configs and translations. Only on-device touch confirmation remains (HR-0017).

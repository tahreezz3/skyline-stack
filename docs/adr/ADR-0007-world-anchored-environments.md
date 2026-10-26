# ADR-0007 · World-anchored environments

- Status: accepted
- Date: 2026-10-26
- Author: codex-w2h7, following the owner's correction

## Context

The camera-attached scenic painting and small bounded parallax of T-0315/T-0316 kept the same ground composition visible as the tower rose. Animated water/clouds did not correct that spatial behavior. The owner explicitly rejected it.

## Decision

Build surroundings as independent original 3D world geometry. Ground, landmarks, water and local activity stay under a world root alongside the gameplay objects, outside the camera hierarchy. The existing camera follows the growing tower, naturally leaving low scenery behind; descent reveals the same world again.

Only infinite atmosphere/sun direction uses a camera-attached sky quad. Cloud meshes occupy fixed world-height bands with deterministic offscreen recycling; visible clouds retain world identity across band changes. No full scenic reference image is loaded at runtime.

Keep thematic palettes and settings from v001-v010, and independent module/HUD/rule architecture. Rendering reads the camera and paused clock, never changes rules, save data or outcomes. Reduced Motion freezes ambient activity while retaining essential camera tracking.

## Consequences

Height is verified using projected world anchors and rendered ascent/descent across every theme. Separate original models/layouts replace the painting's baked detail; the old art/prompts remain available as reference/provenance for future artist integration. Static geometry is batched, and cloud/particle pools are bounded. Mobile GPU/device profiling remains part of existing device QA.

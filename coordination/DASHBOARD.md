# Project dashboard

_Generated 2026-10-13 04:27 UTC by `tools/dashboard.py`. Do not edit by hand._

**Current checkpoint:** [CP-000 · Foundation](../coordination/checkpoints/CP-000-foundation.md)

**Last `tools/check.sh`:** PASS at 2026-10-13T04:26:19Z  config: ok · tests: ok · smoke: ok · ui-tour: ok · cleanroom: ok

## Milestones

| Milestone | Progress | Done / total |
|---|---|---|
| M0 Foundation | `████████████████████` | 4 / 4 |
| M1 Core feel | `███████░░░░░░░░░░░░░` | 2 / 6 |
| M2 Game loop | `████████████████████` | 7 / 7 |
| M3 Art and audio | `░░░░░░░░░░░░░░░░░░░░` | 0 / 4 |
| M4 City meta | `░░░░░░░░░░░░░░░░░░░░` | 0 / 3 |
| M5 Services | `░░░░░░░░░░░░░░░░░░░░` | 0 / 4 |
| M6 Release | `░░░░░░░░░░░░░░░░░░░░` | 0 / 4 |

## Ready to claim (5)

- **T-0104** [Android debug build on a real device](../coordination/tasks/T-0104-android-debug-build-on-a-real-device.md) · M1 P0
- **T-0304** [Localisation framework](../coordination/tasks/T-0304-localisation-framework.md) · M3 P2
- **T-0401** [City map grid and placement](../coordination/tasks/T-0401-city-map-grid-and-placement.md) · M4 P1
- **T-0501** [Rewarded and interstitial ads](../coordination/tasks/T-0501-rewarded-and-interstitial-ads.md) · M5 P1
- **T-0503** [Analytics events](../coordination/tasks/T-0503-analytics-events.md) · M5 P2

## In-Progress (1)

- **T-0101** [Tune core stacking constants](../coordination/tasks/T-0101-tune-core-stacking-constants.md) · M1 P0 · _owner opus55-a7k2_

## Review (1)

- **T-0110** [Design the unique hook](../coordination/tasks/T-0110-design-the-unique-hook.md) · M1 P1 · _owner opus55-a7k2_

## Blocked (0)

- none

## Waiting (12)

- **T-0105** [Crane polish and swing patterns](../coordination/tasks/T-0105-crane-polish-and-swing-patterns.md) · M1 P2 · _waits on T-0101_
- **T-0301** [Integrate final block, background and crane art](../coordination/tasks/T-0301-integrate-final-block-background-and-cra.md) · M3 P1 · _needs HR-0002, HR-0004, HR-0006_
- **T-0302** [Integrate final SFX and music](../coordination/tasks/T-0302-integrate-final-sfx-and-music.md) · M3 P1 · _needs HR-0008, HR-0009_
- **T-0303** [UI skin and font](../coordination/tasks/T-0303-ui-skin-and-font.md) · M3 P2 · _needs HR-0010, HR-0002_
- **T-0402** [Design our own city placement rules](../coordination/tasks/T-0402-design-our-own-city-placement-rules.md) · M4 P1 · _waits on T-0110_
- **T-0403** [City population and district unlocks](../coordination/tasks/T-0403-city-population-and-district-unlocks.md) · M4 P2 · _waits on T-0401, T-0402_
- **T-0502** [Remove-ads purchase](../coordination/tasks/T-0502-remove-ads-purchase.md) · M5 P1 · _waits on T-0501; needs HR-0013_
- **T-0504** [Consent and privacy](../coordination/tasks/T-0504-consent-and-privacy.md) · M5 P1 · _waits on T-0501; needs HR-0016_
- **T-0601** [Release build pipeline](../coordination/tasks/T-0601-release-build-pipeline.md) · M6 P0 · _waits on T-0104; needs HR-0013, HR-0014, HR-0011_
- **T-0602** [Performance and device QA](../coordination/tasks/T-0602-performance-and-device-qa.md) · M6 P1 · _waits on T-0301_
- **T-0603** [Store listing](../coordination/tasks/T-0603-store-listing.md) · M6 P1 · _waits on T-0301; needs HR-0001, HR-0012_
- **T-0604** [Soft launch checklist](../coordination/tasks/T-0604-soft-launch-checklist.md) · M6 P1 · _waits on T-0601, T-0602, T-0603_

## Needs a human (17 open of 17)

Details and exact file names: [HUMAN_NEEDED.md](../HUMAN_NEEDED.md)

| ID | Request | Type | Priority | Files | Blocks |
|---|---|---|---|---|---|
| HR-0001 | Final game name | decision | P1 | - | T-0603 |
| HR-0002 | Art direction choice | decision | P0 | - | T-0301, T-0303 |
| HR-0003 | Approve the unique hook | decision | P1 | - | - |
| HR-0004 | Building block sprites (4 colours × 4 parts) | art | P1 | 0/16 | T-0301 |
| HR-0005 | Crane hook and rope | art | P2 | 0/2 | - |
| HR-0006 | Background layers | art | P1 | 0/4 | T-0301 |
| HR-0007 | Ground, dust and debris effects | art | P2 | 0/4 | - |
| HR-0008 | Sound effects set | audio | P1 | 0/12 | T-0302 |
| HR-0009 | Music loops | music | P2 | 0/3 | T-0302 |
| HR-0010 | UI font | font | P2 | 0/2 | T-0303 |
| HR-0011 | App icon | art | P1 | 0/3 | T-0601 |
| HR-0012 | Store listing graphics | store | P2 | 0/1 | T-0603 |
| HR-0013 | Studio name, package id and Google Play account | account | P1 | - | T-0502, T-0601 |
| HR-0014 | Android signing keystore | account | P1 | - | T-0601 |
| HR-0015 | Ads and analytics accounts | account | P2 | - | - |
| HR-0016 | Privacy policy and legal entity | legal | P1 | - | T-0504 |
| HR-0017 | Device playtest of core feel | playtest | P1 | - | - |

## Recent sessions

- [Session 2026-10-13 · opus55-planner · foundation](../coordination/sessions/2026-10-13_opus55-planner_foundation.md)

## Checkpoints

- [CP-000 · Foundation](../coordination/checkpoints/CP-000-foundation.md) 2026-10-13

## Warnings

- none

## Done (13)

- T-0001 Project foundation, docs and vision
- T-0002 Core tower rules engine with tests
- T-0003 Placeholder tower round scene with autoplay
- T-0004 Coordination tooling and dashboard
- T-0102 Juice pass with placeholder effects
- T-0103 AudioDirector autoload with placeholder sounds
- T-0201 Scene flow: boot, menu, select, round, results
- T-0202 Block type selection and unlocks
- T-0203 Player level and progression rules
- T-0204 Save system v2
- T-0205 Results screen and stats
- T-0206 Pause and app lifecycle
- T-0207 Endless mode

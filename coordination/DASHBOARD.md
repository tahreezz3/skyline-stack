# Project dashboard

_Generated 2026-10-24 01:47 UTC by `tools/dashboard.py`. Do not edit by hand._

**Current checkpoint:** [CP-000 · Foundation](../coordination/checkpoints/CP-000-foundation.md)

**Last `tools/check.sh`:** PASS at 2026-10-24T01:47:35Z  config: ok · tests: ok · smoke: ok · ui-tour: ok · theme-tour: ok · background-motion: ok · cleanroom: ok · translations: ok

## Milestones

| Milestone | Progress | Done / total |
|---|---|---|
| M0 Foundation | `████████████████████` | 4 / 4 |
| M1 Core feel | `███████████░░░░░░░░░` | 5 / 9 |
| M2 Game loop | `████████████████████` | 8 / 8 |
| M3 Art and audio | `████████████████░░░░` | 13 / 16 |
| M4 City meta | `███████░░░░░░░░░░░░░` | 1 / 3 |
| M5 Services | `█████████░░░░░░░░░░░` | 3 / 7 |
| M6 Release | `░░░░░░░░░░░░░░░░░░░░` | 0 / 4 |

## Ready to claim (0)

- none

## In-Progress (0)

- none

## Review (3)

- **T-0101** [Tune core stacking constants](../coordination/tasks/T-0101-tune-core-stacking-constants.md) · M1 P0 · _owner opus55-a7k2_
- **T-0104** [Android debug build on a real device](../coordination/tasks/T-0104-android-debug-build-on-a-real-device.md) · M1 P0 · _owner opus55-a7k2_
- **T-0110** [Design the unique hook](../coordination/tasks/T-0110-design-the-unique-hook.md) · M1 P1 · _owner opus55-a7k2_

## Blocked (0)

- none

## Waiting (14)

- **T-0105** [Crane polish and swing patterns](../coordination/tasks/T-0105-crane-polish-and-swing-patterns.md) · M1 P2 · _waits on T-0101_
- **T-0301** [Integrate final block, background and crane art](../coordination/tasks/T-0301-integrate-final-block-background-and-cra.md) · M3 P1 · _needs HR-0002, HR-0004, HR-0006_
- **T-0302** [Integrate final SFX and music](../coordination/tasks/T-0302-integrate-final-sfx-and-music.md) · M3 P1 · _needs HR-0008, HR-0009_
- **T-0303** [UI skin and font](../coordination/tasks/T-0303-ui-skin-and-font.md) · M3 P2 · _needs HR-0010, HR-0002_
- **T-0402** [Design our own city placement rules](../coordination/tasks/T-0402-design-our-own-city-placement-rules.md) · M4 P1 · _waits on T-0110_
- **T-0403** [City population and district unlocks](../coordination/tasks/T-0403-city-population-and-district-unlocks.md) · M4 P2 · _waits on T-0401, T-0402_
- **T-0502** [Remove-ads purchase](../coordination/tasks/T-0502-remove-ads-purchase.md) · M5 P1 · _needs HR-0013_
- **T-0504** [Consent and privacy](../coordination/tasks/T-0504-consent-and-privacy.md) · M5 P1 · _needs HR-0016_
- **T-0505** [Integrate the production analytics provider](../coordination/tasks/T-0505-integrate-the-production-analytics-provi.md) · M5 P2 · _needs HR-0015_
- **T-0506** [Integrate AdMob plugin with test ad units](../coordination/tasks/T-0506-integrate-admob-plugin-with-test-ad-unit.md) · M5 P1 · _waits on T-0501, T-0104_
- **T-0601** [Release build pipeline](../coordination/tasks/T-0601-release-build-pipeline.md) · M6 P0 · _waits on T-0104; needs HR-0013, HR-0014, HR-0011_
- **T-0602** [Performance and device QA](../coordination/tasks/T-0602-performance-and-device-qa.md) · M6 P1 · _waits on T-0301_
- **T-0603** [Store listing](../coordination/tasks/T-0603-store-listing.md) · M6 P1 · _waits on T-0301; needs HR-0001, HR-0012_
- **T-0604** [Soft launch checklist](../coordination/tasks/T-0604-soft-launch-checklist.md) · M6 P1 · _waits on T-0601, T-0602, T-0603_

## Needs a human (18 open of 19)

Details and exact file names: [HUMAN_NEEDED.md](../HUMAN_NEEDED.md)

| ID | Request | Type | Priority | Files | Blocks |
|---|---|---|---|---|---|
| HR-0001 | Final game name | decision | P1 | - | T-0603 |
| HR-0003 | Approve the unique hook | decision | P1 | - | - |
| HR-0004 | Building storey models (4 families × 4 parts, low-poly 3D) | art | P1 | 0/16 | T-0301 |
| HR-0005 | Crane hook model | art | P2 | 0/1 | - |
| HR-0006 | City environment models (street, buildings, cars, props) | art | P1 | 0/11 | T-0301 |
| HR-0007 | Effect look-dev (optional polish) | art | P2 | 0/1 | - |
| HR-0008 | Sound effects set | audio | P1 | 0/12 | T-0302 |
| HR-0009 | Music loops | music | P2 | 0/3 | T-0302 |
| HR-0010 | UI font | font | P2 | 0/2 | T-0303 |
| HR-0011 | App icon | art | P1 | 0/3 | T-0601 |
| HR-0012 | Store listing graphics | store | P2 | 0/1 | T-0603 |
| HR-0013 | Studio name, package id and Google Play account | account | P1 | - | T-0502, T-0601 |
| HR-0014 | Android signing keystore | account | P1 | - | T-0601 |
| HR-0015 | Ads and analytics accounts | account | P2 | - | T-0505 |
| HR-0016 | Privacy policy and legal entity | legal | P1 | - | T-0504 |
| HR-0017 | Device playtest of core feel | playtest | P1 | - | - |
| HR-0018 | Review Spanish and German translations | design | P2 | - | - |
| HR-0019 | Restore GitHub authentication and sync the theme implementation | account | P2 | - | T-0314, T-0315, T-0316 |

Delivered / answered: HR-0002

## Recent sessions

- [Session 2026-10-24 · codex-r6b2 · reference backgrounds](../coordination/sessions/2026-10-24_codex-r6b2_reference-backgrounds.md)
- [Session 2026-10-24 · codex-p8m4 · ten themes](../coordination/sessions/2026-10-24_codex-p8m4_ten-themes.md)
- [Session 2026-10-24 · codex-d7q5 · living backgrounds](../coordination/sessions/2026-10-24_codex-d7q5_living-backgrounds.md)
- [Session 2026-10-13 · opus55-planner · foundation](../coordination/sessions/2026-10-13_opus55-planner_foundation.md)
- [Session 2026-10-13 · opus55-a7k2 · M1/M2 build-out](../coordination/sessions/2026-10-13_opus55-a7k2_m1-m2-build.md)

## Checkpoints

- [CP-000 · Foundation](../coordination/checkpoints/CP-000-foundation.md) 2026-10-13

## Warnings

- none

## Done (34)

- T-0001 Project foundation, docs and vision
- T-0002 Core tower rules engine with tests
- T-0003 Placeholder tower round scene with autoplay
- T-0004 Coordination tooling and dashboard
- T-0102 Juice pass with placeholder effects
- T-0103 AudioDirector autoload with placeholder sounds
- T-0106 First block on the foundation never wobbles
- T-0107 Combo ticking keeps playing when paused or after leaving the round
- T-0108 Keep crane and tower on screen as the tower grows
- T-0201 Scene flow: boot, menu, select, round, results
- T-0202 Block type selection and unlocks
- T-0203 Player level and progression rules
- T-0204 Save system v2
- T-0205 Results screen and stats
- T-0206 Pause and app lifecycle
- T-0207 Endless mode
- T-0208 Towers start at 20 storeys; retune rewards and unlocks
- T-0304 Localisation framework
- T-0305 Low-poly 3D tower renderer with procedural placeholders
- T-0306 Low-poly environment: sky by height, parallax hills and skyline, clouds
- T-0307 Fix flicker on the tower base (landings, window resize)
- T-0308 Detailed angled buildings: shop-front ground storey, richer storeys, painterly sky
- T-0309 City setting: street in front, city skyline behind, lower camera
- T-0310 Cozy lo-fi look: zoom in, spacious distant city, warm palette, a cat
- T-0311 Awning shadow flicker; overall shadow quality
- T-0312 Foreground detail pass and a setting pink sun
- T-0313 Dreamy violet-pink sun
- T-0314 Implement ten visual themes and reference HUD
- T-0315 Match bright reference backgrounds for all themes
- T-0316 Animate the ten reference environments
- T-0401 City map grid and placement
- T-0501 Rewarded and interstitial ads
- T-0503 Analytics events
- T-0507 Out-of-lives 'No thanks' button does nothing

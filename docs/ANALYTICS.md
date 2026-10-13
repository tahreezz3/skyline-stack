# Analytics

Source of truth: `game/scripts/core/analytics_events.gd`. `game/tests/test_analytics.gd` fails if this table and
the schema drift apart, so update both together.

## Privacy rules
- Nothing is sent unless `settings.analytics_consent == "granted"`. Before the player decides, events are
  **dropped, not queued**. Default is `unknown`; the opt-in toggle is in Settings; the first-launch consent flow is
  T-0504 (with the ads consent, HR-0016).
- No personal data, device ids, free text or precise location in event parameters. Values are simple
  (bool/int/float/short string); `validate()` enforces it.
- Only the setting keys in `REPORTABLE_SETTINGS` are reported.

## Backends
- `log` (default during development): JSON lines in `user://analytics_log.jsonl`
  (macOS: `~/Library/Application Support/Godot/app_userdata/Skyline Stack (working title)/`).
- `none`: used automatically for `--autoplay` and `--tour` runs.
- The production provider (Firebase or GameAnalytics, HR-0015) will be another backend implementing `_send()`.
- `--analytics-print` prints each sent event to the console.

## Events

| Event | Params | When |
|---|---|---|
| `session_start` | `app_version`, `locale` | app start (only if consent was already granted) |
| `round_start` | `block_type`, `endless` | a round begins |
| `round_end` | `block_type`, `endless`, `complete`, `star`, `population`, `height`, `max_combo`, `duration_s` | a round ends |
| `level_up` | `from_level`, `to_level` | player level rises |
| `tower_unlocked` | `block_type` | a tower type unlocks |
| `city_tower_placed` | `block_type`, `city_population` | a tower is placed on the city map |
| `setting_changed` | `key`, `value` | a reportable setting changes |

## Questions these answer (soft launch KPIs, docs/00_VISION.md)
- Session length and rounds per session: `session_start`, `round_start`/`round_end` with `duration_s`.
- Difficulty curve: completion and trophy rate per `block_type` from `round_end`. Compare with
  `docs/balance/sim_report.md` to calibrate the simulator against real players.
- Progression pacing: time to each `tower_unlocked` and `level_up`.
- Meta engagement: share of players who place towers (`city_tower_placed`).

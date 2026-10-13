# Unique hook: design briefs (T-0110, decision HR-0003)

Every stacker has a crane, a tap, and a tower. To be worth downloading (and to stand clearly apart from
the reference game), we need one or two signature ideas. Below are five briefs. Each lists the rules,
the data it needs, the UI, effort, and risks, judged against the pillars in `docs/00_VISION.md`.

Effort: S = under 3 agent-days, M = about a week, L = several weeks (includes human art/audio time).

---

## H1 · Height zones and weather
**Pitch:** the sky changes as you climb. Wind gusts push falling blocks at 20+ storeys, dusk dims the view
at 30+, and clouds hide the tower top at 40+.

**Rules**
- Zones defined by height: `{from_height, wind: {strength, interval_s}, visibility, clouds}`.
- Wind applies a horizontal velocity to the *falling* block during a gust; an arrow and a sock flag telegraph
  direction one second ahead, so skill beats luck.
- Clouds periodically cover the top 2 storeys; the swing guide line still shows.
- All deterministic from a seed so tests and daily challenges work.

**Data:** `zones.json`. **UI:** wind sock, gust warning, sky tint. **Art/audio:** sky gradient stages
(already in HR-0006), wind and thunder sounds (new HR).

**Effort:** M. **Pillars:** 1 (skill: reading the telegraph), 3 (drama at height).
**Risks:** feels unfair if the telegraph is unclear; must be playtested. Only matters to players who reach 20+.

---

## H2 · Special blocks
**Pitch:** some blocks are not like the others. The next block is always shown, so you can plan.

| Block | Rule | Why it's fun |
|---|---|---|
| **Steel** | heavy: on landing it clears the wobble window (tower stops swaying) | a reward for patience; a "reset" to save a shaky tower |
| **Glass** | double residents, but collapses if offset > 0.25 instead of 0.35 | risk/reward |
| **Balloon** | falls at half speed | lets you aim carefully; breaks rhythm |
| **Gold** | a perfect on it starts the combo with a doubled pool | chase moments |

**Rules:** a block sequence generator (seeded) picks special blocks by weight per tower type; the HUD shows
"next block". Each special changes one parameter in `TowerState.land()` for that block only.

**Data:** `special_blocks.json` (weights per tower type, per-block parameter overrides).
**UI:** next-block preview. **Art:** 4 block skins (new HR). **Audio:** 1 sound per special.

**Effort:** M. **Pillars:** 1, 2 (steel is forgiveness you earn), 3.
**Risks:** clutters the clean one-tap feel if too frequent; start at about 1 in 8 blocks.

---

## H3 · Daily skyline
**Pitch:** one shared tower per day. Same seed for everyone (crane pattern, special blocks, weather), one
target, a personal best, and a share card ("Day 213: 34 storeys, 6x combo 🏗️").

**Rules:** seed = date. Unlimited attempts, best attempt counts. A streak counter rewards playing on
consecutive days (cosmetic rewards only).

**Data:** `daily.json` (target rules, rewards). Works offline (seed from date); online leaderboard later.
**UI:** daily card on the menu, result share image. **Art:** share card frame (new HR).

**Effort:** S if H1 or H2 exists (it reuses the seeded generator), M otherwise.
**Pillars:** 4 (reason to come back), 5 (no paywall). **Risks:** low; sharing needs a native share plugin.

---

## H4 · Tenants with wishes
**Pitch:** your residents ask for things: "a 5-perfect streak", "a 15-storey red tower", "no collapses this
round". Completing wishes earns coins and cosmetics.

**Rules:** 3 active wishes, refreshed as they complete; a wish is a condition over round summaries
(the `round_ended` signal already carries what's needed).

**Data:** `wishes.json` (condition type, params, reward). **UI:** wish list panel, completion toast.
**Art:** tenant portraits (new HR; the reference game has guests with wishes, so our tenants and conditions
must be designed fresh).

**Effort:** M. **Pillars:** 4. **Risks:** chore-list feel; conceptually close to the reference game's wish system.

---

## H5 · District themes (cosmetic)
**Pitch:** build in different cities: neon Tokyo, Nordic wood, desert adobe, Victorian brick. Each theme
changes block art, background, music and particle colours. Unlocked by play or bought.

**Rules:** none (cosmetic only). **Data:** `themes.json`. **Art/audio:** a full asset set per theme: the most
expensive option by far.

**Effort:** L (mostly human art). **Pillars:** 4, 5 (fair monetisation via cosmetics).
**Risks:** cost; it doesn't change gameplay, so it can't be the *only* hook.

---

## Recommendation
**Build H2 (special blocks) first, then H3 (daily skyline) on top of it.**
- H2 adds decisions and moments while keeping one-tap play, and the steel block deepens our wobble rule.
- H3 is cheap once blocks come from a seeded generator, and gives the strongest retention reason.
- H1 is a strong v1.1 follow-up (it reuses the same seeded generator); H5 is the monetisation path after launch.
- H4 is the closest to the reference game; skip it or redesign it heavily.

## What happens after HR-0003 is answered
The deciding human writes the choice under HR-0003. The next session then:
1. writes the full spec for the chosen hook(s) into `docs/01_GDD.md` §6;
2. creates tasks with `tools/new_task.py` (draft list for H2+H3 below);
3. adds art/audio requests to `HUMAN_NEEDED.md`.

Draft tasks for H2 + H3:
- Seeded block sequence generator in `scripts/core/` + tests (M2)
- Special block rules in `TowerState` + tests (M2)
- Next-block preview HUD (M2)
- `special_blocks.json` + validator (M2)
- Daily skyline mode: date seed, best, streak (M2)
- Share card (M5, needs a share plugin)
- HR: 4 special block skins, 4 special sounds, share card frame

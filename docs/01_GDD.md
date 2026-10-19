# 01 · Game design document

Status: core rules implemented and tested (CP-000). Sections marked **[planned]** are not built yet.
Numbers in this document are defaults; the source of truth is `game/config/*.json`.

## 1. Core loop
1. A crane swings a block left and right above the tower; the swing speeds up as the tower grows.
2. The player taps; the block drops straight down.
3. The block lands (perfect, stack or collapse) or misses the tower entirely.
4. Repeat until the tower reaches its target height (tower complete, roof bonus) or lives run out.
5. Population earned goes to the player's lifetime total, unlocking block types and city districts.

## 2. Terms
- **Offset**: horizontal distance between the new block's centre and the block below, in block widths.
- **Population**: score. Each landed block houses residents.
- **Wobble/sway**: how much the tower swings sideways, built from recent offsets.
- **Combo / super time**: a timed bonus state started by a perfect landing.

## 3. Tower rules (implemented in `game/scripts/core/tower_state.gd`)

| Rule | Default | Config key |
|---|---|---|
| Perfect snap if \|offset\| < | 0.06 | `snap_window` |
| Collapse if \|offset\| > | 0.35 | `max_offset` |
| Miss if \|offset\| ≥ (no overlap) | 1.0 | `miss_offset` |
| Block counts as stable if \|diff\| < | 0.20 | `stable_offset` |
| Delay between toppling blocks | 0.2 s | `collapse_interval_s` |
| Residents per block | 4 to 1 | `residents_max` |
| Wobble window | last 5 blocks | `wobble_window` |
| Wobble gain | 1.4 | `wobble_gain` |
| Lives | 3 | `lives` |
| Collapse costs a life | yes | `collapse_costs_life` |

### 3.1 Landing
- **First storey on the foundation:** if its centre lands within `first_block_zone` (0.62, the visible foundation
  pad) it stays where it landed and counts as perfectly stable: it adds no wobble and never falls in a collapse.
  Residents and the perfect snap still follow the normal rules (owner request, T-0106). Further out it topples off
  (collapse) or misses.
- **Perfect** (\|offset\| < snap window): the block snaps exactly onto the one below (offset becomes 0).
  4 residents. Starts or refills the combo bar. Pushes 0 into the wobble window, which calms the tower.
- **Stack** (snap ≤ \|offset\| ≤ max): the block stays where it landed.
  Residents = `max(1, 4 − floor(min(1, |offset|/max_offset) × 4))`. Its signed offset enters the wobble window.
- **Collapse** (max < \|offset\| < miss): the block topples. Then, while the block now on top has
  \|diff\| ≥ stable_offset, that block topples too (0.2 s apart). The foundation never falls.
  Residents of fallen blocks are subtracted. **Costs a life** (`collapse_costs_life`, set in T-0101 because without it
  no one could lose; see `docs/balance/TUNING_LOG.md`). Breaks the combo (the pool is banked).
- **Miss** (\|offset\| ≥ miss): the block falls past the tower and off screen. Lose 1 life; at 0 lives the round
  ends. Breaks the combo (banked).

Design intent: a run of sloppy same-side placements leaves several unstable blocks, so one more bad drop
takes 3–4 of them down "until the tower is stable again". Careful players lose little.

### 3.2 Wobble and sway
- `wobble = wobble_gain × sum(signed offsets of the last 5 blocks)`.
- The scene sways the tower: top displacement = `clamp(wobble × sway.scale, ±sway.max) × sin(t × sway.speed)`,
  scaled linearly down to 0 at the foundation.
- The sway is **real**: landings are measured against the swaying top, so a wobbly tower is harder to hit.

### 3.3 Combo ("super time")
- A perfect sets the bar to 8 s and adds 1 to the combo count. While the bar is running, every landed block
  (perfect or stack) adds 1 to the count.
- After each such block: `pool += min(count, 8) × 1 × min(ceil(height / 10), 4)`
  (`combo.count_cap`, `combo.bonus_factor`, `combo.height_step`, `combo.height_mult_cap`).
- The bar drains at `1 + 3 × min(1, count / 15)` seconds per second: it gets shorter as the streak grows.
- When the bar empties, or a collapse/miss breaks it, the pool is paid into population, and the count and pool reset.
- Note: playtesting may replace this with "next N blocks score double" (an idea from the team). Treat it as a tuning
  option for T-0101, not a fixed rule.

### 3.4 Round goal
- Each block type has a `target_height` (blue 20, red 30, green 40, yellow 50 since T-0208). Reaching it completes the tower: the combo is banked, then a roof is
  added: `roof_people`, or `star_roof_people` (the trophy roof) if population ≥ `star_population`. The trophy is
  decided before the roof bonus is added (`TowerState.is_star`).
- Endless mode: `target_height = 0`, play until lives run out; crane speed keeps ramping to `speed_max`;
  its best is saved separately (`best_by_type.endless`).

### 3.5 Crane
- `crane_x = amplitude × sin(t × speed)`, speed = `min(speed + speed_per_block × height, speed_max)`.
- The block falls with constant gravity from `gap_blocks` block heights above the top.
- **[planned T-0105]** swing patterns (pauses, wind gusts at height, variable amplitude).

## 4. Progression (rules implemented in `scripts/core/progression.gd`; UI in M2)
- Lifetime population (sum of all rounds) raises the player level (`levels.json`).
- Each block type unlocks when lifetime population reaches its `unlock_population` (`block_types.json`).
- Tower select screen: choose an unlocked type; harder types are taller with bigger roof bonuses. Locked types show
  their unlock population. Results show level-ups and new unlocks.

## 5. City map (grid and placement built in T-0401; rules and districts pending T-0402/T-0403)
- A grid of plots (start 5×5). Completing a tower lets you place it on a plot.
- Placement rules give variety (draft: some types must neighbour others; downtown plots for skyscrapers).
- City population = sum of placed towers; new districts unlock at population thresholds.
- The original genre game used neighbour rules; we must design **our own** rule set in T-0402.

## 6. The unique hook (needs HR-0003)
Full design briefs with rules, effort and risks: `docs/design/hooks.md` (recommendation: special blocks, then
daily skyline). Summary of the candidates:
1. **Weather and height zones**: wind at 20+ storeys pushes the falling block; night zone dims the view; clouds hide the top.
2. **Special blocks**: heavy block (stabilises: resets wobble), glass block (double residents, collapses at 0.25), balloon block (floats slowly).
3. **Daily skyline**: one seeded challenge tower per day with a shared target, local best and a share card.
4. **Tenants with wishes**: residents ask for "a perfect streak of 5" or "a 15-storey tower", rewarding cosmetics.
5. **Cosmetic district themes**: Tokyo neon, Nordic wood, desert adobe; changes block art, music and backgrounds.

## 7. Economy and monetisation (ad flow built in T-0501 with a test backend; real SDK in T-0506)
- Soft currency: coins from towers (population → coins), spent on cosmetics and districts.
- Rewarded ad: "continue" once per round after the last life is lost (not after a completed tower), restoring
  `rewarded.continue_lives`; "double reward" on results adds the round's population again to lifetime population.
- Interstitial: only on the results screen; not before 3 rounds played, at most every 3 rounds, at least 90 s apart,
  never for players who bought remove-ads (`config/economy.json`, `core/ad_policy.gd`).
- Coins are not implemented yet; population is the only currency so far.
- IAP: remove ads (non-consumable). Optional later: cosmetic packs.

## 8. Feedback and juice (look: Modern low-poly 2.5D, docs/06_ART_AUDIO_SPEC.md §2)
- Perfect: chime pitch rising per combo step, sparkle, tiny camera kick, "PERFECT" text.
- Sloppy landing: creak, dust puff on the overhang side.
- Collapse: rumble, blocks tumble with rotation, screen shake scaled by blocks lost.
- Combo bar: ticking sound speeding up with drain rate; music layer during combo.

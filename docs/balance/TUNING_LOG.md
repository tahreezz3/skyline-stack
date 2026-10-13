# Tuning log

Every balance change: what changed, why, and the evidence. Newest first.
Simulator: `godot --headless --path game --script res://tools/sim_balance.gd -- --rounds=500 [--set=key=value ...]`.
Reports: `sim_report.md` (current config), `sim_report_before.md` (CP-000 values).

The simulator models a player aiming at the swaying top with a normal landing error (σ, in block widths,
growing with crane speed and sway). It measures what the rules *do*; it cannot judge how they *feel*.
Feel sign-off comes from the human playtest (HR-0017).

## 2026-10-13 · T-0101 · opus55-a7k2 · first data-driven pass

### Problems found in the CP-000 values (`sim_report_before.md`)
1. **No one could lose.** 100% completion at every skill level on every tower. Lives only dropped on a full miss
   (offset ≥ 1.0), which the simulated players almost never did (0.00–0.14 per round), so lives were meaningless.
2. **Combo dominated scoring.** 47–75% of points in tall towers, 98% in endless: the count grew without limit and
   multiplied by `ceil(height/10)`.
3. **Endless never ended.** Average players reached about 250 storeys (simulation cap 300).
4. **Trophies were trivial or impossible.** Blue trophy at 91% for novices; yellow trophy for experts only.

### Changes
| Key | Before | After | Why |
|---|---|---|---|
| `collapse_costs_life` (new) | (no rule) | `true` | Gives lives meaning and makes rounds losable. It also matches the project owner's original description of the game ("blocks drop → life lost"). |
| `combo.bonus_factor` | 2 | 1 | Halves the combo pool. |
| `combo.count_cap` (new) | ∞ | 8 | Long streaks still pay, but linearly after 8. |
| `combo.height_mult_cap` (new) | ∞ | 4 | Stops the height multiplier exploding in endless. |
| `blue` roof / star pop / star roof | 40 / 70 / 60 | 30 / 62 / 50 | Trophy ≈ 50–65% for "good" players |
| `red` | 80 / 250 / 120 | 60 / 150 / 100 | same |
| `green` | 130 / 550 / 180 | 100 / 280 / 160 | same |
| `yellow` | 130 / 1000 / 250 | 140 / 410 / 220 | same; roof now grows with tower size |

Also fixed: the trophy shown on the results screen was computed from population *after* the roof bonus, which
disagreed with the rules (the trophy is decided before the roof). `TowerState.is_star` is now the single source of
truth (test `test_trophy_decided_before_roof`).

### Result (`sim_report.md`, 500 rounds per cell)
| Tower | good (σ .07) complete / trophy | average (σ .11) | casual (σ .16) | combo share (avg player) |
|---|---|---|---|---|
| blue | 100% / 54% | 100% / 12% | 95% / 3% | 21% |
| red | 100% / 60% | 100% / 14% | 74% / 1% | 31% |
| green | 100% / 55% | 97% / 6% | 35% / 0% | 38% |
| yellow | 100% / 66% | 82% / 9% | 6% / 0% | 44% |
| endless | best 2360 pop, ~180 storeys | ~52 storeys | ~26 storeys | 65% |

Each tower type is now a clear step up. Rounds last 23–78 s, which fits the 1–3 minute session target.
Unlock pacing: about 3 blue rounds to unlock red, about 3 red rounds to green, about 5 green rounds to yellow.

### Open questions for the playtest (HR-0017)
- Does losing a life on a collapse feel fair, or too punishing? Alternative: lose a life only when 3+ blocks fall
  (would need a new `collapse_life_min_blocks` key).
- The owner's idea "the next 5 blocks after a perfect score double" is not implemented. The capped pool behaves
  similarly (bonus builds over the first 8 combo blocks). Compare both in the playtest if the combo doesn't feel
  exciting enough.
- Endless is still combo-heavy for strong players (76%). Fine for a score-chase mode, but watch it.
- The perfect window (0.06) was not changed: the simulation can't judge whether it *feels* generous.

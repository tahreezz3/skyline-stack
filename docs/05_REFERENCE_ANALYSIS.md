# 05 · Reference analysis (read-only knowledge)

Before this project started, an existing game in the genre ("City Bloxx" 0.7.8, package
`com.zeek.citybloxx`, Unity IL2CPP) was statically analysed to understand how its mechanics work.
The full extraction lives **outside this repo** at `../extracted/` (see `../extracted/README.md` and
`../extracted/MECHANICS.md`).

**Use it only to understand behaviour. Never copy any file, text, image, sound, level or code from it.**
See `07_LEGAL_CLEANROOM.md`. Game mechanics and general numbers are not protected, but expression is,
and we want our own identity anyway.

## What we learned and adopted (re-implemented from scratch)
| Finding in the reference | Where we use the idea |
|---|---|
| Perfect snap window 0.06, collapse past 0.35, residents 4→1 by offset | `tower_rules.json`, GDD §3.1 |
| Wobble = 1.4 × sum of last 5 signed offsets | GDD §3.2 |
| Collapse drops top blocks 0.2 s apart until the top has offset < 0.2 | GDD §3.1 |
| Lives = 3, lost when a block falls off screen | GDD §3.1 |
| Combo: 8 s bar, refilled by perfects, drain 1 + 3·min(1, n/15), pool n·2·ceil(h/10) | GDD §3.3 |
| 4 tower types with target heights 10/20/30/40 and roof bonuses | `block_types.json` (retune) |
| Population-based level unlocks | `levels.json` (retune) |
| City map 5×5 with neighbour placement rules | GDD §5, our own rules in T-0402 |

## What we deliberately do differently
- Engine (Godot instead of Unity) and our own architecture.
- No energy system in the core mode.
- Our own hook (GDD §6), art direction, audio, names and text.
- Scope: one polished mode for 1.0 instead of four loosely connected ones.

## Verified details vs guesses
Values above were read from the reference's disassembly and config tables, except:
- the role of one flag in its landing check (not resolved);
- whether the reference ever resets its combo pool (we always reset on bank: our design choice).

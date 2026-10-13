# 07 · Legal and clean-room rules

This is not legal advice. Before commercial release, have a lawyer review the name, store listing and overall
similarity to games in the genre.

## The rule
We may study how other games **behave**. We may not copy what they **are**.

| Allowed | Not allowed |
|---|---|
| Implementing similar mechanics from a written description | Copying code, decompiled or not, or translating it line by line |
| Using numbers as starting points for tuning, then retuning | Shipping their levels, tables or data files as-is |
| Describing a feature ("tower sways when stacked badly") | Using their art, audio, fonts, animations, UI layouts, text or names |
| Being in the same genre | A name, icon or store page that could be confused with theirs |

## Practical rules for agents
1. Never open `../extracted/unity_assets`, `../extracted/base` or `../extracted/arm64` to take files.
   You may read `../extracted/MECHANICS.md` and the config CSVs to understand behaviour.
2. Write code from the GDD, not from disassembly.
3. `tools/cleanroom_check.py` (run by `tools/check.sh`) fails if any file in `game/` or `assets_inbox/` is
   byte-identical to a file in `../extracted/`. It cannot catch redrawn or re-recorded copies; humans must not trace or sample.
4. Every shipped asset has a row in `assets_inbox/LICENSES.md`.
5. Third-party code (plugins, addons) must have a licence compatible with commercial release; record it in `docs/THIRD_PARTY.md` when added.

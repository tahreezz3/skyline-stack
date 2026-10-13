## Autoload "GameEvents": global signal bus. Systems (audio, analytics, UI,
## achievements) listen here instead of referencing each other directly.
## Add new signals here and list them in docs/02_ARCHITECTURE.md.
extends Node

## A falling block was resolved. `ev` is the dictionary returned by TowerState.land().
signal block_resolved(ev: Dictionary)
## The combo bar ran out or was broken and its pool was paid out.
signal combo_banked(amount: int)
## A round ended. summary = {complete, star, population, height, max_combo, block_type}
signal round_ended(summary: Dictionary)

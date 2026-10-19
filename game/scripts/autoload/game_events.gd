## Autoload "GameEvents": global signal bus. Systems (audio, analytics, UI,
## achievements) listen here instead of referencing each other directly.
## Add new signals here and list them in docs/02_ARCHITECTURE.md.
extends Node

## A round began (tower_game _ready).
signal round_started(block_type: String, endless: bool)
## A block was released from the crane.
signal block_released
## A falling block was resolved. `ev` is the dictionary returned by TowerState.land().
signal block_resolved(ev: Dictionary)
## A collapsed block finished toppling (one per block, 0.2 s apart).
signal block_toppled
## Combo count changed (0 = combo over). drain_rate = bar seconds lost per second.
signal combo_progress(count: int, drain_rate: float)
## The combo bar ran out or was broken and its pool was paid out.
signal combo_banked(amount: int)
## A round ended. summary = {complete, star, population, height, max_combo, block_type, endless}
signal round_ended(summary: Dictionary)
## Player level rose (SaveData.record_round).
signal level_up(from_level: int, to_level: int)
## A block type became available (SaveData.record_round).
signal block_type_unlocked(id: String)
## A setting changed (SaveData.set_setting).
signal setting_changed(key: String, value: Variant)
## A tower was placed on the city map (city_map screen).
signal city_tower_placed(tower: Dictionary, city_population: int)
## An ad finished (Ads autoload). format = rewarded | interstitial.
signal ad_finished(format: String, placement: String, completed: bool)
## SceneRouter is about to leave the current screen for `to` (fires before the fade).
signal screen_changing(to: String)
## Any UI button pressed (for the click sound).
signal ui_pressed

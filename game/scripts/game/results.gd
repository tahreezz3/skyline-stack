## Results screen. Params from tower_game: {summary, record} where summary is the
## round_ended payload and record is SaveData.record_round()'s result.
extends Control

const UI := preload("res://scripts/game/ui_kit.gd")


func _ready() -> void:
	var summary: Dictionary = SceneRouter.params.get("summary", {})
	var record: Dictionary = SceneRouter.params.get("record", {})
	if SceneRouter.autoplay:
		print("AUTOPLAY_RESULTS ", JSON.stringify({"summary": summary, "record": record}))
		get_tree().quit(0)
		return

	AudioDirector.play_music("menu")
	var col := UI.screen(self, 16)
	var title: String = tr("RES_COMPLETE") if summary.get("complete", false) else tr("RES_GAME_OVER")
	if summary.get("endless", false):
		title = tr("RES_ENDLESS")
	col.add_child(UI.label(title, 56, UI.ACCENT))
	if summary.get("star", false):
		col.add_child(UI.label(tr("RES_TROPHY"), 36, UI.ACCENT))
	col.add_child(UI.spacer(16))

	col.add_child(UI.label(tr("RES_POPULATION") % summary.get("population", 0) + (tr("NEW_BEST") if record.get("new_best_population", false) else ""), 40))
	col.add_child(UI.label(tr("RES_HEIGHT") % summary.get("height", 0) + (tr("NEW_BEST") if record.get("new_best_height", false) else ""), 32))
	col.add_child(UI.label(tr("RES_BEST_COMBO") % summary.get("max_combo", 0), 28, UI.MUTED))

	if record.get("level_after", 0) > record.get("level_before", 0):
		col.add_child(UI.label(tr("RES_LEVEL_UP") % record["level_after"], 36, UI.ACCENT))
	for id in record.get("unlocked", []):
		col.add_child(UI.label(tr("RES_UNLOCKED") % UI.type_name(GameConfig.block_type(id)), 30, UI.ACCENT))

	col.add_child(UI.spacer(24))
	var pop := int(summary.get("population", 0))
	var bonus := pop * (int(GameConfig.table("economy")["rewarded"]["double_reward_multiplier"]) - 1)
	if bonus > 0:
		var bonus_btn := UI.button(tr("BTN_DOUBLE_REWARD") % bonus, func() -> void: pass, 26)
		bonus_btn.pressed.connect(func() -> void:
			bonus_btn.disabled = true
			if await Ads.show_rewarded("double_reward"):
				var progress: Dictionary = SaveData.add_bonus_population(bonus)
				bonus_btn.text = tr("RES_BONUS") % bonus
				for id in progress["unlocked"]:
					col.add_child(UI.label(tr("RES_UNLOCKED") % UI.type_name(GameConfig.block_type(id)), 30, UI.ACCENT))
			else:
				bonus_btn.disabled = false)
		col.add_child(bonus_btn)
	if record.get("city_tower_added", false):
		col.add_child(UI.button(tr("RES_PLACE_CITY"), func() -> void: SceneRouter.go("city")))
	var again := {"block_type": summary.get("block_type", "blue"), "endless": summary.get("endless", false)}
	col.add_child(UI.button(tr("BTN_PLAY_AGAIN"), func() -> void: SceneRouter.go("game", again)))
	col.add_child(UI.button(tr("BTN_CHOOSE_TOWER"), func() -> void: SceneRouter.go("select")))
	col.add_child(UI.button(tr("BTN_MENU"), on_back))


	# Interstitials only ever appear here, between rounds (docs/01_GDD.md §7).
	Ads.on_round_finished.call_deferred()


func on_back() -> void:
	SceneRouter.go("menu")

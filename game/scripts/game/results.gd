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
	# Rewarded "double population" arrives with ads in T-0501.
	col.add_child(UI.button(tr("BTN_DOUBLE_AD"), func() -> void: pass, 26, false))
	var again := {"block_type": summary.get("block_type", "blue"), "endless": summary.get("endless", false)}
	col.add_child(UI.button(tr("BTN_PLAY_AGAIN"), func() -> void: SceneRouter.go("game", again)))
	col.add_child(UI.button(tr("BTN_CHOOSE_TOWER"), func() -> void: SceneRouter.go("select")))
	col.add_child(UI.button(tr("BTN_MENU"), on_back))


func on_back() -> void:
	SceneRouter.go("menu")

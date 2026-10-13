## Main menu: level progress, lifetime stats, play buttons.
extends Control

const UI := preload("res://scripts/game/ui_kit.gd")
const Progression := preload("res://scripts/core/progression.gd")


func _ready() -> void:
	if SceneRouter.autoplay:
		# Smoke test: go straight into a round with the default tower.
		SceneRouter.go.call_deferred("game", {"block_type": "blue"})
		return
	AudioDirector.play_music("menu")
	var col := UI.screen(self)
	col.add_child(UI.label(tr("TITLE"), 64, UI.ACCENT))
	col.add_child(UI.label(tr("SUBTITLE_WORKING"), 22, UI.MUTED))
	col.add_child(UI.spacer(40))

	var pop := SaveData.lifetime_population()
	var info := Progression.level_info(pop, GameConfig.table("levels")["levels"])
	col.add_child(UI.label(tr("LEVEL_N") % info["level"], 40))
	col.add_child(UI.progress(info["progress"]))
	var next_text: String = tr("MAX_LEVEL") if info["next"] < 0 else tr("NEXT_LEVEL") % [pop, info["next"]]
	col.add_child(UI.label(next_text, 24, UI.MUTED))
	col.add_child(UI.spacer(40))

	col.add_child(UI.button(tr("BTN_PLAY"), func() -> void: SceneRouter.go("select")))
	col.add_child(UI.button(tr("BTN_ENDLESS"), func() -> void: SceneRouter.go("game", {"block_type": "blue", "endless": true})))
	var to_place: int = SaveData.data["city"]["unplaced"].size()
	var city_text: String = tr("BTN_CITY") % to_place if to_place > 0 else tr("BTN_CITY_PLAIN")
	col.add_child(UI.button(city_text, func() -> void: SceneRouter.go("city")))
	col.add_child(UI.button(tr("BTN_SETTINGS"), func() -> void: SceneRouter.go("settings"), 30))
	col.add_child(UI.spacer(40))

	var s := SaveData.stats()
	col.add_child(UI.label(tr("MENU_STATS") % [
		s["best_height"], s["best_population"], s["rounds_played"], s["towers_completed"], s["trophy_roofs"]], 22, UI.MUTED))


func on_back() -> void:
	get_tree().quit()

## Main menu: level progress, lifetime stats, play buttons.
extends Control

const UI := preload("res://scripts/game/ui_kit.gd")
const Progression := preload("res://scripts/core/progression.gd")


func _ready() -> void:
	if SceneRouter.autoplay:
		# Smoke test: go straight into a round with the default tower.
		SceneRouter.go.call_deferred("game", {"block_type": "blue"})
		return
	var col := UI.screen(self)
	col.add_child(UI.label("SKYLINE STACK", 64, UI.ACCENT))
	col.add_child(UI.label("working title", 22, UI.MUTED))
	col.add_child(UI.spacer(40))

	var pop := SaveData.lifetime_population()
	var info := Progression.level_info(pop, GameConfig.table("levels")["levels"])
	col.add_child(UI.label("Level %d" % info["level"], 40))
	col.add_child(UI.progress(info["progress"]))
	var next_text := "Max level" if info["next"] < 0 else "%d / %d population to next level" % [pop, info["next"]]
	col.add_child(UI.label(next_text, 24, UI.MUTED))
	col.add_child(UI.spacer(40))

	col.add_child(UI.button("Play", func() -> void: SceneRouter.go("select")))
	col.add_child(UI.button("Endless", func() -> void: SceneRouter.go("game", {"block_type": "blue", "endless": true})))
	col.add_child(UI.spacer(40))

	var s := SaveData.stats()
	col.add_child(UI.label("Best tower %d storeys · Best round %d people\nRounds %d · Towers completed %d · Trophy roofs %d" % [
		s["best_height"], s["best_population"], s["rounds_played"], s["towers_completed"], s["trophy_roofs"]], 22, UI.MUTED))


func on_back() -> void:
	get_tree().quit()

## Tower select: one button per block type; locked types show their unlock
## requirement and cannot start. Data: config/block_types.json, unlocks via
## scripts/core/progression.gd.
extends Control

const UI := preload("res://scripts/game/ui_kit.gd")
const Progression := preload("res://scripts/core/progression.gd")


func _ready() -> void:
	AudioDirector.play_music("menu")
	var col := UI.screen(self, 18)
	col.add_child(UI.label("Choose a tower", 48))
	var pop := SaveData.lifetime_population()
	col.add_child(UI.label("Lifetime population %d" % pop, 24, UI.MUTED))
	col.add_child(UI.spacer(16))

	for t in GameConfig.table("block_types")["types"]:
		var unlocked := Progression.is_unlocked(t, pop)
		var best: Dictionary = SaveData.data["best_by_type"].get(t["id"], {})
		var text := "%s\n%d storeys · roof +%d" % [UI.type_name(t), t["target_height"], t["roof_people"]]
		if not unlocked:
			text = "%s  🔒\nUnlocks at %d population" % [UI.type_name(t), t["unlock_population"]]
		elif not best.is_empty():
			text += " · best %d%s" % [best["population"], " 🏆" if best.get("star", false) else ""]
		var id: String = t["id"]
		var b := UI.button(text, func() -> void: SceneRouter.go("game", {"block_type": id}), 28, unlocked)
		b.custom_minimum_size = Vector2(0, 120)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(t["colour"]) if unlocked else UI.LOCKED
		sb.set_corner_radius_all(14)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("disabled", sb)
		var hover := sb.duplicate()
		hover.bg_color = sb.bg_color.lightened(0.1)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", hover)
		col.add_child(b)

	col.add_child(UI.spacer(16))
	col.add_child(UI.button("Back", on_back))


func on_back() -> void:
	SceneRouter.go("menu")

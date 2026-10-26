## Tower select: one button per block type; locked types show their unlock
## requirement and cannot start. Data: config/block_types.json, unlocks via
## scripts/core/progression.gd.
extends Control

const UI := preload("res://scripts/game/ui_kit.gd")
const ThemeCatalog := preload("res://scripts/game/theme_catalog.gd")
const Progression := preload("res://scripts/core/progression.gd")


func _ready() -> void:
	AudioDirector.play_music("menu")
	var col := UI.screen(self, 18)
	col.add_child(UI.label(tr("SELECT_TITLE"), 48))
	var pop := SaveData.lifetime_population()
	col.add_child(UI.label(tr("LIFETIME_POP") % pop, 24, UI.MUTED))
	col.add_child(UI.spacer(16))
	col.add_child(UI.label(tr("THEME_SELECT"), 24, UI.MUTED))
	var choices := OptionButton.new()
	choices.name = "ThemeSelector"
	choices.custom_minimum_size = Vector2(0, 64)
	choices.add_theme_font_size_override("font_size", 26)
	choices.get_popup().add_theme_font_size_override("font_size", 26)
	choices.get_popup().add_theme_constant_override("v_separation", 16)
	var config: Dictionary = GameConfig.table("themes")
	var selected := ThemeCatalog.resolve(config, SceneRouter.selected_theme)
	SceneRouter.selected_theme = selected["id"]
	for theme in config["themes"]:
		choices.add_item(tr(theme["name_key"]))
		choices.set_item_metadata(choices.item_count - 1, theme["id"])
		if theme["id"] == selected["id"]:
			choices.select(choices.item_count - 1)
	col.add_child(choices)
	var description := UI.label(tr(selected["description_key"]), 21, UI.MUTED)
	description.custom_minimum_size.y = 54
	col.add_child(description)
	choices.item_selected.connect(func(index: int) -> void:
		SceneRouter.selected_theme = choices.get_item_metadata(index)
		var theme := ThemeCatalog.resolve(config, SceneRouter.selected_theme)
		description.text = tr(theme["description_key"]))

	for t in GameConfig.table("block_types")["types"]:
		var unlocked := Progression.is_unlocked(t, pop)
		var best: Dictionary = SaveData.data["best_by_type"].get(t["id"], {})
		var text := tr("TOWER_INFO") % [UI.type_name(t), t["target_height"], t["roof_people"]]
		if not unlocked:
			text = tr("TOWER_LOCKED") % [UI.type_name(t), t["unlock_population"]]
		elif not best.is_empty():
			text += (tr("TOWER_BEST") % best["population"]) + (" 🏆" if best.get("star", false) else "")
		var id: String = t["id"]
		var b := UI.button(text, func() -> void: SceneRouter.go("game", {"block_type": id}), 28, unlocked)
		b.custom_minimum_size = Vector2(0, 100)
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
	col.add_child(UI.button(tr("BTN_BACK"), on_back))


func on_back() -> void:
	SceneRouter.go("menu")

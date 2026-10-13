## Settings: music and sound volume, reduced motion (disables shake and camera kick).
## Values live in SaveData.data.settings (docs/03_DATA_SPEC.md "Save file").
extends Control

const UI := preload("res://scripts/game/ui_kit.gd")


func _ready() -> void:
	var col := UI.screen(self, 20)
	col.add_child(UI.label("Settings", 56, UI.ACCENT))
	col.add_child(UI.spacer(24))
	_slider(col, "Music volume", "music_volume")
	_slider(col, "Sound volume", "sfx_volume")
	var motion := CheckButton.new()
	motion.text = "Reduced motion (no screen shake)"
	motion.add_theme_font_size_override("font_size", 30)
	motion.button_pressed = bool(SaveData.get_setting("reduced_motion"))
	motion.focus_mode = Control.FOCUS_NONE
	motion.toggled.connect(func(on: bool) -> void: SaveData.set_setting("reduced_motion", on))
	col.add_child(motion)
	col.add_child(UI.spacer(40))
	col.add_child(UI.button("Back", on_back))


func _slider(col: VBoxContainer, title: String, key: String) -> void:
	col.add_child(UI.label(title, 30, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(SaveData.get_setting(key))
	s.custom_minimum_size = Vector2(0, 56)
	s.focus_mode = Control.FOCUS_NONE
	s.drag_ended.connect(func(_changed: bool) -> void:
		SaveData.set_setting(key, s.value)
		GameEvents.ui_pressed.emit())
	col.add_child(s)


func on_back() -> void:
	SceneRouter.go("menu")

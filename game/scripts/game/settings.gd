## Settings: music and sound volume, reduced motion (disables shake and camera kick).
## Values live in SaveData.data.settings (docs/03_DATA_SPEC.md "Save file").
extends Control

const UI := preload("res://scripts/game/ui_kit.gd")


func _ready() -> void:
	var col := UI.screen(self, 20)
	col.add_child(UI.label(tr("SETTINGS_TITLE"), 56, UI.ACCENT))
	col.add_child(UI.spacer(24))
	_slider(col, tr("SET_MUSIC"), "music_volume")
	_slider(col, tr("SET_SFX"), "sfx_volume")
	var motion := CheckButton.new()
	motion.text = tr("SET_REDUCED_MOTION")
	motion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # long translations must not widen the screen
	motion.custom_minimum_size = Vector2(1, 0)
	motion.add_theme_font_size_override("font_size", 30)
	motion.button_pressed = bool(SaveData.get_setting("reduced_motion"))
	motion.focus_mode = Control.FOCUS_NONE
	motion.toggled.connect(func(on: bool) -> void: SaveData.set_setting("reduced_motion", on))
	col.add_child(motion)
	var stats := CheckButton.new()
	stats.text = tr("SET_ANALYTICS")
	stats.add_theme_font_size_override("font_size", 30)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.custom_minimum_size = Vector2(1, 0)
	stats.focus_mode = Control.FOCUS_NONE
	stats.button_pressed = String(SaveData.get_setting("analytics_consent")) == "granted"
	stats.toggled.connect(func(on: bool) -> void: SaveData.set_setting("analytics_consent", "granted" if on else "denied"))
	col.add_child(stats)
	col.add_child(UI.label(tr("SET_LANGUAGE"), 30, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	var lang := OptionButton.new()
	lang.add_theme_font_size_override("font_size", 30)
	lang.custom_minimum_size = Vector2(0, 80)
	lang.focus_mode = Control.FOCUS_NONE
	var names := {"": tr("LANG_AUTO"), "en": "English", "es": "Español", "de": "Deutsch"}
	for code in SaveData.LANGUAGES:
		lang.add_item(names[code])
	lang.selected = SaveData.LANGUAGES.find(String(SaveData.get_setting("language")))
	lang.item_selected.connect(func(i: int) -> void:
		SaveData.set_setting("language", SaveData.LANGUAGES[i])
		SceneRouter.go("settings"))   # rebuild texts in the new language
	col.add_child(lang)
	col.add_child(UI.spacer(40))
	col.add_child(UI.button(tr("BTN_BACK"), on_back))


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

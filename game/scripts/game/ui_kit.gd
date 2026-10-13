## Small helpers for building placeholder UI in code. Styling is temporary until
## the UI theme lands (T-0303); keep all visual constants here so they can be
## swapped for a Theme resource in one place.
extends RefCounted

const BG := Color("#1c2333")
const PANEL := Color("#283246")
const TEXT := Color("#f0f3fa")
const MUTED := Color("#9aa4b8")
const ACCENT := Color("#f2b632")
const LOCKED := Color("#4a5163")


## Full-screen root with a background and a centred vertical column.
static func screen(owner: Control, gap := 24) -> VBoxContainer:
	owner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	owner.add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 80)
	owner.add_child(margin)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", gap)
	margin.add_child(col)
	return col


static func label(text: String, size := 32, colour := TEXT, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	return l


static func button(text: String, on_press: Callable, size := 36, enabled := true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 96)
	b.add_theme_font_size_override("font_size", size)
	b.disabled = not enabled
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void:
		GameEvents.ui_pressed.emit()
		on_press.call())
	return b


static func progress(value: float) -> ProgressBar:
	var p := ProgressBar.new()
	p.min_value = 0.0
	p.max_value = 1.0
	p.step = 0.001
	p.value = value
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, 24)
	return p


static func spacer(h := 24) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## Display name for a block type until localisation exists (T-0304).
static func type_name(t: Dictionary) -> String:
	var key := String(t.get("name_key", ""))
	var translated: String = String(TranslationServer.translate(key)) if key != "" else ""
	if translated != "" and translated != key:
		return translated
	return String(t["id"]).capitalize() + " Tower"

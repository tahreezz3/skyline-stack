## Compact HUD shared by every theme. Draws original pixel icons locally.
## The segmented blue meter measures completed floors, not physical block width.
extends Control

var game: Node2D
var config: Dictionary
var population: Label
var badge: Label
var combo: ProgressBar
var pause_button: Button


func setup(p_game: Node2D, p_config: Dictionary) -> void:
	game = p_game
	config = p_config
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := float(config["margin"])
	population = _label(int(config["population_font_size"]))
	population.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	population.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	population.offset_left = -margin - 260
	population.offset_right = -margin
	population.offset_top = -float(config["bottom_clearance"]) - 4
	population.offset_bottom = -margin
	population.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge = _label(24)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.tooltip_text = tr("HUD_METER_HELP") % int(config["endless_page_floors"])
	combo = ProgressBar.new()
	combo.min_value = 0.0
	combo.max_value = 1.0
	combo.step = 0.001
	combo.show_percentage = false
	combo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	combo.offset_left = -margin - float(config["combo_width"])
	combo.offset_right = -margin
	combo.offset_top = -margin - float(config["combo_height"])
	combo.offset_bottom = -margin
	add_child(combo)
	pause_button = Button.new()
	pause_button.text = tr("HUD_PAUSE")
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -margin - float(config["pause_size"])
	pause_button.offset_right = -margin
	pause_button.offset_top = margin
	pause_button.offset_bottom = margin + float(config["pause_size"])
	pause_button.add_theme_font_size_override("font_size", 26)
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.pressed.connect(game.pause_game)
	pause_button.tooltip_text = tr("PAUSED")
	add_child(pause_button)
	resized.connect(queue_redraw)
	refresh()


func _label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#fff7dd"))
	label.add_theme_color_override("font_outline_color", Color("#172d46"))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label


func meter_rect() -> Rect2:
	return Rect2(float(config["margin"]), size.y - float(config["bottom_clearance"]) - float(config["meter_height"]), float(config["meter_width"]), float(config["meter_height"]))


func refresh() -> void:
	population.text = ("%0" + str(int(config["counter_digits"])) + "d") % int(game.state.population)
	population.tooltip_text = tr("HUD_POPULATION") % game.state.population
	badge.text = str(game.state.height())
	var meter := meter_rect()
	badge.position = meter.position - Vector2(4, float(config["badge_height"]) + 8)
	badge.size = Vector2(meter.size.x + 8, float(config["badge_height"]))
	combo.value = game.state.combo_ratio()
	combo.visible = game.state.combo_time > 0.0
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(game):
		return
	var margin := float(config["margin"])
	var pixel := float(config["heart_pixel"])
	# Rows are deliberately square pixels; no platform-dependent heart glyphs.
	var heart := ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
	for i in range(int(game.rules["lives"])):
		var at := Vector2(margin + i * float(config["heart_spacing"]), margin)
		var fill := Color("#fa5557") if i < game.state.lives else Color("#66576c")
		for y in range(heart.size()):
			for x in range(heart[y].length()):
				if heart[y][x] == "1":
					draw_rect(Rect2(at + Vector2(x - 0.4, y - 0.4) * pixel, Vector2.ONE * pixel * 1.8), Color("#302a42"))
		for y in range(heart.size()):
			for x in range(heart[y].length()):
				if heart[y][x] == "1":
					draw_rect(Rect2(at + Vector2(x, y) * pixel, Vector2.ONE * pixel), fill)
		draw_rect(Rect2(at + Vector2(pixel, pixel), Vector2(pixel * 2, pixel)), fill.lightened(0.3))
	var meter := meter_rect()
	var badge_rect := Rect2(badge.position, badge.size)
	_panel(badge_rect)
	_panel(meter)
	var goal: int = game.state.target_height()
	var page := int(config["endless_page_floors"])
	var ratio := clampf(float(game.state.height()) / maxi(1, goal), 0.0, 1.0) if goal > 0 else float(posmod(game.state.height(), page)) / page
	var segments := int(config["meter_segments"])
	var inner := meter.grow(-6)
	var segment_h := inner.size.y / segments
	for i in range(segments):
		var rect := Rect2(inner.position + Vector2(0, inner.size.y - (i + 1) * segment_h), Vector2(inner.size.x, segment_h - 2))
		draw_rect(rect, Color("#38c5ef") if float(i) / segments < ratio else Color("#205179"))
	# Small gold person sits immediately before the right-aligned population digits.
	var person := Vector2(size.x - margin - population.get_minimum_size().x - 32, size.y - float(config["bottom_clearance"]) + 6)
	var gold := Color("#ffd36b")
	draw_circle(person + Vector2(11, 0), 7, Color("#253245"))
	draw_circle(person + Vector2(11, 0), 5, gold)
	draw_rect(Rect2(person + Vector2(4, 8), Vector2(14, 13)), Color("#253245"))
	draw_rect(Rect2(person + Vector2(5, 8), Vector2(12, 10)), gold)
	for x in [5, 13]:
		draw_rect(Rect2(person + Vector2(x, 17), Vector2(4, 12)), gold)


func _panel(rect: Rect2) -> void:
	draw_rect(rect.grow(3), Color("#172d46"))
	draw_rect(rect, Color("#eac564"))
	draw_rect(rect.grow(-3), Color("#166799"))

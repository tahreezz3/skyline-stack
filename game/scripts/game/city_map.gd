## City map screen (T-0401): a top-down grid of plots. Pick a completed tower
## from the tray at the bottom, then tap a free plot to place it. Rules live in
## scripts/core/city_state.gd; the city is stored in SaveData.data.city.
## Placeholder visuals (coloured squares) until city art is requested.
extends Control

const UI := preload("res://scripts/game/ui_kit.gd")
const CityState := preload("res://scripts/core/city_state.gd")

const GRID_SIZE := 600.0
const PLOT_GAP := 8.0

var city
var selected := -1
var grid: Control
var pop_label: Label
var hint_label: Label
var tray: HFlowContainer


func _ready() -> void:
	AudioDirector.play_music("city")
	city = CityState.new(GameConfig.table("city_map"), SaveData.data["city"])
	var col := UI.screen(self, 16)
	col.add_child(UI.label(tr("CITY_TITLE"), 52, UI.ACCENT))
	pop_label = UI.label("", 30)
	col.add_child(pop_label)

	grid = Control.new()
	grid.custom_minimum_size = Vector2(GRID_SIZE, GRID_SIZE)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.draw.connect(_draw_grid)
	grid.gui_input.connect(_on_grid_input)
	col.add_child(grid)

	hint_label = UI.label("", 26, UI.MUTED)
	col.add_child(hint_label)
	tray = HFlowContainer.new()
	tray.add_theme_constant_override("h_separation", 12)
	tray.add_theme_constant_override("v_separation", 12)
	col.add_child(tray)
	col.add_child(UI.button(tr("BTN_MENU"), on_back))
	_refresh()


func _refresh() -> void:
	pop_label.text = tr("CITY_POP") % city.population()
	var unplaced: Array = SaveData.data["city"]["unplaced"]
	if selected >= unplaced.size():
		selected = -1
	if unplaced.is_empty():
		hint_label.text = tr("CITY_NONE")
	else:
		hint_label.text = tr("CITY_TAP_PLOT") if selected >= 0 else tr("CITY_PICK")
	for c in tray.get_children():
		c.queue_free()
	for i in range(unplaced.size()):
		var t: Dictionary = unplaced[i]
		var type_cfg := GameConfig.block_type(t["type"])
		var label: String = tr("CITY_TOWER_BTN") % [UI.type_name(type_cfg), t["population"]]
		if t.get("star", false):
			label += " 🏆"
		var idx := i
		var b := UI.button(label, func() -> void:
			selected = -1 if selected == idx else idx
			_refresh(), 24)
		b.custom_minimum_size = Vector2(190, 100)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(type_cfg["colour"])
		sb.set_corner_radius_all(12)
		if i == selected:
			sb.set_border_width_all(6)
			sb.border_color = UI.ACCENT
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		tray.add_child(b)
	grid.queue_redraw()


func _cell_size() -> float:
	return (GRID_SIZE - PLOT_GAP * (city.width() + 1)) / city.width()


func _cell_rect(x: int, y: int) -> Rect2:
	var s := _cell_size()
	return Rect2(PLOT_GAP + x * (s + PLOT_GAP), PLOT_GAP + y * (s + PLOT_GAP), s, s)


func _draw_grid() -> void:
	grid.draw_rect(Rect2(Vector2.ZERO, grid.size), Color("#2f3a2f"))
	var font := ThemeDB.fallback_font
	for y in range(city.height()):
		for x in range(city.width()):
			var r := _cell_rect(x, y)
			if city.is_disabled(x, y):
				grid.draw_rect(r, Color("#3b4a5a"))     # water / blocked placeholder
				continue
			var t: Dictionary = city.tower_at(x, y)
			if t.is_empty():
				var free_colour := Color("#4f6b4a") if selected < 0 else Color("#6f9a62")
				grid.draw_rect(r, free_colour)
				continue
			var colour := Color(GameConfig.block_type(t["type"])["colour"])
			grid.draw_rect(r, colour)
			grid.draw_rect(r, colour.darkened(0.4), false, 4.0)
			grid.draw_string(font, r.position + Vector2(0, r.size.y * 0.62), str(t["height"]),
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 34, Color.WHITE)
			if t.get("star", false):
				grid.draw_string(font, r.position + Vector2(0, 28), "🏆", HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 6, 22)


func _on_grid_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	for y in range(city.height()):
		for x in range(city.width()):
			if not _cell_rect(x, y).has_point(event.position):
				continue
			var t: Dictionary = city.tower_at(x, y)
			if selected >= 0:
				var reason: String = city.place(selected, x, y)
				if reason == CityState.OK:
					selected = -1
					SaveData.write_save()
					GameEvents.ui_pressed.emit()
					_refresh()
					hint_label.text = tr("CITY_PLACED")
				elif reason == CityState.ERR_OCCUPIED:
					hint_label.text = tr("CITY_OCCUPIED")
			elif not t.is_empty():
				hint_label.text = tr("CITY_TOWER_INFO") % [UI.type_name(GameConfig.block_type(t["type"])), t["height"], t["population"]]
			return


func on_back() -> void:
	SceneRouter.go("menu")

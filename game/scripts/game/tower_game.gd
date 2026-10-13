## Tower round scene: crane, falling block, rendering, HUD, input.
## All rules are delegated to TowerState (scripts/core/tower_state.gd); this
## script only moves things on screen and turns state events into feedback.
##
## Placeholder visuals: blocks are coloured rectangles drawn in _draw() until
## the art in HUMAN_NEEDED.md (HR-0004..HR-0007) is delivered.
##
## Headless autoplay for smoke tests:
##   godot --headless --path game -- --autoplay --seconds=20
extends Node2D

const TowerState := preload("res://scripts/core/tower_state.gd")

const UNIT := 160.0                     # screen pixels per world unit (one block width)
const SCREEN := Vector2(720, 1280)
const GROUND_PX := 1120.0               # screen y of world y=0 when the camera is at the bottom
const VIEW_BELOW_TOP := 3.0             # world units kept visible under the stack top
const FOUNDATION_COLOUR := Color("#5a5a66")

var rules: Dictionary
var block_type: Dictionary
var state

var t := 0.0
var view_y := 0.0
var crane_x := 0.0
var sway_top := 0.0
var falling: Dictionary = {}            # {x, y, vy, missed, miss_x}
var debris: Array[Dictionary] = []      # toppled blocks: {x, y, vx, vy, rot, vrot, delay}
var popups: Array[Dictionary] = []      # floating text: {text, x, y, age, colour}
var round_finished := false

var autoplay := false
var autoplay_seconds := 0.0

var hud_population: Label
var hud_lives: Label
var hud_height: Label
var hud_combo: ProgressBar
var hud_message: Label


func _ready() -> void:
	rules = GameConfig.table("tower_rules")
	block_type = GameConfig.block_type("blue")   # block selection arrives in M2 (T-0202)
	state = TowerState.new(rules, {
		"target_height": block_type["target_height"],
		"roof_people": block_type["roof_people"],
		"star_population": block_type["star_population"],
		"star_roof_people": block_type["star_roof_people"],
	})
	_parse_args()
	_build_hud()
	_refresh_hud()


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			autoplay = true
			Engine.time_scale = 4.0
		elif arg.begins_with("--seconds="):
			autoplay_seconds = float(arg.get_slice("=", 1))


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE)
	if pressed:
		_on_tap()


func _on_tap() -> void:
	if round_finished:
		get_tree().reload_current_scene()
		return
	if falling.is_empty() and not state.is_over:
		falling = {"x": crane_x, "y": _crane_y(), "vy": 0.0, "missed": false, "miss_x": 0.0}


func _process(delta: float) -> void:
	t += delta
	var crane: Dictionary = rules["crane"]
	var speed := minf(float(crane["speed"]) + float(crane["speed_per_block"]) * state.height(), float(crane["speed_max"]))
	crane_x = float(crane["amplitude"]) * sin(t * speed)

	var sway: Dictionary = rules["sway"]
	var amp := clampf(state.wobble() * float(sway["scale"]), -float(sway["max"]), float(sway["max"]))
	sway_top = amp * sin(t * float(sway["speed"]))

	_update_falling(delta)
	_update_debris(delta)
	_update_popups(delta)

	var banked: int = state.tick(delta)
	if banked > 0:
		_on_combo_banked(banked)

	view_y = lerpf(view_y, maxf(0.0, _top_y() - VIEW_BELOW_TOP), minf(1.0, delta * 4.0))
	if autoplay:
		_autoplay_step()
	_refresh_hud()
	queue_redraw()


func _update_falling(delta: float) -> void:
	if falling.is_empty():
		return
	falling["vy"] -= float(rules["crane"]["gravity"]) * delta
	falling["y"] += falling["vy"] * delta
	var top_y := _top_y()

	if not falling["missed"] and falling["y"] <= top_y:
		var x_tower: float = falling["x"] - sway_top
		if absf(x_tower - state.top_x()) >= float(rules["miss_offset"]):
			falling["missed"] = true          # keeps falling past the tower
			falling["miss_x"] = x_tower
		else:
			var ev: Dictionary = state.land(x_tower)
			falling = {}
			_on_resolved(ev)
			return

	if falling["missed"] and falling["y"] < top_y - float(rules["fall_kill_depth"]):
		var ev: Dictionary = state.land(falling["miss_x"])
		falling = {}
		_on_resolved(ev)


func _on_resolved(ev: Dictionary) -> void:
	GameEvents.block_resolved.emit(ev)
	match ev["result"]:
		TowerState.RESULT_PERFECT:
			_popup("PERFECT! +%d" % ev["residents"], Color.GOLD)
		TowerState.RESULT_STACK:
			_popup("+%d" % ev["residents"], Color.WHITE)
		TowerState.RESULT_COLLAPSE:
			_spawn_debris(ev)
			_popup("COLLAPSE -%d" % ev["lost_residents"], Color.ORANGE_RED)
		TowerState.RESULT_MISS:
			_popup("MISS - %d lives left" % ev["lives"], Color.RED)
	if ev.get("banked", 0) > 0:
		_on_combo_banked(int(ev["banked"]))
	if ev.get("complete", false):
		_popup("ROOF +%d%s" % [ev["roof_people"], "  TROPHY!" if ev["star"] else ""], Color.GOLD)
	if state.is_over:
		_finish_round()


func _on_combo_banked(amount: int) -> void:
	GameEvents.combo_banked.emit(amount)
	_popup("COMBO BONUS +%d" % amount, Color.AQUA)


func _finish_round() -> void:
	round_finished = true
	var summary := {
		"complete": state.is_complete,
		"star": state.is_complete and state.population >= int(block_type["star_population"]),
		"population": state.population,
		"height": state.height(),
		"max_combo": state.max_combo,
		"block_type": block_type["id"],
	}
	GameEvents.round_ended.emit(summary)
	SaveData.record_round(summary)
	hud_message.text = ("TOWER COMPLETE!" if state.is_complete else "GAME OVER") \
		+ "\nPopulation %d\nTap to play again" % state.population
	hud_message.visible = true
	if autoplay:
		print("AUTOPLAY_SUMMARY ", JSON.stringify(summary))
		get_tree().quit(0)


func _spawn_debris(ev: Dictionary) -> void:
	var dir := signf(float(ev["offset"]))
	var k := 0
	for b in ev["fallen"]:
		debris.append({
			"x": float(b["x"]),
			"y": (int(b["index"]) - 1) * _block_h(),
			"vx": dir * 1.5,
			"vy": 0.0,
			"rot": 0.0,
			"vrot": dir * 2.5,
			"delay": k * float(rules["collapse_interval_s"]),
		})
		k += 1


func _update_debris(delta: float) -> void:
	var g := float(rules["crane"]["gravity"]) * 0.5
	for d in debris:
		if d["delay"] > 0.0:
			d["delay"] -= delta
			continue
		d["vy"] -= g * delta
		d["x"] += d["vx"] * delta
		d["y"] += d["vy"] * delta
		d["rot"] += d["vrot"] * delta
	debris = debris.filter(func(d): return d["y"] > view_y - 4.0)


func _popup(text: String, colour: Color) -> void:
	popups.append({"text": text, "x": state.top_x(), "y": _top_y() + 0.8, "age": 0.0, "colour": colour})


func _update_popups(delta: float) -> void:
	for p in popups:
		p["age"] += delta
		p["y"] += delta * 0.8
	popups = popups.filter(func(p): return p["age"] < 1.4)


# --- helpers -----------------------------------------------------------------

func _block_h() -> float:
	return float(rules["block"]["height"])


func _top_y() -> float:
	return state.height() * _block_h()


func _crane_y() -> float:
	return _top_y() + float(rules["crane"]["gap_blocks"]) * _block_h()


func _to_screen(x: float, y: float) -> Vector2:
	return Vector2(SCREEN.x * 0.5 + x * UNIT, GROUND_PX - (y - view_y) * UNIT)


func _block_rect_at(x: float, bottom_y: float) -> Rect2:
	var w := float(rules["block"]["width"]) * UNIT
	var h := _block_h() * UNIT
	var p := _to_screen(x, bottom_y)
	return Rect2(p.x - w * 0.5, p.y - h, w, h)


func _autoplay_step() -> void:
	if autoplay_seconds > 0.0 and t > autoplay_seconds and not round_finished:
		print("AUTOPLAY_TIMEOUT height=%d population=%d" % [state.height(), state.population])
		get_tree().quit(0)
		return
	if round_finished:
		return
	# Drop when the crane is roughly above the swaying top; deliberately imperfect.
	if falling.is_empty() and absf((crane_x - sway_top) - state.top_x()) < 0.25:
		_on_tap()


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("#1c2333"))
	var ground := _to_screen(0.0, 0.0)
	draw_rect(Rect2(0, ground.y, SCREEN.x, SCREEN.y), FOUNDATION_COLOUR)

	var colour := Color(block_type["colour"])
	var h := maxi(1, state.height())
	for i in range(1, state.blocks.size()):
		var b: Dictionary = state.blocks[i]
		var x: float = b["x"] + sway_top * (float(i) / h)
		_draw_block(_block_rect_at(x, (i - 1) * _block_h()), colour)

	for d in debris:
		var r := _block_rect_at(d["x"], d["y"])
		draw_set_transform(r.get_center(), d["rot"], Vector2.ONE)
		_draw_block(Rect2(-r.size * 0.5, r.size), colour.darkened(0.25))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Crane: rope + hook + carried block.
	var crane_pos := _to_screen(crane_x, _crane_y())
	draw_line(Vector2(crane_pos.x, 0), crane_pos, Color("#aaaaaa"), 3.0)
	if falling.is_empty() and not state.is_over:
		_draw_block(_block_rect_at(crane_x, _crane_y() - _block_h()), colour.lightened(0.15))
	if not falling.is_empty():
		_draw_block(_block_rect_at(falling["x"], falling["y"]), colour.lightened(0.15))

	var font := ThemeDB.fallback_font
	for p in popups:
		var pos := _to_screen(p["x"], p["y"])
		var c: Color = p["colour"]
		c.a = 1.0 - p["age"] / 1.4
		draw_string(font, pos - Vector2(200, 0), p["text"], HORIZONTAL_ALIGNMENT_CENTER, 400, 34, c)


func _draw_block(r: Rect2, colour: Color) -> void:
	draw_rect(r, colour)
	draw_rect(r, colour.darkened(0.4), false, 3.0)
	# placeholder windows
	var ww := r.size.x / 7.0
	for k in range(3):
		draw_rect(Rect2(r.position.x + ww * (1 + k * 2), r.position.y + r.size.y * 0.3, ww, r.size.y * 0.4), colour.darkened(0.3))


# --- HUD ---------------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud_population = _hud_label(layer, Vector2(24, 24), 40)
	hud_lives = _hud_label(layer, Vector2(24, 80), 30)
	hud_height = _hud_label(layer, Vector2(24, 124), 30)
	hud_combo = ProgressBar.new()
	hud_combo.min_value = 0.0
	hud_combo.max_value = 1.0
	hud_combo.step = 0.001
	hud_combo.show_percentage = false
	hud_combo.position = Vector2(420, 32)
	hud_combo.size = Vector2(276, 28)
	layer.add_child(hud_combo)
	hud_message = _hud_label(layer, Vector2(0, 520), 48)
	hud_message.size = Vector2(SCREEN.x, 300)
	hud_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_message.visible = false


func _hud_label(layer: CanvasLayer, pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	layer.add_child(l)
	return l


func _refresh_hud() -> void:
	hud_population.text = "Population %d" % state.population
	hud_lives.text = "Lives %d" % state.lives
	var goal: int = state.target_height()
	hud_height.text = "Height %d / %d" % [state.height(), goal] if goal > 0 else "Height %d" % state.height()
	hud_combo.value = state.combo_ratio()
	hud_combo.visible = state.combo_time > 0.0

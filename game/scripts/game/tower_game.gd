## Tower round scene: crane, falling block, rendering, HUD, input.
## All rules are delegated to TowerState (scripts/core/tower_state.gd); this
## script only moves things on screen and turns state events into feedback.
##
## Placeholder visuals: blocks are coloured rectangles drawn in _draw() until
## the art in HUMAN_NEEDED.md (HR-0004..HR-0007) is delivered.
##
## Params (SceneRouter.params): {block_type: id, endless: bool}.
## Headless autoplay for smoke tests (menu jumps straight here):
##   godot --headless --path game -- --autoplay --seconds=20
extends Node2D

const TowerState := preload("res://scripts/core/tower_state.gd")
const UI := preload("res://scripts/game/ui_kit.gd")
const AdPolicy := preload("res://scripts/core/ad_policy.gd")
const TowerView3D := preload("res://scripts/game/tower_view_3d.gd")
const RESUME_COUNTDOWN_S := 3
const RESULTS_DELAY_S := 1.2

const UNIT := 160.0                     # screen pixels per world unit (one block width)
const SCREEN := Vector2(720, 1280)
const GROUND_PX := 1120.0               # screen y of world y=0 when the camera is at the bottom
const HUD_MARGIN_PX := 170.0            # keep the crane hook below the HUD at the top of the screen
const FOUNDATION_COLOUR := Color("#5a5a66")

var rules: Dictionary
var block_type: Dictionary
var endless := false
var state

var t := 0.0
var view_y := 0.0
var view_x := 0.0                       # camera follows the tower sideways as it drifts (T-0108)
var crane_x := 0.0
var crane_center := 0.0                 # the crane swings around the (smoothed) tower top
var framing_violations := 0             # autoplay check: crane/tower left the screen
var sway_top := 0.0
var falling: Dictionary = {}            # {x, y, vy, missed, miss_x}
var debris: Array[Dictionary] = []      # toppled blocks: {x, y, vx, vy, rot, vrot, delay}
var popups: Array[Dictionary] = []      # floating text: {text, x, y, age, colour}
var round_finished := false

# presentation-only feedback (config/feel.json, T-0102)
var feel: Dictionary
var reduced_motion := false
var shake := 0.0
var shake_offset := Vector2.ZERO
var kick := 0.0                         # displayed camera kick (px), eased towards kick_target
var kick_target := 0.0
var squash_t := 0.0
var particles: Array[Dictionary] = []   # {x, y, vx, vy, age, life, kind, size}
var last_combo_count := 0
var view3d = null                      # low-poly 3D renderer (ADR-0006); null = 2D fallback
var continues_used := 0
var offering_continue := false
var continue_layer: CanvasLayer
var pause_btn: Button

var autoplay := false
var autoplay_seconds := 0.0

var hud_population: Label
var hud_lives: Label
var hud_height: Label
var hud_combo: ProgressBar
var hud_message: Label
var pause_layer: CanvasLayer
var pause_label: Label
var pause_buttons: VBoxContainer
var paused := false


func _ready() -> void:
	rules = GameConfig.table("tower_rules")
	feel = GameConfig.table("feel")
	reduced_motion = bool(SaveData.get_setting("reduced_motion"))
	AudioDirector.play_music("round")
	block_type = GameConfig.block_type(String(SceneRouter.params.get("block_type", "blue")))
	endless = bool(SceneRouter.params.get("endless", false))
	state = TowerState.new(rules, {
		"target_height": 0 if endless else block_type["target_height"],
		"roof_people": block_type["roof_people"],
		"star_population": block_type["star_population"],
		"star_roof_people": block_type["star_roof_people"],
	})
	if SceneRouter.autoplay:
		autoplay = true
		autoplay_seconds = SceneRouter.autoplay_seconds
		Engine.time_scale = 4.0
		SaveData.persist = false
	if String(feel.get("view", "3d")) == "3d":
		view3d = TowerView3D.new()
		add_child(view3d)
		view3d.setup(self)
	GameEvents.round_started.emit(String(block_type["id"]), endless)
	_build_hud()
	_build_pause()
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE)
	if pressed:
		_on_tap()


func _on_tap() -> void:
	if round_finished or paused:
		return
	if falling.is_empty() and not state.is_over:
		falling = {"x": crane_x, "y": _crane_y(), "vy": 0.0, "missed": false, "miss_x": 0.0}
		GameEvents.block_released.emit()


# --- pause and app lifecycle (T-0206) -----------------------------------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if not autoplay:
			pause_game()     # refuses while the continue prompt or results are up (T-0507)
		SaveData.write_save()


func on_back() -> void:
	if round_finished:
		return
	if offering_continue:
		_decline_continue()      # back on the "Out of lives" prompt = "No thanks"
		return
	if paused:
		SceneRouter.go("menu")
	else:
		pause_game()


## Never pause underneath the continue prompt or after the round ended: the paused tree would
## freeze the prompt's buttons and hide the pause menu behind it (owner bug T-0507).
func can_pause() -> bool:
	return not round_finished and not offering_continue


func pause_game() -> void:
	if paused or not can_pause():
		return
	paused = true
	get_tree().paused = true
	pause_label.text = tr("PAUSED")
	pause_buttons.visible = true
	pause_layer.visible = true


func resume_game() -> void:
	pause_buttons.visible = false
	for n in range(RESUME_COUNTDOWN_S, 0, -1):
		pause_label.text = str(n)
		await get_tree().create_timer(1.0, true, false, true).timeout
		if not is_inside_tree():
			return
	pause_layer.visible = false
	paused = false
	get_tree().paused = false


func _build_pause() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 10
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.visible = false
	add_child(pause_layer)
	var root := Control.new()
	pause_layer.add_child(root)
	var col := UI.screen(root)
	(root.get_child(0) as ColorRect).color = Color(0, 0, 0, 0.6)
	pause_label = UI.label(tr("PAUSED"), 72, UI.ACCENT)
	col.add_child(pause_label)
	pause_buttons = VBoxContainer.new()
	pause_buttons.add_theme_constant_override("separation", 24)
	pause_buttons.add_child(UI.button(tr("BTN_RESUME"), resume_game))
	pause_buttons.add_child(UI.button(tr("BTN_RESTART"), func() -> void: SceneRouter.go("game", SceneRouter.params)))
	pause_buttons.add_child(UI.button(tr("BTN_QUIT_MENU"), func() -> void: SceneRouter.go("menu")))
	col.add_child(pause_buttons)


func _process(delta: float) -> void:
	t += delta
	var crane: Dictionary = rules["crane"]
	var speed := minf(float(crane["speed"]) + float(crane["speed_per_block"]) * state.height(), float(crane["speed_max"]))
	# The crane's swing centre glides after the tower top, so a drifting tower never walks off screen
	# and the swing stays symmetric around it (same difficulty wherever the tower is).
	crane_center = move_toward(crane_center, state.top_x(), float(crane["follow_speed"]) * delta)
	crane_x = crane_center + float(crane["amplitude"]) * sin(t * speed)

	var sway: Dictionary = rules["sway"]
	var amp := clampf(state.wobble() * float(sway["scale"]), -float(sway["max"]), float(sway["max"]))
	sway_top = amp * sin(t * float(sway["speed"]))

	_update_falling(delta)
	_update_debris(delta)
	_update_popups(delta)

	var banked: int = state.tick(delta)
	if banked > 0:
		_on_combo_banked(banked)
	_emit_combo_progress()
	_update_feedback(delta)

	view_y = lerpf(view_y, _desired_view_y(), minf(1.0, delta * 6.0))
	view_x = lerpf(view_x, crane_center, minf(1.0, delta * 3.0))
	if autoplay:
		_autoplay_step()
		if t > 1.5:          # let the camera settle after the scene starts
			_check_framing()
	if view3d:
		view3d.sync(delta)
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
	ev["combo"] = state.combo_count
	GameEvents.block_resolved.emit(ev)
	var sh: Dictionary = feel["shake"]
	match ev["result"]:
		TowerState.RESULT_PERFECT:
			_popup(tr("POP_PERFECT") % ev["residents"], Color.GOLD)
			_add_shake(float(sh["perfect"]))
			_kick(float(feel["camera_kick"]["perfect"]))
			_squash()
			_spawn_particles("sparkle", ev["x"], _top_y(), int(feel["particles"]["sparkle_count"]), 0.0)
		TowerState.RESULT_STACK:
			_popup(tr("POP_STACK") % ev["residents"], Color.WHITE)
			var sloppy := absf(float(ev["offset"])) >= float(rules["stable_offset"])
			_add_shake(float(sh["land_sloppy"] if sloppy else sh["land"]))
			_squash()
			_spawn_particles("dust", ev["x"] + signf(float(ev["offset"])) * 0.5, _top_y() - _block_h(), int(feel["particles"]["dust_count"]), signf(float(ev["offset"])))
		TowerState.RESULT_COLLAPSE:
			_spawn_debris(ev)
			var lives_text: String = tr("POP_LIVES_LEFT") % ev["lives"] if bool(rules.get("collapse_costs_life", false)) else ""
			_popup(tr("POP_COLLAPSE") % ev["lost_residents"] + lives_text, Color.ORANGE_RED)
			_add_shake(float(sh["collapse_per_block"]) * int(ev["removed"]))
		TowerState.RESULT_MISS:
			_popup(tr("POP_MISS") % ev["lives"], Color.RED)
			_add_shake(float(sh["miss"]))
	if ev.get("banked", 0) > 0:
		_on_combo_banked(int(ev["banked"]))
	if ev.get("complete", false):
		_popup(tr("POP_ROOF") % ev["roof_people"] + (tr("POP_TROPHY") if ev["star"] else ""), Color.GOLD)
	if state.is_over:
		_on_round_over()


## Game over (not a completed tower): offer one rewarded "continue" per round, then finish.
func _on_round_over() -> void:
	var cfg: Dictionary = GameConfig.table("economy")["rewarded"]
	if state.is_complete or autoplay or not AdPolicy.can_offer_continue(continues_used, cfg):
		_finish_round()
		return
	offering_continue = true
	pause_btn.visible = false
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS     # the prompt must work even if something paused the tree
	add_child(layer)
	continue_layer = layer
	var root := Control.new()
	layer.add_child(root)
	var col := UI.screen(root)
	(root.get_child(0) as ColorRect).color = Color(0, 0, 0, 0.7)
	col.add_child(UI.label(tr("CONTINUE_TITLE"), 56, UI.ACCENT))
	col.add_child(UI.label(tr("CONTINUE_OFFER") % int(cfg["continue_lives"]), 32))
	col.add_child(UI.button(tr("BTN_WATCH_CONTINUE"), func() -> void:
		layer.queue_free()
		continue_layer = null
		continues_used += 1
		var earned: bool = await Ads.show_rewarded("continue")
		offering_continue = false
		get_tree().paused = false
		if earned and state.revive(int(cfg["continue_lives"])):
			_popup(tr("POP_EXTRA_LIFE") % int(cfg["continue_lives"]), Color.GREEN_YELLOW)
			pause_btn.visible = true
		else:
			_finish_round()))
	col.add_child(UI.button(tr("BTN_NO_THANKS"), _decline_continue))


func _decline_continue() -> void:
	if not offering_continue:
		return
	offering_continue = false
	if continue_layer:
		continue_layer.queue_free()
		continue_layer = null
	get_tree().paused = false
	_finish_round()


# --- feedback (presentation only) ------------------------------------------------

func _emit_combo_progress() -> void:
	if state.combo_count != last_combo_count:
		last_combo_count = state.combo_count
		GameEvents.combo_progress.emit(state.combo_count, state.drain_rate())


func _add_shake(amount: float) -> void:
	if not reduced_motion:
		shake = minf(shake + amount, float(feel["shake"]["max"]))


func _kick(amount: float) -> void:
	if not reduced_motion:
		kick_target += amount


func _squash() -> void:
	squash_t = float(feel["squash"]["time"])


func _spawn_particles(kind: String, x: float, y: float, count: int, side: float) -> void:
	var life := float(feel["particles"][kind + "_life"])
	for i in range(count):
		var a := randf_range(0.0, TAU)
		var speed := randf_range(0.6, 1.8)
		var vx := cos(a) * speed
		if side != 0.0:
			vx = absf(vx) * side
		particles.append({"x": x, "y": y, "vx": vx, "vy": absf(sin(a)) * speed * (0.5 if kind == "dust" else 1.2),
			"age": 0.0, "life": life * randf_range(0.7, 1.0), "kind": kind, "size": randf_range(0.5, 1.0)})


func _update_feedback(delta: float) -> void:
	shake = lerpf(shake, 0.0, minf(1.0, float(feel["shake"]["decay"]) * delta))
	# Smooth wobble (a few incommensurate sines) instead of a fresh random offset every frame:
	# per-frame random jumps read as flicker, especially on the static base.
	var f := float(feel["shake"].get("frequency", 1.0))
	var wobble := Vector2(sin(t * 31.0 * f) * 0.6 + sin(t * 17.3 * f) * 0.4, cos(t * 27.7 * f) * 0.6 + sin(t * 13.1 * f) * 0.4)
	shake_offset = wobble * shake if shake > 0.2 else Vector2.ZERO
	# ease in and out: an instant camera jump reads as a flicker of the whole scene
	kick_target = lerpf(kick_target, 0.0, minf(1.0, float(feel["camera_kick"]["decay"]) * delta))
	kick = lerpf(kick, kick_target, minf(1.0, 14.0 * delta))
	squash_t = maxf(0.0, squash_t - delta)
	for p in particles:
		p["age"] += delta
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		p["vy"] -= (1.5 if p["kind"] == "dust" else 3.0) * delta
	particles = particles.filter(func(p): return p["age"] < p["life"])


func _on_combo_banked(amount: int) -> void:
	GameEvents.combo_banked.emit(amount)
	_popup(tr("POP_COMBO_BONUS") % amount, Color.AQUA)


func _finish_round() -> void:
	round_finished = true
	var summary := {
		"complete": state.is_complete,
		"star": state.is_star,
		"population": state.population,
		"height": state.height(),
		"max_combo": state.max_combo,
		"block_type": block_type["id"],
		"endless": endless,
	}
	GameEvents.round_ended.emit(summary)
	var record: Dictionary = SaveData.record_round(summary)
	hud_message.text = tr("HUD_TOWER_COMPLETE") if state.is_complete else tr("HUD_GAME_OVER")
	hud_message.visible = true
	if autoplay:
		print("AUTOPLAY_SUMMARY ", JSON.stringify(summary))
		print("AUTOPLAY_FRAMING violations=%d" % framing_violations)
	# process_always: reaches the results screen even if the tree got paused meanwhile
	await get_tree().create_timer(RESULTS_DELAY_S, true).timeout
	SceneRouter.go("results", {"summary": summary, "record": record})


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
		if not d.get("toppled", false):
			d["toppled"] = true
			GameEvents.block_toppled.emit()
		d["vy"] -= g * delta
		d["x"] += d["vx"] * delta
		d["y"] += d["vy"] * delta
		d["rot"] += d["vrot"] * delta
	debris = debris.filter(func(d): return d["y"] > view_y - 4.0)


func _popup(text: String, colour: Color) -> void:
	# stack simultaneous popups instead of drawing them on top of each other
	var young := popups.filter(func(p): return p["age"] < 0.5).size()
	popups.append({"text": text, "x": state.top_x(), "y": _top_y() + 0.8 + 0.4 * young, "age": 0.0, "colour": colour})


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
	return Vector2(SCREEN.x * 0.5 + (x - view_x) * UNIT, GROUND_PX - (y - view_y) * UNIT + kick) + shake_offset


## Camera height that keeps the crane hook just below the HUD (and so the stack top in view).
func _desired_view_y() -> float:
	var hook_y := _crane_y() + 0.15
	if view3d:
		return maxf(0.0, view3d.view_y_for_top_point(hook_y, HUD_MARGIN_PX))
	# 2D fallback: hook at HUD_MARGIN_PX from the top of a 1280 px screen
	return maxf(0.0, hook_y - (GROUND_PX - HUD_MARGIN_PX) / UNIT)


## Autoplay framing check: crane hook and tower top must stay on screen.
func _check_framing() -> void:
	if view3d == null or round_finished:
		return
	var size := get_viewport().get_visible_rect().size
	var hook: Vector2 = view3d.world_to_screen(crane_x, _crane_y() + 0.15)
	var top: Vector2 = view3d.world_to_screen(state.top_x(), _top_y())
	for p in [hook, top]:
		if p.x < 0.0 or p.x > size.x or p.y < 0.0 or p.y > size.y:
			framing_violations += 1
			return


func _block_rect_at(x: float, bottom_y: float) -> Rect2:
	var w := float(rules["block"]["width"]) * UNIT
	var h := _block_h() * UNIT
	var p := _to_screen(x, bottom_y)
	return Rect2(p.x - w * 0.5, p.y - h, w, h)


func _autoplay_step() -> void:
	if autoplay_seconds > 0.0 and t > autoplay_seconds and not round_finished:
		print("AUTOPLAY_TIMEOUT height=%d population=%d" % [state.height(), state.population])
		print("AUTOPLAY_FRAMING violations=%d" % framing_violations)
		get_tree().quit(0)
		return
	if round_finished:
		return
	# Drop when the crane is roughly above the swaying top; deliberately imperfect.
	if falling.is_empty() and absf((crane_x - sway_top) - state.top_x()) < 0.25:
		_on_tap()


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	if view3d:
		_draw_popups()   # the 3D view draws the world; only floating text stays 2D
		return
	draw_rect(Rect2(Vector2(-64, -64), SCREEN + Vector2(128, 128)), Color("#1c2333"))
	var ground := _to_screen(0.0, 0.0)
	draw_rect(Rect2(0, ground.y, SCREEN.x, SCREEN.y), FOUNDATION_COLOUR)

	var colour := Color(block_type["colour"])
	var h := maxi(1, state.height())
	for i in range(1, state.blocks.size()):
		var b: Dictionary = state.blocks[i]
		var x: float = b["x"] + sway_top * (float(i) / h)
		var r := _block_rect_at(x, (i - 1) * _block_h())
		if i == state.height() and squash_t > 0.0:
			# squash the newest block around its bottom centre, then spring back
			var k := sin(squash_t / float(feel["squash"]["time"]) * PI) * float(feel["squash"]["amount"])
			var pivot := Vector2(r.get_center().x, r.end.y)
			draw_set_transform(pivot, 0.0, Vector2(1.0 + k, 1.0 - k))
			_draw_block(Rect2(r.position - pivot, r.size), colour)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			_draw_block(r, colour)

	for p in particles:
		var pos := _to_screen(p["x"], p["y"])
		var fade: float = 1.0 - p["age"] / p["life"]
		if p["kind"] == "dust":
			draw_circle(pos, (10.0 + 26.0 * (1.0 - fade)) * p["size"], Color(0.85, 0.85, 0.9, 0.45 * fade))
		else:
			var s: float = 12.0 * p["size"] * fade
			var c := Color(1.0, 0.85, 0.3, fade)
			draw_line(pos - Vector2(s, 0), pos + Vector2(s, 0), c, 3.0)
			draw_line(pos - Vector2(0, s), pos + Vector2(0, s), c, 3.0)

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

	_draw_popups()


func _draw_popups() -> void:
	var font := ThemeDB.fallback_font
	for p in popups:
		var pos: Vector2 = view3d.world_to_screen(p["x"], p["y"]) if view3d else _to_screen(p["x"], p["y"])
		var c: Color = p["colour"]
		c.a = 1.0 - p["age"] / 1.4
		# dark outline keeps text readable over a bright sky
		draw_string_outline(font, pos - Vector2(200, 0), p["text"], HORIZONTAL_ALIGNMENT_CENTER, 400, 34, 8, Color(0, 0, 0, c.a * 0.55))
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
	pause_btn = Button.new()
	pause_btn.text = "II"
	pause_btn.position = Vector2(620, 80)
	pause_btn.size = Vector2(76, 76)
	pause_btn.add_theme_font_size_override("font_size", 32)
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.pressed.connect(pause_game)
	layer.add_child(pause_btn)
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
	hud_population.text = tr("HUD_POPULATION") % state.population
	hud_lives.text = tr("HUD_LIVES") % state.lives
	var goal: int = state.target_height()
	hud_height.text = tr("HUD_HEIGHT_GOAL") % [state.height(), goal] if goal > 0 else tr("HUD_HEIGHT") % state.height()
	hud_combo.value = state.combo_ratio()
	hud_combo.visible = state.combo_time > 0.0
	if hud_combo.visible:
		# pulse, and turn red when nearly empty
		var cb: Dictionary = feel["combo_bar"]
		var pulse := 1.0 + 0.06 * sin(t * TAU * float(cb["pulse_hz"]))
		hud_combo.pivot_offset = hud_combo.size * 0.5
		hud_combo.scale = Vector2(pulse, pulse)
		hud_combo.modulate = Color(1.0, 0.45, 0.4) if state.combo_ratio() < float(cb["warn_below"]) else Color(1.0, 0.9, 0.5)

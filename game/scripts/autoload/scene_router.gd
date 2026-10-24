## Autoload "SceneRouter": moves between screens with a short fade and passes
## parameters to the next screen (read them with SceneRouter.params).
## Also routes the Android back button to the current screen's on_back().
extends CanvasLayer

const SCENES := {
	"menu": "res://scenes/main_menu.tscn",
	"select": "res://scenes/tower_select.tscn",
	"game": "res://scenes/tower_game.tscn",
	"results": "res://scenes/results.tscn",
	"settings": "res://scenes/settings.tscn",
	"city": "res://scenes/city_map.tscn",
}
const FADE_S := 0.15

## Parameters for the screen being entered, e.g. {"block_type": "red"}.
var params: Dictionary = {}
## Cosmetic choice for this app session; deliberately independent of saved tower types.
var selected_theme := ""
## True when the game was started with `-- --autoplay` (headless smoke test).
var autoplay := false
var autoplay_seconds := 0.0
## True with `-- --tour`: visit every screen for a moment, then quit (for screenshots/smoke).
var tour := false

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			autoplay = true
		elif arg.begins_with("--seconds="):
			autoplay_seconds = float(arg.get_slice("=", 1))
		elif arg == "--tour":
			tour = true
		elif arg.begins_with("--lang="):
			# debug: preview a language without changing the save (e.g. for screenshots)
			TranslationServer.set_locale(arg.get_slice("=", 1))
		elif arg.begins_with("--theme="):
			selected_theme = arg.get_slice("=", 1)
	if tour:
		_run_tour.call_deferred()


## `godot --path game --write-movie /tmp/tour/f.png --fixed-fps 10 -- --tour`
## captures every screen (menu, select, round, pause, results).
func _run_tour() -> void:
	var fake_summary := {"complete": true, "star": true, "population": 123, "height": 10, "max_combo": 7, "block_type": "blue", "endless": false}
	var fake_record := {"new_best_population": true, "new_best_height": false, "level_before": 1, "level_after": 2, "unlocked": ["red"]}
	var steps := [["menu", {}], ["select", {}], ["game", {"block_type": "red"}], ["pause", {}], ["game", {"block_type": "blue"}], ["continue", {}], ["game", {"block_type": "blue"}], ["combo_audio", {}], ["game", {"block_type": "blue"}], ["decline", {}], ["game", {"block_type": "blue"}], ["decline_real", {}], ["results", {"summary": fake_summary, "record": fake_record}], ["settings", {}], ["city", {}], ["city_place", {}], ["analytics", {}]]
	# The tour never writes the save; it fills the city with sample towers in memory so the screen has content.
	SaveData.persist = false
	SaveData.data["city"] = {"plots": {
		"0,0": {"type": "blue", "population": 90, "height": 10, "star": true},
		"1,0": {"type": "red", "population": 210, "height": 20, "star": false},
		"2,2": {"type": "green", "population": 380, "height": 30, "star": true}},
		"unplaced": [{"type": "yellow", "population": 560, "height": 40, "star": false},
		{"type": "blue", "population": 75, "height": 10, "star": false}]}
	for step in steps:
		await get_tree().create_timer(1.0, true, false, true).timeout
		if step[0] == "pause":
			get_tree().current_scene.pause_game()
		elif step[0] == "continue":
			# force a game over, accept the continue offer through the fake ad, check the round resumes
			var g := get_tree().current_scene
			for i in range(3):
				g._on_resolved(g.state.land(9.0))
			await get_tree().create_timer(0.8, true, false, true).timeout
			var watch: Button = null
			for b in g.find_children("*", "Button", true, false):
				if b.text == tr("BTN_WATCH_CONTINUE"):
					watch = b
			var found := watch != null   # the button is freed once pressed; freed objects compare equal to null
			Ads.backend = "fake"
			if found:
				watch.pressed.emit()
			await get_tree().create_timer(Ads.FAKE_AD_S + 0.8, true, false, true).timeout
			Ads.backend = "none"
			var ok: bool = found and not g.state.is_over and g.state.lives == 1
			print("TOUR continue ", "ok" if ok else "FAILED (button=%s over=%s lives=%d)" % [found, g.state.is_over, g.state.lives])
		elif step[0] == "combo_audio":
			# owner bug T-0107: start a combo, pause -> ticking must freeze; quit to menu -> it must stop
			var g := get_tree().current_scene
			g._on_resolved(g.state.land(g.state.top_x()))     # perfect -> combo starts
			await get_tree().create_timer(0.3, true, false, true).timeout
			var ticking: bool = AudioDirector.is_combo_ticking()
			g.pause_game()
			await get_tree().create_timer(0.3, true, false, true).timeout
			var frozen: bool = not AudioDirector.is_combo_ticking()
			await go("menu")
			get_tree().paused = false
			await get_tree().create_timer(0.3, true, false, true).timeout
			var stopped: bool = not AudioDirector._tick_player.playing
			print("TOUR combo_audio ", "ok" if ticking and frozen and stopped else "FAILED (ticking=%s frozen=%s stopped=%s)" % [ticking, frozen, stopped])
		elif step[0] == "decline":
			# owner bug: game over -> continue prompt -> REAL mouse click on "No thanks" must lead to results
			var g := get_tree().current_scene
			for i in range(3):
				g._on_resolved(g.state.land(9.0))
			await get_tree().create_timer(0.8, true, false, true).timeout
			var btn: Button = null
			for b in g.find_children("*", "Button", true, false):
				if b.text == tr("BTN_NO_THANKS"):
					btn = b
			var found := btn != null
			if found:
				_click(btn.get_global_rect().get_center())
			await get_tree().create_timer(2.5, true, false, true).timeout
			var at_results: bool = get_tree().current_scene != null and get_tree().current_scene.scene_file_path == SCENES["results"]
			print("TOUR decline ", "ok" if found and at_results else "FAILED (button=%s scene=%s)" % [found, get_tree().current_scene.scene_file_path if get_tree().current_scene else "none"])
		elif step[0] == "decline_real":
			# full real play: tap when the crane is far from the tower so blocks miss, let them fall,
			# then click "No thanks" on the continue prompt
			var g := get_tree().current_scene
			var waited := 0.0
			var btn: Button = null
			while waited < 40.0 and btn == null:
				if g.falling.is_empty() and not g.state.is_over and absf(g.crane_x - g.state.top_x()) > 1.15:
					_click(Vector2(360, 700))
				await get_tree().process_frame
				waited += get_process_delta_time()
				for b in g.find_children("*", "Button", true, false):
					if b.text == tr("BTN_NO_THANKS") and b.is_visible_in_tree():
						btn = b
			# owner bug T-0507: losing focus (app switch, notification) while the prompt is up used to
			# pause the game underneath it and freeze its buttons
			g._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)    # player switches apps / a notification appears
			await get_tree().process_frame
			g._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
			await get_tree().create_timer(0.5, true, false, true).timeout
			if btn and is_instance_valid(btn):
				_click(btn.get_global_rect().get_center())
			await get_tree().create_timer(3.0, true, false, true).timeout
			var at_results: bool = get_tree().current_scene != null and get_tree().current_scene.scene_file_path == SCENES["results"]
			print("TOUR decline_real ", "ok" if at_results else "FAILED (scene=%s)" % (get_tree().current_scene.scene_file_path if get_tree().current_scene else "none"))
		elif step[0] == "analytics":
			SaveData.data["settings"]["analytics_consent"] = "unknown"
			var dropped: bool = not Analytics.track("level_up", {"from_level": 1, "to_level": 2})
			SaveData.data["settings"]["analytics_consent"] = "denied"
			var dropped2: bool = not Analytics.track("level_up", {"from_level": 1, "to_level": 2})
			SaveData.data["settings"]["analytics_consent"] = "granted"
			var sent: bool = Analytics.track("level_up", {"from_level": 1, "to_level": 2})
			print("TOUR analytics ", "ok" if dropped and dropped2 and sent else "FAILED")
		elif step[0] == "city_place":
			# simulate: pick the first tray tower, tap plot (1,1); fails the tour if it didn't land
			var scene := get_tree().current_scene
			var before: int = SaveData.data["city"]["unplaced"].size()
			scene.selected = 0
			var tap := InputEventMouseButton.new()
			tap.button_index = MOUSE_BUTTON_LEFT
			tap.pressed = true
			tap.position = scene._cell_rect(1, 1).get_center()
			scene._on_grid_input(tap)
			var ok: bool = SaveData.data["city"]["unplaced"].size() == before - 1 and not scene.city.tower_at(1, 1).is_empty()
			print("TOUR city_place ", "ok" if ok else "FAILED")
			if not ok:
				push_error("tour: city placement did not work")
		else:
			await go(step[0], step[1])
		print("TOUR ", step[0])
	await get_tree().create_timer(1.0, true, false, true).timeout
	print("TOUR_DONE")
	get_tree().quit(0)


## Go to a screen by name (see SCENES).
func go(screen: String, p: Dictionary = {}) -> void:
	if _busy:
		return
	assert(SCENES.has(screen), "Unknown screen " + screen)
	_busy = true
	params = p
	GameEvents.screen_changing.emit(screen)
	get_tree().paused = false
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE_S)
	await tw.finished
	get_tree().change_scene_to_file(SCENES[screen])
	tw = create_tween()
	tw.tween_property(_fade, "color:a", 0.0, FADE_S)
	await tw.finished
	_busy = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()


## Back button / Escape: ask the current screen; quit from the main menu.
func back() -> void:
	var s := get_tree().current_scene
	if s and s.has_method("on_back"):
		s.on_back()
	else:
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		back()
		get_viewport().set_input_as_handled()


## Send a real left click (press + release) at a canvas position, like a player's tap.
func _click(pos: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = pos
		e.global_position = pos
		get_viewport().push_input(e, true)   # position is in canvas coordinates
		await get_tree().process_frame

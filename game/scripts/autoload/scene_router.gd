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
	if tour:
		_run_tour.call_deferred()


## `godot --path game --write-movie /tmp/tour/f.png --fixed-fps 10 -- --tour`
## captures every screen (menu, select, round, pause, results).
func _run_tour() -> void:
	var fake_summary := {"complete": true, "star": true, "population": 123, "height": 10, "max_combo": 7, "block_type": "blue", "endless": false}
	var fake_record := {"new_best_population": true, "new_best_height": false, "level_before": 1, "level_after": 2, "unlocked": ["red"]}
	var steps := [["menu", {}], ["select", {}], ["game", {"block_type": "red"}], ["pause", {}], ["game", {"block_type": "blue"}], ["continue", {}], ["results", {"summary": fake_summary, "record": fake_record}], ["settings", {}], ["city", {}], ["city_place", {}], ["analytics", {}]]
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

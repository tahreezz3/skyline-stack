## Integration check / optional rendered gallery, without writing the player's save.
## godot --headless --path game --script res://tools/theme_tour.gd
## godot --path game --script res://tools/theme_tour.gd -- --screenshots=/tmp/themes
extends SceneTree

var failures := 0
var screenshot_dir := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			screenshot_dir = arg.get_slice("=", 1)
			DirAccess.make_dir_recursive_absolute(screenshot_dir)
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("THEME_TOUR FAILED ", label)


func _frame() -> void:
	await process_frame
	if not screenshot_dir.is_empty():
		await RenderingServer.frame_post_draw


func _capture(name: String) -> void:
	if not screenshot_dir.is_empty():
		await _frame()
		root.get_texture().get_image().save_png(screenshot_dir.path_join(name + ".png"))


func _click(router: Node, at: Vector2) -> void:
	# Desktop hover state follows mouse motion; include it before the press/release.
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)
	await _frame()
	await router._click(at)


func _run() -> void:
	await process_frame
	var router := root.get_node("SceneRouter")
	root.size = Vector2i(720, 1280)
	# Keep popup input in this viewport on desktop as well as in headless runs.
	root.gui_embed_subwindows = true
	var save := root.get_node("SaveData")
	var config := root.get_node("GameConfig")
	save.persist = false
	# Layout must work even when the new player has not unlocked any other family.
	save.data["stats"]["lifetime_population"] = 0
	await router.go("select")
	await _frame()
	var selector: OptionButton = current_scene.get_node("ThemeSelector") if current_scene.has_node("ThemeSelector") else current_scene.find_child("ThemeSelector", true, false)
	check(selector != null and selector.item_count == 10, "selector exposes all ten free cosmetics")
	await _capture("selection")
	# The menu must fit a narrow portrait viewport too, including the longest localized names.
	root.size = Vector2i(600, 1280)
	await _frame()
	check(Rect2(Vector2.ZERO, current_scene.size).encloses(selector.get_global_rect()), "theme selector fits narrow portrait")
	await _capture("selection_narrow")
	root.size = Vector2i(720, 1280)
	await create_timer(0.2).timeout
	await _frame()
	# Open the real option control and select the last item with a real mouse/touch click.
	await _click(router, selector.get_global_rect().get_center())
	await _frame()
	var popup := selector.get_popup()
	# The popup has ten equally sized rows. Click the centre of its final row.
	var click := Vector2(popup.position) + Vector2(popup.size.x * 0.5, popup.size.y - popup.size.y / 20.0)
	await _click(router, click)
	await _frame()
	await _frame()
	check(router.selected_theme == "v010", "real selector input changes theme")
	# Starting a tower through a real click must carry the chosen cosmetic into the round.
	var play: Button
	for button in current_scene.find_children("*", "Button", true, false):
		if button != selector and not button.disabled and button.custom_minimum_size.y == 100:
			play = button
			break
	check(play != null, "unlocked tower start button exists")
	if play:
		await _click(router, play.get_global_rect().get_center())
		var waited := 0.0
		while not current_scene.has_method("_on_tap") and waited < 2.0:
			await create_timer(0.05).timeout
			waited += 0.05
		check(current_scene.has_method("_on_tap") and current_scene.visual_theme["id"] == "v010", "selection reaches game via a real click (scene=%s)" % current_scene.scene_file_path)

	# A click starts an asynchronous fade; let it finish before requesting the next round.
	while router._busy:
		await _frame()
	if "--input-only" in OS.get_cmdline_user_args():
		await router.go("menu")
		print("THEME_INPUT_DONE failures=", failures)
		quit(0 if failures == 0 else 1)
		return

	for theme in config.table("themes")["themes"]:
		router.selected_theme = theme["id"]
		await router.go("game", {"block_type": "blue"})
		await _frame()
		var game := current_scene
		game.set_process(false)
		check(game.visual_theme["id"] == theme["id"], "round uses " + theme["id"])
		await _capture(theme["id"] + "_ground")
		# Populate a deterministic six-floor preview without advancing the live simulation.
		for i in range(6):
			game.state.land(0.0)
		game.view_y = game._desired_view_y()
		game.view3d.sync(0.0)
		game._refresh_hud()
		check(game.view3d.carried.mesh == game.view3d.storey_mesh, "active module uses matching storey mesh")
		check(game.view3d.tower_nodes.size() == 6, "all placed modules render")
		check(game.round_hud.population.text == "00024" and game.round_hud.badge.text == "6", "population and floor counter stay synchronized")
		await _capture(theme["id"])
		# One release can resolve only once, even if another falling update follows immediately.
		var before: int = game.state.height()
		game.falling = {"x": game.state.top_x(), "y": game._top_y(), "vy": 0.0, "missed": false, "miss_x": 0.0}
		game._update_falling(0.0)
		game._update_falling(0.0)
		check(game.state.height() == before + 1 and game.falling.is_empty(), "one resolution per release")
		var lives_before: int = game.state.lives
		game.falling = {"x": 9.0, "y": game._top_y() - float(game.rules["fall_kill_depth"]) - 1.0, "vy": 0.0, "missed": true, "miss_x": 9.0}
		game._update_falling(0.0)
		game._update_falling(0.0)
		check(game.state.lives == lives_before - 1 and game.state.height() == before + 1, "one life deduction per missed release")
		# HUD anchors follow narrow and tall logical viewports.
		for viewport_size in [Vector2i(600, 1280), Vector2i(720, 1600)]:
			# A half-size tall window fits laptop displays while preserving a 720x1600 logical canvas.
			root.size = viewport_size if viewport_size.y <= 1280 else viewport_size / 2
			await _frame()
			game._refresh_hud()
			var hud: Control = game.round_hud
			check(absf(hud.size.x / hud.size.y - float(viewport_size.x) / viewport_size.y) < 0.001, "HUD expands to actual portrait aspect")
			check(hud.meter_rect().end.y <= hud.size.y and hud.meter_rect().position.y > 0, "meter fits portrait")
			for control in [hud.population, hud.badge, hud.pause_button]:
				check(Rect2(Vector2.ZERO, hud.size).encloses(control.get_rect()), "HUD control stays within viewport")
			if theme["id"] == "v010":
				await _capture("v010_%dx%d" % [viewport_size.x, viewport_size.y])
		root.size = Vector2i(720, 1280)
		print("THEME_TOUR ", theme["id"], " checked")
	# Restart retains cosmetic selection and resets the round, without changing save schema.
	await router.go("game", {"block_type": "blue"})
	await _frame()
	check(current_scene.visual_theme["id"] == "v010" and current_scene.state.height() == 0 and current_scene.state.population == 0 and current_scene.state.lives == 3, "restart preserves theme and resets gameplay")
	await _click(router, current_scene.pause_btn.get_global_rect().get_center())
	await _frame()
	check(current_scene.paused and paused, "anchored pause button works through a real click")
	await router.go("menu")
	print("THEME_TOUR_DONE failures=", failures)
	quit(0 if failures == 0 else 1)

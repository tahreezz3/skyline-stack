## Deterministic live-environment integration checks and optional native animation export.
## godot --headless --path game --script res://tools/background_motion_tour.gd
## godot --path game --script res://tools/background_motion_tour.gd -- --screenshots=/tmp/motion --frames=72
extends SceneTree
var failures := 0
var screenshot_dir := ""
var frames := 0
var fps := 12.0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			screenshot_dir=arg.get_slice("=",1)
			DirAccess.make_dir_recursive_absolute(screenshot_dir)
		if arg.begins_with("--frames="):
			frames=int(arg.get_slice("=",1))
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	if not ok:
		failures+=1
		printerr("BACKGROUND_MOTION FAILED ",label)


func _frame() -> void:
	await process_frame
	if not screenshot_dir.is_empty():
		await RenderingServer.frame_post_draw


func _pixels() -> PackedByteArray:
	return root.get_texture().get_image().get_data()


func _capture(name: String) -> void:
	if not screenshot_dir.is_empty():
		root.get_texture().get_image().save_png(screenshot_dir.path_join(name+".png"))


func _run() -> void:
	await process_frame
	root.size=Vector2i(405,720)
	root.get_node("SaveData").persist=false
	var router := root.get_node("SceneRouter")
	var config := root.get_node("GameConfig")
	for theme in config.table("themes")["themes"]:
		router.selected_theme=theme["id"]
		await router.go("game",{"block_type":"blue"})
		var game := current_scene
		game.set_process(false)
		for i in range(6):
			game.state.land(0.0)
		game.view_y=game._desired_view_y()
		game._refresh_hud()
		var view = game.view3d
		view._update_background(600.0) # settle depth exactly before testing independent motion
		view.background_motion.elapsed=0.0
		view.sync(0.0)
		await _frame()
		await _frame()
		var before: float=view.background_motion.elapsed
		var fixed_depth: Vector2=view.background_motion.depth
		var actor_first: Array = view.world_environment.actor_signature()
		var first := PackedByteArray()
		if not screenshot_dir.is_empty():
			first=_pixels()
			actor_first=view.world_environment.actor_signature()
		view.sync(4.0)
		await _frame()
		check(view.background_motion.depth==fixed_depth,"motion is independent of camera movement")
		check(is_equal_approx(view.background_motion.elapsed,before+4.0),"live clock advances for "+theme["id"])
		check(view.world_environment.actors.size()>0,"world has independent moving actors")
		if not screenshot_dir.is_empty():
			check(actor_first!=view.world_environment.actor_signature(),"independent world actors animate for "+theme["id"])
			check(first!=_pixels(),"rendered clouds/water/actors visibly change for "+theme["id"])
			_capture(theme["id"]+"_live")
		# Exercise the actual pause flow, then call renderer sync defensively while paused.
		game.pause_game()
		check(game.paused and paused,"round pause reaches environment")
		var frozen: float=view.background_motion.elapsed
		var depth: Vector2=view.background_motion.depth
		view.sync(9.0)
		await _frame()
		check(view.background_motion.elapsed==frozen and view.background_motion.depth==depth,"pause freezes time and depth")
		game.paused=false
		paused=false
		game.pause_layer.visible=false
		game.reduced_motion=true
		view.sync(1.0)
		await _frame()
		await _frame()
		var reduced := PackedByteArray()
		if not screenshot_dir.is_empty():
			reduced=_pixels()
		view.sync(3.0)
		await _frame()
		check(view.background_motion.render_time()==0.0 and view.background_motion.depth==Vector2.ZERO,"Reduced Motion disables environment movement")
		check(view.background_motion.elapsed==frozen,"Reduced Motion does not advance the environment clock")
		if not screenshot_dir.is_empty():
			check(reduced==_pixels(),"Reduced Motion produces stable rendered pixels")
		game.reduced_motion=false
		view.sync(1.0)
		check(is_equal_approx(view.background_motion.elapsed,frozen+1.0),"resume has no wall-clock jump")
		# The preview freezes gameplay while stepping only the living environment.
		if frames>0 and not screenshot_dir.is_empty():
			var path := screenshot_dir.path_join(theme["id"])
			DirAccess.make_dir_recursive_absolute(path)
			view.background_motion.elapsed=0.0
			for i in range(frames):
				view.sync(1.0/fps)
				await _frame()
				_capture(theme["id"]+"/frame_%04d"%i)
		print("BACKGROUND_MOTION ",theme["id"]," checked")
	await router.go("menu")
	print("BACKGROUND_MOTION_DONE failures=",failures)
	quit(0 if failures==0 else 1)

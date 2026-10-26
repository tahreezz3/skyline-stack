## Real camera ascent/descent contracts and optional native progression clips.
## --screenshots=/tmp/world --frames=96 --themes=v001,v009,v010
extends SceneTree
var failures := 0
var directory := ""
var frames := 0
var only: PackedStringArray=[]


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			directory=arg.get_slice("=",1)
			DirAccess.make_dir_recursive_absolute(directory)
		if arg.begins_with("--frames="):frames=int(arg.get_slice("=",1))
		if arg.begins_with("--themes="):only=arg.get_slice("=",1).split(",")
	_run.call_deferred()


func check(ok: bool,label: String) -> void:
	if not ok:
		failures+=1
		printerr("WORLD_CLIMB FAILED ",label)


func _clear_preview_focus_pause() -> bool:
	# Export mode steps a frozen game itself. OS focus changes must not cover the
	# footage with a pause menu; actual lifecycle pause is tested by the other tours.
	if current_scene and current_scene.has_method("pause_game") and current_scene.paused:
		current_scene.paused=false
		paused=false
		current_scene.pause_layer.visible=false
		return true
	return false


func frame() -> void:
	await process_frame
	_clear_preview_focus_pause()
	if not directory.is_empty():
		await RenderingServer.frame_post_draw
		if _clear_preview_focus_pause():
			await process_frame
			await RenderingServer.frame_post_draw


func capture(name: String) -> void:
	if not directory.is_empty():root.get_texture().get_image().save_png(directory.path_join(name+".png"))


func _run() -> void:
	await process_frame
	root.size=Vector2i(405,720)
	root.get_node("SaveData").persist=false
	var router := root.get_node("SceneRouter")
	var config := root.get_node("GameConfig")
	for theme in config.table("themes")["themes"]:
		var id: String=theme["id"]
		if not only.is_empty() and not id in only:continue
		router.selected_theme=id
		await router.go("game",{"block_type":"blue","endless":true})
		var game := current_scene
		game.set_process(false)
		var view=game.view3d
		var world=view.world_environment
		game.view_y=0.0
		view.sync(0.0)
		await frame()
		await frame()
		var origin: Vector3=world.ground_anchor.global_position
		var initial_screen: Vector2=view.camera.unproject_position(origin)
		var landmark: Vector3=world.landmarks[0].global_position
		var landmark_screen: Vector2=view.camera.unproject_position(landmark)
		capture(id+"_ground")
		for height in [6,12,20,40]:
			while game.state.height()<height:game.state.land(0.0)
			game.view_y=game._desired_view_y()
			view.sync(0.0)
			game._refresh_hud()
			await frame()
			check(world.ground_anchor.global_position==origin,"ground does not follow camera "+id)
			check(world.landmarks[0].global_position==landmark,"landmark is fixed in world "+id)
			if height>=12:
				check(view.camera.unproject_position(origin).y>root.get_visible_rect().size.y and view.camera.unproject_position(origin).y>initial_screen.y,"ground passes below view with height "+id)
				check(view.camera.unproject_position(landmark).y>landmark_screen.y,"world landmark scrolls down "+id)
			capture(id+"_height_%02d"%height)
		game.view_y=0.0
		view.sync(0.0)
		await frame()
		check(view.camera.unproject_position(origin).distance_to(initial_screen)<.01,"descent restores original ground framing "+id)
		if frames>0 and not directory.is_empty():
			DirAccess.make_dir_recursive_absolute(directory.path_join(id))
			# Rebuild a fresh round, then smoothly follow the real height framing.
			await router.go("game",{"block_type":"blue","endless":true})
			game=current_scene
			game.set_process(false)
			var y := 0.0
			for i in range(frames):
				var target_height := int(24.0*float(i)/maxi(1,frames-1))
				while game.state.height()<target_height:game.state.land(0.0)
				y=lerpf(y,game._desired_view_y(),.18)
				game.view_y=y
				game.view3d.sync(1.0/12.0)
				game._refresh_hud()
				await frame()
				capture(id+"/frame_%04d"%i)
		print("WORLD_CLIMB ",id," checked")
	await router.go("menu")
	print("WORLD_CLIMB_DONE failures=",failures)
	quit(0 if failures==0 else 1)

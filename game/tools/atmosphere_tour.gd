## Actual-round weather/space integration and optional native visual exports.
## --screenshots=/tmp/atmosphere --frames=120 (12 fps, 0..125-floor ascent).
extends SceneTree
const Rules := preload("res://scripts/core/tower_state.gd")
var failures := 0
var directory := ""
var frames := 0
var weather_frames := 0
var testing_pause := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			directory=arg.get_slice("=",1)
			DirAccess.make_dir_recursive_absolute(directory)
		if arg.begins_with("--frames="):frames=int(arg.get_slice("=",1))
		if arg.begins_with("--weather-frames="):weather_frames=int(arg.get_slice("=",1))
	_run.call_deferred()


func check(ok: bool,label: String) -> void:
	if not ok:
		failures+=1
		printerr("ATMOSPHERE FAILED ",label)


func _clear_focus_pause() -> bool:
	# This harness manually steps a frozen game. Actual pause is exercised below.
	if not testing_pause and current_scene and current_scene.has_method("pause_game") and current_scene.paused:
		current_scene.paused=false
		paused=false
		current_scene.pause_layer.visible=false
		return true
	return false


func frame() -> void:
	await process_frame
	_clear_focus_pause()
	if not directory.is_empty():
		await RenderingServer.frame_post_draw
		if _clear_focus_pause():
			await process_frame
			await RenderingServer.frame_post_draw


func capture(filename: String) -> void:
	if not directory.is_empty():root.get_texture().get_image().save_png(directory.path_join(filename+".png"))


func pixels() -> PackedByteArray:
	return root.get_texture().get_image().get_data() if not directory.is_empty() else PackedByteArray()


func rules_signature(state: RefCounted) -> String:
	return JSON.stringify([state.blocks,state.wobble_offsets,state.lives,state.population,state.combo_count,state.combo_time,state.combo_pool,state.is_over,state.is_complete])


func game_signature(game: Node) -> String:
	return JSON.stringify([rules_signature(game.state),game.t,game.crane_x,game.crane_center,game.sway_top,game.falling,game.debris,game.continues_used,game.round_finished])


func _run() -> void:
	await process_frame
	root.size=Vector2i(405,720)
	root.get_node("SaveData").persist=false
	var config := root.get_node("GameConfig")
	var router := root.get_node("SceneRouter")
	var table: Dictionary=config.table("atmosphere")
	var profiles: Array=table["weather"]
	var reference := Rules.new(config.table("tower_rules"))
	var drops := [0.0,0.18,0.05,1.6,0.04,0.07]
	for x in drops:
		reference.land(x)
		reference.tick(.3)
	for profile in profiles:
		# Restrict only the in-memory cosmetic candidate list for deterministic QA.
		# Production configuration and the game's random selection path are untouched.
		table["weather"]=[profile]
		router.selected_theme="v010"
		await router.go("game",{"block_type":"blue","endless":true})
		table["weather"]=profiles
		var game := current_scene
		game.set_process(false)
		var view=game.view3d
		var atmosphere=view.atmosphere
		check(atmosphere.state.weather["id"]==profile["id"],"selected weather reaches actual renderer")
		for x in drops:
			game.state.land(x)
			game.state.tick(.3)
			var signature := game_signature(game)
			view.sync(.3)
			check(signature==game_signature(game),"rendering cannot mutate gameplay: "+profile["id"])
		check(rules_signature(game.state)==rules_signature(reference),"identical inputs give identical outcomes: "+profile["id"])
		game.view_y=0.0
		game._refresh_hud()
		view.background_motion.elapsed=2.8
		view.sync(0.0)
		await frame()
		await frame()
		capture("weather_"+String(profile["id"]))
		var before := pixels()
		view.sync(.6)
		await frame()
		if not directory.is_empty():check(before!=pixels(),"native weather/world motion: "+profile["id"])
		# Pause freezes all shader time, cyclone rotation and planet rotation.
		testing_pause=true
		game.pause_game()
		await frame()
		await frame()
		var clock: float=view.background_motion.elapsed
		before=pixels()
		view.sync(8.0)
		await frame()
		check(view.background_motion.elapsed==clock,"weather pause: "+profile["id"])
		if not directory.is_empty():check(before==pixels(),"native paused pixels: "+profile["id"])
		testing_pause=false
		_clear_focus_pause()
		game.reduced_motion=true
		view.sync(1.0)
		await frame()
		await frame()
		before=pixels()
		view.sync(3.0)
		await frame()
		check(view.background_motion.elapsed==clock,"Reduced Motion freezes cosmetic clock")
		check(atmosphere.weather_material.get_shader_parameter("motion_amount")==0.0,"Reduced Motion suppresses lightning")
		if not directory.is_empty():check(before==pixels(),"native Reduced Motion pixels: "+profile["id"])
		game.reduced_motion=false
		view.sync(.5)
		check(is_equal_approx(view.background_motion.elapsed,clock+.5),"weather resumes without time jump")
		if weather_frames>0 and not directory.is_empty():
			var id: String=profile["id"]
			DirAccess.make_dir_recursive_absolute(directory.path_join(id))
			view.background_motion.elapsed=0.0
			for i in range(weather_frames):
				view.sync(1.0/12.0)
				await frame()
				capture(id+"/frame_%04d"%i)
		game.view_y=float(table["altitude"]["space_end"])
		view.sync(0.0)
		check(not atmosphere.weather_plane.visible,"no precipitation/fog/wind volume in space")
		for cloud in view.world_environment.cloud_nodes:check(not cloud.visible,"no atmospheric clouds in space")
		if atmosphere.cyclone:check(not atmosphere.cyclone.visible,"no cyclone in space")
		print("ATMOSPHERE ",profile["id"]," checked")
	# Use one actual endless round for ascent, geometry anchors and reverse framing.
	table["weather"]=[profiles[1]]
	router.selected_theme="v001"
	await router.go("game",{"block_type":"blue","endless":true})
	table["weather"]=profiles
	var game := current_scene
	game.set_process(false)
	var view=game.view3d
	var anchors: Array=[]
	for p in view.atmosphere.planets:anchors.append(p["node"].global_position)
	var ground: Vector3=view.world_environment.ground_anchor.global_position
	for floors in [0,25,40,55,65,75,90,105,120]:
		while game.state.height()<floors:game.state.land(0.0)
		game.view_y=game._desired_view_y() if floors>0 else 0.0
		view.sync(.25)
		game._refresh_hud()
		await frame()
		for i in range(anchors.size()):check(view.atmosphere.planets[i]["node"].global_position==anchors[i],"planets retain world anchors on ascent")
		check(view.world_environment.ground_anchor.global_position==ground,"space climb never moves ground")
		capture("ascent_%03d"%floors)
		if floors==90:
			testing_pause=true
			game.pause_game()
			await frame()
			await frame()
			var before := pixels()
			view.sync(8.0)
			await frame()
			if not directory.is_empty():check(before==pixels(),"native planets/stars pause in space")
			testing_pause=false
			_clear_focus_pause()
			game.reduced_motion=true
			view.sync(1.0)
			await frame()
			await frame()
			before=pixels()
			view.sync(3.0)
			await frame()
			if not directory.is_empty():check(before==pixels(),"native planets/stars Reduced Motion in space")
			game.reduced_motion=false
	game.view_y=0.0
	view.sync(0.0)
	check(view.atmosphere.amounts["space"]==0.0 and view.atmosphere.weather_plane.visible,"descent restores atmosphere")
	for size in [Vector2i(320,720),Vector2i(450,720)]:
		root.size=size
		view.sync(0.0)
		await frame()
		var aspect := root.get_visible_rect().size.aspect()
		check(is_equal_approx(view.atmosphere.weather_mesh.size.aspect(),aspect),"weather fills resized portrait viewport")
	root.size=Vector2i(405,720)
	if frames>0 and not directory.is_empty():
		await router.go("game",{"block_type":"blue","endless":true})
		game=current_scene
		game.set_process(false)
		DirAccess.make_dir_recursive_absolute(directory.path_join("ascent"))
		var height := 0.0
		for i in range(frames):
			var floors := int(125.0*float(i)/maxi(1,frames-1))
			while game.state.height()<floors:game.state.land(0.0)
			height=lerpf(height,game._desired_view_y(),.3)
			game.view_y=height
			game.view3d.sync(1.0/12.0)
			game._refresh_hud()
			await frame()
			capture("ascent/frame_%04d"%i)
	await router.go("menu")
	print("ATMOSPHERE_DONE failures=",failures)
	quit(0 if failures==0 else 1)

## Living environments must animate independently, pause exactly and respect accessibility.
extends "res://tests/test_case.gd"
const Motion := preload("res://scripts/game/background_motion.gd")
const Actors := preload("res://scripts/game/living_background.gd")
var config: Dictionary


func before_all() -> void:
	config = ConfigLoader.load_json("res://config/background_motion.json")


func test_clock_freezes_on_pause_and_reduced_motion() -> void:
	var clock := Motion.new(config["shared"])
	clock.advance(2.0, false, false, Vector2(1, 10))
	check(near(clock.render_time(),2.0) and clock.depth != Vector2.ZERO,"live environment advances and follows camera depth")
	var depth := clock.depth
	clock.advance(30.0,true,false,Vector2(9,900))
	check(near(clock.render_time(),2.0) and clock.depth == depth,"pause freezes clock and depth even if sync is called")
	clock.advance(30.0,false,true,Vector2(9,900))
	check(near(clock.elapsed,2.0) and near(clock.render_time(),0.0) and clock.depth == Vector2.ZERO,"reduced motion gives a fully stationary environment")
	clock.advance(1.0,false,false,Vector2.ZERO)
	check(near(clock.render_time(),3.0),"resume continues without a wall-clock jump")
	clock.advance(-2.0,false,false,Vector2.ZERO)
	check(near(clock.render_time(),3.0),"negative deltas cannot rewind animation")


func test_depth_is_bounded_and_frame_rate_independent() -> void:
	var whole := Motion.new(config["shared"])
	var frames := Motion.new(config["shared"])
	whole.advance(1.0,false,false,Vector2(1000,1000))
	for i in range(60):
		frames.advance(1.0/60.0,false,false,Vector2(1000,1000))
	check(whole.depth.distance_to(frames.depth)<0.00001 and near(whole.elapsed,frames.elapsed),"animation follows elapsed seconds, not frame count")
	var p: Dictionary = config["shared"]["parallax"]
	check(absf(whole.depth.x)<=p["max_x"] and absf(whole.depth.y)<=p["max_y"],"endless heights cannot expose image edges")


func test_actor_routes_are_deterministic_and_seamless() -> void:
	var actor := {"start":[0.1,0.5],"end":[0.9,0.6],"period":10.0,"phase":0.0}
	var first := Motion.actor_state(actor,0.0,0.12)
	var middle := Motion.actor_state(actor,5.0,0.12)
	var last := Motion.actor_state(actor,10.0,0.12)
	check(first["opacity"]==0.0 and last["opacity"]==0.0,"route loops are hidden by endpoint fades")
	check(middle["position"].distance_to(Vector2(.5,.55))<0.00001 and near(middle["opacity"],1.0),"actor crosses the route independently of tower physics")
	check(first==last,"same animation phase produces identical state")


func test_every_environment_has_distinct_live_detail_and_local_masks() -> void:
	var silhouettes := {}
	for id in config["environments"]:
		var environment: Dictionary = config["environments"][id]
		check(environment["actors"].size()>=3,"every reference environment has independent actors")
		var silhouette := JSON.stringify(environment["sky"])+JSON.stringify(environment["water"])
		check(not silhouettes.has(silhouette),"skyline and shoreline masks are individually fitted")
		silhouettes[silhouette]=true
		var mask := Actors.make_mask(config["shared"],environment).get_image()
		check(mask.get_pixel(mask.get_width()/2,0).r>.9,"clouds have a separate sky layer")
		check(mask.get_pixel(mask.get_width()/2,mask.get_height()-1).g<.01,"water does not spill over foreground construction ground")
		var water_pixels := 0
		for y in range(0,mask.get_height(),8):
			for x in range(0,mask.get_width(),8):
				if mask.get_pixel(x,y).g>.5:
					water_pixels+=1
		check(water_pixels>0,"each environment animates an actual water region")
		for actor in environment["actors"]:
			var start := Motion.actor_state(actor,2.0,float(config["shared"]["actor_fade"]))
			var later := Motion.actor_state(actor,3.0,float(config["shared"]["actor_fade"]))
			check(start["progress"]!=later["progress"],"each live actor advances independently")
	check(config["environments"]["v001"]["actors"][1]["kind"]=="fountain","manor has garden water activity")
	check(config["environments"]["v009"]["actors"][0]["kind"]=="steam","factory has live steam")
	check(config["environments"]["v010"]["actors"][2]["kind"]=="beacon","lighthouse has its own beacon")

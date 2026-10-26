## World scenery contracts: original geometry, anchored landmarks and altitude continuity.
extends "res://tests/test_case.gd"
const World := preload("res://scripts/game/world_environment.gd")
const Models := preload("res://scripts/game/world_environment_kit.gd")
var config: Dictionary


func before_all() -> void:
	config=ConfigLoader.load_json("res://config/environment_world.json")


func test_all_environments_have_distinct_world_landmarks() -> void:
	var signatures := {}
	var kinds := {}
	for id in config["environments"]:
		var profile: Dictionary=config["environments"][id]
		check(profile["features"].size()>=10,id+" has actual scenic objects")
		var signature := JSON.stringify(profile["features"])
		check(not signatures.has(signature),"each theme has its own world layout")
		signatures[signature]=true
		check(profile["actors"].size()>=2,"each world has independent activity")
		for feature in profile["features"]: kinds[feature["kind"]]=true
	for kind in kinds:
		var mesh := Models.model(kind,int(config["shared"]["mesh_sides"]))
		check(mesh.get_surface_count()>0,kind+" is geometry rather than a scenic image")
		var bounds := mesh.get_aabb()
		check(bounds.size.x>0 and bounds.size.y>0 and bounds.size.z>0,kind+" has three-dimensional extent")
		check(bounds.position.is_finite() and bounds.size.is_finite(),"finite scenery bounds")


func test_climbing_never_repositions_ground_or_landmarks() -> void:
	for id in config["environments"]:
		var world := World.new()
		world.setup(id,config)
		var initial: Array=[]
		for anchor in world.landmarks: initial.append(anchor.position)
		var root_position := world.position
		var ground_position := world.ground_anchor.position
		world.update(1.0,30.0,false,false)
		check(world.position==root_position and world.ground_anchor.position==ground_position,"camera climb cannot drag world ground upward")
		for i in range(initial.size()):check(initial[i]==world.landmarks[i].position,"landmarks remain at their actual world heights")
		var high_cloud := world.cloud_nodes[0].position.y
		world.update(0.0,60.0,false,false)
		check(world.cloud_nodes[0].position.y>high_cloud,"upper altitude cloud bands are available at endless heights")
		world.update(0.0,0.0,false,false)
		for i in range(initial.size()):check(initial[i]==world.landmarks[i].position,"descending returns to the same landscape")
		world.free()


func test_world_activity_respects_pause_and_reduced_motion() -> void:
	var world := World.new()
	world.setup("v010",config)
	var first := world.actor_signature()
	world.update(2.0,0.0,false,false)
	check(first!=world.actor_signature(),"boats/birds/beacon animate in the world")
	var frozen := world.actor_signature()
	var elapsed: float=world.clock.elapsed
	world.update(9.0,0.0,true,false)
	check(frozen==world.actor_signature() and world.clock.elapsed==elapsed,"pause freezes world activity")
	world.update(1.0,0.0,false,true)
	var reduced := world.actor_signature()
	world.update(8.0,0.0,false,true)
	check(reduced==world.actor_signature(),"Reduced Motion gives a stable environment")
	check(world.clock.elapsed==elapsed,"paused/reduced time never accumulates")
	world.free()


func test_visible_cloud_identity_survives_pool_boundary() -> void:
	var world := World.new()
	world.setup("v001",config)
	world.update(0.0,4.9,false,false)
	var middle := int(config["shared"]["clouds_per_band"])
	var position := world.cloud_nodes[middle].position
	world.update(0.0,5.1,false,false)
	check(world.cloud_nodes[middle].position==position,"visible clouds do not jump when a higher offscreen band recycles")
	world.free()

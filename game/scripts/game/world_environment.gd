## World-anchored scenery. Camera motion never moves ground, water or landmarks.
## Only offscreen cloud bands recycle; animation uses the paused round clock.
extends Node3D
const Kit := preload("res://scripts/game/building_kit.gd")
const Models := preload("res://scripts/game/world_environment_kit.gd")
const Clock := preload("res://scripts/game/background_motion.gd")
var theme_id := ""
var shared: Dictionary
var profile: Dictionary
var clock: RefCounted
var materials: Dictionary={}
var landmarks: Array[Node3D]=[]
var actors: Array[Dictionary]=[]
var cloud_nodes: Array[MeshInstance3D]=[]
var ground_anchor: Node3D
var water_material: ShaderMaterial
var cloud_material: StandardMaterial3D
var last_cloud_band := -99999


func setup(id: String,config: Dictionary) -> void:
	name="WorldEnvironmentScenery"
	theme_id=id
	shared=config["shared"]
	profile=config["environments"][id]
	clock=Clock.new(shared)
	for slot in profile["colors"]:
		var material := StandardMaterial3D.new()
		material.albedo_color=Color(profile["colors"][slot])
		material.vertex_color_use_as_albedo=true
		material.roughness=.85
		materials[slot]=material
	cloud_material=StandardMaterial3D.new()
	cloud_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_material.albedo_color=Color(profile["colors"]["snow"])
	_build_world()
	_build_water()
	_build_actors()
	_build_clouds()
	update(0.0,0.0,false,false)


func _instance(mesh: Mesh,at: Vector3,parent: Node3D=self) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh=mesh
	node.position=at
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	if mesh is ArrayMesh:
		for i in range(mesh.get_surface_count()):
			node.set_surface_override_material(i,materials.get(mesh.surface_get_name(i),materials["stone"]))
	return node


func _build_world() -> void:
	var b := Kit.Builder.new()
	if profile["water"]=="river":
		var bounds: Array=shared["ground_bounds"]
		b.box("grass",Vector3(bounds[0],bounds[1],bounds[2]),Vector3(bounds[3],bounds[4],bounds[5]))
	else:
		Models.append(b,Models.model("cliff",int(shared["mesh_sides"])),Transform3D(Basis.IDENTITY.scaled(Vector3(2.5,.8,4)),Vector3(0,-.65,.2)))
	for patch in profile["patches"]:
		b.box(patch["material"],_v3(patch["lo"]),_v3(patch["hi"]))
	# Build site is fixed at the gameplay origin, so it leaves the view on ascent.
	var size: Array=shared["foundation_size"]
	b.box("path",Vector3(-size[0]*.5,shared["foundation_y"],-size[2]*.5),Vector3(size[0]*.5,0,size[2]*.5))
	for i in range(9):
		var x := -.85+float(i)*.21
		b.box("stone",Vector3(x,.001,-.85),Vector3(x+.009,.002,.85))
		b.box("stone",Vector3(-.85,.001,x),Vector3(.85,.002,x+.009))
	var cache := {}
	for feature in profile["features"]:
		var kind: String=feature["kind"]
		if not cache.has(kind): cache[kind]=Models.model(kind,int(shared["mesh_sides"]))
		var p := _v3(feature["position"])
		var scale := _v3(feature["size"])
		var basis := Basis(Vector3.UP,deg_to_rad(float(feature["rotation"]))).scaled(scale)
		Models.append(b,cache[kind],Transform3D(basis,p))
		if kind in ["manor","palace","fort","office","igloo","prison","pagoda","refinery","lighthouse"]:
			var anchor := Node3D.new()
			anchor.name=kind+str(landmarks.size())
			add_child(anchor)
			anchor.position=p+Vector3(0,scale.y*.5,0)
			landmarks.append(anchor)
	var scenery_mesh := _instance(b.commit(),Vector3.ZERO)
	scenery_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	ground_anchor=Node3D.new()
	ground_anchor.name="FixedGroundOrigin"
	add_child(ground_anchor)


func _build_water() -> void:
	var plane := PlaneMesh.new()
	var size: Array=shared["water_size"]
	plane.size=Vector2(size[0],size[1])
	plane.subdivide_width=int(shared["mesh_sides"])*2
	plane.subdivide_depth=int(shared["mesh_sides"])*2
	var position := _v3(shared["water_center"])
	if profile["water"]=="river":
		var bounds: Array=shared["river_bounds"]
		plane.size=Vector2(float(bounds[3])-float(bounds[0]),float(bounds[5])-float(bounds[2]))
		position=Vector3((float(bounds[3])+float(bounds[0]))*.5,bounds[4],(float(bounds[5])+float(bounds[2]))*.5)
	water_material=ShaderMaterial.new()
	water_material.shader=load("res://scripts/game/shaders/world_water.gdshader")
	water_material.set_shader_parameter("water_color",Color(profile["colors"]["water"]))
	water_material.set_shader_parameter("wave_amplitude",shared["water_wave_amplitude"])
	water_material.set_shader_parameter("wave_speed",shared["water_wave_speed"])
	water_material.set_shader_parameter("glint",shared["water_glint"])
	_instance(plane,position).material_override=water_material


func _build_actors() -> void:
	for entry in profile["actors"]:
		var kind: String=entry["kind"]
		var root := Node3D.new()
		root.name=kind+str(actors.size())
		add_child(root)
		var b := Kit.Builder.new()
		var children: Array[MeshInstance3D]=[]
		match kind:
			"sailboat", "ferry":
				b.frustum("trunk",Vector3.ZERO,.6,.42,.14,4)
				b.box("white",Vector3(-.45,.12,-.2),Vector3(.45,.18,.2))
				if kind=="sailboat":
					b.frustum("trunk",Vector3(0,.15,0),.018,.018,1.0,6)
					b.tri("white",Vector3(.015,.28,0),Vector3(.015,1.1,0),Vector3(.56,.28,0),Vector3.BACK)
					b.tri("path",Vector3(-.015,.28,0),Vector3(-.48,.28,0),Vector3(-.015,.95,0),Vector3.BACK)
				else:b.box("white",Vector3(-.26,.18,-.17),Vector3(.27,.42,.17))
			"car":
				b.box("red",Vector3(-.5,.03,-.23),Vector3(.5,.23,.23))
				b.box("glass",Vector3(-.2,.23,-.2),Vector3(.25,.4,.2))
				for x in [-.3,.3]:
					for z in [-.24,.24]:b.blob("dark",Vector3(x,.08,z),.12)
			"floe": b.frustum("snow",Vector3.ZERO,.65,.57,.14,7)
			"flag":
				b.frustum("metal",Vector3.ZERO,.025,.025,.95,6)
				var plane := QuadMesh.new()
				plane.size=Vector2(.8,.45)
				var flag := _instance(plane,Vector3(.4,.72,0),root)
				var shader := ShaderMaterial.new()
				shader.shader=load("res://scripts/game/shaders/world_flag.gdshader")
				shader.set_shader_parameter("cloth_color",Color(profile["colors"]["flag"]))
				shader.set_shader_parameter("wind_speed",shared["flag_speed"])
				shader.set_shader_parameter("wind_amplitude",shared["flag_amplitude"])
				flag.material_override=shader
				root.set_meta("flag_material",shader)
			"steam", "fountain", "beacon":
				var count := int(shared["steam_puffs"] if kind=="steam" else shared["fountain_drops"])
				if kind=="beacon":count=1
				for i in range(count):
					var sphere := SphereMesh.new()
					sphere.radius=.5
					sphere.height=1.0
					sphere.radial_segments=8
					sphere.rings=4
					var node := _instance(sphere,Vector3.ZERO,root)
					node.material_override=materials["white" if kind=="steam" else "gold" if kind=="beacon" else "water"]
					children.append(node)
			"birds":
				for x in [-.8,0.0,.8]:
					b.tri("dark",Vector3(x,0,0),Vector3(x-.45,.2,-.1),Vector3(x-.2,0,.1),Vector3.UP)
					b.tri("dark",Vector3(x,0,0),Vector3(x+.2,0,.1),Vector3(x+.45,.2,-.1),Vector3.UP)
		if not b.order.is_empty():_instance(b.commit(),Vector3.ZERO,root)
		root.scale=Vector3.ONE*float(entry["size"])
		root.position=_v3(entry["start"])
		actors.append({"node":root,"entry":entry,"children":children})


func _build_clouds() -> void:
	var b := Kit.Builder.new()
	for p in [Vector3(-.4,0,0),Vector3(0,.12,0),Vector3(.4,0,0)]:
		Models._dome(b,"snow",p,.45,.4,int(shared["mesh_sides"]))
	var mesh := b.commit()
	for i in range(int(shared["cloud_bands"])*int(shared["clouds_per_band"])):
		var cloud := _instance(mesh,Vector3.ZERO)
		cloud.material_override=cloud_material
		cloud.scale=_v3(shared["cloud_size"])
		cloud_nodes.append(cloud)


func update(delta: float,camera_height: float,paused: bool,reduced: bool) -> void:
	clock.advance(delta,paused,reduced,Vector2.ZERO)
	var t: float=clock.render_time()
	water_material.set_shader_parameter("scene_seconds",t)
	water_material.set_shader_parameter("motion_amount",0.0 if reduced else 1.0)
	var band := floori(camera_height/float(shared["cloud_gap"]))-1
	last_cloud_band=band
	for i in range(cloud_nodes.size()):
		var row := band+i/int(shared["clouds_per_band"])
		var column := i%int(shared["clouds_per_band"])
		var shift := sin(float(row*7+column*11))*1.7
		var width := float(shared["cloud_width"])
		var x := fposmod(column*width/float(shared["clouds_per_band"])+shift+t*float(shared["cloud_speed"])+width*.5,width)-width*.5
		var slot := posmod(row,int(shared["cloud_bands"]))*int(shared["clouds_per_band"])+column
		cloud_nodes[slot].position=Vector3(x,row*float(shared["cloud_gap"])+float(shared["cloud_projection_bias"]),float(shared["cloud_depth"])-column*float(shared["cloud_depth_step"]))
	for actor in actors:
		var e: Dictionary=actor["entry"]
		var node: Node3D=actor["node"]
		var p := fposmod(t/float(e["period"])+float(e["phase"]),1.0)
		node.position=_v3(e["start"]).lerp(_v3(e["end"]),p)
		match String(e["kind"]):
			"sailboat", "ferry", "floe":
				node.position.y+=sin(t*float(shared["boat_bob_speed"])+p*TAU)*float(shared["boat_bob"])
				node.rotation.z=sin(t+p*TAU)*float(shared["boat_roll_amplitude"])
			"birds":node.rotation.z=sin(t*float(shared["bird_flap_speed"]))*float(shared["bird_roll_amplitude"])
			"steam":
				for i in range(actor["children"].size()):
					var q := fposmod(p+float(i)/actor["children"].size(),1.0)
					var puff: Node3D=actor["children"][i]
					puff.position=Vector3(q*float(shared["steam_drift"]),q*float(shared["steam_rise"]),sin(q*TAU)*float(shared["steam_wobble"]))
					puff.scale=Vector3.ONE*float(shared["steam_radius"])*(.8+q*2.5)*sin(q*PI)
			"fountain":
				for i in range(actor["children"].size()):
					var q := fposmod(p+float(i)/actor["children"].size(),1.0)
					var angle: float = TAU*float(i)/actor["children"].size()
					var drop: Node3D=actor["children"][i]
					drop.position=Vector3(cos(angle)*q*.35,4*q*(1-q)*float(shared["fountain_height"]),sin(angle)*q*.35)
					drop.scale=Vector3.ONE*.04
			"flag":node.get_meta("flag_material").set_shader_parameter("scene_seconds",t)
			"beacon":
				actor["children"][0].scale=Vector3.ONE*(.08+pow(maxf(0,cos(p*TAU)),12)*.4)


func actor_signature() -> Array:
	var signature: Array=[]
	for actor in actors:
		var node: Node3D=actor["node"]
		signature.append(node.transform)
		for child in actor["children"]:signature.append(child.transform)
	return signature


static func _v3(a: Array) -> Vector3:
	return Vector3(a[0],a[1],a[2])

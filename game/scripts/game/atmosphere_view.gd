## Cosmetic atmosphere. No reference to rules, input, save data or physics.
## Cyclones and planets are world anchored; only the infinite weather volume
## follows the camera, with height fed to its particle field for spatial continuity.
extends Node3D
const State := preload("res://scripts/game/atmosphere_state.gd")
const Kit := preload("res://scripts/game/building_kit.gd")
const Models := preload("res://scripts/game/world_environment_kit.gd")
var state: RefCounted
var sky: ShaderMaterial
var weather_material: ShaderMaterial
var weather_mesh: QuadMesh
var weather_plane: MeshInstance3D
var cyclone: Node3D
var planets: Array[Dictionary]=[]
var amounts: Dictionary


func setup(config: Dictionary,camera: Camera3D,sky_material: ShaderMaterial) -> void:
	name="CosmeticAtmosphere"
	var visual_seed := -1
	var forced_weather := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--visual-seed="):visual_seed=int(arg.get_slice("=",1))
		if arg.begins_with("--weather="):forced_weather=arg.get_slice("=",1)
	state=State.new(config,visual_seed,forced_weather)
	sky=sky_material
	for key in config["sky"]:
		var value=config["sky"][key]
		sky.set_shader_parameter(key,Color(value) if value is String else value)
	sky.set_shader_parameter("weather_tint",Color(state.weather["tint"]))
	sky.set_shader_parameter("weather_tint_amount",state.weather["tint_amount"])
	weather_material=ShaderMaterial.new()
	weather_material.shader=load("res://scripts/game/shaders/world_weather.gdshader")
	for key in ["rain","snow","wind","fog","storm"]:
		weather_material.set_shader_parameter(key,state.weather[key])
	for key in config["effects"]:
		if key in ["depth","overscan"]:continue
		var value=config["effects"][key]
		weather_material.set_shader_parameter(key,Vector2(value[0],value[1]) if value is Array else value)
	weather_mesh=QuadMesh.new()
	weather_plane=_mesh(weather_mesh,weather_material,camera)
	weather_plane.name="DistantWeatherVolume"
	weather_plane.position.z=-float(config["effects"]["depth"])
	_build_planets()
	_build_cyclone()


func _mesh(mesh: Mesh,material: Material,parent: Node3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color=color
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo=true
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	return material


func _build_planets() -> void:
	var config: Dictionary=state.config["planet_mesh"]
	for entry in state.config["planets"]:
		var root := Node3D.new()
		root.name=String(entry["kind"])+"WorldPlanet"
		root.position=_v3(entry["position"])
		add_child(root)
		var sphere := SphereMesh.new()
		sphere.radius=float(entry["radius"])
		sphere.height=sphere.radius*2.0
		sphere.radial_segments=int(config["segments"])
		sphere.rings=int(config["rings"])
		var material := ShaderMaterial.new()
		material.shader=load("res://scripts/game/shaders/world_planet.gdshader")
		material.set_shader_parameter("planet_color",Color(entry["color"]))
		material.set_shader_parameter("accent",Color(entry["accent"]))
		material.set_shader_parameter("kind",["earth","gas","moon"].find(entry["kind"]))
		var body := _mesh(sphere,material,root)
		if entry["ring"]:
			var b := Kit.Builder.new()
			for i in range(int(config["segments"])):
				var a := TAU*float(i)/float(config["segments"])
				var c := TAU*float(i+1)/float(config["segments"])
				var inner := float(entry["radius"])*float(config["ring_inner"])
				var outer := float(entry["radius"])*float(config["ring_outer"])
				for band in range(4):
					var r0 := lerpf(inner,outer,float(band)/4.0)
					var r1 := lerpf(inner,outer,(float(band)+.8)/4.0)
					b.color=Color.WHITE*(.75+float(band)*.08)
					b.quad("ring",Vector3(cos(a)*r0,0,sin(a)*r0),Vector3(cos(a)*r1,0,sin(a)*r1),Vector3(cos(c)*r1,0,sin(c)*r1),Vector3(cos(c)*r0,0,sin(c)*r0),Vector3.UP)
			var ring := _mesh(b.commit(),_flat(Color(config["ring_color"])),root)
			ring.rotation_degrees=Vector3(float(config["ring_tilt"]),0,-float(config["ring_tilt"]))
		planets.append({"node":root,"body":body,"entry":entry})


func _build_cyclone() -> void:
	var kind: String=state.weather["cyclone"]
	if kind=="none":return
	var c: Dictionary=state.config["cyclone"]
	cyclone=Node3D.new()
	cyclone.name="Distant"+kind.capitalize()
	cyclone.position=_v3(c["position"])
	add_child(cyclone)
	var b := Kit.Builder.new()
	var bands := int(c["bands"])
	var segments := int(c["segments"])
	if kind=="tornado":
		# Faceted tapered column, with a bent axis and layered cloud skirts.
		for i in range(bands):
			var p := float(i)/bands
			var radius := .07+pow(p,1.5)*.65
			b.color=Color.WHITE*(.7+p*.3)
			b.frustum("cloud",Vector3(sin(p*5.0)*.13,p,0),radius,radius*1.12,1.0/bands*1.1,segments)
		cyclone.scale=_v3(c["tornado_size"])
	else:
		# Two spiral cloud arms around an open eye; a 3D disc, not a storm image.
		for arm in range(2):
			for i in range(bands):
				var p := float(i)/bands
				var a := p*TAU*1.25+arm*PI
				var r := .25+p*.9
				b.color=Color.WHITE*(.8+p*.2)
				Models._orb(b,"cloud",Vector3(cos(a)*r,.05*sin(p*PI),sin(a)*r),.13+p*.16,segments)
		cyclone.scale=_v3(c["hurricane_size"])
	var material := _flat(Color(c["color"]))
	material.shading_mode=BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness=1.0
	var model := _mesh(b.commit(),material,cyclone)
	model.name="SwirlingCloudGeometry"
	if kind=="hurricane":cyclone.rotation_degrees.x=float(c["hurricane_tilt"])


func update(scene_seconds: float,height: float,reduced: bool,aspect: float,view_units: float) -> void:
	amounts=state.sample(height)
	sky.set_shader_parameter("upper_amount",amounts["upper"])
	sky.set_shader_parameter("space_amount",amounts["space"])
	sky.set_shader_parameter("weather_amount",amounts["weather"])
	weather_material.set_shader_parameter("scene_seconds",scene_seconds)
	weather_material.set_shader_parameter("altitude",height)
	weather_material.set_shader_parameter("weather_amount",amounts["weather"])
	weather_material.set_shader_parameter("viewport_aspect",aspect)
	weather_material.set_shader_parameter("motion_amount",0.0 if reduced else 1.0)
	weather_plane.visible=float(amounts["weather"])>0.0
	weather_mesh.size=Vector2(view_units*aspect,view_units)*float(state.config["effects"]["overscan"])
	if cyclone:
		cyclone.visible=float(amounts["weather"])>0.0
		var model: MeshInstance3D=cyclone.get_child(0)
		model.rotation.y=scene_seconds*float(state.config["cyclone"]["rotation_speed"])
		model.transparency=1.0-float(amounts["weather"])
	for planet in planets:
		planet["node"].visible=float(amounts["space"])>0.0
		for child in planet["node"].get_children():child.transparency=1.0-float(amounts["space"])
		planet["body"].rotation.y=scene_seconds*float(planet["entry"]["rotation_speed"])


static func _v3(a: Array) -> Vector3:
	return Vector3(a[0],a[1],a[2])

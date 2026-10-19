## Low-poly 3D presentation of a tower round (ADR-0006, T-0305/T-0306).
## A locked orthographic camera looks at a 2D playfield (everything gameplay-related
## lives on z = 0, in rules units), pitched slightly down so block tops show.
## This node only *reads* the TowerGame each frame; it never changes game state.
##
## Placeholder meshes come from low_poly.gd; delivered .glb files replace them in T-0301.
extends Node3D

const LowPoly := preload("res://scripts/game/low_poly.gd")

const PITCH_DEG := 14.0
const CAM_DIST := 20.0             # ortho: distance doesn't change size; closer keeps the shadow range tight
const VIEW_UNITS := 8.0            # visible world height (1280 px / 160 px per unit)
const CENTER_ABOVE_VIEW := 3.0     # same layout as the 2D view: ground 3 units below screen centre
const PX_TO_UNITS := 1.0 / 160.0
const MAX_SHARDS := 256

## Sky keyframes by height: [top colour, bottom colour, sun colour, sun energy, ambient energy]
const SKY_DAY := [Color("#4f9cf5"), Color("#cfe6ff"), Color("#fff1dc"), 1.05, 0.38]
const SKY_DUSK := [Color("#36398a"), Color("#ff9a66"), Color("#ffa866"), 0.85, 0.3]
const SKY_NIGHT := [Color("#070b24"), Color("#27306b"), Color("#9fb4ff"), 0.35, 0.22]

var game: Node2D
var block_h := 0.6

var camera: Camera3D
var sun: DirectionalLight3D
var env: Environment
var backdrop_mat: ShaderMaterial

var storey_mesh: ArrayMesh
var mat_body: StandardMaterial3D
var mat_trim: StandardMaterial3D
var mat_glass: StandardMaterial3D
var mat_emissive: StandardMaterial3D
var mat_gold: StandardMaterial3D
var mat_dust: StandardMaterial3D
var mat_spark: StandardMaterial3D

var tower_nodes: Array[MeshInstance3D] = []
var debris_nodes: Array[MeshInstance3D] = []
var crane_pivot: Node3D
var carried: MeshInstance3D
var rope: MeshInstance3D
var falling_node: MeshInstance3D
var roof_node: MeshInstance3D
var layers: Array[Dictionary] = []      # {node, mat, base: Color, haze, parallax, z, horizon}
var clouds: Array[Dictionary] = []      # {node, speed}
var rings: Array[Dictionary] = []       # {node, mat, age}
var dust_mm: MultiMesh
var spark_mm: MultiMesh

var last_crane_x := 0.0
var swing := 0.0
var cam_y := 0.0
var night := 0.0
var combo_glow := 0.0          # eased 0..1; never switched instantly (instant changes read as flicker)
var combo_target := 0.0


func setup(p_game: Node2D) -> void:
	game = p_game
	block_h = float(game.rules["block"]["height"])
	_build_materials()
	_build_camera_and_light()
	_build_environment_layers()
	_build_actors()
	GameEvents.block_resolved.connect(_on_block_resolved)
	GameEvents.combo_progress.connect(func(count: int, _rate: float) -> void: combo_target = 1.0 if count > 0 else 0.0)


# --- construction -------------------------------------------------------------

func _lit(colour: Color, rough := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = rough
	m.metallic = 0.0
	return m


func _glow(colour: Color, energy: float) -> StandardMaterial3D:
	var m := _lit(colour)
	m.emission_enabled = true
	m.emission = colour
	m.emission_energy_multiplier = energy
	return m


func _build_materials() -> void:
	var family := Color(game.block_type["colour"])
	mat_body = _lit(family)
	mat_trim = _lit(family.lightened(0.22))
	mat_glass = _glow(Color("#22304a"), 0.0)
	mat_glass.emission = Color("#ffd27a")
	mat_glass.roughness = 0.25
	mat_emissive = _glow(Color("#ff5a4a"), 2.5)       # antenna lights
	mat_gold = _glow(Color("#f2c14e"), 0.6)
	mat_gold.metallic = 0.4
	mat_gold.roughness = 0.4
	mat_dust = _lit(Color("#e7e2d6"))
	mat_spark = _glow(Color("#ffd75e"), 4.0)
	mat_spark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	storey_mesh = LowPoly.storey(block_h)


func _build_camera_and_light() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = VIEW_UNITS
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 0.5
	camera.far = 260.0
	camera.rotation_degrees = Vector3(-PITCH_DEG, 0, 0)
	add_child(camera)
	camera.current = true

	# Backdrop: a gradient quad parented to the camera so it always fills the view.
	var quad := QuadMesh.new()
	quad.size = Vector2(16, 16)
	backdrop_mat = ShaderMaterial.new()
	backdrop_mat.shader = load("res://scripts/game/shaders/sky_backdrop.gdshader")
	var backdrop := MeshInstance3D.new()
	backdrop.mesh = quad
	backdrop.material_override = backdrop_mat
	backdrop.position = Vector3(0, 0, -240)
	backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera.add_child(backdrop)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	# Stable, crisp shadows: split shadow maps are stabilised against camera movement, a short
	# range keeps texels small, and crisp edges fit the low-poly style (no shimmering soft fringe).
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 36.0
	sun.directional_shadow_split_1 = 0.5
	sun.directional_shadow_blend_splits = true
	sun.shadow_blur = 0.6   # light softening antialiases small contact shadows
	sun.shadow_bias = 0.15
	sun.shadow_normal_bias = 3.0
	add_child(sun)
	sun.look_at_from_position(Vector3(-4, 9, 7), Vector3.ZERO)

	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY_DAY[1]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#bcd4ff")
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR   # keeps the flat colours saturated
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0
	we.environment = env
	add_child(we)


func _add_layer(mesh: Mesh, colour: Color, z: float, horizon: float, parallax: float, haze: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := _lit(colour, 1.0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	layers.append({"node": mi, "mat": m, "base": colour, "haze": haze, "parallax": parallax, "z": z, "horizon": horizon})


func _build_environment_layers() -> void:
	# far to near; horizon = world y (at z = 0 framing) where the layer's base sits on screen
	_add_layer(LowPoly.ridge(90.0, 18, 3.0, 7.5, 11, 1.5), Color("#7088b0"), -70.0, -1.0, 0.85, 0.7)
	_add_layer(LowPoly.skyline(60.0, 23), Color("#5f6f92"), -45.0, -0.9, 0.7, 0.5)
	_add_layer(LowPoly.ridge(70.0, 22, 1.2, 3.6, 37, 1.0), Color("#5c8a58"), -25.0, -0.4, 0.4, 0.22)

	var plaza := MeshInstance3D.new()
	plaza.mesh = LowPoly.plaza(60.0)
	plaza.set_surface_override_material(0, _lit(Color("#6fa25f")))
	plaza.set_surface_override_material(1, _lit(Color("#b8b2a6")))
	plaza.set_surface_override_material(2, _lit(Color("#8b909b")))
	add_child(plaza)
	var tree_mesh := LowPoly.tree(1.0)
	var lamp_mesh := LowPoly.lamp()
	var leaf := _lit(Color("#4f8f4a"))
	var bark := _lit(Color("#8a6243"))
	var steel := _lit(Color("#5d6470"))
	for spot in [Vector3(-1.75, 0, -2.0), Vector3(-2.15, 0, -0.9), Vector3(1.8, 0, -2.3), Vector3(2.1, 0, -1.0), Vector3(-1.2, 0, -3.4), Vector3(1.3, 0, -3.6)]:
		var tr := MeshInstance3D.new()
		tr.mesh = tree_mesh
		tr.set_surface_override_material(0, bark)
		tr.set_surface_override_material(1, leaf)
		tr.position = spot
		tr.scale = Vector3.ONE * (0.9 + 0.25 * absf(sin(spot.x * 3.1)))
		add_child(tr)
	for lx in [-1.4, 1.4]:
		var l := MeshInstance3D.new()
		l.mesh = lamp_mesh
		l.set_surface_override_material(0, steel)
		l.set_surface_override_material(1, mat_glass)   # lamps light up with the windows
		l.position = Vector3(lx, 0, 0.7)
		add_child(l)

	var cloud_mat := _glow(Color("#ffffff"), 0.12)        # slightly self-lit so clouds stay soft at dusk
	cloud_mat.roughness = 1.0
	for i in range(7):
		var c := MeshInstance3D.new()
		c.mesh = LowPoly.cloud(100 + i)
		c.material_override = cloud_mat
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		c.position = Vector3(-6.0 + fmod(i * 4.3, 12.0), 4.5 + i * 4.2, -30.0 - (i % 3) * 6.0)
		c.scale = Vector3.ONE * (0.55 + (i % 3) * 0.15)
		add_child(c)
		clouds.append({"node": c, "speed": 0.15 + (i % 5) * 0.06})


func _build_actors() -> void:
	crane_pivot = Node3D.new()
	add_child(crane_pivot)
	rope = MeshInstance3D.new()
	var rope_mesh := BoxMesh.new()
	rope_mesh.size = Vector3(0.025, 1.0, 0.025)
	rope.mesh = rope_mesh
	rope.material_override = _lit(Color("#3c4250"))
	crane_pivot.add_child(rope)
	var hook := MeshInstance3D.new()
	hook.mesh = LowPoly.hook()
	hook.material_override = _lit(Color("#f2b632"), 0.5)
	hook.position = Vector3(0, 0.02, 0)
	crane_pivot.add_child(hook)
	carried = _make_block()
	crane_pivot.add_child(carried)
	falling_node = _make_block()
	add_child(falling_node)

	dust_mm = _make_shards(mat_dust)
	spark_mm = _make_shards(mat_spark)


func _make_block() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = storey_mesh
	mi.set_surface_override_material(0, mat_body)
	mi.set_surface_override_material(1, mat_trim)
	mi.set_surface_override_material(2, mat_glass)
	return mi


func _make_shards(mat: Material) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = LowPoly.shard()
	mm.instance_count = MAX_SHARDS
	mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mm


# --- events -------------------------------------------------------------------

func _on_block_resolved(ev: Dictionary) -> void:
	if ev["result"] == "perfect":
		var mi := MeshInstance3D.new()
		mi.mesh = LowPoly.ring(0.6, 0.06, 20)
		var m := _glow(Color("#ffd75e"), 3.0)
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(float(ev["x"]), (int(ev["height"]) - 0.5) * block_h, 0.6)
		add_child(mi)
		rings.append({"node": mi, "mat": m, "age": 0.0})
	if ev.get("complete", false):
		roof_node = MeshInstance3D.new()
		var trophy := bool(ev.get("star", false))
		roof_node.mesh = LowPoly.roof(trophy)
		roof_node.set_surface_override_material(0, mat_gold if trophy else mat_trim)
		roof_node.set_surface_override_material(1, mat_gold if trophy else mat_body)
		roof_node.set_surface_override_material(2, mat_spark if trophy else mat_emissive)
		add_child(roof_node)


# --- per frame ------------------------------------------------------------------

## Screen position (canvas pixels) of a playfield point, for 2D popups.
func world_to_screen(x: float, y: float) -> Vector2:
	return camera.unproject_position(Vector3(x, y, 0))


func sync(delta: float) -> void:
	var st = game.state
	_update_camera(delta)
	_update_time_of_day(delta)
	_update_tower(st)
	_update_crane(st, delta)
	_update_debris()
	_update_particles()
	_update_rings(delta)
	_update_clouds(delta)


func _update_camera(_delta: float) -> void:
	cam_y = float(game.view_y) + CENTER_ABOVE_VIEW
	var shake: Vector2 = game.shake_offset * PX_TO_UNITS
	var target := Vector3(shake.x, cam_y + float(game.kick) * PX_TO_UNITS - shake.y, 0)
	var back := Vector3(0, sin(deg_to_rad(PITCH_DEG)), cos(deg_to_rad(PITCH_DEG))) * CAM_DIST
	camera.position = target + back
	# background layers: placed so their base sits on the horizon, then drift up slower than the camera
	var tan_p := tan(deg_to_rad(PITCH_DEG))
	for l in layers:
		var n: MeshInstance3D = l["node"]
		n.position = Vector3(0, float(l["horizon"]) + float(l["z"]) * tan_p + (cam_y - CENTER_ABOVE_VIEW) * float(l["parallax"]), float(l["z"]))


func _sky(k: int) -> Variant:
	# blend day -> dusk -> night by `night` (0..1)
	if night < 0.5:
		return _lerp_any(SKY_DAY[k], SKY_DUSK[k], night * 2.0)
	return _lerp_any(SKY_DUSK[k], SKY_NIGHT[k], (night - 0.5) * 2.0)


func _lerp_any(a: Variant, b: Variant, w: float) -> Variant:
	if a is Color:
		return (a as Color).lerp(b, w)
	return lerpf(float(a), float(b), w)


func _update_time_of_day(delta: float) -> void:
	var target := clampf((cam_y - 9.0) / 20.0, 0.0, 1.0)
	night = lerpf(night, target, minf(1.0, delta * 1.5))
	combo_glow = move_toward(combo_glow, combo_target, delta * 2.5)   # ~0.4 s fade in/out
	var top: Color = _sky(0)
	var bottom: Color = _sky(1)
	backdrop_mat.set_shader_parameter("top_color", top)
	backdrop_mat.set_shader_parameter("bottom_color", bottom)
	backdrop_mat.set_shader_parameter("stars", clampf((night - 0.55) * 2.2, 0.0, 1.0))
	env.background_color = bottom
	sun.light_color = _sky(2)
	sun.light_energy = _sky(3)
	env.ambient_light_energy = _sky(4)
	env.ambient_light_color = Color("#bcd4ff").lerp(bottom, 0.4)
	# combo adds a gentle warm glow, weaker by day so windows don't flash gold in sunlight
	mat_glass.emission_energy_multiplier = clampf((night - 0.3) * 3.5, 0.0, 2.6) + combo_glow * lerpf(0.18, 0.5, night)
	for l in layers:
		(l["mat"] as StandardMaterial3D).albedo_color = (l["base"] as Color).lerp(bottom, float(l["haze"])).darkened(night * 0.45)


func _update_tower(st) -> void:
	var count: int = st.blocks.size() - 1
	while tower_nodes.size() < count:
		var mi := _make_block()
		add_child(mi)
		tower_nodes.append(mi)
	while tower_nodes.size() > count:
		tower_nodes.pop_back().queue_free()
	var h := maxi(1, count)
	var sway: float = game.sway_top
	for i in range(count):
		var b: Dictionary = st.blocks[i + 1]
		var k := float(i + 1) / h
		var node := tower_nodes[i]
		node.position = Vector3(float(b["x"]) + sway * k, i * block_h, 0)
		node.rotation = Vector3(0, 0, -sway * 0.06 * k)
		node.scale = Vector3.ONE
	if count > 0 and float(game.squash_t) > 0.0:
		var sq: Dictionary = game.feel["squash"]
		var a := sin(float(game.squash_t) / float(sq["time"]) * PI) * float(sq["amount"])
		tower_nodes[count - 1].scale = Vector3(1.0 + a, 1.0 - a, 1.0 + a)
	if roof_node:
		if count > 0:
			var top_node := tower_nodes[count - 1]
			roof_node.position = top_node.position + Vector3(0, block_h, 0)
			roof_node.rotation = top_node.rotation
		roof_node.visible = count > 0


func _update_crane(st, delta: float) -> void:
	var cx: float = game.crane_x
	var cy: float = game._crane_y()
	var vel := (cx - last_crane_x) / maxf(delta, 0.0001)
	last_crane_x = cx
	swing = lerpf(swing, clampf(-vel * 0.03, -0.12, 0.12), minf(1.0, delta * 6.0))
	crane_pivot.position = Vector3(cx, cy, 0)
	var rope_len := 14.0
	rope.scale = Vector3(1, rope_len, 1)
	rope.position = Vector3(0, rope_len * 0.5 + 0.14, 0)
	# the block hangs from the hook and tilts with the swing around its top centre (visual only)
	var tilt := Basis(Vector3.BACK, swing)
	carried.transform = Transform3D(tilt, tilt * Vector3(0, -block_h, 0))
	carried.visible = game.falling.is_empty() and not st.is_over
	falling_node.visible = not game.falling.is_empty()
	if falling_node.visible:
		falling_node.position = Vector3(float(game.falling["x"]), float(game.falling["y"]), 0)


func _update_debris() -> void:
	var list: Array = game.debris
	while debris_nodes.size() < list.size():
		var mi := _make_block()
		add_child(mi)
		debris_nodes.append(mi)
	while debris_nodes.size() > list.size():
		debris_nodes.pop_back().queue_free()
	for i in range(list.size()):
		var d: Dictionary = list[i]
		var rot := float(d["rot"])
		var basis := Basis.from_euler(Vector3(rot * 0.7, rot * 0.3, rot))   # tumble in 3D
		var centre := Vector3(float(d["x"]), float(d["y"]) + block_h * 0.5, 0.0)
		debris_nodes[i].transform = Transform3D(basis, centre - basis * Vector3(0, block_h * 0.5, 0))


func _update_particles() -> void:
	var nd := 0
	var ns := 0
	for p in game.particles:
		var fade := 1.0 - float(p["age"]) / float(p["life"])
		var size := float(p["size"])
		var spin := float(p["age"]) * 9.0 + size * 10.0
		var pos := Vector3(float(p["x"]), float(p["y"]), 0.55)
		if p["kind"] == "dust" and nd < MAX_SHARDS:
			var s := 0.07 + 0.09 * size * (0.4 + fade)
			dust_mm.set_instance_transform(nd, Transform3D(Basis.from_euler(Vector3(spin, spin * 0.7, 0)).scaled(Vector3.ONE * s), pos))
			nd += 1
		elif p["kind"] == "sparkle" and ns < MAX_SHARDS:
			var s2 := 0.12 * size * fade
			spark_mm.set_instance_transform(ns, Transform3D(Basis.from_euler(Vector3(spin, spin, spin * 0.5)).scaled(Vector3.ONE * s2), pos))
			ns += 1
	dust_mm.visible_instance_count = nd
	spark_mm.visible_instance_count = ns


func _update_rings(delta: float) -> void:
	for r in rings:
		r["age"] = float(r["age"]) + delta
		var k := float(r["age"]) / 0.45
		(r["node"] as Node3D).scale = Vector3.ONE * (1.0 + k * 1.4)
		var c: Color = (r["mat"] as StandardMaterial3D).albedo_color
		c.a = clampf(1.0 - k, 0.0, 1.0)
		(r["mat"] as StandardMaterial3D).albedo_color = c
	for r in rings.filter(func(x): return float(x["age"]) >= 0.45):
		(r["node"] as Node).queue_free()
	rings = rings.filter(func(x): return float(x["age"]) < 0.45)


func _update_clouds(delta: float) -> void:
	for c in clouds:
		var n: Node3D = c["node"]
		n.position.x += float(c["speed"]) * delta
		if n.position.x > 7.0:
			n.position.x = -7.0

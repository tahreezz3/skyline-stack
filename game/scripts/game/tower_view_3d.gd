## Low-poly 3D presentation of a tower round (ADR-0006, T-0314 themes).
## A locked orthographic camera looks at a 2D playfield (everything gameplay-related
## lives on z = 0, in rules units), pitched slightly down. Buildings are turned by
## the configured yaw so two faces show. theme_kit.gd uses the existing mesh
## builder and keeps the visible footprint close to the gameplay width.
## This node only *reads* the TowerGame each frame; it never changes game state.
extends Node3D

const LowPoly := preload("res://scripts/game/low_poly.gd")
const Kit := preload("res://scripts/game/building_kit.gd")
const ThemeKit := preload("res://scripts/game/theme_kit.gd")

const PITCH_DEG := 6.0              # low street-level angle: little foreground (owner feedback, T-0309)
const CAM_DIST := 20.0             # ortho: distance doesn't change size; closer keeps the shadow range tight
const VIEW_UNITS := 6.5            # visible world height: zoomed in so the buildings read (T-0310)
const CENTER_ABOVE_VIEW := 2.75    # ground this far below screen centre: only the street shows below the tower
const PX_TO_UNITS := VIEW_UNITS / 1280.0   # screen pixels -> world units at the current zoom
const MAX_SHARDS := 256

## Sky keyframes by height, cozy lo-fi palette (T-0310): golden hour at the ground,
## pink-violet dusk in the middle, deep indigo night with warm windows at the top.
## [top, bottom, cloud warm, cloud light, cloud amount, sun colour, sun energy, ambient colour, ambient energy]
const SKY_DAY := [Color("#8e9fe6"), Color("#ffc9a3"), Color("#f2a3ad"), Color("#ffe3bf"), 0.8, Color("#ffd7a8"), 1.05, Color("#b9a8e6"), 0.46]
const SKY_DUSK := [Color("#5b4a9f"), Color("#ff9a74"), Color("#d96f8f"), Color("#ffb88a"), 0.75, Color("#ff9f73"), 0.85, Color("#8f78c9"), 0.36]
const SKY_NIGHT := [Color("#15153a"), Color("#3c2f6b"), Color("#3a3366"), Color("#56497f"), 0.35, Color("#a9b0ff"), 0.32, Color("#5b4fa0"), 0.26]

var theme: Dictionary
var theme_config: Dictionary
var game: Node2D
var block_h := 0.6
var yaw := 0.0

var camera: Camera3D
var sun: DirectionalLight3D
var env: Environment
var backdrop_mat: ShaderMaterial

var storey_mesh: ArrayMesh
var base_mesh: ArrayMesh
var mats: Dictionary = {}            # surface name -> material (see building_kit.gd)
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
var rings: Array[Dictionary] = []       # {node, mat, age}
var rim: DirectionalLight3D
var dust_mm: MultiMesh
var spark_mm: MultiMesh

var cam_y := 0.0
var night := 0.0
var combo_glow := 0.0          # eased 0..1; never switched instantly (instant changes read as flicker)
var combo_target := 0.0


func setup(p_game: Node2D) -> void:
	game = p_game
	theme = game.visual_theme
	theme_config = GameConfig.table("themes")
	yaw = deg_to_rad(float(theme_config["geometry"]["yaw_degrees"]))
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
	var p: Dictionary = theme["palette"]
	mats["body"] = _lit(Color(p["body"]))
	mats["body_dark"] = _lit(Color(p["shadow"]))
	mats["body2"] = _lit(Color(p["shadow"]))
	mats["trim"] = _lit(Color(p["trim"]))
	mats["accent"] = _lit(Color(p["accent"]))
	mats["gold"] = _lit(Color(p["gold"]))
	mats["roof"] = _lit(Color(p["shadow"]).darkened(0.15))
	var glass := _glow(Color(p["glass"]), 0.0)
	glass.emission = Color(p["gold"])
	glass.roughness = 0.2
	glass.metallic = 0.25
	mats["glass"] = glass
	mats["plant"] = _lit(Color("#729875") if theme["scenery"] != "arctic" else Color("#e1f4f5"))
	mats["emissive"] = _glow(Color(p["gold"]), 1.6)
	mat_gold = _glow(Color(p["gold"]), 0.6)
	mat_gold.metallic = 0.4
	mat_gold.roughness = 0.4
	mat_dust = _lit(Color(p["trim"]))
	mat_spark = _glow(Color("#ffd75e"), 4.0)
	mat_spark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var g: Dictionary = theme_config["geometry"]
	storey_mesh = ThemeKit.storey(theme, block_h, g)
	base_mesh = ThemeKit.storey(theme, block_h, g, true)


## Assign materials by surface name; `overrides` replaces some (e.g. gold trophy roof).
func _dress(mi: MeshInstance3D, overrides := {}) -> void:
	for i in range(mi.mesh.get_surface_count()):
		var name: String = mi.mesh.surface_get_name(i)
		mi.set_surface_override_material(i, overrides.get(name, mats.get(name, mats["trim"])))


func _build_camera_and_light() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = VIEW_UNITS
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 0.5
	camera.far = 260.0
	camera.rotation_degrees = Vector3(-PITCH_DEG, 0, 0)
	# soft background blur (like the reference's depth of field); the playfield stays sharp
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = CAM_DIST + 6.0
	attrs.dof_blur_far_transition = 20.0
	attrs.dof_blur_amount = 0.08
	camera.attributes = attrs
	add_child(camera)
	camera.current = true

	# Backdrop: gradient + painterly clouds on a quad parented to the camera.
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
	# Stable, crisp shadows (T-0307): stabilised splits, short range, tuned bias.
	# Shadow quality (T-0311): stabilised 2-split maps; the near split (0..~23 units from the camera)
	# covers the tower and street at high texel density; filtered (PCF) soft edges; small biases
	# because double-sided casting and closed meshes no longer need large ones.
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 30.0
	sun.directional_shadow_split_1 = 0.78
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_fade_start = 0.9
	sun.shadow_blur = 1.0
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.0
	add_child(sun)
	# warm key light from the upper left: the left faces glow, the right faces fall into cool shade
	sun.look_at_from_position(Vector3(-7, 8, 4), Vector3.ZERO)
	# pink rim light from behind on the right, where the lo-fi sun sets (no shadows; fades at night)
	rim = DirectionalLight3D.new()
	rim.light_color = Color("#ff8fb3")
	rim.light_energy = 0.4
	rim.shadow_enabled = false
	add_child(rim)
	rim.look_at_from_position(Vector3(6, 3, -6), Vector3.ZERO)

	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY_DAY[1]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = SKY_DAY[7]
	env.ambient_light_energy = SKY_DAY[8]
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR   # keeps the flat colours saturated
	# distance haze: far city rows fade into the sky colour (depth fog; the playfield stays clear)
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = CAM_DIST + 3.0
	env.fog_depth_end = CAM_DIST + 75.0
	env.fog_depth_curve = 1.3          # gentle near, stronger far: colours survive in the near rows
	env.fog_light_color = SKY_DAY[1]
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	# glow only on genuinely emissive parts (windows at night, sparks), never on sunlit white trim
	env.glow_intensity = 0.8
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.6
	we.environment = env
	add_child(we)


func _add_layer(mesh: Mesh, colour: Color, z: float, horizon: float, parallax: float, haze: float, scale_y := 1.0) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.scale = Vector3(1.0, scale_y, 1.0)
	var m := _lit(colour, 1.0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	layers.append({"node": mi, "mat": m, "base": colour, "haze": haze, "parallax": parallax, "z": z, "horizon": horizon})


func _build_environment_layers() -> void:
	var landscape := Color(theme["landscape"])
	mats["land"] = _lit(landscape)
	mats["water"] = _lit(Color(theme["sky_top"]).darkened(0.12), 0.28)
	mats["rock"] = _lit(landscape.lightened(0.15))
	mats["path"] = _lit(Color(theme["palette"]["trim"]).darkened(0.12))
	var ground := MeshInstance3D.new()
	ground.mesh = ThemeKit.landscape(theme)
	_dress(ground)
	add_child(ground)

	# Background uses this theme's architecture as well, with haze and smaller scale.
	var layout: Dictionary = theme_config["scenery_layout"]
	for row in range(layout["row_depths"].size()):
		var haze := float(layout["haze"][row])
		var background_mats := {}
		for slot in mats:
			var m: StandardMaterial3D = mats[slot].duplicate()
			m.albedo_color = m.albedo_color.lerp(Color(theme["sky_bottom"]), haze)
			m.emission_energy_multiplier = 0.0
			background_mats[slot] = m
		var mi := MeshInstance3D.new()
		mi.mesh = ThemeKit.skyline(theme, block_h, theme_config["geometry"], layout, row)
		mi.scale = Vector3.ONE * float(layout["row_scales"][row])
		_dress(mi, background_mats)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		layers.append({"node": mi, "mat": null, "base": Color.WHITE, "haze": haze,
			"parallax": layout["row_parallax"][row], "z": layout["row_depths"][row],
			"horizon": layout["row_horizons"][row], "world": false})
	if theme["scenery"] not in ["skyline", "campus", "harbor", "compound"]:
		_add_layer(LowPoly.ridge(14.0, 24, 0.35, 0.8, 11, 0.2), landscape, -60.0, 2.7, 0.85, 0.0)


func _build_actors() -> void:
	crane_pivot = Node3D.new()
	add_child(crane_pivot)
	rope = MeshInstance3D.new()
	var rope_mesh := BoxMesh.new()
	rope_mesh.size = Vector3(0.025, 1.0, 0.025)
	rope.mesh = rope_mesh
	rope.material_override = _lit(Color("#3c4250"))
	crane_pivot.add_child(rope)
	carried = _make_block(false)
	crane_pivot.add_child(carried)
	var rig := Kit.Builder.new()
	var c := float(theme_config["geometry"]["half_width"])
	var sling_h := float(theme_config["geometry"]["sling_height"])
	for x in [-c, c]:
		for z in [-c, c]:
			var wire := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = float(theme_config["geometry"]["rope_width"]) * 0.5
			cylinder.bottom_radius = cylinder.top_radius
			var corner := Basis(Vector3.UP, yaw) * Vector3(x, 0, z)
			var top := Vector3(0, sling_h, 0)
			cylinder.height = corner.distance_to(top)
			wire.mesh = cylinder
			wire.material_override = rope.material_override
			wire.position = (corner + top) * 0.5
			wire.quaternion = Quaternion(Vector3.UP, (top - corner).normalized())
			crane_pivot.add_child(wire)
			wire.set_meta("sling", true)
	# Striped hoist is a separate moving mesh, never baked into a floor.
	for i in range(6):
		var x0 := -c * 0.4 + i * c * 0.8 / 6.0
		rig.box("gold" if i % 2 == 0 else "roof", Vector3(x0, sling_h, -c * 0.15), Vector3(x0 + c * 0.8 / 6.0, sling_h + c * 0.25, c * 0.15))
	var hoist := MeshInstance3D.new()
	hoist.mesh = rig.commit()
	_dress(hoist, {"gold": _lit(Color("#f7c54a")), "roof": _lit(Color("#282c35"))})
	crane_pivot.add_child(hoist)
	falling_node = _make_block(false)
	add_child(falling_node)

	dust_mm = _make_shards(mat_dust)
	spark_mm = _make_shards(mat_spark)


func _make_block(is_base: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED   # thin parts cast reliably
	_set_block_mesh(mi, is_base)
	return mi


func _set_block_mesh(mi: MeshInstance3D, is_base: bool) -> void:
	var wanted := base_mesh if is_base else storey_mesh
	if mi.mesh != wanted:
		mi.mesh = wanted
		_dress(mi)


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


## Basis for a building part: turned by the building yaw, then leaning with the sway.
func _block_basis(lean: float) -> Basis:
	return Basis(Vector3.BACK, lean) * Basis(Vector3.UP, yaw)


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
		roof_node.mesh = ThemeKit.roof(theme, theme_config["geometry"])
		roof_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		_dress(roof_node, {"trim": mat_gold, "accent": mat_gold, "gold": mat_gold, "emissive": mat_spark} if trophy else {})
		add_child(roof_node)


# --- per frame ------------------------------------------------------------------

## view_y (tower_game's camera height) that puts world height `y` `margin_px` below the
## top of the screen (used to keep the crane hook under the HUD).
func view_y_for_top_point(y: float, margin_px: float) -> float:
	var half := VIEW_UNITS * 0.5
	var units_per_px := VIEW_UNITS / 1280.0
	var centre := y - (half - margin_px * units_per_px)
	return centre - CENTER_ABOVE_VIEW


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


func _update_camera(_delta: float) -> void:
	cam_y = float(game.view_y) + CENTER_ABOVE_VIEW
	var shake: Vector2 = game.shake_offset * PX_TO_UNITS
	var target := Vector3(float(game.view_x) + shake.x, cam_y + float(game.kick) * PX_TO_UNITS - shake.y, 0)
	var back := Vector3(0, sin(deg_to_rad(PITCH_DEG)), cos(deg_to_rad(PITCH_DEG))) * CAM_DIST
	camera.position = target + back
	# background layers: placed so their base sits on the horizon, then drift up slower than the camera
	var tan_p := tan(deg_to_rad(PITCH_DEG))
	for l in layers:
		var n: MeshInstance3D = l["node"]
		var lift := (cam_y - CENTER_ABOVE_VIEW) * float(l["parallax"])
		if l.get("world", false):
			# mesh built at its real depth; when scaled down, shift it back so it stays at that depth, then
			# lift/lower it so its base lands `base_v` above the ground line on screen
			var z := float(l["z"])
			var sp := sin(deg_to_rad(PITCH_DEG))
			var y_base := (float(l["base_v"]) + z * sp) / cos(deg_to_rad(PITCH_DEG))
			n.position = Vector3(0, y_base + lift, z * (1.0 - float(l.get("scale", 1.0))))
		else:
			n.position = Vector3(0, float(l["horizon"]) + float(l["z"]) * tan_p + lift, float(l["z"]))
	backdrop_mat.set_shader_parameter("scroll", (cam_y - CENTER_ABOVE_VIEW) * 0.01)


func _sky(k: int) -> Variant:
	# blend day -> dusk -> night by `night` (0..1)
	if night < 0.5:
		var day: Variant = Color(theme["sky_top"]) if k == 0 else (Color(theme["sky_bottom"]) if k == 1 else SKY_DAY[k])
		return _lerp_any(day, SKY_DUSK[k], night * 2.0)
	return _lerp_any(SKY_DUSK[k], SKY_NIGHT[k], (night - 0.5) * 2.0)


func _lerp_any(a: Variant, b: Variant, w: float) -> Variant:
	if a is Color:
		return (a as Color).lerp(b, w)
	return lerpf(float(a), float(b), w)


func _update_time_of_day(delta: float) -> void:
	var target := clampf((cam_y - 9.0) / 20.0, 0.0, 1.0)
	night = lerpf(night, target, minf(1.0, delta * 1.5))
	combo_glow = move_toward(combo_glow, combo_target, delta * 2.5)   # ~0.4 s fade in/out
	var bottom: Color = _sky(1)
	backdrop_mat.set_shader_parameter("top_color", _sky(0))
	backdrop_mat.set_shader_parameter("bottom_color", bottom)
	backdrop_mat.set_shader_parameter("cloud_warm", _sky(2))
	backdrop_mat.set_shader_parameter("cloud_light", _sky(3))
	backdrop_mat.set_shader_parameter("cloud_amount", _sky(4))
	backdrop_mat.set_shader_parameter("stars", clampf((night - 0.55) * 2.2, 0.0, 1.0))
	env.background_color = bottom
	sun.light_color = _sky(5)
	sun.light_energy = _sky(6)
	env.ambient_light_color = _sky(7)
	env.ambient_light_energy = _sky(8)
	# combo adds a gentle warm glow, weaker by day so windows don't flash gold in sunlight
	(mats["glass"] as StandardMaterial3D).emission_energy_multiplier = clampf((night - 0.3) * 3.5, 0.0, 2.6) + combo_glow * lerpf(0.18, 0.5, night)
	for l in layers:
		if l["mat"] != null:
			(l["mat"] as StandardMaterial3D).albedo_color = (l["base"] as Color).darkened(night * 0.45)

	env.fog_light_color = bottom.lerp(_sky(0), 0.3).lightened(0.1)   # lavender-peach haze, not a flat orange wash
	# the lo-fi sun sinks and fades as the tower climbs into night (T-0312)
	var sun_amount := 1.0 - smoothstep(0.35, 0.8, night)
	backdrop_mat.set_shader_parameter("sun_amount", sun_amount)
	backdrop_mat.set_shader_parameter("sun_pos", Vector2(0.578, 0.5 + night * 0.22))   # right of the tower; sinks behind the city
	rim.light_energy = 0.4 * sun_amount + 0.12 * night
	rim.light_color = Color("#ff8fb3").lerp(Color("#8f9bff"), night)


func _update_tower(st) -> void:
	var count: int = st.blocks.size() - 1
	while tower_nodes.size() < count:
		var mi := _make_block(tower_nodes.is_empty())
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
		node.transform = Transform3D(_block_basis(-sway * 0.06 * k), Vector3(float(b["x"]) + sway * k, i * block_h, 0))
	if count > 0 and float(game.squash_t) > 0.0:
		var sq: Dictionary = game.feel["squash"]
		var a := sin(float(game.squash_t) / float(sq["time"]) * PI) * float(sq["amount"])
		var top := tower_nodes[count - 1]
		top.transform = Transform3D(top.transform.basis.scaled(Vector3(1.0 + a, 1.0 - a, 1.0 + a)), top.transform.origin)
	if roof_node:
		if count > 0:
			var top_node := tower_nodes[count - 1]
			roof_node.transform = Transform3D(top_node.transform.basis.orthonormalized(), top_node.transform.origin + Vector3(0, block_h, 0))
		roof_node.visible = count > 0


func _update_crane(st, _delta: float) -> void:
	var cx: float = game.crane_x
	var cy: float = game._crane_y()
	crane_pivot.position = Vector3(cx, cy, 0)
	var rope_len := 14.0
	rope.scale = Vector3(1, rope_len, 1)
	rope.position = Vector3(0, rope_len * 0.5 + float(theme_config["geometry"]["sling_height"]), 0)
	# The next block uses the matching ground-floor facade when the tower is empty.
	var next_is_base: bool = st.height() == 0
	for child in crane_pivot.get_children():
		if child.has_meta("sling"):
			child.visible = game.falling.is_empty() and not st.is_over
	_set_block_mesh(carried, next_is_base)
	_set_block_mesh(falling_node, next_is_base)
	# Keep the carried top corners fixed to the four suspension cables.
	var tilt := Basis.IDENTITY
	carried.transform = Transform3D(tilt * Basis(Vector3.UP, yaw), tilt * Vector3(0, -block_h, 0))
	carried.visible = game.falling.is_empty() and not st.is_over
	falling_node.visible = not game.falling.is_empty()
	if falling_node.visible:
		falling_node.transform = Transform3D(_block_basis(0.0), Vector3(float(game.falling["x"]), float(game.falling["y"]), 0))


func _update_debris() -> void:
	var list: Array = game.debris
	while debris_nodes.size() < list.size():
		var mi := _make_block(false)
		add_child(mi)
		debris_nodes.append(mi)
	while debris_nodes.size() > list.size():
		debris_nodes.pop_back().queue_free()
	for i in range(list.size()):
		var d: Dictionary = list[i]
		_set_block_mesh(debris_nodes[i], int(d.get("index", 2)) == 1)
		var rot := float(d["rot"])
		var basis := Basis.from_euler(Vector3(rot * 0.7, rot * 0.3, rot)) * Basis(Vector3.UP, yaw)   # tumble in 3D
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

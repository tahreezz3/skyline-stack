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

var theme: Dictionary
var theme_config: Dictionary
var game: Node2D
var block_h := 0.6
var yaw := 0.0

var camera: Camera3D
var sun: DirectionalLight3D
var env: Environment
var backdrop_mat: ShaderMaterial
var backdrop_mesh: QuadMesh
var background_texture: Texture2D
var lighting: Dictionary

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
var rings: Array[Dictionary] = []       # {node, mat, age}
var rim: DirectionalLight3D
var dust_mm: MultiMesh
var spark_mm: MultiMesh

var cam_y := 0.0
var combo_glow := 0.0          # eased 0..1; never switched instantly (instant changes read as flicker)
var combo_target := 0.0


func setup(p_game: Node2D) -> void:
	game = p_game
	theme = game.visual_theme
	lighting = theme["background"]["lighting"]
	theme_config = GameConfig.table("themes")
	yaw = deg_to_rad(float(theme_config["geometry"]["yaw_degrees"]))
	block_h = float(game.rules["block"]["height"])
	_build_materials()
	_build_camera_and_light()
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
	# Artwork already contains the intended atmospheric depth; keep it crisp and untinted.
	add_child(camera)
	camera.current = true
	backdrop_mesh = QuadMesh.new()
	backdrop_mesh.size = Vector2(VIEW_UNITS, VIEW_UNITS)
	background_texture = load(String(theme["background"]["texture"])) as Texture2D
	backdrop_mat = ShaderMaterial.new()
	backdrop_mat.shader = load("res://scripts/game/shaders/sky_backdrop.gdshader")
	backdrop_mat.set_shader_parameter("environment_image", background_texture)
	backdrop_mat.set_shader_parameter("image_aspect", background_texture.get_size().aspect())
	var backdrop := MeshInstance3D.new()
	backdrop.mesh = backdrop_mesh
	backdrop.material_override = backdrop_mat
	backdrop.position = Vector3(0, 0, -float(theme_config["backdrop"]["distance"]))
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
	# Reference-specific daylight or golden-hour light; no shared lavender fill.
	var key_at: Array = lighting["key_position"]
	sun.look_at_from_position(Vector3(key_at[0], key_at[1], key_at[2]), Vector3.ZERO)
	# Neutral fill for daytime scenes and a restrained warm edge for sunset scenes.
	rim = DirectionalLight3D.new()
	rim.light_color = Color(lighting["rim_color"])
	rim.light_energy = float(lighting["rim_energy"])
	rim.shadow_enabled = false
	add_child(rim)
	var rim_at: Array = lighting["rim_position"]
	rim.look_at_from_position(Vector3(rim_at[0], rim_at[1], rim_at[2]), Vector3.ZERO)

	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(lighting["ambient_color"])
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(lighting["ambient_color"])
	env.ambient_light_energy = float(lighting["ambient_energy"])
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR   # keeps the flat colours saturated
	# The background owns its own atmosphere and sun. Keep gameplay geometry legible.
	env.fog_enabled = false
	env.glow_enabled = false
	we.environment = env
	add_child(we)


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
	_update_lighting(delta)
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
	var aspect := get_viewport().get_visible_rect().size.aspect()
	backdrop_mesh.size = Vector2(VIEW_UNITS * aspect, VIEW_UNITS) * float(theme_config["backdrop"]["overscan"])
	backdrop_mat.set_shader_parameter("viewport_aspect", aspect)


func _update_lighting(delta: float) -> void:
	# Height never turns the owner's bright daytime scene into generic purple dusk.
	combo_glow = move_toward(combo_glow, combo_target, delta * 2.5)
	sun.light_color = Color(lighting["key_color"])
	sun.light_energy = float(lighting["key_energy"])
	env.ambient_light_color = Color(lighting["ambient_color"])
	env.ambient_light_energy = float(lighting["ambient_energy"])
	(mats["glass"] as StandardMaterial3D).emission_energy_multiplier = float(lighting["window_glow"]) + combo_glow * 0.18


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

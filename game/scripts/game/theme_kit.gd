## Original procedural architecture for the v001-v010 brief. Only meshes, never rules.
## Mesh origin is bottom centre; every storey fits exactly in [0, block.height].
## Fixed fractions below describe mesh topology; tunable dimensions live in themes.json.
extends RefCounted

const Kit := preload("res://scripts/game/building_kit.gd")


static func storey(theme: Dictionary, h: float, g: Dictionary, is_base := false) -> ArrayMesh:
	var b := Kit.Builder.new()
	var c := float(g["half_width"])
	var ledge := float(g["cornice_width"])
	var kind: String = theme["architecture"]
	var round_body := kind in ["ice", "lighthouse"]
	if round_body:
		var r := float(g["round_radius"])
		b.frustum("body", Vector3.ZERO, r * 0.94, r * 0.94, h * 0.87, int(g["round_sides"]))
		b.frustum("trim" if kind == "ice" else "accent", Vector3(0, h * 0.87, 0), r, r * 0.94, h * 0.13, int(g["round_sides"]))
	else:
		b.box("body", Vector3(-c, 0, -c), Vector3(c, (h * 0.79 if kind in ["fort", "pagoda"] else h * 0.91), c), true)
		if kind != "pagoda":
			b.box("trim", Vector3(-ledge, h * (0.79 if kind == "fort" else 0.91), -ledge), Vector3(ledge, h * (0.86 if kind == "fort" else 1.0), ledge))
		else:
			b.cone("roof", Vector3(0, h * 0.91, 0), c * 1.02, h * 0.09, 4, PI * 0.25)
		b.box("trim", Vector3(-ledge, 0, -ledge), Vector3(ledge, h * 0.05, ledge), true)

	b.each_side(func(_side: int) -> void:
		var z := c if not round_body else float(g["round_radius"]) * 0.96
		match kind:
			"classical", "palace":
				for x in [-c * 0.81, c * 0.81]:
					b.box("trim", Vector3(x - c * 0.09, h * 0.05, z), Vector3(x + c * 0.09, h * 0.91, z + c * 0.07))
				for x in [-c * 0.36, c * 0.36]:
					b.arch("trim", x, c * 0.28, h * 0.16, h * 0.64, z, z + c * 0.06, 8, 0.0)
					b.arch("glass", x, c * 0.20, h * 0.21, h * 0.64, z + c * 0.06, z + c * 0.07, 8, 0.0)
					b.box("accent", Vector3(x - c * 0.02, h * 0.20, z + c * 0.07), Vector3(x + c * 0.02, h * 0.74, z + c * 0.09))
				if kind == "palace":
					b.box("accent", Vector3(-c, h * 0.84, z + c * 0.01), Vector3(c, h * 0.88, z + c * 0.05))
					b.blob("gold", Vector3(0, h * 0.82, z + c * 0.08), c * 0.09)
			"glass", "office":
				b.box("glass", Vector3(-c * 0.95, h * 0.08, z), Vector3(c * 0.95, h * 0.88, z + c * 0.02))
				var columns := int(g["window_columns"]) + (1 if kind == "glass" else 0)
				for i in range(columns + 1):
					var x := lerpf(-c * 0.94, c * 0.94, float(i) / columns)
					b.box("trim", Vector3(x - c * 0.025, h * 0.08, z + c * 0.02), Vector3(x + c * 0.025, h * 0.91, z + c * 0.045))
				b.box("trim", Vector3(-c, h * 0.47, z + c * 0.02), Vector3(c, h * 0.50, z + c * 0.045))
				if kind == "office":
					b.box("body_dark", Vector3(-c * 0.7, h * 0.09, z + c * 0.05), Vector3(c * 0.7, h * 0.19, z + c * 0.10))
					for x in [-c * 0.5, 0.0, c * 0.5]:
						b.blob("plant", Vector3(x, h * 0.23, z + c * 0.1), c * 0.1)
			"pagoda":
				b.box("glass", Vector3(-c * 0.78, h * 0.18, z), Vector3(c * 0.78, h * 0.69, z + c * 0.02))
				for x in [-c * 0.88, -c * 0.3, c * 0.3, c * 0.88]:
					b.box("accent", Vector3(x - c * 0.07, h * 0.05, z), Vector3(x + c * 0.07, h * 0.8, z + c * 0.08))
				for y in [0.18, 0.43, 0.68]:
					b.box("accent", Vector3(-c, h * y, z + c * 0.02), Vector3(c, h * (y + 0.025), z + c * 0.05))
				# Curved hip eaves rise at the corners. Reuse this silhouette for every module.
				for i in range(8):
					var x0 := lerpf(-ledge, ledge, float(i) / 8.0)
					var x1 := lerpf(-ledge, ledge, float(i + 1) / 8.0)
					var y0 := h * (0.8 + 0.12 * pow(x0 / ledge, 2))
					var y1 := h * (0.8 + 0.12 * pow(x1 / ledge, 2))
					b.quad("roof", Vector3(x0, y0, ledge), Vector3(x1, y1, ledge), Vector3(x1 * 0.66, h * 0.91, c * 0.72), Vector3(x0 * 0.66, h * 0.91, c * 0.72), Vector3.UP)
					b.box("gold", Vector3(x0, y0 - h * 0.015, ledge - c * 0.025), Vector3(x1, y0, ledge))
				for x in [-c * 0.75, c * 0.75]:
					b.frustum("accent", Vector3(x, h * 0.56, z + c * 0.16), c * 0.1, c * 0.1, h * 0.18, 8)
					b.box("gold", Vector3(x - c * 0.025, h * 0.51, z + c * 0.14), Vector3(x + c * 0.025, h * 0.57, z + c * 0.18))
			"fort":
				b.arch("body_dark", 0, c * 0.23, h * 0.18, h * 0.59, z, z + c * 0.025, 6, 0.2)
				b.arch("glass", 0, c * 0.14, h * 0.22, h * 0.59, z + c * 0.025, z + c * 0.035, 6, 0.2)
				for x in [-c * 0.82, 0.0, c * 0.82]:
					b.box("body", Vector3(x - c * 0.17, h * 0.86, z - c * 0.13), Vector3(x + c * 0.17, h, z + c * 0.05))
				b.box("accent", Vector3(c * 0.5, h * 0.27, z + c * 0.04), Vector3(c * 0.78, h * 0.73, z + c * 0.06))
				b.box("gold", Vector3(c * 0.61, h * 0.32, z + c * 0.06), Vector3(c * 0.66, h * 0.67, z + c * 0.07))
				for y in [0.3, 0.6]:
					b.box("body_dark", Vector3(-c, h * y, z), Vector3(c, h * (y + 0.015), z + c * 0.01))
			"ice", "lighthouse":
				b.arch("trim" if kind == "ice" else "accent", 0, c * 0.4, h * 0.15, h * 0.54, z - c * 0.16, z + c * 0.04, 8, 0.0)
				b.arch("glass", 0, c * 0.28, h * 0.20, h * 0.54, z + c * 0.04, z + c * 0.05, 8, 0.0)
				if kind == "ice":
					for y in [0.28, 0.57]:
						b.box("body_dark", Vector3(-c * 0.65, h * y, z - c * 0.05), Vector3(-c * 0.42, h * (y + 0.018), z))
			"prison", "factory":
				for x in [-c * 0.5, c * 0.5]:
					b.box("glass", Vector3(x - c * 0.31, h * 0.25, z), Vector3(x + c * 0.31, h * 0.75, z + c * 0.03))
					for i in range(4):
						var bx: float = x + c * (-0.24 + i * 0.16)
						b.box("trim", Vector3(bx, h * 0.25, z + c * 0.03), Vector3(bx + c * 0.035, h * 0.75, z + c * 0.06))
				_railing(b, c, h * 0.08, h * 0.23, z + c * 0.08)
				if kind == "factory":
					b.frustum("trim", Vector3(c * 0.87, h * 0.05, z + c * 0.12), c * 0.09, c * 0.09, h * 0.81, 8)
					b.box("accent", Vector3(-c, h * 0.78, z), Vector3(c, h * 0.84, z + c * 0.07))
					b.box("gold", Vector3(-c * 0.2, h * 0.32, z + c * 0.03), Vector3(c * 0.2, h * 0.65, z + c * 0.05))
		if is_base:
			# A door belongs to this architecture, never the old cafe facade.
			b.box("trim", Vector3(-c * 0.23, h * 0.02, z + c * 0.06), Vector3(c * 0.23, h * 0.66, z + c * 0.09))
			b.box("glass", Vector3(-c * 0.17, h * 0.04, z + c * 0.09), Vector3(c * 0.17, h * 0.59, z + c * 0.10))
	)
	if kind == "lighthouse":
		# Circular balcony, kept inside the same full-width envelope as the round body.
		var radius := float(g["round_radius"])
		b.frustum("trim", Vector3(0, h * 0.75, 0), radius, radius, h * 0.018, int(g["round_sides"]))
		for i in range(int(g["round_sides"])):
			var angle := TAU * i / int(g["round_sides"])
			b.frustum("trim", Vector3(cos(angle) * radius, h * 0.62, sin(angle) * radius), radius * 0.012, radius * 0.012, h * 0.13, 6)
	return b.commit()


static func _railing(b, c: float, lo: float, hi: float, z: float) -> void:
	b.box("trim", Vector3(-c, hi, z), Vector3(c, hi + c * 0.025, z + c * 0.03))
	for x in [-c, -c * 0.5, 0.0, c * 0.5, c]:
		b.box("trim", Vector3(x, lo, z), Vector3(x + c * 0.025, hi, z + c * 0.03))


static func roof(theme: Dictionary, g: Dictionary) -> ArrayMesh:
	var b := Kit.Builder.new()
	var c := float(g["cornice_width"])
	var h := float(g["roof_height"])
	match String(theme["architecture"]):
		"pagoda":
			b.box("roof", Vector3(-c, 0, -c), Vector3(c, h * 0.12, c), true)
			b.cone("roof", Vector3(0, h * 0.12, 0), c, h * 0.78, 4, PI * 0.25)
			b.frustum("gold", Vector3(0, h * 0.9, 0), c * 0.035, 0, h * 0.1, 8)
		"ice":
			b.frustum("trim", Vector3.ZERO, float(g["round_radius"]), c * 0.8, h * 0.65, int(g["round_sides"]))
			b.frustum("trim", Vector3(0, h * 0.65, 0), c * 0.8, c * 0.05, h * 0.35, int(g["round_sides"]))
		"lighthouse":
			b.frustum("trim", Vector3.ZERO, c * 1.2, c * 1.2, h * 0.1, 16)
			b.frustum("emissive", Vector3(0, h * 0.1, 0), c * 0.65, c * 0.65, h * 0.5, 12)
			b.cone("accent", Vector3(0, h * 0.6, 0), c * 0.9, h * 0.4, 16)
		"palace", "classical":
			b.box("trim", Vector3(-c, 0, -c), Vector3(c, h * 0.1, c), true)
			b.cone("accent", Vector3(0, h * 0.1, 0), c, h * 0.8, 4, PI * 0.25)
			b.blob("gold", Vector3(0, h * 0.93, 0), h * 0.07)
		_:
			b.box("trim", Vector3(-c, 0, -c), Vector3(c, h * 0.12, c), true)
			if theme["architecture"] == "factory":
				b.frustum("body_dark", Vector3(c * 0.5, h * 0.12, 0), c * 0.18, c * 0.18, h * 0.88, 12)
			else:
				b.box("body", Vector3(-c * 0.5, h * 0.12, -c * 0.5), Vector3(c * 0.5, h * 0.5, c * 0.5))
	return b.commit()


## Garden/compound/coast details, distinct from the moving playfield and its hitboxes.
static func landscape(theme: Dictionary) -> ArrayMesh:
	var b := Kit.Builder.new()
	var scene: String = theme["scenery"]
	var watery := scene in ["river", "arctic", "coast", "harbor"]
	b.box("land", Vector3(-30, -0.16, -30), Vector3(30, -0.12, 4), true)
	if watery:
		b.box("water", Vector3(-30, -0.11, -22), Vector3(30, -0.10, -3))
		for side in [-1.0, 1.0]:
			for i in range(4):
				var x: float = side * (1.4 + i * 1.2)
				if scene in ["coast", "arctic"]:
					b.blob("rock", Vector3(x, -0.04, -1.5 - i * 0.4), 0.4 + i * 0.14)
				elif scene == "harbor":
					b.box("body_dark", Vector3(x, 0, -1.5), Vector3(x + 0.55, 0.24, -0.8))
					b.frustum("trim", Vector3(x, 0, -2), 0.16, 0.16, 0.7, 12)
	# Paved base remains beneath the full-width first-block acceptance zone.
	b.box("path", Vector3(-0.95, -0.09, -0.95), Vector3(0.95, -0.025, 0.95))
	for side in [-1.0, 1.0]:
		if scene in ["garden", "courtyard", "campus", "skyline"]:
			for i in range(5):
				var z := -0.5 - i * 0.75
				b.box("path", Vector3(side * 1.15 - 0.3, -0.10, z - 0.3), Vector3(side * 1.15 + 0.3, -0.06, z + 0.3))
				b.blob("plant", Vector3(side * 1.15, 0.12, z), 0.27)
			if scene == "courtyard":
				b.frustum("trim", Vector3(side * 1.5, 0, -1), 0.25, 0.18, 0.75, 12)
				b.blob("gold", Vector3(side * 1.5, 0.9, -1), 0.18)
		elif scene in ["fortress", "compound"]:
			b.box("body_dark", Vector3(side * 1.45 - 0.12, 0, -4), Vector3(side * 1.45 + 0.12, 0.5, -1.0))
			for i in range(5):
				b.box("trim", Vector3(side * 1.45 - 0.15, 0.5, -4 + i * 0.6), Vector3(side * 1.45 + 0.15, 0.65, -3.7 + i * 0.6))
			b.box("body", Vector3(side * 1.45 - 0.45, 0, -4.5), Vector3(side * 1.45 + 0.45, 1.3, -3.6))
			b.box("glass", Vector3(side * 1.45 - 0.30, 0.8, -3.59), Vector3(side * 1.45 + 0.30, 1.1, -3.57))
		elif scene == "river":
			b.frustum("accent", Vector3(side * 1.4, 0, -0.5), 0.04, 0.04, 0.9, 8)
			b.blob("accent", Vector3(side * 1.4, 0.74, -0.5), 0.15)
	return b.commit()


## Batch a row into one mesh per material to keep scenery draw calls bounded.
static func skyline(theme: Dictionary, h: float, g: Dictionary, layout: Dictionary, row: int) -> ArrayMesh:
	var b := Kit.Builder.new()
	var floor_mesh := storey(theme, h, g)
	var crown := roof(theme, g)
	var counts: Array = layout["floor_counts"]
	var yaw := Basis(Vector3.UP, deg_to_rad(float(g["yaw_degrees"])))
	for i in range(-int(layout["row_extent"]), int(layout["row_extent"]) + 1):
		if i == 0:
			continue
		var floors := int(counts[posmod(i + row, counts.size())])
		var x := i * float(layout["row_spacing"])
		for floor_index in range(floors):
			_append_mesh(b, floor_mesh, Transform3D(yaw, Vector3(x, floor_index * h, 0)))
		_append_mesh(b, crown, Transform3D(yaw, Vector3(x, floors * h, 0)))
	return b.commit()


static func _append_mesh(b, mesh: ArrayMesh, transform: Transform3D) -> void:
	for surface in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var name := mesh.surface_get_name(surface)
		for i in range(0, vertices.size(), 3):
			b.tri(name, transform * vertices[i], transform * vertices[i + 1], transform * vertices[i + 2], transform.basis * normals[i])

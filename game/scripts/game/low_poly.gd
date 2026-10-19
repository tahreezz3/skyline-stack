## Procedural low-poly placeholder meshes in the chosen art direction
## (docs/06_ART_AUDIO_SPEC.md §2, ADR-0006). Everything is flat-shaded (each
## triangle has its own normal) and built in world units (1 = block width).
## Surface names follow the artist spec so delivered .glb files can replace these
## one-for-one: body, trim, glass, emissive (T-0301).
extends RefCounted

## Godot treats clockwise triangles as front faces.
const EMIT_CLOCKWISE := true


# --- triangle helpers -----------------------------------------------------------

## Add one triangle whose normal points along `outward` (winding fixed automatically).
static func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-12:
		return
	if n.dot(outward) < 0.0:
		var tmp := b
		b = c
		c = tmp
		n = -n
	st.set_normal(n.normalized())
	if EMIT_CLOCKWISE:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)
	else:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)


static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
	tri(st, a, b, c, outward)
	tri(st, a, c, d, outward)


## Axis-aligned box from `lo` to `hi`. `bottom` = include the underside.
static func box(st: SurfaceTool, lo: Vector3, hi: Vector3, bottom := false) -> void:
	var x0 := lo.x
	var y0 := lo.y
	var z0 := lo.z
	var x1 := hi.x
	var y1 := hi.y
	var z1 := hi.z
	quad(st, Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.BACK)     # +Z front
	quad(st, Vector3(x1, y0, z0), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3.FORWARD)  # -Z back
	quad(st, Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3.RIGHT)
	quad(st, Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), Vector3.LEFT)
	quad(st, Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3(x0, y1, z0), Vector3.UP)
	if bottom:
		quad(st, Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector3.DOWN)


## Pyramid / cone with `sides` facets on a base ring at `base` (y up).
static func cone(st: SurfaceTool, base: Vector3, radius: float, height: float, sides: int, angle_offset := 0.0) -> void:
	var apex := base + Vector3(0, height, 0)
	for i in range(sides):
		var a0 := angle_offset + TAU * i / sides
		var a1 := angle_offset + TAU * (i + 1) / sides
		var p0 := base + Vector3(cos(a0), 0, sin(a0)) * radius
		var p1 := base + Vector3(cos(a1), 0, sin(a1)) * radius
		var mid := (p0 + p1) * 0.5 - base
		tri(st, p0, p1, apex, mid + Vector3(0, radius * 0.3, 0))


## Prism (low-poly cylinder) with `sides` facets.
static func prism(st: SurfaceTool, base: Vector3, radius: float, height: float, sides: int, top := true) -> void:
	for i in range(sides):
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var d0 := Vector3(cos(a0), 0, sin(a0)) * radius
		var d1 := Vector3(cos(a1), 0, sin(a1)) * radius
		var up := Vector3(0, height, 0)
		quad(st, base + d0, base + d1, base + d1 + up, base + d0 + up, (d0 + d1) * 0.5)
		if top:
			tri(st, base + up, base + d0 + up, base + d1 + up, Vector3.UP)


## Octahedron (used for shards, sparkles and antenna lights). `stretch` scales each axis.
static func octa(st: SurfaceTool, c: Vector3, r: float, stretch := Vector3.ONE) -> void:
	var px := c + Vector3(r * stretch.x, 0, 0)
	var nx := c - Vector3(r * stretch.x, 0, 0)
	var py := c + Vector3(0, r * stretch.y, 0)
	var ny := c - Vector3(0, r * stretch.y * 0.35, 0)     # flatter underside
	var pz := c + Vector3(0, 0, r * stretch.z)
	var nz := c - Vector3(0, 0, r * stretch.z)
	for e in [[px, pz], [pz, nx], [nx, nz], [nz, px]]:
		tri(st, e[0], e[1], py, (e[0] + e[1] + py) / 3.0 - c)
		tri(st, e[0], e[1], ny, (e[0] + e[1] + ny) / 3.0 - c)


# --- meshes -------------------------------------------------------------------

static func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func _commit(mesh: ArrayMesh, st: SurfaceTool, name: String) -> void:
	st.commit(mesh)
	mesh.surface_set_name(mesh.get_surface_count() - 1, name)


## One storey of a building: body, trim bands (cornice + plinth line), glass windows.
## Origin at bottom centre, front faces +Z, height `h` (rules block.height).
static func storey(h: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var body := _st()
	box(body, Vector3(-0.47, 0.03, -0.44), Vector3(0.47, h - 0.07, 0.44))
	_commit(mesh, body, "body")
	var trim := _st()
	box(trim, Vector3(-0.5, h - 0.07, -0.47), Vector3(0.5, h, 0.47))        # cornice
	box(trim, Vector3(-0.485, 0.0, -0.455), Vector3(0.485, 0.03, 0.455))     # plinth line
	for k in range(4):                                                      # pilasters between windows
		var px := -0.42 + k * 0.28
		box(trim, Vector3(px - 0.025, 0.03, 0.44), Vector3(px + 0.025, h - 0.07, 0.46))
	_commit(mesh, trim, "trim")
	var glass := _st()
	var wy0 := h * 0.22
	var wy1 := h * 0.78
	for k in range(3):
		var cx := -0.28 + k * 0.28
		box(glass, Vector3(cx - 0.085, wy0, 0.44), Vector3(cx + 0.085, wy1, 0.452))
	for side in [-1.0, 1.0]:
		for k in range(2):
			var cz := -0.2 + k * 0.4
			var xa: float = 0.47 * side
			var xb: float = 0.482 * side
			box(glass, Vector3(minf(xa, xb), wy0, cz - 0.1), Vector3(maxf(xa, xb), wy1, cz + 0.1))
	_commit(mesh, glass, "glass")
	return mesh


## Roof cap that sits on the last storey. Trophy roofs get a gold spire and an emissive star.
static func roof(trophy: bool) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var trim := _st()
	box(trim, Vector3(-0.52, 0.0, -0.49), Vector3(0.52, 0.08, 0.49))
	box(trim, Vector3(-0.015, 0.34, -0.015), Vector3(0.015, 0.95 if trophy else 0.75, 0.015))   # antenna
	_commit(mesh, trim, "trim")
	var body := _st()
	box(body, Vector3(-0.34, 0.08, -0.3), Vector3(0.34, 0.34, 0.3))                 # rooftop block
	if trophy:
		cone(body, Vector3(0, 0.34, 0), 0.32, 0.38, 4, PI / 4.0)
	else:
		box(body, Vector3(0.12, 0.34, -0.2), Vector3(0.3, 0.44, -0.02))             # vent box
	_commit(mesh, body, "body")
	var light := _st()
	octa(light, Vector3(0, 1.0 if trophy else 0.78, 0), 0.07 if trophy else 0.035)
	_commit(mesh, light, "emissive")
	return mesh


## Crane hook: small pulley block plus a hook prism.
static func hook() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var st := _st()
	box(st, Vector3(-0.12, 0.0, -0.08), Vector3(0.12, 0.14, 0.08), true)
	prism(st, Vector3(0, -0.06, 0), 0.05, 0.06, 6)
	_commit(mesh, st, "trim")
	return mesh


## Foundation plaza around the tower base: slab, paving, curb.
static func plaza(width: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var ground := _st()
	box(ground, Vector3(-width * 0.5, -3.0, -8.0), Vector3(width * 0.5, -0.06, 2.0))
	_commit(mesh, ground, "body")
	var paving := _st()
	# Every top face sits at its own height: coplanar overlapping faces z-fight (flicker).
	box(paving, Vector3(-2.2, -0.06, -1.6), Vector3(2.2, -0.035, 1.3))   # plaza paving, top -0.035
	_commit(mesh, paving, "trim")
	var plinth := _st()
	box(plinth, Vector3(-0.75, -0.06, -0.7), Vector3(0.75, -0.015, 0.7))  # lower step, top -0.015
	box(plinth, Vector3(-0.62, -0.015, -0.58), Vector3(0.62, 0.0, 0.58))  # foundation the first storey sits on
	_commit(mesh, plinth, "body2")
	return mesh


## Low-poly tree: trunk prism + two stacked faceted cones.
static func tree(height := 1.0) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var trunk := _st()
	prism(trunk, Vector3.ZERO, 0.05 * height, 0.3 * height, 5)
	_commit(mesh, trunk, "trim")
	var leaves := _st()
	cone(leaves, Vector3(0, 0.22 * height, 0), 0.3 * height, 0.5 * height, 6)
	cone(leaves, Vector3(0, 0.5 * height, 0), 0.22 * height, 0.42 * height, 6, 0.5)
	_commit(mesh, leaves, "body")
	return mesh


## Street lamp: pole + emissive head.
static func lamp() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var pole := _st()
	prism(pole, Vector3.ZERO, 0.02, 0.6, 4)
	_commit(mesh, pole, "trim")
	var head := _st()
	octa(head, Vector3(0, 0.64, 0), 0.06)
	_commit(mesh, head, "emissive")
	return mesh


## Background ridge (hills/mountains): a faceted strip facing +Z. Vertices are jittered
## in depth so neighbouring triangles catch the light differently (the low-poly look).
static func ridge(width: float, segments: int, min_h: float, max_h: float, rng_seed: int, jitter := 0.8) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var st := _st()
	var tops: Array[Vector3] = []
	for i in range(segments + 1):
		var x := -width * 0.5 + width * i / segments
		tops.append(Vector3(x, rng.randf_range(min_h, max_h), rng.randf_range(-jitter, jitter)))
	for i in range(segments):
		var t0 := tops[i]
		var t1 := tops[i + 1]
		var mid := Vector3((t0.x + t1.x) * 0.5, minf(t0.y, t1.y) * rng.randf_range(0.45, 0.7), rng.randf_range(-jitter, jitter))
		var b0 := Vector3(t0.x, -2.0, 0)
		var b1 := Vector3(t1.x, -2.0, 0)
		tri(st, t0, t1, mid, Vector3(0, 0.3, 1))
		tri(st, b0, mid, t0, Vector3(0, 0.1, 1))
		tri(st, b0, b1, mid, Vector3(0, 0, 1))
		tri(st, b1, t1, mid, Vector3(0, 0.1, 1))
	var mesh := ArrayMesh.new()
	_commit(mesh, st, "body")
	return mesh


## Distant skyline: a row of simple boxes with stepped tops.
static func skyline(width: float, rng_seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var st := _st()
	var x := -width * 0.5
	while x < width * 0.5:
		var w := rng.randf_range(0.6, 1.6)
		var h := rng.randf_range(0.6, 3.2)
		var d := rng.randf_range(0.6, 1.2)
		box(st, Vector3(x, -2.0, -d), Vector3(x + w * 0.9, h, d))
		if rng.randf() < 0.4:
			box(st, Vector3(x + w * 0.25, h, -d * 0.5), Vector3(x + w * 0.65, h + rng.randf_range(0.4, 1.4), d * 0.5))
		x += w
	var mesh := ArrayMesh.new()
	_commit(mesh, st, "body")
	return mesh


## Cloud: a row of overlapping faceted puffs, wide and flat-bottomed, biggest in the middle.
static func cloud(rng_seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var st := _st()
	var n := rng.randi_range(3, 5)
	for i in range(n):
		var k := (float(i) / (n - 1)) * 2.0 - 1.0             # -1..1 across the cloud
		var r := lerpf(0.55, 0.3, absf(k)) * rng.randf_range(0.85, 1.15)
		octa(st, Vector3(k * 0.75, (1.0 - absf(k)) * 0.12, rng.randf_range(-0.1, 0.1)), r, Vector3(1.5, 0.9, 0.8))
	var mesh := ArrayMesh.new()
	_commit(mesh, st, "body")
	return mesh


## Particle shard (small octahedron, about 1 unit across; scaled per instance).
static func shard() -> ArrayMesh:
	var st := _st()
	octa(st, Vector3.ZERO, 0.5)
	var mesh := ArrayMesh.new()
	_commit(mesh, st, "emissive")
	return mesh


## Flat ring in the XY plane (faces the camera), used for the perfect-landing flash.
static func ring(radius: float, thickness: float, segments: int) -> ArrayMesh:
	var st := _st()
	for i in range(segments):
		var a0 := TAU * i / segments
		var a1 := TAU * (i + 1) / segments
		var o0 := Vector3(cos(a0), sin(a0), 0) * radius
		var o1 := Vector3(cos(a1), sin(a1), 0) * radius
		var i0 := o0 * (1.0 - thickness / radius)
		var i1 := o1 * (1.0 - thickness / radius)
		quad(st, i0, o0, o1, i1, Vector3.BACK)
	var mesh := ArrayMesh.new()
	_commit(mesh, st, "emissive")
	return mesh

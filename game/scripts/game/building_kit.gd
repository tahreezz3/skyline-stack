## Detailed low-poly building parts (T-0308), modelled on the owner's reference
## (docs/art/references/owner_reference_corner_building.webp): corner pilasters,
## stepped cornices, siding battens, mullioned windows with sills, flower pots,
## and a distinct shop-front ground storey with plinth panels, arched doors and a
## striped awning that wraps the corners.
##
## Square footprint: the view turns every block by BUILDING_YAW so two faces show;
## the footprint is sized so the turned block's on-screen width matches the
## gameplay width (1 unit). Origin at bottom centre, y up.
##
## Surface (material slot) names, recoloured per tower family by tower_view_3d.gd
## and expected in delivered .glb models (docs/06_ART_AUDIO_SPEC.md §2.6):
##   body, body_dark, body2, wall2, trim, accent, glass, pot, plant, emissive
extends RefCounted

const LowPoly := preload("res://scripts/game/low_poly.gd")

## Core half-width. Core (0.66) turned by 38° spans ~0.93 on screen; cornices ~1.06.
const C := 0.33


## Collects triangles per named surface under a movable transform, so one facade
## can be written once and repeated on all four sides.
class Builder:
	var surfaces: Dictionary = {}
	var order: Array[String] = []
	var xf := Transform3D.IDENTITY

	func st(name: String) -> SurfaceTool:
		if not surfaces.has(name):
			var s := SurfaceTool.new()
			s.begin(Mesh.PRIMITIVE_TRIANGLES)
			surfaces[name] = s
			order.append(name)
		return surfaces[name]

	func tri(name: String, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
		LowPoly.tri(st(name), xf * a, xf * b, xf * c, xf.basis * outward)

	func quad(name: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
		tri(name, a, b, c, outward)
		tri(name, a, c, d, outward)

	func box(name: String, lo: Vector3, hi: Vector3, bottom := false) -> void:
		var x0 := minf(lo.x, hi.x)
		var x1 := maxf(lo.x, hi.x)
		var y0 := minf(lo.y, hi.y)
		var y1 := maxf(lo.y, hi.y)
		var z0 := minf(lo.z, hi.z)
		var z1 := maxf(lo.z, hi.z)
		quad(name, Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.BACK)
		quad(name, Vector3(x1, y0, z0), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3.FORWARD)
		quad(name, Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3.RIGHT)
		quad(name, Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), Vector3.LEFT)
		quad(name, Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3(x0, y1, z0), Vector3.UP)
		if bottom:
			quad(name, Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector3.DOWN)

	## Frustum (tapered low-poly cylinder) with a top cap.
	func frustum(name: String, base: Vector3, r0: float, r1: float, h: float, sides: int) -> void:
		for i in range(sides):
			var a0 := TAU * i / sides
			var a1 := TAU * (i + 1) / sides
			var d0 := Vector3(cos(a0), 0, sin(a0))
			var d1 := Vector3(cos(a1), 0, sin(a1))
			var up := Vector3(0, h, 0)
			quad(name, base + d0 * r0, base + d1 * r0, base + up + d1 * r1, base + up + d0 * r1, (d0 + d1) * 0.5)
			tri(name, base + up, base + up + d0 * r1, base + up + d1 * r1, Vector3.UP)

	func cone(name: String, base: Vector3, r: float, h: float, sides: int, offset := 0.0) -> void:
		var apex := base + Vector3(0, h, 0)
		for i in range(sides):
			var a0 := offset + TAU * i / sides
			var a1 := offset + TAU * (i + 1) / sides
			var p0 := base + Vector3(cos(a0), 0, sin(a0)) * r
			var p1 := base + Vector3(cos(a1), 0, sin(a1)) * r
			tri(name, p0, p1, apex, (p0 + p1) * 0.5 - base + Vector3(0, r * 0.3, 0))

	func blob(name: String, c: Vector3, r: float) -> void:
		var pts := [Vector3(r, 0, 0), Vector3(-r, 0, 0), Vector3(0, r, 0), Vector3(0, -r * 0.5, 0), Vector3(0, 0, r), Vector3(0, 0, -r)]
		for e in [[0, 4], [4, 1], [1, 5], [5, 0]]:
			for pole in [2, 3]:
				var a: Vector3 = c + pts[e[0]]
				var b: Vector3 = c + pts[e[1]]
				var p: Vector3 = c + pts[pole]
				tri(name, a, b, p, (a + b + p) / 3.0 - c)

	## Arched opening on the +Z plane: rectangle up to y_spring, then a faceted arch.
	## Extruded from z0 to z1 (front face plus side walls).
	func arch(name: String, cx: float, half_w: float, y0: float, y_spring: float, z0: float, z1: float, segs := 4, pointed := 0.25) -> void:
		var pts: Array[Vector3] = [Vector3(cx - half_w, y0, z1), Vector3(cx + half_w, y0, z1)]
		for i in range(segs + 1):
			var a := PI * i / segs
			var lift := 1.0 + pointed * sin(a)       # slightly pointed, like the reference
			pts.append(Vector3(cx + cos(a) * half_w, y_spring + sin(a) * half_w * lift, z1))
		var centre := Vector3(cx, (y0 + y_spring) * 0.5, z1)
		for i in range(pts.size()):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[(i + 1) % pts.size()]
			tri(name, centre, a, b, Vector3.BACK)
			if i != 0:   # side walls (skip the bottom edge)
				var out := ((a + b) * 0.5 - centre)
				out.z = 0.0
				quad(name, Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0), b, a, out)

	## Run `fn(face_index)` once per side with the transform turned to that side.
	func each_side(fn: Callable) -> void:
		for i in range(4):
			xf = Transform3D(Basis(Vector3.UP, i * PI / 2.0), Vector3.ZERO)
			fn.call(i)
		xf = Transform3D.IDENTITY

	func commit() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		for name in order:
			(surfaces[name] as SurfaceTool).commit(mesh)
			mesh.surface_set_name(mesh.get_surface_count() - 1, name)
		return mesh


## Regular storey: siding, corner pilasters, stepped cornice, one mullioned window per
## side with a sill, and a flower pot on alternating sides.
static func storey(h: float) -> ArrayMesh:
	var b := Builder.new()
	# core stops inside the cornice: two top faces at the same height would z-fight (T-0307)
	b.box("body", Vector3(-C, 0.0, -C), Vector3(C, h - 0.03, C))
	b.box("trim", Vector3(-0.355, 0.0, -0.355), Vector3(0.355, 0.035, 0.355))            # ledge
	b.box("trim", Vector3(-0.375, h - 0.05, -0.375), Vector3(0.375, h - 0.02, 0.375))    # cornice
	b.box("trim", Vector3(-0.36, h - 0.02, -0.36), Vector3(0.36, h, 0.36))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:                                                            # corner pilasters
			b.box("trim", Vector3(sx * 0.300, 0.035, sz * 0.300), Vector3(sx * 0.362, h - 0.05, sz * 0.362))
	b.each_side(func(i: int) -> void:
		for k in range(9):                                                                # siding battens
			var x := -0.26 + k * 0.065
			b.box("body_dark", Vector3(x - 0.005, 0.035, C), Vector3(x + 0.005, h - 0.05, C + 0.005))
		b.box("glass", Vector3(-0.2, 0.17, C), Vector3(0.2, 0.452, C + 0.010))
		b.box("accent", Vector3(-0.225, 0.455, C), Vector3(0.225, 0.48, C + 0.024))         # frame
		b.box("accent", Vector3(-0.225, 0.145, C), Vector3(0.225, 0.17, C + 0.024))
		b.box("accent", Vector3(-0.225, 0.17, C), Vector3(-0.2, 0.454, C + 0.024))
		b.box("accent", Vector3(0.2, 0.17, C), Vector3(0.225, 0.454, C + 0.024))
		b.box("accent", Vector3(-0.008, 0.17, C), Vector3(0.008, 0.453, C + 0.018))        # mullions
		b.box("accent", Vector3(-0.2, 0.305, C), Vector3(0.2, 0.32, C + 0.018))
		b.box("accent", Vector3(-0.105, 0.17, C), Vector3(-0.095, 0.453, C + 0.016))
		b.box("accent", Vector3(0.095, 0.17, C), Vector3(0.105, 0.453, C + 0.016))
		b.box("trim", Vector3(-0.245, 0.125, C), Vector3(0.245, 0.145, C + 0.04))          # sill
		var px := -0.255 if i % 2 == 0 else 0.255                                            # flower pot
		b.frustum("pot", Vector3(px, 0.035, C + 0.022), 0.02, 0.03, 0.045, 6)
		b.blob("plant", Vector3(px - 0.012, 0.095, C + 0.022), 0.024)
		b.blob("plant", Vector3(px + 0.013, 0.1, C + 0.018), 0.02)
	)
	return b.commit()


## Ground storey / shop front: panelled plinth, arched doors between white columns,
## striped awning wrapping all four sides, cornice above.
static func base_storey(h: float) -> ArrayMesh:
	var b := Builder.new()
	b.box("trim", Vector3(-0.385, 0.0, -0.385), Vector3(0.385, 0.025, 0.385))            # skirt
	b.box("body2", Vector3(-0.37, 0.025, -0.37), Vector3(0.37, 0.17, 0.37))              # plinth
	b.box("trim", Vector3(-0.385, 0.17, -0.385), Vector3(0.385, 0.2, 0.385))             # ledge
	b.box("wall2", Vector3(-C, 0.2, -C), Vector3(C, 0.496, C))                              # shop wall
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:                                                            # corner columns
			b.box("trim", Vector3(sx * 0.295, 0.2, sz * 0.295), Vector3(sx * 0.365, 0.498, sz * 0.365))
	b.box("trim", Vector3(-0.375, 0.5, -0.375), Vector3(0.375, 0.555, 0.375))            # cornice
	b.box("trim", Vector3(-0.36, 0.555, -0.36), Vector3(0.36, h, 0.36))
	b.each_side(func(_i: int) -> void:
		for k in range(4):                                                                # plinth panels
			var x := -0.24 + k * 0.16
			b.box("trim", Vector3(x - 0.06, 0.05, 0.37), Vector3(x + 0.06, 0.145, 0.378))
		b.box("trim", Vector3(-0.022, 0.2, C), Vector3(0.022, 0.497, C + 0.016))             # centre column
		for dx in [-0.145, 0.145]:                                                        # arched doors
			b.arch("accent", dx, 0.085, 0.2, 0.34, C, C + 0.012)
			b.arch("glass", dx, 0.066, 0.2, 0.335, C, C + 0.019)
		# striped awning: a sloped trapezoid; neighbouring sides meet on the diagonal (hip)
		var strips := 8
		var top_y := 0.505
		var bot_y := 0.405
		for k in range(strips):
			var u0 := float(k) / strips
			var u1 := float(k + 1) / strips
			var name := "accent" if k % 2 == 0 else "trim"
			var t0 := Vector3(lerpf(-0.34, 0.34, u0), top_y, 0.34)
			var t1 := Vector3(lerpf(-0.34, 0.34, u1), top_y, 0.34)
			var b0 := Vector3(lerpf(-0.47, 0.47, u0), bot_y, 0.47)
			var b1 := Vector3(lerpf(-0.47, 0.47, u1), bot_y, 0.47)
			b.quad(name, b0, b1, t1, t0, Vector3(0, 0.75, 0.6))
			b.quad(name, b0 + Vector3(0, -0.035, 0), b1 + Vector3(0, -0.035, 0), b1, b0, Vector3.BACK)   # valance
	)
	return b.commit()


## Roof that caps the finished tower: parapet, roof deck, water tank, AC unit, antenna.
## The trophy roof adds a stepped golden spire with an emissive star.
static func roof(trophy: bool) -> ArrayMesh:
	var b := Builder.new()
	b.box("body2", Vector3(-0.34, 0.0, -0.34), Vector3(0.34, 0.045, 0.34))               # roof deck
	for s in [-1.0, 1.0]:                                                                 # parapet ring
		b.box("trim", Vector3(-0.375, 0.0, s * 0.34), Vector3(0.375, 0.09, s * 0.375))
		b.box("trim", Vector3(s * 0.34, 0.0, -0.34), Vector3(s * 0.375, 0.09, 0.34))
	if trophy:
		b.box("trim", Vector3(-0.2, 0.045, -0.2), Vector3(0.2, 0.2, 0.2))
		b.box("trim", Vector3(-0.13, 0.2, -0.13), Vector3(0.13, 0.32, 0.13))
		b.cone("trim", Vector3(0, 0.32, 0), 0.14, 0.34, 4, PI / 4.0)
		b.blob("emissive", Vector3(0, 0.72, 0), 0.06)
	else:
		b.frustum("accent", Vector3(0.14, 0.045, -0.12), 0.075, 0.075, 0.18, 7)            # water tank
		b.cone("accent", Vector3(0.14, 0.225, -0.12), 0.085, 0.07, 7)
		for lx in [0.08, 0.2]:
			b.box("body_dark", Vector3(lx - 0.008, 0.07, -0.05), Vector3(lx + 0.008, 0.11, -0.04))
		b.box("trim", Vector3(-0.22, 0.045, 0.04), Vector3(-0.06, 0.15, 0.2))              # AC unit
		b.box("body_dark", Vector3(-0.2, 0.09, 0.2), Vector3(-0.08, 0.135, 0.205))
		b.box("trim", Vector3(-0.24, 0.045, -0.24), Vector3(-0.225, 0.42, -0.225))          # antenna
		b.blob("emissive", Vector3(-0.2325, 0.44, -0.2325), 0.022)
	return b.commit()

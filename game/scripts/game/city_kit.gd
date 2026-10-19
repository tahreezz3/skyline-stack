## Procedural low-poly city around the tower (T-0309): the street in front (sidewalks,
## curb, asphalt, lane markings, zebra crossing, foundation pad), city rows behind,
## cars and street lights. Same style rules as building_kit.gd (flat-shaded, named
## surfaces). City rows use vertex colours so one mesh holds many coloured buildings.
##
## Layout (world units, z towards the camera): the tower stands at the origin on the
## back sidewalk; the road runs along x in front of it (z 1.3..5.3); city rows sit
## behind (negative z).
##
## Surfaces: sidewalk, curb, asphalt, marking, plinth (street); body (vertex colour),
## trim, glass, glass_dark, accent (vertex colour), roof (city rows); car parts.
extends RefCounted

const Kit := preload("res://scripts/game/building_kit.gd")

const ROAD_NEAR := 5.3
const ROAD_FAR := 1.3
const PASTELS := ["#f2c6a0", "#a9c8e8", "#f5e1a4", "#c6e2c3", "#e8b4b8", "#d9cdf0", "#f7d9c4", "#b7d7d8", "#efe6d8", "#c9d3e6"]
const ACCENTS := ["#d9825b", "#3f9a9c", "#4a7fc1", "#c95f6e", "#5e9e5a"]


## The street: back sidewalk (tower side), curb, road with markings and a zebra
## crossing in front of the tower, front sidewalk, and the tower's foundation pad.
static func street(width: float) -> ArrayMesh:
	var b := Kit.Builder.new()
	var hw := width * 0.5
	# Top faces all sit at different heights (no z-fighting, T-0307).
	b.box("sidewalk", Vector3(-hw, -2.0, -40.0), Vector3(hw, -0.035, ROAD_FAR - 0.12))            # back sidewalk
	b.box("curb", Vector3(-hw, -2.0, ROAD_FAR - 0.12), Vector3(hw, -0.03, ROAD_FAR))              # curb stone
	b.box("asphalt", Vector3(-hw, -2.0, ROAD_FAR), Vector3(hw, -0.09, ROAD_NEAR))                 # road
	b.box("curb", Vector3(-hw, -2.0, ROAD_NEAR), Vector3(hw, -0.03, ROAD_NEAR + 0.12))
	b.box("sidewalk", Vector3(-hw, -2.0, ROAD_NEAR + 0.12), Vector3(hw, -0.035, ROAD_NEAR + 6.0))  # front sidewalk
	# sidewalk paving joints (thin raised strips)
	var x := -hw
	while x < hw:
		b.box("curb", Vector3(x, -0.035, -1.6), Vector3(x + 0.02, -0.03, ROAD_FAR - 0.12))
		x += 0.6
	var mid := (ROAD_FAR + ROAD_NEAR) * 0.5
	var cross_half := 0.55
	# dashed centre line, interrupted by the crossing
	x = -hw
	while x < hw:
		if x + 0.5 < -cross_half or x > cross_half:
			b.box("marking", Vector3(x, -0.09, mid - 0.04), Vector3(x + 0.5, -0.084, mid + 0.04))
		x += 0.9
	# edge lines
	b.box("marking", Vector3(-hw, -0.09, ROAD_FAR + 0.12), Vector3(hw, -0.085, ROAD_FAR + 0.17))
	b.box("marking", Vector3(-hw, -0.09, ROAD_NEAR - 0.17), Vector3(hw, -0.085, ROAD_NEAR - 0.12))
	# zebra crossing in front of the tower: bars along the traffic direction, side by side across the road
	var z := ROAD_FAR + 0.3
	while z < ROAD_NEAR - 0.35:
		b.box("marking", Vector3(-cross_half, -0.09, z), Vector3(cross_half, -0.082, z + 0.22))
		z += 0.42
	# foundation pad the first storey sits on (the visible building zone)
	b.box("plinth", Vector3(-0.75, -0.06, -0.7), Vector3(0.75, -0.015, 0.7))
	b.box("plinth", Vector3(-0.62, -0.015, -0.58), Vector3(0.62, 0.0, 0.58))
	return b.commit()


## One generic city building into builder `b`: body, cornice, window grid on the front
## (+Z) and both sides, optional shop awning and rooftop props. `detail` 0..1.
static func _building(b: Kit.Builder, rng: RandomNumberGenerator, x0: float, z_front: float, w: float, d: float, h: float, detail: float) -> void:
	var colour := Color(PASTELS[rng.randi() % PASTELS.size()])
	var accent := Color(ACCENTS[rng.randi() % ACCENTS.size()])
	var x1 := x0 + w
	var zb := z_front - d
	b.color = colour
	b.box("body", Vector3(x0, -2.0, zb), Vector3(x1, h - 0.06, z_front))
	b.color = Color.WHITE
	b.box("trim", Vector3(x0 - 0.04, h - 0.08, zb - 0.04), Vector3(x1 + 0.04, h, z_front + 0.04))     # cornice
	var floor_h := rng.randf_range(0.36, 0.46)
	var cols := maxi(1, int(w / 0.3))
	var col_w := w / cols
	var first := 0.6 if detail > 0.5 else 0.25            # ground floor height (shops on near rows)
	var y := first
	while y + floor_h < h - 0.12:
		for c in range(cols):
			var cx := x0 + (c + 0.5) * col_w
			var lit := "glass" if rng.randf() < 0.55 else "glass_dark"
			b.box(lit, Vector3(cx - col_w * 0.28, y + floor_h * 0.2, z_front), Vector3(cx + col_w * 0.28, y + floor_h * 0.8, z_front + 0.015))
		if detail > 0.3:                                   # side windows (visible on the corners)
			for side in [x0, x1]:
				var dir := -1.0 if side == x0 else 1.0
				for k in range(maxi(1, int(d / 0.35))):
					var cz := z_front - (k + 0.5) * (d / maxi(1, int(d / 0.35)))
					var lit2 := "glass" if rng.randf() < 0.5 else "glass_dark"
					b.box(lit2, Vector3(side, y + floor_h * 0.2, cz - 0.07), Vector3(side + dir * 0.015, y + floor_h * 0.8, cz + 0.07))
		if detail > 0.6:                                   # floor band
			b.box("trim", Vector3(x0, y - 0.015, z_front), Vector3(x1, y + 0.005, z_front + 0.02))
		y += floor_h
	if detail > 0.5:                                       # shop front: glass + striped awning
		b.box("glass", Vector3(x0 + 0.08, 0.05, z_front), Vector3(x1 - 0.08, 0.42, z_front + 0.012))
		var strips := maxi(4, int(w / 0.12))
		for k in range(strips):
			var u0 := x0 + w * k / strips
			var u1 := x0 + w * (k + 1) / strips
			b.color = accent if k % 2 == 0 else Color("#f3f1ec")
			b.quad("accent", Vector3(u0, 0.43, z_front + 0.22), Vector3(u1, 0.43, z_front + 0.22), Vector3(u1, 0.53, z_front), Vector3(u0, 0.53, z_front), Vector3(0, 0.8, 0.6))
			b.quad("accent", Vector3(u0, 0.39, z_front + 0.22), Vector3(u1, 0.39, z_front + 0.22), Vector3(u1, 0.43, z_front + 0.22), Vector3(u0, 0.43, z_front + 0.22), Vector3.BACK)
		b.color = Color.WHITE
	if detail > 0.2:                                       # rooftop props
		var r := rng.randf()
		var cx := x0 + w * rng.randf_range(0.25, 0.75)
		var cz := z_front - d * rng.randf_range(0.3, 0.7)
		if r < 0.35:
			b.frustum("roof", Vector3(cx, h, cz), 0.12, 0.12, 0.22, 7)                      # water tank
			b.cone("roof", Vector3(cx, h + 0.22, cz), 0.14, 0.1, 7)
		elif r < 0.7:
			b.box("roof", Vector3(cx - 0.15, h, cz - 0.1), Vector3(cx + 0.15, h + 0.14, cz + 0.1))   # AC unit
		else:
			b.box("roof", Vector3(cx - 0.012, h, cz - 0.012), Vector3(cx + 0.012, h + 0.6, cz + 0.012))   # antenna


## A row of buildings side by side along x, fronts at z_front. Returns one mesh.
static func city_row(rng_seed: int, x_from: float, x_to: float, z_front: float, depth: float, min_h: float, max_h: float, detail: float, gap_at_origin := 0.0) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var b := Kit.Builder.new()
	var x := x_from
	while x < x_to:
		var w := rng.randf_range(0.9, 1.7)
		if gap_at_origin > 0.0 and x < gap_at_origin and x + w > -gap_at_origin:
			x = gap_at_origin      # keep the space behind the tower clear
			continue
		var zf := z_front - rng.randf_range(0.0, 0.35)
		_building(b, rng, x, zf, w - 0.06, depth * rng.randf_range(0.8, 1.1), rng.randf_range(min_h, max_h), detail)
		x += w
	return b.commit()


## Low-poly car: body, cabin, windows, wheels, head/tail lights. Length along x.
static func car(rng_seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var b := Kit.Builder.new()
	var L := 0.36
	var W := 0.17
	b.box("body", Vector3(-L, 0.05, -W), Vector3(L, 0.17, W))
	b.box("body", Vector3(-L * 0.55, 0.17, -W * 0.92), Vector3(L * 0.45, 0.28, W * 0.92))      # cabin
	b.box("glass", Vector3(-L * 0.5, 0.18, W * 0.92), Vector3(L * 0.4, 0.26, W * 0.95))        # side windows
	b.box("glass", Vector3(-L * 0.5, 0.18, -W * 0.95), Vector3(L * 0.4, 0.26, -W * 0.92))
	b.box("glass", Vector3(L * 0.45, 0.18, -W * 0.85), Vector3(L * 0.47, 0.26, W * 0.85))      # windscreen
	for wx in [-L * 0.62, L * 0.62]:
		for wz in [-W, W]:
			b.xf = Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(wx, 0.06, wz))
			b.frustum("wheel", Vector3(0, -0.03, 0), 0.06, 0.06, 0.06, 8)
	b.xf = Transform3D.IDENTITY
	b.box("emissive", Vector3(L, 0.1, -W * 0.8), Vector3(L + 0.01, 0.14, -W * 0.45))          # headlights
	b.box("emissive", Vector3(L, 0.1, W * 0.45), Vector3(L + 0.01, 0.14, W * 0.8))
	b.box("tail", Vector3(-L - 0.01, 0.1, -W * 0.8), Vector3(-L, 0.14, -W * 0.45))            # tail lights
	b.box("tail", Vector3(-L - 0.01, 0.1, W * 0.45), Vector3(-L, 0.14, W * 0.8))
	return b.commit()


## Street light: pole, arm reaching over the sidewalk edge, lamp head (emissive).
static func street_light() -> ArrayMesh:
	var b := Kit.Builder.new()
	b.frustum("pole", Vector3.ZERO, 0.03, 0.022, 1.1, 6)
	b.box("pole", Vector3(-0.015, 1.06, 0.0), Vector3(0.015, 1.09, 0.32))
	b.box("pole", Vector3(-0.05, 1.02, 0.26), Vector3(0.05, 1.07, 0.38))
	b.box("lamp", Vector3(-0.04, 1.005, 0.27), Vector3(0.04, 1.02, 0.37))
	return b.commit()

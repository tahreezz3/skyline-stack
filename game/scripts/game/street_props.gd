## Detailed foreground props for the street (T-0312): ornate post-top street lamps,
## a slatted park bench, a wooden flower planter, a fire hydrant, a trash bin, a café
## A-frame sign, a manhole cover, a storm drain, and three car models with real
## silhouettes. Flat-shaded low-poly, named surfaces (recoloured by tower_view_3d.gd).
##
## Surfaces used: iron, glass_lamp, wood, wood_dark, metal, paint, rubber, hub, chrome,
## glass, light, tail, red, green, board, chalk, leaf, flower_a, flower_b, flower_c, soil.
extends RefCounted

const Kit := preload("res://scripts/game/building_kit.gd")


## Classic post-top street lamp, ~1.2 tall: octagonal plinth, fluted pole with collars,
## lantern with glass (glows at night), cap and finial. Light source sits at LAMP_Y.
const LAMP_Y := 1.08

static func street_lamp() -> ArrayMesh:
	var b := Kit.Builder.new()
	b.frustum("iron", Vector3.ZERO, 0.075, 0.06, 0.05, 8)                 # base plinth
	b.frustum("iron", Vector3(0, 0.05, 0), 0.055, 0.035, 0.12, 8)         # flared foot
	b.frustum("iron", Vector3(0, 0.17, 0), 0.026, 0.021, 0.78, 8)         # pole
	for y in [0.17, 0.45, 0.93]:
		b.frustum("iron", Vector3(0, y, 0), 0.036, 0.036, 0.025, 8)        # collars
	b.frustum("iron", Vector3(0, 0.955, 0), 0.03, 0.05, 0.05, 6)           # lantern seat
	b.frustum("glass_lamp", Vector3(0, 1.005, 0), 0.045, 0.062, 0.13, 6)   # glass
	for i in range(6):                                                    # lantern frame bars
		var a := TAU * i / 6.0
		var p0 := Vector3(cos(a) * 0.046, 1.005, sin(a) * 0.046)
		var p1 := Vector3(cos(a) * 0.063, 1.135, sin(a) * 0.063)
		b.box("iron", p0 - Vector3(0.006, 0, 0.006), Vector3(p1.x + 0.006, 1.135, p1.z + 0.006))
	b.cone("iron", Vector3(0, 1.135, 0), 0.085, 0.07, 6)                   # cap
	b.blob("iron", Vector3(0, 1.22, 0), 0.016)                             # finial
	return b.commit()


## Park bench: three seat slats, two back slats, cast-iron sides with armrests.
static func bench() -> ArrayMesh:
	var b := Kit.Builder.new()
	for k in range(3):
		var z := -0.045 + k * 0.035
		b.box("wood", Vector3(-0.21, 0.072, z - 0.014), Vector3(0.21, 0.086, z + 0.014))
	for k in range(2):
		var y := 0.11 + k * 0.04
		b.box("wood", Vector3(-0.21, y, -0.068), Vector3(0.21, y + 0.028, -0.056))
	for sx in [-0.185, 0.185]:
		b.box("iron", Vector3(sx - 0.009, 0.0, 0.04), Vector3(sx + 0.009, 0.075, 0.052))     # front leg
		b.box("iron", Vector3(sx - 0.009, 0.0, -0.07), Vector3(sx + 0.009, 0.185, -0.058))   # back leg + back post
		b.box("iron", Vector3(sx - 0.009, 0.06, -0.07), Vector3(sx + 0.009, 0.072, 0.05))    # seat rail
		b.box("iron", Vector3(sx - 0.011, 0.12, -0.065), Vector3(sx + 0.011, 0.132, 0.06))   # armrest
		b.box("iron", Vector3(sx - 0.009, 0.075, 0.048), Vector3(sx + 0.009, 0.125, 0.058))  # armrest post
	return b.commit()


## Wooden planter box with plank lines, soil, leaves and three flower colours.
static func planter() -> ArrayMesh:
	var b := Kit.Builder.new()
	b.box("wood", Vector3(-0.17, 0.0, -0.09), Vector3(0.17, 0.12, 0.09))
	for y in [0.04, 0.08]:                                                 # plank grooves
		b.box("wood_dark", Vector3(-0.172, y - 0.004, -0.092), Vector3(0.172, y + 0.004, 0.092))
	b.box("wood_dark", Vector3(-0.18, 0.12, -0.1), Vector3(0.18, 0.135, 0.1))   # rim
	b.box("soil", Vector3(-0.15, 0.135, -0.075), Vector3(0.15, 0.14, 0.075))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var flowers := ["flower_a", "flower_b", "flower_c"]
	for i in range(7):
		var c := Vector3(-0.12 + i * 0.04, 0.16 + rng.randf_range(0.0, 0.03), rng.randf_range(-0.04, 0.04))
		b.blob("leaf", c, 0.04)
		var f: String = flowers[i % 3]
		b.box("leaf", c + Vector3(-0.003, 0.0, -0.003), c + Vector3(0.003, 0.05, 0.003))   # stem
		for p in range(5):                                                                    # petals
			var a := TAU * p / 5.0
			b.blob(f, c + Vector3(cos(a) * 0.012, 0.055, sin(a) * 0.012), 0.009)
		b.blob("flower_c" if f != "flower_c" else "flower_a", c + Vector3(0, 0.058, 0), 0.006)   # centre
	return b.commit()


## Fire hydrant: base flange, body, bonnet dome, side nozzles, cap chains.
static func hydrant() -> ArrayMesh:
	var b := Kit.Builder.new()
	b.frustum("red", Vector3.ZERO, 0.05, 0.05, 0.02, 8)
	b.frustum("red", Vector3(0, 0.02, 0), 0.034, 0.03, 0.12, 8)
	b.frustum("red", Vector3(0, 0.14, 0), 0.042, 0.042, 0.015, 8)
	b.cone("red", Vector3(0, 0.155, 0), 0.034, 0.04, 8)
	b.blob("chrome", Vector3(0, 0.198, 0), 0.008)
	for sx in [-1.0, 1.0]:
		b.xf = Transform3D(Basis(Vector3.BACK, sx * PI / 2.0), Vector3(sx * 0.028, 0.09, 0))
		b.frustum("red", Vector3.ZERO, 0.016, 0.014, 0.025, 6)
		b.frustum("chrome", Vector3(0, 0.025, 0), 0.018, 0.018, 0.008, 6)
	b.xf = Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.08, 0.028))
	b.frustum("red", Vector3.ZERO, 0.02, 0.018, 0.02, 6)                    # front nozzle
	b.xf = Transform3D.IDENTITY
	return b.commit()


## Slatted metal trash bin with a domed lid.
static func trash_bin() -> ArrayMesh:
	var b := Kit.Builder.new()
	b.frustum("green", Vector3.ZERO, 0.055, 0.06, 0.18, 10)
	for y in [0.03, 0.15]:
		b.frustum("metal", Vector3(0, y, 0), 0.063, 0.063, 0.012, 10)
	b.frustum("metal", Vector3(0, 0.18, 0), 0.066, 0.055, 0.02, 10)
	b.cone("metal", Vector3(0, 0.2, 0), 0.055, 0.03, 10)
	return b.commit()


## Café A-frame chalkboard sign with "menu" lines and a little coffee-cup doodle.
static func cafe_sign() -> ArrayMesh:
	var b := Kit.Builder.new()
	for side in [-1.0, 1.0]:
		var tilt := Basis(Vector3.RIGHT, side * 0.22)
		b.xf = Transform3D(tilt, Vector3(0, 0, side * 0.03))
		b.box("wood", Vector3(-0.07, 0.0, -0.006), Vector3(0.07, 0.2, 0.006))
		b.box("board", Vector3(-0.058, 0.02, side * 0.006 - 0.001), Vector3(0.058, 0.185, side * 0.006 + 0.001))
		for k in range(3):
			var y := 0.13 - k * 0.03
			b.box("chalk", Vector3(-0.045, y, side * 0.0075 - 0.0005), Vector3(0.03 - k * 0.012, y + 0.006, side * 0.0075 + 0.0005))
		b.box("chalk", Vector3(-0.015, 0.035, side * 0.0075 - 0.0005), Vector3(0.015, 0.06, side * 0.0075 + 0.0005))   # cup
	b.xf = Transform3D.IDENTITY
	return b.commit()


## Manhole cover (flush with the asphalt, slightly raised) and curb storm drain.
static func manhole() -> ArrayMesh:
	var b := Kit.Builder.new()
	b.frustum("metal", Vector3(0, -0.09, 0), 0.16, 0.16, 0.003, 12)
	for r in [0.11, 0.06]:
		b.frustum("chrome", Vector3(0, -0.087, 0), r, r, 0.0015, 12)
	return b.commit()


static func storm_drain() -> ArrayMesh:
	var b := Kit.Builder.new()
	b.box("metal", Vector3(-0.16, -0.09, 0.0), Vector3(0.16, -0.087, 0.12))
	for k in range(7):
		var x := -0.13 + k * 0.043
		b.box("chrome", Vector3(x, -0.087, 0.015), Vector3(x + 0.02, -0.0855, 0.105))
	return b.commit()


## Cars with real silhouettes (side profile extruded across the width). Front at +x.
## kind: 0 = compact hatchback, 1 = rounded retro car, 2 = little van.
static func car(kind: int) -> ArrayMesh:
	var b := Kit.Builder.new()
	var L := 0.38
	var W := 0.17
	var profile: Array
	var win_front: Array
	var win_rear: Array
	match kind:
		0:
			profile = [Vector2(-L, 0.05), Vector2(L, 0.05), Vector2(L, 0.13), Vector2(L * 0.92, 0.16), Vector2(L * 0.42, 0.18),
				Vector2(L * 0.12, 0.29), Vector2(-L * 0.62, 0.29), Vector2(-L * 0.95, 0.2), Vector2(-L, 0.15)]
			win_front = [Vector2(L * 0.36, 0.19), Vector2(L * 0.12, 0.275), Vector2(-L * 0.2, 0.275), Vector2(-L * 0.2, 0.19)]
			win_rear = [Vector2(-L * 0.26, 0.19), Vector2(-L * 0.26, 0.275), Vector2(-L * 0.6, 0.275), Vector2(-L * 0.86, 0.2)]
		1:
			profile = [Vector2(-L, 0.06), Vector2(L, 0.06), Vector2(L, 0.12), Vector2(L * 0.85, 0.17), Vector2(L * 0.5, 0.19),
				Vector2(L * 0.25, 0.3), Vector2(-L * 0.25, 0.31), Vector2(-L * 0.55, 0.27), Vector2(-L * 0.85, 0.19), Vector2(-L, 0.13)]
			win_front = [Vector2(L * 0.44, 0.2), Vector2(L * 0.23, 0.29), Vector2(0.0, 0.295), Vector2(0.0, 0.2)]
			win_rear = [Vector2(-L * 0.06, 0.2), Vector2(-L * 0.06, 0.295), Vector2(-L * 0.3, 0.29), Vector2(-L * 0.6, 0.2)]
		_:
			profile = [Vector2(-L, 0.05), Vector2(L, 0.05), Vector2(L, 0.15), Vector2(L * 0.8, 0.2), Vector2(L * 0.62, 0.33),
				Vector2(-L, 0.34)]
			win_front = [Vector2(L * 0.58, 0.215), Vector2(L * 0.48, 0.315), Vector2(L * 0.1, 0.315), Vector2(L * 0.1, 0.215)]
			win_rear = [Vector2(0.0, 0.215), Vector2(0.0, 0.315), Vector2(-L * 0.4, 0.315), Vector2(-L * 0.4, 0.215)]
	b.extrude("paint", profile, -W, W)
	for side in [-1.0, 1.0]:                                     # side windows sit just proud of the body
		var z0: float = side * W
		var z1: float = side * (W + 0.004)
		b.extrude("glass", win_front, minf(z0, z1), maxf(z0, z1))
		b.extrude("glass", win_rear, minf(z0, z1), maxf(z0, z1))
	b.box("chrome", Vector3(L - 0.01, 0.05, -W - 0.005), Vector3(L + 0.018, 0.08, W + 0.005))     # bumpers
	b.box("chrome", Vector3(-L - 0.018, 0.05, -W - 0.005), Vector3(-L + 0.01, 0.08, W + 0.005))
	b.box("light", Vector3(L, 0.1, -W * 0.85), Vector3(L + 0.008, 0.13, -W * 0.5))                 # headlights
	b.box("light", Vector3(L, 0.1, W * 0.5), Vector3(L + 0.008, 0.13, W * 0.85))
	b.box("tail", Vector3(-L - 0.008, 0.1, -W * 0.85), Vector3(-L, 0.135, -W * 0.55))              # tail lights
	b.box("tail", Vector3(-L - 0.008, 0.1, W * 0.55), Vector3(-L, 0.135, W * 0.85))
	for side in [-1.0, 1.0]:                                                                        # mirrors
		b.box("paint", Vector3(L * 0.3, 0.18, side * W), Vector3(L * 0.36, 0.205, side * (W + 0.025)))
	for wx in [-L * 0.62, L * 0.62]:                                                                # wheels + hubs
		for side in [-1.0, 1.0]:
			b.xf = Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(wx, 0.065, side * (W - 0.02)))
			b.frustum("rubber", Vector3(0, -0.032, 0), 0.062, 0.062, 0.064, 10)
			b.xf = Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(wx, 0.065, side * (W + 0.0125)))
			b.frustum("hub", Vector3(0, -0.002, 0), 0.032, 0.026, 0.004, 8)
	b.xf = Transform3D.IDENTITY
	return b.commit()

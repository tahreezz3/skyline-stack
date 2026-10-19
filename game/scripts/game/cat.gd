## A cozy ginger cat on a bench by the tower (T-0310). Pure decoration: it watches
## the swinging block, swishes its tail, blinks, perks up on a perfect landing and
## hops in fright when the tower collapses or a block misses. Never affects gameplay.
extends Node3D

const Kit := preload("res://scripts/game/building_kit.gd")

const GINGER := Color("#e3904f")
const STRIPE := Color("#c06a33")
const CREAM := Color("#f6dcb8")
const PINK := Color("#ef9aa1")
const EYE := Color("#2b2433")

var head: Node3D
var tail_segments: Array[Node3D] = []
var eyes: Array[Node3D] = []
var t := 0.0
var hop_t := -1.0          # >= 0 while hopping
var perk_t := -1.0         # >= 0 while the tail is up after a perfect
var blink_in := 2.5
var look_x := 0.0          # world x the cat is watching


func _ready() -> void:
	_build()
	GameEvents.block_resolved.connect(_on_block_resolved)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


func _part(build: Callable) -> MeshInstance3D:
	var b := Kit.Builder.new()
	build.call(b)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	var colours := {"fur": GINGER, "stripe": STRIPE, "cream": CREAM, "pink": PINK, "eye": EYE}
	for i in range(mi.mesh.get_surface_count()):
		mi.set_surface_override_material(i, _mat(colours.get(mi.mesh.surface_get_name(i), GINGER)))
	return mi


func _build() -> void:
	# sitting body: haunches, chest, front legs, paws (about 0.17 units tall in total)
	add_child(_part(func(b) -> void:
		b.box("fur", Vector3(-0.05, 0.0, -0.06), Vector3(0.05, 0.065, 0.04))            # haunches
		b.box("fur", Vector3(-0.038, 0.04, -0.01), Vector3(0.038, 0.11, 0.045))          # chest
		b.box("cream", Vector3(-0.026, 0.045, 0.045), Vector3(0.026, 0.1, 0.05))         # chest patch
		b.box("stripe", Vector3(-0.051, 0.03, -0.045), Vector3(0.051, 0.04, 0.0))        # back stripes
		b.box("stripe", Vector3(-0.051, 0.05, -0.04), Vector3(0.051, 0.058, -0.005))
		for sx in [-0.02, 0.02]:
			b.box("fur", Vector3(sx - 0.011, 0.0, 0.03), Vector3(sx + 0.011, 0.06, 0.05))   # front legs
			b.box("cream", Vector3(sx - 0.012, 0.0, 0.045), Vector3(sx + 0.012, 0.012, 0.062))  # paws
	))
	head = Node3D.new()
	head.position = Vector3(0, 0.115, 0.02)
	add_child(head)
	head.add_child(_part(func(b) -> void:
		b.box("fur", Vector3(-0.038, 0.0, -0.03), Vector3(0.038, 0.055, 0.03))          # head
		b.box("cream", Vector3(-0.018, 0.004, 0.03), Vector3(0.018, 0.022, 0.042))       # muzzle
		b.box("pink", Vector3(-0.005, 0.02, 0.041), Vector3(0.005, 0.027, 0.045))        # nose
		b.box("stripe", Vector3(-0.012, 0.05, -0.02), Vector3(0.012, 0.056, 0.02))       # forehead stripe
		for sx in [-1.0, 1.0]:
			b.blob("fur", Vector3(sx * 0.036, 0.016, 0.012), 0.017)                    # cheek tufts
			for k in range(2):                                                         # whiskers
				var wy := 0.012 + k * 0.007
				b.box("cream", Vector3(minf(sx * 0.016, sx * 0.05), wy, 0.04), Vector3(maxf(sx * 0.016, sx * 0.05), wy + 0.0015, 0.0415))
		for sx in [-0.024, 0.024]:
			b.cone("fur", Vector3(sx, 0.05, 0.0), 0.017, 0.03, 4, PI / 4.0)            # ears
			b.cone("pink", Vector3(sx, 0.052, 0.006), 0.009, 0.02, 4, PI / 4.0)
	))
	for sx in [-0.016, 0.016]:
		var eye := _part(func(b) -> void: b.box("eye", Vector3(-0.006, -0.006, 0.0), Vector3(0.006, 0.006, 0.004)))
		eye.position = Vector3(sx, 0.034, 0.03)
		head.add_child(eye)
		eyes.append(eye)
	# tail: three segments, each a child of the previous, so a wave travels along it
	var parent: Node3D = self
	var pos := Vector3(0.0, 0.015, -0.06)
	for i in range(4):
		var seg := Node3D.new()
		seg.position = pos
		parent.add_child(seg)
		var len := 0.036 - i * 0.005
		var colour_name := "cream" if i == 3 else ("stripe" if i == 2 else "fur")
		seg.add_child(_part(func(b) -> void: b.box(colour_name, Vector3(-0.008, 0.0, -0.008), Vector3(0.008, len, 0.008))))
		tail_segments.append(seg)
		parent = seg
		pos = Vector3(0, len, 0)


func _on_block_resolved(ev: Dictionary) -> void:
	match ev["result"]:
		"collapse", "miss":
			hop_t = 0.0
		"perfect":
			perk_t = 0.0


## Called by the view every frame with the x of the block the cat should watch.
func tick(delta: float, watch_x: float) -> void:
	t += delta
	look_x = lerpf(look_x, watch_x, minf(1.0, delta * 3.0))
	# head turns towards the block and tilts a little, like a curious cat
	var rel := look_x - global_position.x
	head.rotation = Vector3(-0.25, clampf(rel * 0.6, -0.9, 0.9), sin(t * 0.7) * 0.06)
	# tail: lazy swish, or straight up and wiggling after a perfect
	var up := 0.0
	if perk_t >= 0.0:
		perk_t += delta
		up = clampf(1.0 - perk_t / 1.2, 0.0, 1.0)
		if perk_t > 1.2:
			perk_t = -1.0
	for i in range(tail_segments.size()):
		var seg := tail_segments[i]
		var swish := sin(t * 2.2 - i * 0.9) * (0.35 + i * 0.15)
		seg.rotation = Vector3(lerpf(-1.2 if i == 0 else 0.35, -0.1, up), 0.0, swish * (1.0 - up * 0.6) + up * sin(t * 14.0) * 0.2)
	# hop when startled
	var y := 0.0
	if hop_t >= 0.0:
		hop_t += delta
		y = maxf(0.0, sin(hop_t / 0.4 * PI)) * 0.06
		if hop_t > 0.4:
			hop_t = -1.0
	position.y = base_y + y
	# blink
	blink_in -= delta
	var closed := blink_in < 0.0
	if blink_in < -0.12:
		blink_in = randf_range(2.0, 5.0)
	for e in eyes:
		e.scale = Vector3(1.0, 0.15 if closed else 1.0, 1.0)


var base_y := 0.0


func place(at: Vector3, facing_y: float) -> void:
	position = at
	base_y = at.y
	rotation.y = facing_y

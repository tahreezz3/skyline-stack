## Independent hand-drawn environment actors, composited behind the live 3D tower.
## Geometry below is vector art; positions, scale, timing and colors are in JSON.
extends Node2D

const Motion := preload("res://scripts/game/background_motion.gd")
var settings: Dictionary
var scene: Dictionary
var canvas := Vector2.ZERO
var seconds := 0.0


func configure(shared: Dictionary, environment: Dictionary) -> void:
	settings = shared
	scene = environment
	canvas = Vector2(shared["canvas_size"][0], shared["canvas_size"][1])
	queue_redraw()


func frame(time: float) -> void:
	if seconds != time:
		seconds = time
		queue_redraw()


func _poly(points: Array, color: Color) -> void:
	var packed := PackedVector2Array()
	for point in points:
		packed.append(Vector2(point[0], point[1]))
	draw_colored_polygon(packed, color)


func _oval(at: Vector2, radius: Vector2, color: Color) -> void:
	draw_set_transform(at, 0.0, radius)
	draw_circle(Vector2.ZERO, 1.0, color, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)


func _draw() -> void:
	if scene.is_empty():
		return
	for actor in scene["actors"]:
		var state := Motion.actor_state(actor, seconds, float(settings["actor_fade"]))
		var at: Vector2 = state["position"] * canvas
		var size := float(actor["size"]) * canvas.x
		var color := Color(actor["color"])
		color.a = state["opacity"]
		var phase := float(state["progress"]) * TAU
		match String(actor["kind"]):
			"birds":
				_birds(at, size, color, phase)
			"sailboat", "ferry":
				_boat(at, size, color, phase, actor)
			"floe":
				_floe(at, size, color, phase)
			"car":
				_car(at, size, color, actor)
			"steam", "mist":
				_steam(at, float(actor["size"]), color, actor, actor["kind"] == "mist")
			"fountain":
				_fountain(at, size, color, actor)
			"flag":
				_flag(at, size, color, phase)
			"beacon":
				_beacon(at, size, color, phase)
			"pollen":
				for i in range(5):
					var p := at + Vector2(sin(phase + i) * size * 4.0, cos(phase * 2.0 + i) * size * 5.0)
					draw_circle(p, size * 0.15, Color(color, color.a * 0.65), true, -1.0, true)


func _birds(at: Vector2, size: float, color: Color, phase: float) -> void:
	for i in range(3):
		var p := at + Vector2(-i * size * 2.2, sin(float(i)) * size * 1.6)
		var wing := sin(seconds * TAU * float(settings["bird_wing_hz"]) + i + phase) * size * 0.55
		var line := PackedVector2Array([p + Vector2(-size, -wing), p + Vector2(-size * 0.4, -wing * 0.3), p, p + Vector2(size * 0.4, -wing * 0.3), p + Vector2(size, -wing)])
		draw_polyline(line, color, maxf(1.0, size * 0.13), true)


func _boat(at: Vector2, size: float, color: Color, phase: float, actor: Dictionary) -> void:
	var bob := sin(phase * 3.0 + seconds * TAU * float(settings["boat_bob_hz"])) * float(settings["boat_bob"]) * canvas.y
	at.y += bob
	# Fine widening wake, separate from the water's masked ripple animation.
	var direction := 1.0 if float(actor["end"][0]) >= float(actor["start"][0]) else -1.0
	for i in range(3):
		var p := at - Vector2(direction * size * (0.8 + i * 0.3), -size * 0.12)
		draw_line(p, p - Vector2(direction * size * 0.8, -size * (0.04 + i * 0.1)), Color("#e7f7f7", color.a * 0.35), 1.0, true)
	draw_set_transform(at, sin(phase * 2.0) * 0.025, Vector2(direction, 1))
	_poly([[-size*.65,0],[size*.65,0],[size*.4,size*.19],[-size*.42,size*.19]], color.darkened(.48))
	_poly([[-size*.53,-size*.04],[size*.56,-size*.04],[size*.65,0],[-size*.65,0]], color)
	if actor["kind"] == "sailboat":
		draw_line(Vector2(0, -size * 1.1), Vector2(0, size*.08), color.darkened(.55), maxf(1.0,size*.035), true)
		_poly([[-size*.04,-size*1.04],[-size*.04,-size*.12],[-size*.55,-size*.16]], color)
		_poly([[size*.04,-size*.85],[size*.04,-size*.15],[size*.43,-size*.15]], color.lightened(.18))
	else:
		_poly([[-size*.34,-size*.22],[size*.28,-size*.22],[size*.38,-size*.04],[-size*.42,-size*.04]], color)
		draw_line(Vector2(-size*.28,-size*.14),Vector2(size*.22,-size*.14),color.darkened(.65),maxf(1.0,size*.05),true)
	draw_set_transform(Vector2.ZERO)


func _floe(at: Vector2, size: float, color: Color, phase: float) -> void:
	at.y += sin(seconds * TAU * float(settings["floe_bob_hz"]) + phase) * float(settings["boat_bob"]) * canvas.y
	draw_set_transform(at, sin(phase) * .08)
	_poly([[-size*.6,0],[-size*.25,-size*.18],[size*.5,-size*.1],[size*.65,0],[size*.3,size*.16],[-size*.4,size*.12]],color.darkened(.18))
	_poly([[-size*.6,-size*.04],[-size*.25,-size*.23],[size*.5,-size*.15],[size*.65,-size*.04],[size*.3,size*.04],[-size*.4,size*.02]],color)
	draw_set_transform(Vector2.ZERO)


func _car(at: Vector2, size: float, color: Color, actor: Dictionary) -> void:
	var direction := (Vector2(actor["end"][0],actor["end"][1])-Vector2(actor["start"][0],actor["start"][1])) * canvas
	draw_set_transform(at, direction.angle())
	_poly([[-size*.6,-size*.12],[size*.5,-size*.12],[size*.65,size*.12],[-size*.6,size*.12]], color.darkened(.6))
	draw_rect(Rect2(-size*.5,-size*.25,size,size*.33),color)
	draw_rect(Rect2(-size*.2,-size*.3,size*.43,size*.2),color.lightened(.4))
	draw_rect(Rect2(size*.15,-size*.26,size*.1,size*.14),Color("#648aa2",color.a))
	draw_set_transform(Vector2.ZERO)


func _steam(at: Vector2, size: float, color: Color, actor: Dictionary, mist: bool) -> void:
	var count := int(settings["steam_puffs"])
	for i in range(count):
		var p := fposmod(seconds / float(actor["period"]) + float(i)/count + float(actor["phase"]), 1.0)
		var alpha := sin(p * PI) * (0.12 if mist else 0.24) * color.a
		var rise := float(settings["steam_rise"]) * canvas.y * size
		var drift := float(settings["steam_drift"]) * canvas.x * size
		var center := at + Vector2(drift * p + sin(p * TAU + i) * drift * .12, -rise * p)
		var radius := float(settings["steam_radius"]) * canvas.x * size * (.4 + p)
		if mist:
			radius *= 8.0
		for soft in range(3,0,-1):
			_oval(center,Vector2(radius * (2.5 if mist else 1.2), radius) * float(soft)/2.0, Color(color,alpha/float(soft)))


func _fountain(at: Vector2, size: float, color: Color, actor: Dictionary) -> void:
	var height := float(settings["fountain_height"]) * canvas.y
	var spread := float(settings["fountain_spread"]) * canvas.x
	for side in [-1.0,1.0]:
		var points := PackedVector2Array()
		for i in range(13):
			var p := float(i)/12.0
			points.append(at + Vector2(side*spread*p, -height*4.0*p*(1.0-p)))
		draw_polyline(points,Color(color,color.a*.3),maxf(1.0,size*.05),true)
	for i in range(int(settings["fountain_drops"])):
		var p := fposmod(seconds/float(actor["period"])+float(i)/float(settings["fountain_drops"]),1.0)
		var side := -1.0 if i%2 == 0 else 1.0
		var point := at + Vector2(side*spread*p,-height*4.0*p*(1.0-p))
		draw_circle(point,maxf(1.0,size*.055),Color(color,color.a*.8),true,-1.0,true)
	for i in range(2):
		var p := fposmod(seconds/float(actor["period"])+i*.5,1.0)
		_oval(at,Vector2(size*(.3+p*.8),size*(.06+p*.15)),Color(color,(1.0-p)*.13))


func _flag(at: Vector2, size: float, color: Color, phase: float) -> void:
	var flutter := seconds * TAU * float(settings["flag_flutter_hz"]) + phase
	draw_line(at,at-Vector2(0,size*1.5),Color("#d7c59a"),1.0,true)
	var points := []
	for i in range(7):
		var x := float(i)/6.0
		points.append([at.x+x*size,at.y-size*1.45+sin(flutter-x*4.0)*size*.12*x])
	for i in range(6,-1,-1):
		var x := float(i)/6.0
		points.append([at.x+x*size,at.y-size*.8+sin(flutter-x*4.0)*size*.12*x])
	_poly(points,color)
	draw_line(at-Vector2(0,size*1.12),at+Vector2(size,size*-1.12+sin(flutter-4.0)*size*.12),color.lightened(.45),1.0,true)


func _beacon(at: Vector2, size: float, color: Color, phase: float) -> void:
	var brightness := pow(maxf(0.0,cos(phase)),12.0)
	for i in range(3,0,-1):
		_oval(at,Vector2(size*float(i),size*.13*float(i)),Color(color,brightness*.06))
	draw_circle(at,size*.06,Color(color,.35+brightness*.65),true,-1.0,true)


## Rasterize original vector masks once. This does not modify the source artwork.
static func make_mask(shared: Dictionary, environment: Dictionary) -> ImageTexture:
	var size := Vector2i(int(shared["canvas_size"][0]*float(shared["mask_scale"])),int(shared["canvas_size"][1]*float(shared["mask_scale"])))
	var image := Image.create(size.x,size.y,false,Image.FORMAT_RGB8)
	image.fill(Color.BLACK)
	var sky: Array = [[0,0],[1,0]]
	var horizon: Array = environment["sky"].duplicate()
	horizon.reverse()
	sky.append_array(horizon)
	_fill_polygon(image,sky,Color.RED)
	for polygon in environment["water"]:
		_fill_polygon(image,polygon,Color.GREEN)
	for polygon in environment["water_exclusions"]:
		_fill_polygon(image,polygon,Color.BLACK)
	for polygon in environment["wind"]:
		_fill_polygon(image,polygon,Color.BLUE)
	return ImageTexture.create_from_image(image)


static func _fill_polygon(image: Image, points: Array, color: Color) -> void:
	var size := image.get_size()
	for row in range(size.y):
		var y := (float(row)+.5)/size.y
		var hits: Array[float] = []
		for i in range(points.size()):
			var a: Array = points[i]
			var b: Array = points[(i+1)%points.size()]
			if (float(a[1]) <= y and float(b[1]) > y) or (float(b[1]) <= y and float(a[1]) > y):
				hits.append(float(a[0])+(y-float(a[1]))/(float(b[1])-float(a[1]))*(float(b[0])-float(a[0])))
		hits.sort()
		for i in range(0,hits.size()-1,2):
			var x0 := clampi(int(ceil(hits[i]*size.x)),0,size.x)
			var x1 := clampi(int(ceil(hits[i+1]*size.x)),0,size.x)
			image.fill_rect(Rect2i(x0,row,x1-x0,1),color)

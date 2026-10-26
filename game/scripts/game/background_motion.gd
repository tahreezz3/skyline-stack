## Presentation clock and camera depth; no simulation or wall-clock dependency.
extends RefCounted

var elapsed := 0.0
var depth := Vector2.ZERO
var reduced := false
var config: Dictionary


func _init(settings: Dictionary) -> void:
	config = settings


func advance(delta: float, is_paused: bool, reduced_motion: bool, camera_position: Vector2) -> void:
	if is_paused:
		return
	reduced = reduced_motion
	if reduced:
		depth = Vector2.ZERO
		return
	elapsed += maxf(delta, 0.0)
	if not config.has("parallax"):
		depth = Vector2.ZERO
		return
	var p: Dictionary = config["parallax"]
	var target := Vector2(
		clampf(camera_position.x * float(p["x_per_unit"]), -float(p["max_x"]), float(p["max_x"])),
		clampf(-camera_position.y * float(p["y_per_unit"]), -float(p["max_y"]), float(p["max_y"]))
	)
	depth = depth.lerp(target, 1.0 - exp(-float(p["follow_rate"]) * maxf(delta, 0.0)))


func render_time() -> float:
	return 0.0 if reduced else elapsed


## Stable loops fade at their route ends, so boats/traffic never teleport visibly.
static func actor_state(actor: Dictionary, seconds: float, fade: float) -> Dictionary:
	var progress := fposmod(seconds / float(actor["period"]) + float(actor["phase"]), 1.0)
	var start: Array = actor["start"]
	var finish: Array = actor["end"]
	var position := Vector2(start[0], start[1]).lerp(Vector2(finish[0], finish[1]), progress)
	var moving := start != finish
	var opacity := smoothstep(0.0, fade, progress) * (1.0 - smoothstep(1.0 - fade, 1.0, progress)) if moving else 1.0
	return {"position": position, "progress": progress, "opacity": opacity}

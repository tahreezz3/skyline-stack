## Presentation data only. A private RNG never consumes gameplay/global randomness.
## This object receives a camera height, never a tower state or gameplay input.
extends RefCounted
var config: Dictionary
var weather: Dictionary
var visual_seed: int


func _init(data: Dictionary,seed_value: int=-1,forced_weather: String="") -> void:
	config=data
	var rng := RandomNumberGenerator.new()
	if seed_value<0:rng.randomize()
	else:rng.seed=seed_value
	visual_seed=rng.seed
	var total := 0.0
	for entry in config["weather"]:total+=float(entry["weight"])
	var choice := rng.randf()*total
	weather=config["weather"][-1]
	for entry in config["weather"]:
		choice-=float(entry["weight"])
		if choice<0.0:
			weather=entry
			break
	for entry in config["weather"]:
		if entry["id"]==forced_weather:weather=entry


func sample(height: float) -> Dictionary:
	var a: Dictionary=config["altitude"]
	return {
		"upper":smoothstep(float(a["upper_start"]),float(a["upper_end"]),height),
		"space":smoothstep(float(a["space_start"]),float(a["space_end"]),height),
		"weather":1.0-smoothstep(float(a["weather_fade_start"]),float(a["weather_fade_end"]),height)
	}

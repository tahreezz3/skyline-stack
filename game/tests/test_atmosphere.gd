## Cosmetic selection and reversible altitude contracts, independent of game rules.
extends "res://tests/test_case.gd"
const Atmosphere := preload("res://scripts/game/atmosphere_state.gd")
var config: Dictionary


func before_all() -> void:
	config=ConfigLoader.load_json("res://config/atmosphere.json")


func test_private_random_selection_is_reproducible_and_covers_all_weather() -> void:
	var seen := {}
	for i in range(300):
		var a := Atmosphere.new(config,i)
		var b := Atmosphere.new(config,i)
		check(a.weather==b.weather,"same visual seed gives the same weather")
		seen[a.weather["id"]]=true
	check(seen.size()==10,"all ten conditions can be selected")
	seed(7319)
	var expected := randi()
	seed(7319)
	Atmosphere.new(config)
	check(randi()==expected,"weather randomization never consumes global/gameplay randomness")


func test_weather_is_fixed_within_round_and_restored_after_descent() -> void:
	for profile in config["weather"]:
		var a := Atmosphere.new(config,42,profile["id"])
		var initial: Dictionary=a.weather.duplicate(true)
		var ground := a.sample(0.0)
		for height in [0.0,10.0,25.0,50.0,10000.0,12.0,0.0]:a.sample(height)
		check(a.weather==initial,"ascent/descent cannot reroll "+profile["id"])
		check(a.sample(0.0)==ground,"descent restores atmospheric conditions")
		check(a.sample(10000.0)["weather"]==0.0,"no rain, snow, wind or fog in space")
		check(a.sample(10000.0)["space"]==1.0,"space persists at endless heights")


func test_altitude_transitions_are_continuous_and_monotonic() -> void:
	var a := Atmosphere.new(config,4)
	var previous := a.sample(-1.0)
	check(previous=={"upper":0.0,"space":0.0,"weather":1.0},"ground has no space intrusion")
	for i in range(500):
		var current := a.sample(float(i)*.1)
		check(float(current["space"])>=float(previous["space"]) and float(current["upper"])>=float(previous["upper"]) and float(current["weather"])<=float(previous["weather"]),"continuous climb ordering")
		check(absf(float(current["space"])-float(previous["space"]))<.02 and absf(float(current["weather"])-float(previous["weather"]))<.02,"no altitude transition pop")
		previous=current

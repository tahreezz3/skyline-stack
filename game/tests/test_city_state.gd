## City map placement rules (scripts/core/city_state.gd), T-0401.
extends "res://tests/test_case.gd"

const CityState := preload("res://scripts/core/city_state.gd")

const MAP := {"width": 3, "height": 2, "disabled": [[2, 1]], "rules": {}}


func _tower(pop := 50) -> Dictionary:
	return {"block_type": "blue", "population": pop, "height": 10, "star": false, "complete": true}


func _city_with(n: int) -> Dictionary:
	var data := {"plots": {}, "unplaced": []}
	for i in range(n):
		CityState.add_completed(data, _tower(10 * (i + 1)))
	return data


func test_add_completed_tower() -> void:
	var data := _city_with(1)
	check(data["unplaced"].size() == 1 and data["unplaced"][0]["type"] == "blue", "completed round becomes an unplaced tower")


func test_place_and_population() -> void:
	var c = CityState.new(MAP, _city_with(2))
	check(c.place(0, 0, 0) == CityState.OK, "place on a free plot")
	check(c.tower_at(0, 0)["population"] == 10 and c.city["unplaced"].size() == 1, "tower moved from tray to plot")
	check(c.place(0, 1, 0) == CityState.OK and c.population() == 30, "city population sums placed towers")


func test_rejections() -> void:
	var c = CityState.new(MAP, _city_with(2))
	c.place(0, 0, 0)
	check(c.place(0, 0, 0) == CityState.ERR_OCCUPIED, "occupied plot rejected")
	check(c.place(0, 2, 1) == CityState.ERR_DISABLED, "disabled plot rejected")
	check(c.place(0, 3, 0) == CityState.ERR_OUTSIDE, "outside grid rejected")
	check(c.place(5, 1, 1) == CityState.ERR_NO_TOWER, "invalid tray index rejected")
	check(c.city["unplaced"].size() == 1, "failed placements keep the tower in the tray")


func test_free_plots() -> void:
	var c = CityState.new(MAP, _city_with(1))
	check(c.free_plots() == 5, "3x2 minus 1 disabled = 5 free")
	c.place(0, 1, 1)
	check(c.free_plots() == 4, "placing uses a plot")


func test_round_feeds_city_via_save_schema() -> void:
	var SaveSchema := load("res://scripts/core/save_schema.gd")
	var d: Dictionary = SaveSchema.defaults()
	SaveSchema.apply_round(d, {"population": 80, "height": 10, "complete": true, "star": false, "max_combo": 1, "block_type": "red"})
	SaveSchema.apply_round(d, {"population": 30, "height": 4, "complete": false, "star": false, "max_combo": 0, "block_type": "red"})
	SaveSchema.apply_round(d, {"population": 900, "height": 60, "complete": false, "star": false, "max_combo": 5, "block_type": "blue", "endless": true})
	check(d["city"]["unplaced"].size() == 1 and d["city"]["unplaced"][0]["type"] == "red", "only completed non-endless towers go to the city")


func test_migrate_v2_adds_city() -> void:
	var SaveSchema := load("res://scripts/core/save_schema.gd")
	var v2 := {"version": 2, "stats": {"lifetime_population": 10}}
	var d: Dictionary = SaveSchema.migrate(v2)
	check(d["version"] == 3 and d["city"]["unplaced"] == [] and d["city"]["plots"] == {}, "v2 save gains an empty city")

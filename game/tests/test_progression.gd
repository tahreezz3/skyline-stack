## Player level and block unlocks (scripts/core/progression.gd). See docs/01_GDD.md §4.
extends "res://tests/test_case.gd"

const Progression := preload("res://scripts/core/progression.gd")

var levels: Array
var types: Array


func before_all() -> void:
	levels = ConfigLoader.load_json("res://config/levels.json")["levels"]
	types = ConfigLoader.load_json("res://config/block_types.json")["types"]


func test_level_at_zero() -> void:
	var info := Progression.level_info(0, levels)
	check(info["level"] == 1 and info["next"] == int(levels[1]["population"]), "new player is level 1")
	check(near(info["progress"], 0.0), "no progress at 0")


func test_level_midway() -> void:
	var a := int(levels[1]["population"])
	var b := int(levels[2]["population"])
	var info := Progression.level_info((a + b) / 2, levels)
	check(info["level"] == int(levels[1]["level"]), "between thresholds stays at lower level")
	check(near(info["progress"], 0.5, 0.01), "progress halfway")


func test_level_max() -> void:
	var info := Progression.level_info(10_000_000, levels)
	check(info["level"] == int(levels[-1]["level"]) and info["next"] == -1, "capped at max level")
	check(near(info["progress"], 1.0), "max level progress is full")


func test_unlocks() -> void:
	check(Progression.unlocked_ids(types, 0) == ["blue"], "only blue at start")
	check(Progression.unlocked_ids(types, 1_000_000).size() == types.size(), "everything unlocked eventually")


func test_newly_unlocked() -> void:
	var red: Dictionary = types[1]
	var at := int(red["unlock_population"])
	check(Progression.newly_unlocked(types, at - 1, at) == [String(red["id"])], "crossing the threshold unlocks exactly that type")
	check(Progression.newly_unlocked(types, at, at + 10).is_empty(), "already unlocked is not new")

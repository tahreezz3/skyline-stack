## Base class for test suites. A suite is any res://tests/test_*.gd file that
## extends this script and defines methods named test_*.
extends RefCounted

const ConfigLoader := preload("res://scripts/autoload/game_config.gd")

var passed := 0
var failed := 0
var current := ""


## Override for per-suite setup.
func before_all() -> void:
	pass


func check(cond: bool, label: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: %s :: %s :: %s" % [get_script().resource_path.get_file(), current, label])


func near(a: float, b: float, eps := 0.0001) -> bool:
	return absf(a - b) < eps

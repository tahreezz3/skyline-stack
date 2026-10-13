## Save schema, migrations and round bookkeeping (scripts/core/save_schema.gd).
extends "res://tests/test_case.gd"

const SaveSchema := preload("res://scripts/core/save_schema.gd")


func test_defaults_have_version() -> void:
	var d := SaveSchema.defaults()
	check(d["version"] == SaveSchema.VERSION, "defaults carry current version")
	check(d["settings"]["sfx_volume"] == 1.0, "default settings present")


func test_migrate_v1() -> void:
	var v1 := {"version": 1, "lifetime_population": 321, "best_height": 9, "best_population": 120, "rounds_played": 4}
	var d := SaveSchema.migrate(v1)
	check(d["version"] == SaveSchema.VERSION, "migrated to current version")
	check(d["stats"]["lifetime_population"] == 321 and d["stats"]["rounds_played"] == 4, "v1 stats carried over")
	check(not d.has("lifetime_population"), "flat v1 keys removed")
	check(d["settings"].has("reduced_motion"), "new keys filled in")


func test_migrate_fills_partial_current() -> void:
	var partial := {"version": 2, "stats": {"lifetime_population": 50}, "settings": {"sfx_volume": 0.3}}
	var d := SaveSchema.migrate(partial)
	check(d["stats"]["lifetime_population"] == 50 and d["stats"]["best_height"] == 0, "missing stats filled, existing kept")
	check(d["settings"]["sfx_volume"] == 0.3 and d["settings"]["music_volume"] == 0.8, "settings merged")


func test_migrate_does_not_mutate_input() -> void:
	var v1 := {"lifetime_population": 5}
	SaveSchema.migrate(v1)
	check(v1.has("lifetime_population") and not v1.has("stats"), "input left untouched")


func test_apply_round() -> void:
	var d := SaveSchema.defaults()
	var r := SaveSchema.apply_round(d, {"population": 80, "height": 10, "complete": true, "star": true, "max_combo": 6, "block_type": "blue"})
	check(r["new_best_population"] and r["new_best_height"] and r["new_type_best"], "first round sets bests")
	check(d["stats"]["lifetime_population"] == 80 and d["stats"]["towers_completed"] == 1 and d["stats"]["trophy_roofs"] == 1, "stats updated")
	check(d["best_by_type"]["blue"]["star"], "type best records trophy")
	var r2 := SaveSchema.apply_round(d, {"population": 30, "height": 4, "complete": false, "star": false, "max_combo": 1, "block_type": "blue"})
	check(not r2["new_best_population"] and r2["population_before"] == 80 and r2["population_after"] == 110, "worse round accumulates but no best")
	check(d["best_by_type"]["blue"]["star"], "trophy flag is sticky")


func test_endless_best_is_separate() -> void:
	var d := SaveSchema.defaults()
	SaveSchema.apply_round(d, {"population": 500, "height": 60, "complete": false, "star": false, "max_combo": 3, "block_type": "blue", "endless": true})
	check(d["best_by_type"].has("endless") and not d["best_by_type"].has("blue"), "endless best stored under 'endless'")
	check(d["best_by_type"]["endless"]["height"] == 60, "endless best height recorded")

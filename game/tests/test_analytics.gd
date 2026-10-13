## Analytics schema, privacy gate, and docs sync (T-0503).
extends "res://tests/test_case.gd"

const Events := preload("res://scripts/core/analytics_events.gd")


func test_valid_and_invalid_events() -> void:
	check(Events.validate("level_up", {"from_level": 1, "to_level": 2}) == "", "valid event passes")
	check(Events.validate("nope", {}) != "", "unknown event rejected")
	check(Events.validate("level_up", {"from_level": 1}) != "", "missing param rejected")
	check(Events.validate("level_up", {"from_level": 1, "to_level": 2, "email": "x"}) != "", "unexpected param rejected")
	check(Events.validate("tower_unlocked", {"block_type": "a very long free text value that should never be sent"}) != "", "free text rejected")
	check(Events.validate("tower_unlocked", {"block_type": {"nested": 1}}) != "", "non-simple value rejected")


func test_docs_match_schema() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../docs/ANALYTICS.md")
	var text := FileAccess.get_file_as_string(path)
	var re := RegEx.create_from_string("(?m)^\\| `([a-z_]+)` \\| ([^|]+) \\|")
	var documented := {}
	for m in re.search_all(text):
		var params: Array = []
		for p in RegEx.create_from_string("`([a-z_]+)`").search_all(m.get_string(2)):
			params.append(p.get_string(1))
		documented[m.get_string(1)] = params
	for name in Events.SCHEMA:
		check(documented.has(name), "%s documented in docs/ANALYTICS.md" % name)
		if documented.has(name):
			check(documented[name] == Events.SCHEMA[name], "%s params match docs" % name)
	for name in documented:
		check(Events.SCHEMA.has(name), "documented event %s exists in schema" % name)


func test_consent_defaults_to_unknown() -> void:
	var SaveSchema := load("res://scripts/core/save_schema.gd")
	check(SaveSchema.defaults()["settings"]["analytics_consent"] == "unknown", "no consent until the player decides")
	# The live gate (unknown/denied -> dropped, granted -> sent) is exercised by the tour step "analytics".

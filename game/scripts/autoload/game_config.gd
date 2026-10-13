## Autoload "GameConfig": loads every JSON table in res://config once at startup.
## Gameplay code reads numbers from here, never from hard-coded constants
## (see docs/adr/ADR-0002-data-driven-config.md).
extends Node

const TABLES := ["tower_rules", "block_types", "levels", "feel", "city_map"]

var tables: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	for name in TABLES:
		tables[name] = load_json("res://config/%s.json" % name)


func table(name: String) -> Variant:
	return tables.get(name)


func block_type(id: String) -> Dictionary:
	for t in tables["block_types"]["types"]:
		if t["id"] == id:
			return t
	push_error("Unknown block type: %s" % id)
	return {}


static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Config file missing: %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("Config file is not valid JSON: %s" % path)
	return parsed

## Autoload "SaveData": minimal local save (user://save.json).
## Extended in milestone M2 (task T-0204): versioned schema, migrations, cloud save.
extends Node

const PATH := "user://save.json"
const VERSION := 1

var data: Dictionary = {
	"version": VERSION,
	"lifetime_population": 0,
	"best_height": 0,
	"best_population": 0,
	"rounds_played": 0,
}


func _ready() -> void:
	load_save()


func load_save() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		data.merge(parsed, true)


func write_save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not write save: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data, "  "))


func record_round(summary: Dictionary) -> void:
	data["rounds_played"] += 1
	data["lifetime_population"] += int(summary["population"])
	data["best_height"] = maxi(int(data["best_height"]), int(summary["height"]))
	data["best_population"] = maxi(int(data["best_population"]), int(summary["population"]))
	write_save()

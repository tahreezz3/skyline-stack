## SaveData file handling: atomic write, backup, corrupt-file recovery, migration on load.
## Uses user://test_save_* paths so the real save is never touched.
extends "res://tests/test_case.gd"

const SaveDataScript := preload("res://scripts/autoload/save_data.gd")
const SaveSchema := preload("res://scripts/core/save_schema.gd")


func _make() -> Node:
	var s: Node = SaveDataScript.new()
	s.PATH = "user://test_save.json"
	s.TMP_PATH = "user://test_save.tmp.json"
	s.BAK_PATH = "user://test_save.bak.json"
	s.CORRUPT_PATH = "user://test_save.corrupt.json"
	for p in [s.PATH, s.TMP_PATH, s.BAK_PATH, s.CORRUPT_PATH]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	return s


func test_round_trip_and_backup() -> void:
	var s := _make()
	s.load_save()
	s.data["stats"]["lifetime_population"] = 42
	s.write_save()
	check(FileAccess.file_exists(s.PATH) and not FileAccess.file_exists(s.TMP_PATH), "atomic write leaves only the final file")
	s.data["stats"]["lifetime_population"] = 43
	s.write_save()
	check(FileAccess.file_exists(s.BAK_PATH), "previous save kept as backup")
	var s2 := _make_keep(s)
	s2.load_save()
	check(int(s2.data["stats"]["lifetime_population"]) == 43, "reload reads latest value")
	s.free()
	s2.free()


func test_corrupt_file_recovers() -> void:
	var s := _make()
	var f := FileAccess.open(s.PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	s.load_save()
	check(int(s.data["version"]) == SaveSchema.VERSION, "fresh defaults after corrupt file")
	check(FileAccess.file_exists(s.CORRUPT_PATH) and not FileAccess.file_exists(s.PATH), "corrupt file moved aside")
	s.free()


func test_v1_file_migrates_on_load() -> void:
	var s := _make()
	var f := FileAccess.open(s.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "lifetime_population": 77, "best_height": 3, "best_population": 30, "rounds_played": 2}))
	f.close()
	s.load_save()
	check(int(s.data["stats"]["lifetime_population"]) == 77 and int(s.data["version"]) == SaveSchema.VERSION, "v1 file migrated on load")
	s.free()


func _make_keep(src: Node) -> Node:
	var s: Node = SaveDataScript.new()
	s.PATH = src.PATH
	s.TMP_PATH = src.TMP_PATH
	s.BAK_PATH = src.BAK_PATH
	s.CORRUPT_PATH = src.CORRUPT_PATH
	return s

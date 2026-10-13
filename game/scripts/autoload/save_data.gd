## Autoload "SaveData": owns user://save.json. Schema and migrations live in
## scripts/core/save_schema.gd. Writes are atomic (temp file + rename) and the
## previous save is kept as save.bak.json. A corrupt save is moved aside to
## save.corrupt.json and the game starts fresh instead of crashing.
extends Node

const SaveSchema := preload("res://scripts/core/save_schema.gd")
const Progression := preload("res://scripts/core/progression.gd")

## Paths are variables so tests can point them elsewhere (see tests/test_save_io.gd).
var PATH := "user://save.json"
var TMP_PATH := "user://save.tmp.json"
var BAK_PATH := "user://save.bak.json"
var CORRUPT_PATH := "user://save.corrupt.json"

var data: Dictionary = SaveSchema.defaults()
## Set to false in tests or tools to avoid touching the real save.
var persist := true


## Locales with translations in localisation/strings.csv ("" = follow the device).
const LANGUAGES := ["", "en", "es", "de"]


func _ready() -> void:
	load_save()
	apply_language()


## Apply settings.language, falling back to the device language, then English.
func apply_language() -> void:
	var lang := String(get_setting("language"))
	if lang == "":
		lang = OS.get_locale_language()
	TranslationServer.set_locale(lang if lang in LANGUAGES else "en")


func load_save() -> void:
	if not FileAccess.file_exists(PATH):
		data = SaveSchema.defaults()
		return
	var json := JSON.new()
	var ok := json.parse(FileAccess.get_file_as_string(PATH)) == OK
	if ok and json.data is Dictionary:
		data = SaveSchema.migrate(json.data)
	else:
		push_warning("Save file unreadable; moved to %s and starting fresh" % CORRUPT_PATH)
		DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(CORRUPT_PATH))
		data = SaveSchema.defaults()


func write_save() -> void:
	if not persist:
		return
	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not write save: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	var abs_path := ProjectSettings.globalize_path(PATH)
	if FileAccess.file_exists(PATH):
		DirAccess.copy_absolute(abs_path, ProjectSettings.globalize_path(BAK_PATH))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(TMP_PATH), abs_path)


func stats() -> Dictionary:
	return data["stats"]


func lifetime_population() -> int:
	return int(data["stats"]["lifetime_population"])


func get_setting(key: String) -> Variant:
	return data["settings"].get(key)


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	write_save()
	if key == "language":
		apply_language()
	GameEvents.setting_changed.emit(key, value)


## Add bonus lifetime population (rewarded "double reward"). Announces level-ups and unlocks.
## Returns {level_before, level_after, unlocked}.
func add_bonus_population(amount: int) -> Dictionary:
	var before := lifetime_population()
	data["stats"]["lifetime_population"] = before + amount
	write_save()
	return _announce_progress(before, before + amount)


func _announce_progress(before: int, after: int) -> Dictionary:
	var levels: Array = GameConfig.table("levels")["levels"]
	var types: Array = GameConfig.table("block_types")["types"]
	var out := {
		"level_before": Progression.level_info(before, levels)["level"],
		"level_after": Progression.level_info(after, levels)["level"],
		"unlocked": Progression.newly_unlocked(types, before, after),
	}
	if out["level_after"] > out["level_before"]:
		GameEvents.level_up.emit(out["level_before"], out["level_after"])
	for id in out["unlocked"]:
		GameEvents.block_type_unlocked.emit(id)
	return out


## Record a round, persist, and announce level-ups and unlocks.
## Returns the SaveSchema.apply_round() result plus level/unlock info.
func record_round(summary: Dictionary) -> Dictionary:
	var result := SaveSchema.apply_round(data, summary)
	write_save()
	result.merge(_announce_progress(int(result["population_before"]), int(result["population_after"])), true)
	return result

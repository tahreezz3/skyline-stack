## Localisation guard (T-0304): every tr() key used in code exists in
## localisation/strings.csv with text for every language, block name keys exist,
## and UI helpers are never called with hard-coded literal text.
extends "res://tests/test_case.gd"

var keys: Dictionary = {}     # key -> row
var langs: PackedStringArray


func before_all() -> void:
	var f := FileAccess.open("res://localisation/strings.csv", FileAccess.READ)
	langs = f.get_csv_line()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() > 1:
			keys[row[0]] = row


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(d)))
	return out


func test_every_tr_key_exists() -> void:
	var re := RegEx.create_from_string("tr\\(\"([A-Za-z0-9_]+)\"\\)")
	var used := 0
	for path in _scripts("res://scripts"):
		var text := FileAccess.get_file_as_string(path)
		for m in re.search_all(text):
			used += 1
			check(keys.has(m.get_string(1)), "%s uses missing key %s" % [path.get_file(), m.get_string(1)])
	check(used > 30, "found tr() calls (%d)" % used)


func test_all_languages_filled() -> void:
	check(langs.size() >= 4 and langs[0] == "keys" and langs[1] == "en", "header is keys,en,...")
	for k in keys:
		var row: PackedStringArray = keys[k]
		for i in range(1, langs.size()):
			check(i < row.size() and row[i].strip_edges() != "", "%s has %s text" % [k, langs[i]])


func test_block_names_translated() -> void:
	var types: Array = ConfigLoader.load_json("res://config/block_types.json")["types"]
	for t in types:
		check(keys.has(t["name_key"]), "block name key %s exists" % t["name_key"])


func test_no_literal_ui_text() -> void:
	var re := RegEx.create_from_string("UI\\.(label|button)\\(\"[A-Za-z]")
	for path in _scripts("res://scripts/game"):
		var text := FileAccess.get_file_as_string(path)
		check(re.search(text) == null, "%s passes literal text to UI.label/button; use tr()" % path.get_file())


func test_format_placeholders_match() -> void:
	# every language must keep the same %d/%s placeholders as English
	var re := RegEx.create_from_string("%[ds]")
	for k in keys:
		var row: PackedStringArray = keys[k]
		var en := re.search_all(row[1]).map(func(m): return m.get_string())
		for i in range(2, mini(row.size(), langs.size())):
			var other := re.search_all(row[i]).map(func(m): return m.get_string())
			check(en == other, "%s placeholders differ in %s" % [k, langs[i]])


func test_shipped_translation_resources_match_catalogue() -> void:
	var registered: PackedStringArray = ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray())
	for i in range(1, langs.size()):
		var path := "res://localisation/strings.%s.translation" % langs[i]
		check(FileAccess.file_exists(path), "%s ships without an editor import" % langs[i])
		check(path in registered, "%s is registered at startup" % langs[i])
		if not FileAccess.file_exists(path):
			continue
		var translation := load(path) as Translation
		check(translation != null, "%s loads as a Translation resource" % langs[i])
		if translation == null:
			continue
		check(translation.get_locale() == langs[i], "%s resource has the correct locale" % langs[i])
		for key in keys:
			check(String(translation.get_message(key)) == keys[key][i], "%s/%s binary matches CSV" % [langs[i], key])


func test_runtime_menu_formatting_in_every_language() -> void:
	var previous := TranslationServer.get_locale()
	for i in range(1, langs.size()):
		TranslationServer.set_locale(langs[i])
		var level := String(TranslationServer.translate("LEVEL_N"))
		check(level == keys["LEVEL_N"][i], "%s menu receives translated level format" % langs[i])
		# Guard formatting to report a missing translation without aborting this test.
		if "%d" in level:
			check("7" in level % 7, "%s menu can format the level" % langs[i])
		else:
			check(false, "%s level format contains the required placeholder" % langs[i])
		var population := String(TranslationServer.translate("NEXT_LEVEL"))
		check(population == keys["NEXT_LEVEL"][i], "%s menu receives translated population format" % langs[i])
	TranslationServer.set_locale(previous)

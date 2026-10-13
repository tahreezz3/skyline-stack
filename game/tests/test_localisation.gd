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

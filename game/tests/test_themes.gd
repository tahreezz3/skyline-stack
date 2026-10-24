## Presentation contracts: catalog fallback, dimensions, surfaces and theme-independent rules.
extends "res://tests/test_case.gd"

const Catalog := preload("res://scripts/game/theme_catalog.gd")
const ThemeKit := preload("res://scripts/game/theme_kit.gd")
const TowerState := preload("res://scripts/core/tower_state.gd")
var translations := {}
var config: Dictionary


func before_all() -> void:
	config = ConfigLoader.load_json("res://config/themes.json")
	var file := FileAccess.open("res://localisation/strings.csv", FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() > 1:
			translations[row[0]] = true


func test_catalog_and_fallback() -> void:
	check(config["themes"].size() == 10, "all ten themes are available")
	check(Catalog.resolve(config, "missing")["id"] == config["default"], "obsolete theme IDs safely fall back")
	check(Catalog.resolve(config, "")["id"] == config["default"], "new sessions use default theme")
	var ids := {}
	for theme in config["themes"]:
		check(not ids.has(theme["id"]), "unique theme ID " + theme["id"])
		ids[theme["id"]] = true
		check(translations.has(theme["name_key"]) and translations.has(theme["description_key"]), "dynamic theme name and description keys exist")
		check(Catalog.resolve(config, theme["id"]) == theme, "each theme can be selected")
		check(not theme.has("rules") and not theme.has("block_type"), "theme cannot override rules or progression")


func test_all_modules_fit_the_same_gameplay_dimensions() -> void:
	var rules: Dictionary = ConfigLoader.load_json("res://config/tower_rules.json")
	var h := float(rules["block"]["height"])
	var yaw := Basis(Vector3.UP, deg_to_rad(float(config["geometry"]["yaw_degrees"])))
	for theme in config["themes"]:
		for base in [false, true]:
			var mesh := ThemeKit.storey(theme, h, config["geometry"], base)
			var bounds := mesh.get_aabb()
			check(near(bounds.position.y, 0) and near(bounds.size.y, h), "%s storey/base is exactly one floor tall" % theme["id"])
			var min_x := INF
			var max_x := -INF
			var names: Array[String] = []
			for surface in range(mesh.get_surface_count()):
				names.append(mesh.surface_get_name(surface))
				var vertices: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
				for vertex in vertices:
					var x := (yaw * vertex).x
					min_x = minf(min_x, x)
					max_x = maxf(max_x, x)
			check(max_x - min_x <= 1.03 and max_x - min_x >= 0.85, "%s decorative footprint matches full-width gameplay" % theme["id"])
			check("body" in names and "trim" in names and "glass" in names, "%s has material slots" % theme["id"])
		check(ThemeKit.roof(theme, config["geometry"]).get_surface_count() > 0, "theme crown builds")
		check(ThemeKit.landscape(theme).get_surface_count() > 0, "theme scenery builds")


func test_live_hybrid_boundaries_for_every_theme() -> void:
	var rules: Dictionary = ConfigLoader.load_json("res://config/tower_rules.json")
	# Themes never enter TowerState. Exercise the live configuration (old fixtures are unchanged).
	for theme in config["themes"]:
		var state := TowerState.new(rules)
		check(state.land(0.05)["result"] == "perfect" and near(state.top_x(), 0), "%s: perfect snaps" % theme["id"])
		var ev: Dictionary = state.land(0.20)
		check(ev["result"] == "stack" and ev["residents"] == 2 and near(state.top_x(), 0.20), "stack keeps actual centre and residents")
		# Use a fresh centred base to avoid introducing floating subtraction error at exactly .35.
		state = TowerState.new(rules)
		state.land(0)
		ev = state.land(0.35)
		check(ev["result"] == "stack" and ev["residents"] == 1, "max_offset is inclusive")
		var pop := state.population
		ev = state.land(0.85)
		check(ev["result"] == "collapse" and state.height() == 1 and state.lives == 2, "later .50 offset collapses to stable base and costs a life")
		check(state.population == pop - int(ev["lost_residents"]) + int(ev["banked"]), "collapse subtracts fallen residents and banks combo")
		state = TowerState.new(rules)
		check(state.land(1.0)["result"] == "miss" and state.height() == 0 and state.lives == 2, "exact miss threshold loses a life without a floor")
		state = TowerState.new(rules)
		check(state.land(0.55)["result"] == "stack" and near(state.wobble(), 0), "first .55 is accepted and stable")
		state = TowerState.new(rules)
		check(state.land(0.80)["result"] == "collapse", "first .80 collapses")

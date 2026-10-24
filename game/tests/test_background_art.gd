## Background asset contracts: independent local art and responsive cover framing.
extends "res://tests/test_case.gd"

var themes: Dictionary


func before_all() -> void:
	themes = ConfigLoader.load_json("res://config/themes.json")


func test_every_theme_has_distinct_local_portrait_art() -> void:
	var seen_paths := {}
	var seen_content := {}
	for theme in themes["themes"]:
		var background: Dictionary = theme["background"]
		var path: String = background["texture"]
		check(path.begins_with("res://assets/backgrounds/") and FileAccess.file_exists(path), "%s has shipped local artwork" % theme["id"])
		check(not seen_paths.has(path), "themes do not share one generic background")
		seen_paths[path] = true
		var digest := FileAccess.get_md5(path)
		check(not seen_content.has(digest), "artwork content is distinct for %s" % theme["id"])
		seen_content[digest] = true
		var texture := load(path) as Texture2D
		check(texture != null, "Godot imports the background resource")
		var image := texture.get_image()
		check(image.get_width() >= 720 and image.get_height() >= 1280, "background supports portrait resolution")
		check(absf(float(image.get_width()) / image.get_height() - 9.0 / 16.0) < 0.01, "background uses the reference portrait aspect")
		check(texture.get_size() == Vector2(image.get_size()), "Godot imports the full background texture")


func test_reference_lighting_profiles_are_explicit() -> void:
	var sunsets := ["v003", "v009", "v010"]
	for theme in themes["themes"]:
		var background: Dictionary = theme["background"]
		check(background["sun_style"] == ("natural_gold" if theme["id"] in sunsets else "none"), "only reference sunset scenes contain a sun")
		var light: Dictionary = background["lighting"]
		check(float(light["ambient_energy"]) >= 0.5, "bright readable reference lighting")
		check(Color(light["ambient_color"]).g > 0.8, "ambient fill avoids the old purple tint")

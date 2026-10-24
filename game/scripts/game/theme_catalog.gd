## Presentation-only lookup. Unknown or obsolete IDs fall back to the configured theme.
extends RefCounted


static func resolve(config: Dictionary, id: String) -> Dictionary:
	for theme in config["themes"]:
		if theme["id"] == id:
			return theme
	for theme in config["themes"]:
		if theme["id"] == config["default"]:
			return theme
	return config["themes"][0]

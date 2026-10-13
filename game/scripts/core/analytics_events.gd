## Analytics event schema (T-0503). The single list of events the game may send
## and their parameters. docs/ANALYTICS.md mirrors this table and
## tests/test_analytics.gd fails if the two drift apart.
## Rules: no personal data, no free text, no device identifiers in params.
extends RefCounted

const SCHEMA := {
	"session_start": ["app_version", "locale"],
	"round_start": ["block_type", "endless"],
	"round_end": ["block_type", "endless", "complete", "star", "population", "height", "max_combo", "duration_s"],
	"level_up": ["from_level", "to_level"],
	"tower_unlocked": ["block_type"],
	"city_tower_placed": ["block_type", "city_population"],
	"setting_changed": ["key", "value"],
	"ad_finished": ["format", "placement", "completed"],
}

## Setting keys that may be reported (values are non-identifying).
const REPORTABLE_SETTINGS := ["music_volume", "sfx_volume", "reduced_motion", "language"]


## "" if valid, otherwise the reason.
static func validate(name: String, params: Dictionary) -> String:
	if not SCHEMA.has(name):
		return "unknown event %s" % name
	for p in SCHEMA[name]:
		if not params.has(p):
			return "%s missing param %s" % [name, p]
	for p in params:
		if not p in SCHEMA[name]:
			return "%s has unexpected param %s" % [name, p]
		var v: Variant = params[p]
		if not (v is bool or v is int or v is float or v is String):
			return "%s.%s must be a simple value" % [name, p]
		if v is String and String(v).length() > 40:
			return "%s.%s is too long (no free text)" % [name, p]
	return ""

## Pure save-data schema: defaults, migrations and round bookkeeping.
## The SaveData autoload handles files; everything that changes the data's
## shape or values lives here so it can be tested.
##
## Changing the schema: bump VERSION, add a _vN_to_vN+1() step in migrate(),
## add defaults, add a test, and update docs/03_DATA_SPEC.md "Save file".
extends RefCounted

const VERSION := 2


static func defaults() -> Dictionary:
	return {
		"version": VERSION,
		"stats": {
			"lifetime_population": 0,
			"best_height": 0,
			"best_population": 0,
			"rounds_played": 0,
			"towers_completed": 0,
			"trophy_roofs": 0,
			"best_combo": 0,
		},
		"best_by_type": {},     # id -> {population, height, star}
		"settings": {
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"reduced_motion": false,
			"language": "",       # "" = follow the device
		},
	}


## Bring any older (or partial) save up to the current schema.
static func migrate(data: Dictionary) -> Dictionary:
	var out := data.duplicate(true)
	var v := int(out.get("version", 1))
	if v < 2:
		out = _v1_to_v2(out)
	out = _fill(out, defaults())
	out["version"] = VERSION
	return out


## v1 (CP-000) stored stats as flat top-level keys.
static func _v1_to_v2(d: Dictionary) -> Dictionary:
	var out := defaults()
	for k in ["lifetime_population", "best_height", "best_population", "rounds_played"]:
		if d.has(k):
			out["stats"][k] = int(d[k])
	return out


## Recursively add missing keys from `template` without overwriting existing values.
static func _fill(d: Dictionary, template: Dictionary) -> Dictionary:
	for k in template:
		if not d.has(k):
			d[k] = template[k].duplicate(true) if template[k] is Dictionary else template[k]
		elif d[k] is Dictionary and template[k] is Dictionary:
			_fill(d[k], template[k])
	return d


## Record a finished round. Mutates `data`; returns what changed for the results screen:
## {population_before, population_after, new_best_population, new_best_height, new_type_best}
static func apply_round(data: Dictionary, summary: Dictionary) -> Dictionary:
	var s: Dictionary = data["stats"]
	var pop := int(summary["population"])
	var height := int(summary["height"])
	var before := int(s["lifetime_population"])
	var result := {
		"population_before": before,
		"population_after": before + pop,
		"new_best_population": pop > int(s["best_population"]),
		"new_best_height": height > int(s["best_height"]),
		"new_type_best": false,
	}
	s["lifetime_population"] = before + pop
	s["rounds_played"] = int(s["rounds_played"]) + 1
	s["best_population"] = maxi(int(s["best_population"]), pop)
	s["best_height"] = maxi(int(s["best_height"]), height)
	s["best_combo"] = maxi(int(s["best_combo"]), int(summary.get("max_combo", 0)))
	if summary.get("complete", false):
		s["towers_completed"] = int(s["towers_completed"]) + 1
	if summary.get("star", false):
		s["trophy_roofs"] = int(s["trophy_roofs"]) + 1

	var id := String(summary.get("block_type", ""))
	if id != "":
		var best: Dictionary = data["best_by_type"].get(id, {"population": 0, "height": 0, "star": false})
		if pop > int(best["population"]):
			best["population"] = pop
			result["new_type_best"] = true
		best["height"] = maxi(int(best["height"]), height)
		best["star"] = bool(best["star"]) or bool(summary.get("star", false))
		data["best_by_type"][id] = best
	return result

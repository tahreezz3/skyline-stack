## Pure progression rules: lifetime population -> player level and unlocked
## block types. Source data: config/levels.json and config/block_types.json.
## Block unlocks are driven only by block_types[].unlock_population (single
## source of truth); levels give the player a sense of progress between unlocks.
extends RefCounted


## Returns {level, floor, next (-1 at max level), progress 0..1}.
static func level_info(population: int, levels: Array) -> Dictionary:
	var current: Dictionary = levels[0]
	var next: Dictionary = {}
	for l in levels:
		if population >= int(l["population"]):
			current = l
		elif next.is_empty():
			next = l
	var floor_pop := int(current["population"])
	var next_pop := int(next["population"]) if not next.is_empty() else -1
	var progress := 1.0
	if next_pop > floor_pop:
		progress = clampf(float(population - floor_pop) / float(next_pop - floor_pop), 0.0, 1.0)
	return {"level": int(current["level"]), "floor": floor_pop, "next": next_pop, "progress": progress}


static func is_unlocked(block_type: Dictionary, population: int) -> bool:
	return population >= int(block_type["unlock_population"])


static func unlocked_ids(block_types: Array, population: int) -> Array[String]:
	var out: Array[String] = []
	for t in block_types:
		if is_unlocked(t, population):
			out.append(String(t["id"]))
	return out


## Ids that became unlocked when lifetime population went from `before` to `after`.
static func newly_unlocked(block_types: Array, before: int, after: int) -> Array[String]:
	var out: Array[String] = []
	for t in block_types:
		if not is_unlocked(t, before) and is_unlocked(t, after):
			out.append(String(t["id"]))
	return out

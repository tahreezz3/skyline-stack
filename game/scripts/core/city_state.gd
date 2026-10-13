## Pure city-map rules (T-0401): a grid of plots holding completed towers.
## Works directly on the save's "city" dictionary so the SaveData autoload can
## persist it without conversion:
##   {"plots": {"x,y": tower}, "unplaced": [tower, ...]}
##   tower = {"type": id, "population": int, "height": int, "star": bool}
## Placement rules beyond "free and enabled" arrive with T-0402 via can_place().
extends RefCounted

const OK := ""
const ERR_OUTSIDE := "outside"
const ERR_DISABLED := "disabled"
const ERR_OCCUPIED := "occupied"
const ERR_NO_TOWER := "no_tower"

var map_cfg: Dictionary      # config/city_map.json
var city: Dictionary         # save["city"] (mutated in place)


func _init(p_map_cfg: Dictionary, p_city: Dictionary) -> void:
	map_cfg = p_map_cfg
	city = p_city
	if not city.has("plots"):
		city["plots"] = {}
	if not city.has("unplaced"):
		city["unplaced"] = []


static func key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]


func width() -> int:
	return int(map_cfg["width"])


func height() -> int:
	return int(map_cfg["height"])


func is_disabled(x: int, y: int) -> bool:
	for d in map_cfg.get("disabled", []):
		if int(d[0]) == x and int(d[1]) == y:
			return true
	return false


func tower_at(x: int, y: int) -> Dictionary:
	return city["plots"].get(key(x, y), {})


## Why a tower can't go at (x, y), or OK ("").
func can_place(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= width() or y >= height():
		return ERR_OUTSIDE
	if is_disabled(x, y):
		return ERR_DISABLED
	if city["plots"].has(key(x, y)):
		return ERR_OCCUPIED
	return OK


## Place unplaced tower #index at (x, y). Returns OK or an ERR_* reason.
func place(index: int, x: int, y: int) -> String:
	if index < 0 or index >= city["unplaced"].size():
		return ERR_NO_TOWER
	var reason := can_place(x, y)
	if reason != OK:
		return reason
	var tower: Dictionary = city["unplaced"][index]
	city["unplaced"].remove_at(index)
	city["plots"][key(x, y)] = tower
	return OK


## A completed round becomes a tower waiting to be placed.
static func add_completed(city_data: Dictionary, summary: Dictionary) -> void:
	if not city_data.has("unplaced"):
		city_data["unplaced"] = []
	city_data["unplaced"].append({
		"type": String(summary["block_type"]),
		"population": int(summary["population"]),
		"height": int(summary["height"]),
		"star": bool(summary.get("star", false)),
	})


## Sum of placed towers' population (the city's size; drives districts in T-0403).
func population() -> int:
	var total := 0
	for k in city["plots"]:
		total += int(city["plots"][k]["population"])
	return total


func free_plots() -> int:
	var n := 0
	for y in range(height()):
		for x in range(width()):
			if can_place(x, y) == OK:
				n += 1
	return n

## Pure game logic for one tower round. No nodes, no rendering, no randomness:
## everything here is deterministic and covered by tests/run_tests.gd.
##
## Units: 1.0 = one block width. A block's "x" is its horizontal centre in the
## tower's own frame (visual sway is applied by the scene, not here).
## Rules are documented in docs/01_GDD.md section 3; numbers live in
## config/tower_rules.json.
extends RefCounted

const RESULT_PERFECT := "perfect"
const RESULT_STACK := "stack"
const RESULT_COLLAPSE := "collapse"
const RESULT_MISS := "miss"

var rules: Dictionary
## Round goal: {target_height, roof_people, star_population, star_roof_people}.
## target_height 0 = endless.
var round_cfg: Dictionary

## Index 0 is the foundation and never falls. Each entry: {x, diff, residents}.
var blocks: Array[Dictionary] = []
## Signed landing offsets of the most recent blocks (capped at rules.wobble_window).
var wobble_offsets: Array[float] = []

var lives: int
var population: int = 0
var combo_count: int = 0
var combo_time: float = 0.0
var combo_pool: int = 0
var max_combo: int = 0
var is_over: bool = false
var is_complete: bool = false
## True when the tower was completed with the trophy roof (decided before the roof bonus is added).
var is_star: bool = false


func _init(p_rules: Dictionary, p_round_cfg: Dictionary = {}) -> void:
	rules = p_rules
	round_cfg = p_round_cfg
	lives = int(rules["lives"])
	blocks.append({"x": 0.0, "diff": 0.0, "residents": 0})


func height() -> int:
	return blocks.size() - 1


func top_x() -> float:
	return float(blocks[-1]["x"])


func target_height() -> int:
	return int(round_cfg.get("target_height", 0))


## Signed sway amount: wobble_gain * sum of the recent landing offsets.
## Same-side sloppy blocks add up; alternating sides cancel; perfects push 0.
func wobble() -> float:
	var total := 0.0
	for o in wobble_offsets:
		total += o
	return float(rules["wobble_gain"]) * total


## Residents housed by a block that landed `offset` away from the block below.
## 4 near the centre, stepping down to 1 near the edge (never 0 for a landed block).
static func residents_for(offset: float, p_rules: Dictionary) -> int:
	var d := minf(1.0, absf(offset) / float(p_rules["max_offset"]))
	var r := int(p_rules["residents_max"])
	return maxi(1, r - floori(d * r))


## Resolve a block arriving at horizontal position `x` (tower frame).
## Returns an event dictionary; "result" is one of the RESULT_* constants.
func land(x: float) -> Dictionary:
	if is_over:
		return {"result": "ignored"}
	var below_x := top_x()
	var offset := x - below_x
	var dist := absf(offset)

	# The first storey lands on the wide foundation: anywhere inside the building zone it is
	# accepted and counts as perfectly stable (no wobble, never part of a collapse).
	var on_foundation := height() == 0 and rules.has("first_block_zone")
	var zone_ok := on_foundation and dist <= float(rules["first_block_zone"])

	if dist >= float(rules["miss_offset"]):
		return _miss(x)
	if dist > float(rules["max_offset"]) and not zone_ok:
		return _collapse(x, offset)

	var perfect := dist < float(rules["snap_window"])
	if perfect:
		x = below_x
		offset = 0.0

	var residents := residents_for(offset, rules)
	var stability_offset := 0.0 if zone_ok else offset   # what wobble and collapse checks see
	blocks.append({"x": x, "diff": stability_offset, "residents": residents})
	population += residents
	_push_wobble(stability_offset)

	if perfect:
		combo_time = float(rules["combo"]["bar_seconds"])
	if perfect or combo_time > 0.0:
		_grow_combo()

	var ev := {
		"result": RESULT_PERFECT if perfect else RESULT_STACK,
		"x": x,
		"offset": offset,
		"residents": residents,
		"height": height(),
	}
	if target_height() > 0 and height() >= target_height():
		ev.merge(_complete())
	return ev


## Advance the combo bar. Returns the number of people banked when the bar
## runs out this frame, otherwise 0.
func tick(delta: float) -> int:
	if combo_time <= 0.0 or is_over:
		return 0
	combo_time -= delta * drain_rate()
	if combo_time <= 0.0:
		return _bank_combo()
	return 0


## Seconds of bar drained per real second at the current combo count.
func drain_rate() -> float:
	var c: Dictionary = rules["combo"]
	return float(c["drain_base"]) + float(c["drain_extra"]) * minf(1.0, float(combo_count) / float(c["drain_full_at"]))


## Remaining combo bar as 0..1 for the HUD.
func combo_ratio() -> float:
	return clampf(combo_time / float(rules["combo"]["bar_seconds"]), 0.0, 1.0)


func _grow_combo() -> void:
	combo_count += 1
	max_combo = maxi(max_combo, combo_count)
	var c: Dictionary = rules["combo"]
	var counted := mini(combo_count, int(c.get("count_cap", 1 << 30)))
	var height_mult := mini(ceili(float(height()) / float(c["height_step"])), int(c.get("height_mult_cap", 1 << 30)))
	combo_pool += counted * int(c["bonus_factor"]) * height_mult


## Pay the combo pool into population and reset the combo. Returns the amount.
func _bank_combo() -> int:
	var banked := combo_pool
	population += banked
	combo_pool = 0
	combo_count = 0
	combo_time = 0.0
	return banked


func _push_wobble(offset: float) -> void:
	wobble_offsets.append(offset)
	while wobble_offsets.size() > int(rules["wobble_window"]):
		wobble_offsets.pop_front()


## Block landed too far off: it topples, and every unstable block under it
## topples too, until the top block is stable (|diff| < stable_offset).
## Costs a life when rules.collapse_costs_life is true (T-0101 tuning).
func _collapse(x: float, offset: float) -> Dictionary:
	var banked := _bank_combo()
	var fallen: Array[Dictionary] = [{"x": x, "diff": offset, "residents": 0, "index": height() + 1}]
	var lost := 0
	while blocks.size() > 1 and absf(float(blocks[-1]["diff"])) >= float(rules["stable_offset"]):
		var b: Dictionary = blocks.pop_back()
		b["index"] = blocks.size()
		fallen.append(b)
		lost += int(b["residents"])
		if not wobble_offsets.is_empty():
			wobble_offsets.pop_back()
	population -= lost
	if bool(rules.get("collapse_costs_life", false)):
		lives = maxi(0, lives - 1)
		if lives == 0:
			is_over = true
	return {
		"result": RESULT_COLLAPSE,
		"lives": lives,
		"game_over": is_over,
		"x": x,
		"offset": offset,
		"removed": fallen.size(),
		"fallen": fallen,
		"lost_residents": lost,
		"banked": banked,
		"height": height(),
	}


## Block missed the tower entirely and fell off the screen: lose a life.
func _miss(x: float) -> Dictionary:
	var banked := _bank_combo()
	lives = maxi(0, lives - 1)
	if lives == 0:
		is_over = true
	return {"result": RESULT_MISS, "x": x, "lives": lives, "banked": banked, "game_over": is_over}


## Rewarded "continue": give lives back after a game over (never after completion).
## Returns false if the round can't be revived.
func revive(extra_lives: int) -> bool:
	if not is_over or is_complete or extra_lives <= 0:
		return false
	lives += extra_lives
	is_over = false
	return true


func _complete() -> Dictionary:
	var banked := _bank_combo()
	var star := population >= int(round_cfg.get("star_population", 1 << 30))
	var roof := int(round_cfg.get("star_roof_people", 0)) if star else int(round_cfg.get("roof_people", 0))
	population += roof
	is_over = true
	is_complete = true
	is_star = star
	return {"complete": true, "star": star, "roof_people": roof, "banked": banked}

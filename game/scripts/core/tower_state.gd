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

	if dist >= float(rules["miss_offset"]):
		return _miss(x)
	if dist > float(rules["max_offset"]):
		return _collapse(x, offset)

	var perfect := dist < float(rules["snap_window"])
	if perfect:
		x = below_x
		offset = 0.0

	var residents := residents_for(offset, rules)
	blocks.append({"x": x, "diff": offset, "residents": residents})
	population += residents
	_push_wobble(offset)

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
	var c: Dictionary = rules["combo"]
	var rate := float(c["drain_base"]) + float(c["drain_extra"]) * minf(1.0, float(combo_count) / float(c["drain_full_at"]))
	combo_time -= delta * rate
	if combo_time <= 0.0:
		return _bank_combo()
	return 0


## Remaining combo bar as 0..1 for the HUD.
func combo_ratio() -> float:
	return clampf(combo_time / float(rules["combo"]["bar_seconds"]), 0.0, 1.0)


func _grow_combo() -> void:
	combo_count += 1
	max_combo = maxi(max_combo, combo_count)
	var c: Dictionary = rules["combo"]
	combo_pool += combo_count * int(c["bonus_factor"]) * ceili(float(height()) / float(c["height_step"]))


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
	return {
		"result": RESULT_COLLAPSE,
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


func _complete() -> Dictionary:
	var banked := _bank_combo()
	var star := population >= int(round_cfg.get("star_population", 1 << 30))
	var roof := int(round_cfg.get("star_roof_people", 0)) if star else int(round_cfg.get("roof_people", 0))
	population += roof
	is_over = true
	is_complete = true
	return {"complete": true, "star": star, "roof_people": roof, "banked": banked}

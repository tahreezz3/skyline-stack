## Headless rule tests. Run from the repo root:
##   godot --headless --path game --script res://tests/run_tests.gd
## Exit code 0 = all passed. Add a test for every rule change (see docs/08_TESTING.md).
extends SceneTree

const TowerState := preload("res://scripts/core/tower_state.gd")
const ConfigLoader := preload("res://scripts/autoload/game_config.gd")

var rules: Dictionary
var passed := 0
var failed := 0


func _initialize() -> void:
	rules = ConfigLoader.load_json("res://config/tower_rules.json")
	for m in get_method_list():
		var name: String = m["name"]
		if name.begins_with("test_"):
			call(name)
	print("RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func check(cond: bool, label: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", label)


func near(a: float, b: float, eps := 0.0001) -> bool:
	return absf(a - b) < eps


func fresh(round_cfg: Dictionary = {}):
	return TowerState.new(rules, round_cfg)


# --- landing classification ---------------------------------------------------

func test_perfect_snaps_to_centre() -> void:
	var s = fresh()
	var ev: Dictionary = s.land(0.05)
	check(ev["result"] == TowerState.RESULT_PERFECT, "0.05 off is perfect")
	check(near(s.top_x(), 0.0), "perfect block snapped to x of block below")
	check(ev["residents"] == 4, "perfect houses 4")
	check(s.combo_count == 1 and near(s.combo_time, 8.0), "perfect starts combo with full 8 s bar")


func test_normal_stack() -> void:
	var s = fresh()
	var ev: Dictionary = s.land(0.2)
	check(ev["result"] == TowerState.RESULT_STACK, "0.2 off stacks")
	check(ev["residents"] == 2, "0.2 off houses 4 - floor(0.2/0.35*4) = 2")
	check(s.combo_count == 0, "normal stack does not start a combo")


func test_residents_never_zero() -> void:
	check(TowerState.residents_for(0.35, rules) == 1, "edge landing still houses 1")
	check(TowerState.residents_for(0.0, rules) == 4, "centre houses 4")
	check(TowerState.residents_for(-0.1, rules) == 3, "negative offsets mirror positive")


func test_miss_costs_a_life() -> void:
	var s = fresh()
	var ev: Dictionary = s.land(1.2)
	check(ev["result"] == TowerState.RESULT_MISS, "1.2 off misses")
	check(s.lives == 2, "miss costs one life")
	check(s.height() == 0, "miss adds no block")


func test_three_misses_end_the_game() -> void:
	var s = fresh()
	s.land(2.0)
	s.land(2.0)
	var ev: Dictionary = s.land(2.0)
	check(ev["game_over"] and s.is_over and not s.is_complete, "third miss is game over")
	check(s.land(0.0)["result"] == "ignored", "no landing after game over")


# --- collapse -----------------------------------------------------------------

func test_collapse_falls_until_stable() -> void:
	var s = fresh()
	s.land(0.1)    # diff 0.10 stable
	s.land(0.35)   # diff 0.25 unstable
	s.land(0.6)    # diff 0.25 unstable
	var pop_before: int = s.population
	var ev: Dictionary = s.land(1.1)   # diff 0.5: lands badly
	check(ev["result"] == TowerState.RESULT_COLLAPSE, "0.5 off collapses")
	check(ev["removed"] == 3, "new block + two unstable blocks fall")
	check(s.height() == 1, "stops at the stable block")
	check(s.population == pop_before - ev["lost_residents"], "fallen residents are lost")
	check(s.lives == 3, "collapse does not cost a life")


func test_collapse_never_removes_foundation() -> void:
	var s = fresh()
	s.land(0.25)
	s.land(0.5)
	var ev: Dictionary = s.land(1.0 - 0.01 + 0.0)   # 0.49 off
	check(ev["result"] == TowerState.RESULT_COLLAPSE, "collapse")
	check(s.height() == 0 and s.blocks.size() == 1, "foundation remains")


# --- wobble -------------------------------------------------------------------

func test_wobble_accumulates_same_side() -> void:
	var s = fresh()
	s.land(0.2)
	s.land(0.4)
	s.land(0.6)
	check(near(s.wobble(), 1.4 * 0.6), "three 0.2 offsets same side: 1.4 * 0.6")


func test_wobble_cancels_alternating() -> void:
	var s = fresh()
	s.land(0.2)
	s.land(0.0)
	check(near(s.wobble(), 0.0), "+0.2 then -0.2 cancel")


func test_wobble_window_is_five() -> void:
	var s = fresh()
	var x := 0.0
	for i in range(7):
		x += 0.1
		s.land(x)
	check(s.wobble_offsets.size() == 5, "only last 5 offsets kept")


# --- combo --------------------------------------------------------------------

func test_combo_bonus_and_bank() -> void:
	var s = fresh()
	s.land(0.0)                   # perfect, height 1: pool += 1 * 2 * ceil(1/10) = 2
	check(s.combo_pool == 2, "first perfect pool = 2")
	s.land(0.1)                   # stack during combo, height 2: count 2, pool += 2*2*1 = 4
	check(s.combo_count == 2 and s.combo_pool == 6, "stack during combo grows pool to 6")
	var pop: int = s.population
	var banked := 0
	for i in range(100):
		banked += s.tick(0.1)
	check(banked == 6, "bar runs out and banks the pool")
	check(s.population == pop + 6 and s.combo_count == 0, "bank pays out and resets")


func test_combo_drain_speeds_up() -> void:
	var s = fresh()
	s.land(0.0)                   # count 1 -> rate 1 + 3/15 = 1.2
	s.tick(1.0)
	check(near(s.combo_time, 8.0 - 1.2), "drain rate 1.2 at combo 1")


func test_perfect_refills_bar() -> void:
	var s = fresh()
	s.land(0.0)
	s.tick(3.0)
	s.land(0.0)
	check(near(s.combo_time, 8.0), "second perfect refills to 8 s")


func test_collapse_banks_combo() -> void:
	var s = fresh()
	s.land(0.0)
	var ev: Dictionary = s.land(0.5)
	check(ev["banked"] == 2 and s.combo_time == 0.0, "collapse banks and ends combo")


# --- round completion -----------------------------------------------------------

func test_round_complete_with_roof() -> void:
	var s = fresh({"target_height": 2, "roof_people": 40, "star_population": 1000, "star_roof_people": 60})
	s.land(0.2)
	var ev: Dictionary = s.land(0.4)
	check(ev.get("complete", false) and s.is_complete and s.is_over, "reaching target completes")
	check(ev["roof_people"] == 40 and not ev["star"], "normal roof when below star population")


func test_round_complete_with_trophy() -> void:
	var s = fresh({"target_height": 1, "roof_people": 40, "star_population": 4, "star_roof_people": 60})
	var ev: Dictionary = s.land(0.0)
	check(ev["star"] and ev["roof_people"] == 60, "trophy roof when population reaches star value")


# --- config sanity --------------------------------------------------------------

func test_config_tables_load() -> void:
	var blocks: Variant = ConfigLoader.load_json("res://config/block_types.json")
	var levels: Variant = ConfigLoader.load_json("res://config/levels.json")
	check(blocks is Dictionary and blocks["types"].size() == 4, "block_types has 4 types")
	check(levels is Dictionary and levels["levels"].size() >= 1, "levels table loads")
	check(rules["snap_window"] < rules["stable_offset"] and rules["stable_offset"] < rules["max_offset"] and rules["max_offset"] < rules["miss_offset"], "thresholds ordered snap < stable < max < miss")

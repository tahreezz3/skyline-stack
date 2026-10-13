## Ad pacing and the rewarded continue (T-0501).
extends "res://tests/test_case.gd"

const AdPolicy := preload("res://scripts/core/ad_policy.gd")
const TowerState := preload("res://scripts/core/tower_state.gd")

const CFG := {"min_rounds_before_first": 3, "every_n_rounds": 3, "min_seconds_between": 90}


func test_no_interstitial_early_or_for_ad_free() -> void:
	check(not AdPolicy.should_show_interstitial(2, 5, 999.0, false, CFG), "not before 3 rounds")
	check(not AdPolicy.should_show_interstitial(10, 5, 999.0, true, CFG), "never for ad-free players")


func test_interstitial_cadence() -> void:
	check(not AdPolicy.should_show_interstitial(5, 2, 999.0, false, CFG), "not more often than every 3 rounds")
	check(not AdPolicy.should_show_interstitial(5, 3, 30.0, false, CFG), "not within 90 s of the last")
	check(AdPolicy.should_show_interstitial(5, 3, 120.0, false, CFG), "allowed when all rules pass")


func test_continue_offer_limit() -> void:
	var cfg := {"continue_per_round": 1}
	check(AdPolicy.can_offer_continue(0, cfg) and not AdPolicy.can_offer_continue(1, cfg), "one continue per round")


func test_revive() -> void:
	var rules: Dictionary = ConfigLoader.load_json("res://tests/fixtures/tower_rules_v0.json")
	var s = TowerState.new(rules)
	check(not s.revive(1), "can't revive a running round")
	s.land(2.0)
	s.land(2.0)
	s.land(2.0)
	check(s.is_over and s.revive(1) and not s.is_over and s.lives == 1, "revive after game over restores a life")
	check(s.land(0.0)["result"] == TowerState.RESULT_PERFECT, "play continues after revive")
	var done = TowerState.new(rules, {"target_height": 1, "roof_people": 1})
	done.land(0.0)
	check(done.is_complete and not done.revive(1), "a completed tower can't be revived")


func test_economy_config_valid() -> void:
	var e: Dictionary = ConfigLoader.load_json("res://config/economy.json")
	check(int(e["interstitial"]["min_rounds_before_first"]) >= 1, "no ad before the first round ever")
	check(int(e["rewarded"]["double_reward_multiplier"]) >= 2, "double reward actually adds something")

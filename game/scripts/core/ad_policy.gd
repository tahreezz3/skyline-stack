## Pure ad pacing rules (T-0501). Inputs are plain values so tests can drive them.
## Rules (config/economy.json "interstitial"):
## - never for ad-free players;
## - never before `min_rounds_before_first` rounds have been played;
## - at most once every `every_n_rounds` rounds;
## - at least `min_seconds_between` seconds since the last one.
extends RefCounted


static func should_show_interstitial(rounds_played: int, rounds_since_last: int, seconds_since_last: float,
		ad_free: bool, cfg: Dictionary) -> bool:
	if ad_free:
		return false
	if rounds_played < int(cfg["min_rounds_before_first"]):
		return false
	if rounds_since_last < int(cfg["every_n_rounds"]):
		return false
	return seconds_since_last >= float(cfg["min_seconds_between"])


## Whether a round may offer the rewarded "continue" (one life back).
static func can_offer_continue(continues_used: int, cfg: Dictionary) -> bool:
	return continues_used < int(cfg["continue_per_round"])

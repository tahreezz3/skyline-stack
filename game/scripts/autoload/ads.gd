## Autoload "Ads": the only place that shows ads. Gameplay asks; this decides.
##
##   var earned: bool = await Ads.show_rewarded("continue")
##   Ads.on_round_finished()        # results screen: may show an interstitial per policy
##
## Backends:
## - "fake" (default until T-0506): a 2-second placeholder overlay "TEST AD"; rewarded ads always reward.
##   --ads-decline makes rewarded ads fail (to test the "no reward" path).
## - "none": autoplay/tour runs; rewarded ads reward instantly, interstitials never show.
## The AdMob backend (T-0506, HR-0015) will implement _present(format, placement) -> bool.
extends Node

const AdPolicy := preload("res://scripts/core/ad_policy.gd")
const FAKE_AD_S := 2.0

var backend := "fake"
var decline := false
var _overlay: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg == "--ads-decline":
			decline = true
	if SceneRouter.autoplay or SceneRouter.tour:
		backend = "none"


func is_ad_free() -> bool:
	return bool(SaveData.data.get("purchases", {}).get("remove_ads", false))


## Show a rewarded ad. Returns true if the player earned the reward.
## Rewarded ads are opt-in, so they are shown even to ad-free players.
func show_rewarded(placement: String) -> bool:
	var earned := await _present("rewarded", placement)
	_report("rewarded", placement, earned)
	return earned


## Call once per finished round (results screen). Shows an interstitial if the policy allows.
func on_round_finished() -> void:
	var a: Dictionary = SaveData.data["ads"]
	a["rounds_since_interstitial"] = int(a["rounds_since_interstitial"]) + 1
	var since := Time.get_unix_time_from_system() - float(a["last_interstitial_unix"])
	var ok := AdPolicy.should_show_interstitial(int(SaveData.stats()["rounds_played"]), int(a["rounds_since_interstitial"]),
		since, is_ad_free(), GameConfig.table("economy")["interstitial"])
	if ok and backend != "none":
		await _present("interstitial", "between_rounds")
		a["rounds_since_interstitial"] = 0
		a["last_interstitial_unix"] = Time.get_unix_time_from_system()
		_report("interstitial", "between_rounds", true)
	SaveData.write_save()


func _present(format: String, placement: String) -> bool:
	match backend:
		"none":
			return format == "rewarded"
		"fake":
			_show_overlay("TEST AD\n%s · %s" % [format, placement])
			await get_tree().create_timer(FAKE_AD_S, true, false, true).timeout
			_hide_overlay()
			return not (format == "rewarded" and decline)
	return false


func _report(format: String, placement: String, completed: bool) -> void:
	GameEvents.ad_finished.emit(format, placement, completed)


func _show_overlay(text: String) -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 90
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.96)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(bg)
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 48)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(l)
	add_child(_overlay)


func _hide_overlay() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null

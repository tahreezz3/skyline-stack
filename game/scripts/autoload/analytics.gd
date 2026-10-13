## Autoload "Analytics": turns GameEvents into analytics events (schema in
## scripts/core/analytics_events.gd, documented in docs/ANALYTICS.md).
##
## Privacy: nothing is sent unless settings.analytics_consent == "granted".
## Events before a decision are dropped, not queued. The consent prompt is T-0504;
## for now the Settings screen has an opt-in toggle (default off).
##
## Backends: "log" (default) appends JSON lines to user://analytics_log.jsonl so
## agents can verify events locally; "none" discards. The real provider (HR-0015)
## becomes another backend implementing _send(name, params).
extends Node

const Events := preload("res://scripts/core/analytics_events.gd")
const LOG_PATH := "user://analytics_log.jsonl"

var backend := "log"
var print_events := false     # --analytics-print
var sent: Array[Dictionary] = []   # in-memory copy for tests/tours
var _round_started_ms := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--analytics-print":
			print_events = true
	if SceneRouter.autoplay or SceneRouter.tour:
		backend = "none"   # smoke runs must not pollute the local log
	GameEvents.round_started.connect(func(block_type: String, endless: bool) -> void:
		_round_started_ms = Time.get_ticks_msec()
		track("round_start", {"block_type": block_type, "endless": endless}))
	GameEvents.round_ended.connect(func(s: Dictionary) -> void:
		track("round_end", {"block_type": s["block_type"], "endless": s["endless"], "complete": s["complete"],
			"star": s["star"], "population": s["population"], "height": s["height"], "max_combo": s["max_combo"],
			"duration_s": int((Time.get_ticks_msec() - _round_started_ms) / 1000)}))
	GameEvents.level_up.connect(func(a: int, b: int) -> void: track("level_up", {"from_level": a, "to_level": b}))
	GameEvents.block_type_unlocked.connect(func(id: String) -> void: track("tower_unlocked", {"block_type": id}))
	GameEvents.city_tower_placed.connect(func(t: Dictionary, city_pop: int) -> void:
		track("city_tower_placed", {"block_type": t["type"], "city_population": city_pop}))
	GameEvents.setting_changed.connect(func(k: String, v: Variant) -> void:
		if k in Events.REPORTABLE_SETTINGS:
			track("setting_changed", {"key": k, "value": v}))
	track("session_start", {"app_version": String(ProjectSettings.get_setting("application/config/version", "0.1.0")),
		"locale": TranslationServer.get_locale()})


func consent_granted() -> bool:
	return String(SaveData.get_setting("analytics_consent")) == "granted"


## Validate and send one event. Returns true if it was sent.
func track(name: String, params: Dictionary) -> bool:
	var err := Events.validate(name, params)
	if err != "":
		push_error("analytics: " + err)
		return false
	if not consent_granted():
		return false
	sent.append({"name": name, "params": params})
	if print_events:
		print("ANALYTICS ", name, " ", JSON.stringify(params))
	_send(name, params)
	return true


func _send(name: String, params: Dictionary) -> void:
	match backend:
		"log":
			var f := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
			if f:
				f.seek_end()
				f.store_line(JSON.stringify({"t": Time.get_unix_time_from_system(), "event": name, "params": params}))
		_:
			pass

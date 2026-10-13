## Autoload "AudioDirector": the only place that plays sound. Listens to
## GameEvents, never called by gameplay code directly (screens may call
## play_music()). Sound names match HUMAN_NEEDED.md HR-0008/HR-0009 exactly.
##
## Lookup order for a sound: res://assets/audio/<name>.wav, .ogg, then the
## procedural placeholder (scripts/game/placeholder_synth.gd). Music has no
## placeholder: it is silent until the files are integrated (T-0302).
extends Node

const Synth := preload("res://scripts/game/placeholder_synth.gd")
const AUDIO_DIR := "res://assets/audio/"
const BUSES := ["Music", "SFX", "UI"]
const POOL_SIZE := 8

## Event -> sound name. Keep in sync with HR-0008 (tests/test_audio.gd checks).
const SFX := {
	"release": "sfx_block_release",
	"land": "sfx_block_land",
	"land_sloppy": "sfx_block_land_sloppy",
	"perfect": "sfx_perfect",
	"combo_start": "sfx_combo_start",
	"combo_tick": "sfx_combo_tick_loop",
	"combo_bank": "sfx_combo_bank",
	"collapse": "sfx_collapse",
	"miss": "sfx_miss_fall",
	"life_lost": "sfx_life_lost",
	"complete": "sfx_tower_complete",
	"ui": "sfx_ui_tap",
}
const MUSIC := {"menu": "music_menu_loop", "round": "music_round_loop", "city": "music_city_loop"}

var _cache: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _ui_player: AudioStreamPlayer
var _tick_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _music_name := ""
var _feel: Dictionary


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_feel = GameConfig.table("feel")["audio"]
	_ensure_buses()
	for i in range(POOL_SIZE):
		_pool.append(_make_player("SFX"))
	_ui_player = _make_player("UI")
	_tick_player = _make_player("SFX")
	_music_player = _make_player("Music")
	_apply_volumes()
	GameEvents.block_released.connect(func() -> void: play("release"))
	GameEvents.block_resolved.connect(_on_block_resolved)
	GameEvents.combo_progress.connect(_on_combo_progress)
	GameEvents.combo_banked.connect(func(_amount: int) -> void:
		_tick_player.stop()
		play("combo_bank"))
	GameEvents.round_ended.connect(func(_s: Dictionary) -> void: _tick_player.stop())
	GameEvents.ui_pressed.connect(func() -> void: play("ui", 1.0, _ui_player))
	GameEvents.setting_changed.connect(func(_k: String, _v: Variant) -> void: _apply_volumes())


## Play a sound effect by event key (see SFX).
func play(key: String, pitch := 1.0, player: AudioStreamPlayer = null) -> void:
	var stream := stream_for(SFX[key])
	if stream == null:
		return
	if player == null:
		player = _pool[_next]
		_next = (_next + 1) % _pool.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.play()


## Start a music loop by key (see MUSIC). Silent if the file is not integrated yet.
func play_music(key: String) -> void:
	var name: String = MUSIC.get(key, "")
	if name == _music_name:
		return
	_music_name = name
	var stream := _load_file(name)
	_music_player.stop()
	if stream:
		_music_player.stream = stream
		_music_player.play()


## Real file if integrated, else placeholder, else null. Cached.
func stream_for(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var s := _load_file(name)
	if s == null and Synth.has_recipe(name):
		s = Synth.render(name)
	_cache[name] = s
	return s


func _load_file(name: String) -> AudioStream:
	for ext in [".wav", ".ogg"]:
		var path: String = AUDIO_DIR + name + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null


func _on_block_resolved(ev: Dictionary) -> void:
	match ev["result"]:
		"perfect":
			var steps := mini(int(ev.get("combo", 1)) - 1, int(_feel["perfect_pitch_max_steps"]))
			play("perfect", 1.0 + float(_feel["perfect_pitch_step"]) * steps)
			if int(ev.get("combo", 0)) == 1:
				play("combo_start")
		"stack":
			var sloppy := absf(float(ev["offset"])) >= float(GameConfig.table("tower_rules")["stable_offset"])
			play("land_sloppy" if sloppy else "land")
		"collapse":
			play("collapse")
		"miss":
			play("miss")
			play("life_lost")
	if ev.get("complete", false):
		play("complete")


## Combo ticking loop: plays while the bar runs, faster as it drains faster.
func _on_combo_progress(count: int, drain_rate: float) -> void:
	if count <= 0:
		_tick_player.stop()
		return
	var max_rate := 4.0
	var k := clampf((drain_rate - 1.0) / (max_rate - 1.0), 0.0, 1.0)
	_tick_player.pitch_scale = lerpf(float(_feel["combo_tick_pitch_min"]), float(_feel["combo_tick_pitch_max"]), k)
	if not _tick_player.playing:
		_tick_player.stream = stream_for(SFX["combo_tick"])
		_tick_player.play()


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _ensure_buses() -> void:
	for b in BUSES:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, b)
			AudioServer.set_bus_send(idx, "Master")


func _apply_volumes() -> void:
	var music := float(SaveData.get_setting("music_volume"))
	var sfx := float(SaveData.get_setting("sfx_volume"))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sfx, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), linear_to_db(maxf(sfx, 0.0001)))

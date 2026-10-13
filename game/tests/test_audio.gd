## Audio wiring: every sound requested in HUMAN_NEEDED.md HR-0008 is mapped to an
## event and has a placeholder, so delivered files drop straight in (T-0103/T-0302).
extends "res://tests/test_case.gd"

const Synth := preload("res://scripts/game/placeholder_synth.gd")
const AudioDirectorScript := preload("res://scripts/autoload/audio_director.gd")


func _requested_sfx() -> Array[String]:
	var path := ProjectSettings.globalize_path("res://").path_join("../HUMAN_NEEDED.md")
	var text := FileAccess.get_file_as_string(path)
	var start := text.find("### HR-0008")
	var block := text.substr(start, text.find("### HR-0009") - start)
	var names: Array[String] = []
	var re := RegEx.create_from_string("assets_inbox/audio/(sfx_[a-z_]+)\\.wav")
	for m in re.search_all(block):
		names.append(m.get_string(1))
	return names


func test_every_requested_sound_is_wired() -> void:
	var names := _requested_sfx()
	check(names.size() >= 10, "found the HR-0008 list (%d names)" % names.size())
	var mapped: Array = AudioDirectorScript.SFX.values()
	for n in names:
		check(n in mapped, "%s is mapped to an event in AudioDirector.SFX" % n)
		check(Synth.has_recipe(n), "%s has a placeholder recipe" % n)
	for n in mapped:
		check(n in names, "%s in AudioDirector.SFX is requested in HR-0008" % n)


func test_placeholders_render() -> void:
	for n in Synth.RECIPES:
		var wav := Synth.render(n)
		check(wav.data.size() > 200, "%s renders audio data" % n)
	check(Synth.render("sfx_combo_tick_loop").loop_mode == AudioStreamWAV.LOOP_FORWARD, "tick sound loops")

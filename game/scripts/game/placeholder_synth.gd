## Procedural placeholder sounds so audio plumbing works before the real files
## from HUMAN_NEEDED.md HR-0008 arrive. Each recipe is a short list of tone or
## noise segments rendered to a 16-bit mono AudioStreamWAV. Replace by dropping
## real files into game/assets/audio/<name>.wav (T-0302); AudioDirector prefers them.
extends RefCounted

const RATE := 22050

## name -> {loop: bool, segs: [{t0, dur, f0, f1, wave, vol}]}; wave = sine | square | noise
const RECIPES := {
	"sfx_block_release": {"segs": [{"t0": 0.0, "dur": 0.08, "f0": 0, "f1": 0, "wave": "noise", "vol": 0.35},
		{"t0": 0.0, "dur": 0.12, "f0": 900, "f1": 600, "wave": "square", "vol": 0.15}]},
	"sfx_block_land": {"segs": [{"t0": 0.0, "dur": 0.25, "f0": 140, "f1": 55, "wave": "sine", "vol": 0.9},
		{"t0": 0.0, "dur": 0.05, "f0": 0, "f1": 0, "wave": "noise", "vol": 0.3}]},
	"sfx_block_land_sloppy": {"segs": [{"t0": 0.0, "dur": 0.3, "f0": 120, "f1": 45, "wave": "sine", "vol": 0.9},
		{"t0": 0.08, "dur": 0.3, "f0": 260, "f1": 180, "wave": "square", "vol": 0.12}]},
	"sfx_perfect": {"segs": [{"t0": 0.0, "dur": 0.18, "f0": 988, "f1": 988, "wave": "sine", "vol": 0.6},
		{"t0": 0.09, "dur": 0.35, "f0": 1319, "f1": 1319, "wave": "sine", "vol": 0.55}]},
	"sfx_combo_start": {"segs": [{"t0": 0.0, "dur": 0.6, "f0": 300, "f1": 1200, "wave": "sine", "vol": 0.5},
		{"t0": 0.0, "dur": 0.6, "f0": 0, "f1": 0, "wave": "noise", "vol": 0.08}]},
	"sfx_combo_tick_loop": {"loop": true, "segs": [{"t0": 0.0, "dur": 0.03, "f0": 2000, "f1": 2000, "wave": "square", "vol": 0.2},
		{"t0": 0.25, "dur": 0.03, "f0": 1500, "f1": 1500, "wave": "square", "vol": 0.15},
		{"t0": 0.5, "dur": 0.03, "f0": 2000, "f1": 2000, "wave": "square", "vol": 0.2},
		{"t0": 0.75, "dur": 0.03, "f0": 1500, "f1": 1500, "wave": "square", "vol": 0.15},
		{"t0": 0.99, "dur": 0.01, "f0": 0, "f1": 0, "wave": "sine", "vol": 0.0}]},
	"sfx_combo_bank": {"segs": [{"t0": 0.0, "dur": 0.15, "f0": 784, "f1": 784, "wave": "square", "vol": 0.25},
		{"t0": 0.12, "dur": 0.15, "f0": 988, "f1": 988, "wave": "square", "vol": 0.25},
		{"t0": 0.24, "dur": 0.5, "f0": 1568, "f1": 1568, "wave": "square", "vol": 0.25}]},
	"sfx_collapse": {"segs": [{"t0": 0.0, "dur": 1.3, "f0": 0, "f1": 0, "wave": "noise", "vol": 0.5},
		{"t0": 0.0, "dur": 1.3, "f0": 70, "f1": 35, "wave": "sine", "vol": 0.8}]},
	"sfx_miss_fall": {"segs": [{"t0": 0.0, "dur": 0.9, "f0": 1200, "f1": 250, "wave": "sine", "vol": 0.4}]},
	"sfx_life_lost": {"segs": [{"t0": 0.0, "dur": 0.25, "f0": 330, "f1": 330, "wave": "square", "vol": 0.25},
		{"t0": 0.22, "dur": 0.4, "f0": 220, "f1": 200, "wave": "square", "vol": 0.25}]},
	"sfx_tower_complete": {"segs": [{"t0": 0.0, "dur": 0.2, "f0": 523, "f1": 523, "wave": "square", "vol": 0.25},
		{"t0": 0.18, "dur": 0.2, "f0": 659, "f1": 659, "wave": "square", "vol": 0.25},
		{"t0": 0.36, "dur": 0.2, "f0": 784, "f1": 784, "wave": "square", "vol": 0.25},
		{"t0": 0.54, "dur": 0.8, "f0": 1047, "f1": 1047, "wave": "square", "vol": 0.25}]},
	"sfx_ui_tap": {"segs": [{"t0": 0.0, "dur": 0.05, "f0": 1100, "f1": 900, "wave": "sine", "vol": 0.4}]},
}


static func has_recipe(name: String) -> bool:
	return RECIPES.has(name)


static func render(name: String) -> AudioStreamWAV:
	var recipe: Dictionary = RECIPES[name]
	var segs: Array = recipe["segs"]
	var total := 0.0
	for s in segs:
		total = maxf(total, float(s["t0"]) + float(s["dur"]))
	var n := int(total * RATE) + 1
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)   # deterministic placeholder
	for s in segs:
		var start := int(float(s["t0"]) * RATE)
		var len := int(float(s["dur"]) * RATE)
		var phase := 0.0
		for i in range(len):
			var k := float(i) / maxf(1.0, float(len))
			var f := lerpf(float(s["f0"]), float(s["f1"]), k)
			phase += TAU * f / RATE
			var v := 0.0
			match String(s["wave"]):
				"sine": v = sin(phase)
				"square": v = 1.0 if sin(phase) >= 0.0 else -1.0
				"noise": v = rng.randf_range(-1.0, 1.0)
			# short attack, exponential-ish decay envelope
			var env := minf(1.0, float(i) / (0.005 * RATE)) * pow(1.0 - k, 1.5)
			buf[start + i] += v * env * float(s["vol"])
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if recipe.get("loop", false):
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = n - 1
	return wav

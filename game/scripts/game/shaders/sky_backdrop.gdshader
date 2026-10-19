// Sky backdrop for the 3D tower view (T-0306): vertical gradient plus stars at night.
// Drawn on a quad parented to the camera, so it always fills the screen.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 top_color : source_color = vec3(0.37, 0.66, 1.0);
uniform vec3 bottom_color : source_color = vec3(0.84, 0.92, 1.0);
uniform float stars : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = smoothstep(0.0, 1.0, UV.y);
	vec3 c = mix(top_color, bottom_color, t);
	// stars: one candidate per grid cell, drawn as a tiny soft dot at a random spot in the cell
	vec2 grid = vec2(40.0, 70.0);
	vec2 cell = floor(UV * grid);
	vec2 local = fract(UV * grid);
	float h = hash(cell);
	vec2 spot = vec2(hash(cell + 3.1), hash(cell + 7.7)) * 0.6 + 0.2;
	float d = length((local - spot) * vec2(grid.x / grid.y, 1.0));
	float size = 0.035 + 0.04 * hash(cell + 1.3);
	float dot_mask = smoothstep(size, size * 0.3, d);
	float twinkle = 0.55 + 0.45 * sin(TIME * (1.5 + h * 2.0) + h * 40.0);
	float star = step(0.82, h) * dot_mask * stars * (1.0 - t * 0.7) * twinkle;
	ALBEDO = c + vec3(star) * vec3(0.95, 0.97, 1.0);
}

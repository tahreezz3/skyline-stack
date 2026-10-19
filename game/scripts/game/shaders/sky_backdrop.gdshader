// Sky backdrop for the 3D tower view (T-0306, T-0308): vertical gradient, soft
// painterly clouds in two warm tones (like the owner's reference), stars at night.
// Drawn on a quad parented to the camera, so it always fills the screen.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 top_color : source_color = vec3(0.18, 0.64, 0.9);
uniform vec3 bottom_color : source_color = vec3(1.0, 0.89, 0.74);
uniform vec3 cloud_warm : source_color = vec3(0.97, 0.69, 0.55);
uniform vec3 cloud_light : source_color = vec3(1.0, 0.94, 0.66);
uniform float cloud_amount : hint_range(0.0, 1.0) = 0.85;
uniform float stars : hint_range(0.0, 1.0) = 0.0;
uniform float scroll = 0.0;   // camera height, so clouds drift past as the tower grows

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float t = smoothstep(0.0, 1.0, UV.y);
	vec3 c = mix(top_color, bottom_color, t);

	// painterly clouds: stretched fbm, banded so they read as soft puffs with lit tops
	vec2 cp = vec2(UV.x * 2.2 + TIME * 0.006, (UV.y - scroll) * 3.2);
	float n = fbm(cp * 1.6);
	float mask = smoothstep(0.52, 0.66, n) * cloud_amount;
	float light = smoothstep(0.55, 0.85, fbm(cp * 1.6 + vec2(0.0, -0.08)));   // brighter where puffs bulge up
	vec3 cloud = mix(cloud_warm, cloud_light, light);
	c = mix(c, cloud, mask * 0.9);

	// stars: tiny soft dots at random spots, fading towards the horizon
	vec2 grid = vec2(40.0, 70.0);
	vec2 cell = floor(UV * grid);
	vec2 local = fract(UV * grid);
	float h = hash(cell);
	vec2 spot = vec2(hash(cell + 3.1), hash(cell + 7.7)) * 0.6 + 0.2;
	float d = length((local - spot) * vec2(grid.x / grid.y, 1.0));
	float size = 0.035 + 0.04 * hash(cell + 1.3);
	float dot_mask = smoothstep(size, size * 0.3, d);
	float twinkle = 0.55 + 0.45 * sin(TIME * (1.5 + h * 2.0) + h * 40.0);
	float star = step(0.82, h) * dot_mask * stars * (1.0 - t * 0.7) * twinkle * (1.0 - mask);
	ALBEDO = c + vec3(star) * vec3(0.95, 0.97, 1.0);
}

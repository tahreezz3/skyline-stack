// Living 2.5D environment: independent sky, masked water, live actor layer and depth.
// Explicit scene clock freezes on pause; never use shader TIME here.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D environment_image : source_color, filter_linear, repeat_disable;
uniform sampler2D motion_mask : filter_linear, repeat_disable;
uniform sampler2D live_actors : source_color, filter_linear, repeat_disable;
uniform float image_aspect = 0.5625;
uniform float viewport_aspect = 0.5625;
uniform float scene_seconds = 0.0;
uniform float motion_amount = 1.0;
uniform vec2 depth_offset = vec2(0.0);
uniform vec2 depth_factors = vec2(0.12, 1.0);
uniform vec2 cloud_motion = vec2(0.036, 0.055);
uniform vec2 water_amplitude = vec2(0.0016, 0.00055);
uniform vec2 cloth_motion = vec2(0.0022, 6.2);
uniform float water_speed = 1.4;
uniform float glint_strength = 0.11;
uniform vec2 refraction_frequency = vec2(320.0, 700.0);
uniform vec2 glint_frequency = vec2(210.0, 1100.0);
uniform vec2 glint_sharpness = vec2(18.0, 8.0);
uniform float glint_drift = 0.7;
uniform float cross_wave_speed = 1.0;
uniform float cross_wave_bend = 2.0;
uniform float cloud_edge_pin = 0.08;
uniform float cloth_frequency = 140.0;

void fragment() {
	vec2 uv = UV;
	if (viewport_aspect < image_aspect) {
		uv.x = (uv.x - 0.5) * viewport_aspect / image_aspect + 0.5;
	} else {
		uv.y = 1.0 - (1.0 - uv.y) * image_aspect / viewport_aspect;
	}
	// Foreground moves farther than the distant sky as the round camera climbs.
	uv += depth_offset * mix(depth_factors.x, depth_factors.y, smoothstep(0.15, 0.95, uv.y));
	uv = clamp(uv, vec2(0.001), vec2(0.999));
	vec3 mask = texture(motion_mask, uv).rgb;
	vec2 sample_uv = uv;
	float t = scene_seconds;
	float edge_pin = smoothstep(0.0, cloud_edge_pin, uv.x) * (1.0 - smoothstep(1.0 - cloud_edge_pin, 1.0, uv.x));
	// Conservative sky silhouettes pin all towers, mountain edges and sunset suns.
	sample_uv.x += sin(t * cloud_motion.y) * cloud_motion.x * mask.r * edge_pin * motion_amount;
	sample_uv.x += sin(t * cloth_motion.y - uv.y * cloth_frequency) * cloth_motion.x * mask.b * motion_amount;
	// Subpixel refraction is confined to open water, preserving painted shorelines.
	sample_uv += vec2(sin(uv.y * refraction_frequency.y + t * water_speed), cos(uv.x * refraction_frequency.x - t * water_speed)) * water_amplitude * mask.g * motion_amount;
	vec3 color = texture(environment_image, sample_uv).rgb;
	float ripple = pow(0.5 + 0.5 * sin(uv.y * glint_frequency.y + sin(uv.x * refraction_frequency.x * 0.3125 + t * cross_wave_speed) * cross_wave_bend - t * water_speed), glint_sharpness.x);
	float broken = pow(0.5 + 0.5 * sin(uv.x * glint_frequency.x - t * glint_drift), glint_sharpness.y);
	color = mix(color, vec3(1.0, 0.97, 0.87), ripple * broken * mask.g * glint_strength);
	vec4 actor = texture(live_actors, uv);
	ALBEDO = mix(color, actor.rgb, actor.a);
}

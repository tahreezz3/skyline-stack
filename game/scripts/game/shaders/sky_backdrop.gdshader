// T-0315: reference-matched environment artwork, independent of live tower/crane/HUD.
// Aspect-cover keeps pixels unstretched, retaining the bottom-centre ground clearing.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D environment_image : source_color, filter_linear, repeat_disable;
uniform float image_aspect = 0.5625;
uniform float viewport_aspect = 0.5625;

void fragment() {
	vec2 uv = UV;
	if (viewport_aspect < image_aspect) {
		uv.x = (uv.x - 0.5) * viewport_aspect / image_aspect + 0.5;
	} else {
		uv.y = 1.0 - (1.0 - uv.y) * image_aspect / viewport_aspect;
	}
	ALBEDO = texture(environment_image, uv).rgb;
}

shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 water_color : source_color;
uniform float scene_seconds = 0.0;
uniform float motion_amount = 1.0;
uniform float wave_amplitude = 0.018;
uniform float wave_speed = 1.1;
uniform float glint = 0.12;
varying vec2 world_xz;
void vertex() {
 world_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;
 VERTEX.y+=sin(world_xz.x*5.0+world_xz.y*3.0+scene_seconds*wave_speed)*wave_amplitude*motion_amount;
}
void fragment() {
 float wave=sin(world_xz.x*24.0+sin(world_xz.y*6.0+scene_seconds)*2.0-scene_seconds*wave_speed);
 float light=pow(0.5+0.5*wave,18.0)*glint;
 ALBEDO=mix(water_color.rgb,vec3(1.0,0.98,0.83),light);
}

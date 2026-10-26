shader_type spatial;
render_mode cull_disabled;
uniform vec4 cloth_color : source_color;
uniform float scene_seconds=0.0;
uniform float wind_speed=4.0;
uniform float wind_amplitude=0.035;
void vertex(){VERTEX.z+=sin(UV.x*6.0-scene_seconds*wind_speed)*UV.x*wind_amplitude;}
void fragment(){ALBEDO=cloth_color.rgb;ROUGHNESS=0.9;}

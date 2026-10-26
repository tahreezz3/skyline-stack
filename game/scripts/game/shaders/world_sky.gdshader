// Infinite atmosphere only. All scenery and cloud meshes live in world space.
shader_type spatial;
render_mode unshaded,cull_disabled,shadows_disabled,fog_disabled;
uniform vec4 sky_top : source_color;
uniform vec4 sky_bottom : source_color;
uniform float altitude=0.0;
uniform float altitude_range=30.0;
uniform float sky_horizon=0.44;
uniform bool natural_sun=false;
uniform vec2 sun_position=vec2(0.84,0.30);
uniform float sun_radius=0.065;
uniform float viewport_aspect=0.5625;
void fragment(){
 float high=clamp(altitude/altitude_range,0.0,1.0);
 vec3 color=mix(sky_top.rgb,sky_bottom.rgb,pow(clamp(UV.y/sky_horizon,0.0,1.0),1.4)*(1.0-high*0.7));
 vec2 p=UV-sun_position;p.x*=viewport_aspect;
 float disc=1.0-smoothstep(sun_radius*.96,sun_radius,length(p));
 float glow=exp(-length(p)*18.0)*.16;
 if(natural_sun){color=mix(color,vec3(1.0,.94,.68),disc);color+=vec3(.17,.08,.015)*glow;}
 ALBEDO=color;
}

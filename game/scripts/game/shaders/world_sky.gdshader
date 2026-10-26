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
uniform vec4 weather_tint : source_color;
uniform float weather_tint_amount=0.0;
uniform float weather_amount=1.0;
uniform float upper_amount=0.0;
uniform float space_amount=0.0;
uniform vec4 upper_color : source_color;
uniform vec4 space_top : source_color;
uniform vec4 space_bottom : source_color;
uniform float star_grid=40.0;
uniform float star_size=0.075;
uniform float star_density=0.3;
uniform float star_parallax=0.018;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float stars(vec2 p,float scale){
 vec2 grid=p*scale;
 vec2 cell=floor(grid);
 vec2 center=vec2(hash(cell),hash(cell+17.3))*0.7+0.15;
 float r=star_size*mix(0.45,1.0,hash(cell+31.7));
 float point=1.0-smoothstep(r*0.25,r,length(fract(grid)-center));
 return point*step(1.0-star_density,hash(cell+3.1));
}
void fragment(){
 float high=clamp(altitude/altitude_range,0.0,1.0);
 vec3 color=mix(sky_top.rgb,sky_bottom.rgb,pow(clamp(UV.y/sky_horizon,0.0,1.0),1.4)*(1.0-high*0.7));
 vec2 p=UV-sun_position;p.x*=viewport_aspect;
 float disc=1.0-smoothstep(sun_radius*.96,sun_radius,length(p));
 float glow=exp(-length(p)*18.0)*.16;
 color=mix(color,weather_tint.rgb,weather_tint_amount*weather_amount);
 if(natural_sun){color=mix(color,vec3(1.0,.94,.68),disc*weather_amount);color+=vec3(.17,.08,.015)*glow*weather_amount;}
 color=mix(color,upper_color.rgb,upper_amount*0.65);
 vec3 cosmos=mix(space_top.rgb,space_bottom.rgb,pow(UV.y,2.0));
 // Infinite distant stars shift with camera altitude, rather than a still plate.
 vec2 star_uv=vec2(UV.x*viewport_aspect,UV.y-altitude*star_parallax);
 float star=stars(star_uv,star_grid)+stars(star_uv+23.1,star_grid*0.63)*0.65;
 cosmos+=vec3(0.78,0.89,1.0)*star;
 color=mix(color,cosmos,space_amount);
 ALBEDO=color;
}

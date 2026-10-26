// A textureless atmospheric volume behind the tower. No TIME or physics.
shader_type spatial;
render_mode unshaded,cull_disabled,shadows_disabled,depth_draw_never,fog_disabled;
uniform float scene_seconds=0.0;
uniform float altitude=0.0;
uniform float weather_amount=1.0;
uniform float viewport_aspect=0.5625;
uniform float rain=0.0;
uniform float snow=0.0;
uniform float wind=0.0;
uniform float fog=0.0;
uniform float storm=0.0;
uniform float motion_amount=1.0;
uniform vec2 rain_grid=vec2(35.0,9.0);
uniform float rain_length=0.28;
uniform float rain_width=0.028;
uniform float rain_speed=1.8;
uniform vec2 snow_grid=vec2(22.0,13.0);
uniform float snow_size=0.06;
uniform float snow_speed=0.18;
uniform float wind_speed=0.32;
uniform float wind_opacity=0.4;
uniform float fog_speed=0.025;
uniform float lightning_period=13.0;
uniform float lightning_duration=0.65;
uniform float lightning_strength=0.22;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 a=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(a),hash(a+vec2(1,0)),f.x),mix(hash(a+vec2(0,1)),hash(a+vec2(1,1)),f.x),f.y);
}
void fragment(){
 vec2 p=vec2(UV.x*viewport_aspect,UV.y);
 float drops=0.0;float flakes=0.0;
 for(int i=0;i<2;i++){
  float layer=1.0+float(i)*0.6;
  vec2 r=p*rain_grid*layer;
  r.x+=UV.y*wind*5.0-scene_seconds*wind;
  r.y-=scene_seconds*rain_speed*layer+altitude*0.6;
  vec2 cell=floor(r);vec2 q=fract(r);
  float line=(1.0-smoothstep(rain_width*0.4,rain_width,abs(q.x-0.5)))*(1.0-smoothstep(rain_length*0.4,rain_length,abs(q.y-0.5)));
  drops+=line*step(1.0-rain,hash(cell+float(i)*19.0));
  vec2 s=p*snow_grid*layer;
  s.y-=scene_seconds*snow_speed*layer+altitude*0.4;
  s.x+=sin(s.y*0.3+scene_seconds*0.45)*0.35+scene_seconds*wind;
  vec2 center=vec2(hash(floor(s)),hash(floor(s)+5.1))*0.7+0.15;
  flakes+=(1.0-smoothstep(snow_size*0.35,snow_size,length(fract(s)-center)))*step(1.0-snow,hash(floor(s)+1.7));
 }
 float gust=pow(max(0.0,sin((UV.y+altitude*0.13)*85.0+sin(UV.x*7.0)*0.7)),35.0);
 gust*=pow(max(0.0,sin(UV.x*15.0-scene_seconds*wind_speed*15.0+UV.y*31.0)),14.0)*wind*wind_opacity;
 float haze=noise(vec2(UV.x*4.0+scene_seconds*fog_speed,UV.y*6.0+altitude*0.2));
 float mist=fog*(0.3+0.65*haze)*smoothstep(0.0,0.65,UV.y);
 float phase=mod(scene_seconds,lightning_period);
 float flash=(1.0-smoothstep(0.0,lightning_duration,abs(phase-3.0)))*storm*motion_amount;
 float path=0.81-UV.y*0.24+sin(floor(UV.y*22.0)*7.7)*0.035;
 float bolt=(1.0-smoothstep(0.001,0.004,abs(UV.x-path)))*step(UV.y,0.64)*step(0.1,UV.y)*flash;
 float alpha=clamp(drops*0.38+flakes*0.8+gust+mist+bolt*0.85+flash*lightning_strength*0.15,0.0,0.85);
 ALBEDO=mix(vec3(0.75,0.87,0.94),vec3(1.0),clamp(flakes+bolt,0.0,1.0));
 ALPHA=alpha*weather_amount;
}

shader_type spatial;
render_mode unshaded,shadows_disabled;
uniform vec4 planet_color : source_color;
uniform vec4 accent : source_color;
uniform int kind=0;
varying vec3 local_position;
varying vec3 view_normal;
void vertex(){local_position=VERTEX;view_normal=(MODELVIEW_MATRIX*vec4(NORMAL,0.0)).xyz;}
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 p){
 vec3 a=floor(p);vec3 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(a),hash(a+vec3(1,0,0)),f.x),mix(hash(a+vec3(0,1,0)),hash(a+vec3(1,1,0)),f.x),f.y),mix(mix(hash(a+vec3(0,0,1)),hash(a+vec3(1,0,1)),f.x),mix(hash(a+vec3(0,1,1)),hash(a+vec3(1,1,1)),f.x),f.y),f.z);
}
void fragment(){
 vec3 n=normalize(local_position);
 float geography=noise(n*5.0)+noise(n*13.0)*0.25;
 vec3 color=planet_color.rgb;
 if(kind==0){
  color=mix(color,accent.rgb,smoothstep(0.57,0.66,geography));
  float cloud=smoothstep(0.68,0.82,noise(n*8.0+vec3(5,2,0)));
  color=mix(color,vec3(0.92,0.98,1.0),cloud*0.85+pow(abs(n.y),12.0)*0.7);
 }else if(kind==1){
  float bands=sin(n.y*34.0+sin(n.x*8.0)*0.6+noise(n*7.0)*2.0)*0.5+0.5;
  color=mix(color,accent.rgb,bands);
 }else{
  color=mix(color*0.7,accent.rgb,geography);
  color*=0.84+noise(n*28.0)*0.22;
 }
 vec3 facing=normalize(view_normal);
 float light=0.3+0.7*max(0.0,dot(facing,normalize(vec3(-0.65,0.5,1.0))));
 // Bright blue limb, with the solid sphere still occluding its rear ring.
 float limb=pow(1.0-abs(facing.z),4.0);
 ALBEDO=color*light+vec3(0.15,0.4,0.65)*limb*(kind==0?0.5:0.08);
}

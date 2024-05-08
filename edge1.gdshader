//---------------------------------------------
// Edge-Detection Shader Pass 1
//
// Here we simply pass the vertex normals to the albedo
// so we can access it through the SCREEN_TEXTURE in our Shader Pass 2
// LICENSE: MIT

shader_type spatial;
render_mode unshaded,blend_mix,depth_draw_opaque,cull_back,diffuse_toon,specular_disabled;

varying vec3 world_normal;

void vertex() {
	world_normal = NORMAL + 0.0000001;
}

void fragment() {
	ALBEDO = reflect(VIEW, world_normal);
}

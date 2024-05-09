shader_type spatial;
render_mode unshaded,blend_mix,depth_prepass_alpha,cull_back;
uniform sampler2DArray xcubemap;

varying vec3 barys;
varying vec3 norm;

void vertex() {
	norm = NORMAL;
	int index = VERTEX_ID % 3;
	switch (index) {
		case 0:
			barys = vec3(1.0, 0.0, 0.0);
			break;
		case 1:
			barys = vec3(0.0, 1.0, 0.0);
			break;
		case 2:
			barys = vec3(0.0, 0.0, 1.0);
			break;
	}
}

void fragment() {
	int index = 6;
	if (dot(norm, vec3(1,0,0)) > 0.5) {
		index = 0;
	} else if (dot(norm, vec3(-1,0,0)) > 0.5) {
		index = 1;
	} else if (dot(norm, vec3(0,1,0)) > 0.5) {
		index = 2;
	} else if (dot(norm, vec3(0,-1,0)) > 0.5) {
		index = 3;
	} else if (dot(norm, vec3(0,0,1)) > 0.5) {
		index = 4;
	} else if (dot(norm, vec3(0,0,-1)) > 0.5) {
		index = 5;
	}
	vec3 inner_color = texture(xcubemap, vec3(SCREEN_UV, float(index))).rgb;
	inner_color *= inner_color;
	ALBEDO = inner_color;
	
//	METALLIC = metallic;
//	ROUGHNESS = roughness;
//	SPECULAR = specular;
}

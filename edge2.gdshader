//---------------------------------------------
// Edge-Detection Shader Pass 2
//
// Here's our fully lit and shaded model,
// but through the SCREEN_TEXTURE, we also have the world normals
// of all the visible parts of our model that the first pass gives us.
// LICENSE: MIT

shader_type spatial;
render_mode unshaded,blend_mix,depth_prepass_alpha,cull_back,diffuse_lambert,specular_disabled;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float edge_strength : hint_range(0,1) = 1.0;
uniform vec4 edge_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
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

// essentially a cheap "lightness" function
// returns the average of red, green and blue color channels
float vec3_avg(vec3 color) {
	return (color.r + color.g + color.b) / 3.0;
}

float vec3_diff(vec3 depth_a, vec3 depth_b){
	return 0.5-(dot(depth_a, depth_b))/2.0;
}

// transform a pixel coordinate to screen UV
vec2 pixel_to_screen_uv(vec2 viewport_size, vec2 pixel) {
	return vec2(pixel.x / viewport_size.x, pixel.y / viewport_size.y);
}

void fragment() {
	vec3 viewVec = (vec4(VIEW, 1.0) * VIEW_MATRIX).xyz;
	vec3 normVec = (vec4(NORMAL, 1.0) * VIEW_MATRIX).xyz;
	vec2 iuv = vec2(SCREEN_UV.x * VIEWPORT_SIZE.x, SCREEN_UV.y * VIEWPORT_SIZE.y);
	
	vec3 n = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv)).rgb;
	
	vec3 nl = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(-1.0, 0.0))).rgb;
	vec3 nr = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(1.0, 0.0))).rgb;
	vec3 nu = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0.0, 1.0))).rgb;
	vec3 nd = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0.0, 1.0))).rgb;
	
	float total_diff = (
		vec3_diff(n, nl) +
		vec3_diff(n, nu) +
		vec3_diff(n, nd) +
		vec3_diff(n, nr)
	);
	
	
	ALPHA = 0.0;
	
//	METALLIC = metallic;
//	ROUGHNESS = roughness;
//	SPECULAR = specular;
}

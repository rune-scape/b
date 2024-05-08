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
uniform samplerCube xcubemap;

// essentially a cheap "lightness" function
// returns the average of red, green and blue color channels
float vec3_avg(vec3 color) {
	return (color.r + color.g + color.b) / 3.0;
} 

// transform a pixel coordinate to screen UV
vec2 pixel_to_screen_uv(vec2 viewport_size, vec2 pixel) {
	return vec2(pixel.x / viewport_size.x, pixel.y / viewport_size.y);
}

void fragment() {
	vec2 iuv = vec2(SCREEN_UV.x * VIEWPORT_SIZE.x, SCREEN_UV.y * VIEWPORT_SIZE.y);
	
	vec3 neighbour_l = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(-1.0, 0.0))).rgb;
	vec3 neighbour_r = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(1.0, 0.0))).rgb;
	
	vec3 neighbour_top = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0.0, 1.0))).rgb;
	vec3 neighbour_bot = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0.0, 1.0))).rgb;
	
	// compare normals: if they differ, we draw an edge
	// by mixing in the edge_color, by edge_strength amount
	// feel free to try other ways to mix, such as multiply for more textured objects.
	if (abs(vec3_avg(neighbour_l) - vec3_avg(neighbour_r)) > 0.01 || abs(vec3_avg(neighbour_top) - vec3_avg(neighbour_bot)) > 0.01) {
		//ALBEDO = mix(ALBEDO, edge_color.rgb, edge_strength);
		//ALPHA = edge_strength;
		ALBEDO = edge_color.rgb;
		ALPHA = edge_color.a;
	} else {
		ALBEDO = texture(xcubemap, COLOR.rgb).rgb;
		ALPHA = 0.0;
	}
	
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}

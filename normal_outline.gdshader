shader_type spatial;

uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	// Place fragment code here.
}

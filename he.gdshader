shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D world_tex;

void fragment() {
	COLOR = texture(world_tex, SCREEN_UV);
}

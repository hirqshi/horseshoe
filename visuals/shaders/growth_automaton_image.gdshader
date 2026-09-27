shader_type canvas_item;

// Image pass for growth automaton - reads the current buffer's texture
// and wraps the red channel back into 0..1 range for display/coloring.

uniform sampler2D buffer_texture : filter_linear;

void fragment() {
	vec4 color = texture(buffer_texture, UV);
	color.r = mod(color.r, 1.0);
	COLOR = color;
}

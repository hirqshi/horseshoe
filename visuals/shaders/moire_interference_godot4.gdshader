shader_type canvas_item;

// Port of circular moire / interference pattern shader
// Reads a noise texture twice with opposite time-offsets to create interference
//
// repeat_enable forces tiling sampling at the shader level, regardless of
// node/resource repeat settings - this is what actually fixes the static clamp issue.

uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform float scroll_speed : hint_range(0.0, 0.5) = 0.05;
uniform float tile_size : hint_range(0.001, 1.0) = 0.045;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.4;
uniform float time_offset : hint_range(0.0, 200.0) = 0.0;

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = FRAGCOORD.xy / resolution;
	uv.x = uv.x > 0.5 ? 1.0 - uv.x : uv.x;

	float circle_mask = 1.0 - length((uv - vec2(0.5, 0.5)) * 2.0);
	float tex1 = texture(noise_texture, (uv + (TIME + time_offset) * scroll_speed) * tile_size).r;
	float tex2 = texture(noise_texture, (uv - (TIME + time_offset) * scroll_speed) * tile_size).r;
	float noise_val = tex1 * tex2;

	float col = mix(1.0, noise_val, circle_mask);
	col = step(alpha_cutoff, col);

	COLOR = vec4(col, col, col, 1.0);
}
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float progress_trans : hint_range(0.0, 1.0) = 0.0;

uniform vec4 transition_color : source_color = vec4(
	0.0,
	0.0,
	0.0,
	1.0
);


void fragment() {
	float transition_time = progress_trans * 3.0;

	vec2 viewport_size_px = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 screen_uv = SCREEN_UV;

	float pixelation_speed = 15.0;

	float pixel_size_px = (
		floor(
			pow(
				transition_time,
				1.4
			)
			* pixelation_speed
		)
		* 2.0
		+ 0.01
	);

	screen_uv *= viewport_size_px / pixel_size_px;
	screen_uv = floor(screen_uv);
	screen_uv /= viewport_size_px / pixel_size_px;

	screen_uv += pixel_size_px * 0.002;

	vec4 pixelated_screen = texture(
		SCREEN_TEXTURE,
		screen_uv
	);

	float fade_start = 1.0;
	float fade_end = 2.0;

	float color_mix = smoothstep(
		fade_start,
		fade_end,
		transition_time
	);

	COLOR = mix(
		pixelated_screen,
		transition_color,
		color_mix
	);
}
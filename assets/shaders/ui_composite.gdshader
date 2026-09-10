shader_type canvas_item;

render_mode unshaded, blend_premul_alpha;

uniform sampler2D ui_texture : filter_linear, repeat_disable;

// set from InGameHud using SubViewport size
uniform vec2 ui_texture_pixel_size = vec2(
	0.0005208333,
	0.0009259259
);


// === master ===

uniform float effect_intensity : hint_range(
	0.0,
	1.0,
	0.01
) = 1.0;

// === color ===

uniform float hue_shift_degrees : hint_range(
	-180.0,
	180.0,
	0.1
) = 0.0;

// === convex ui projection ===

uniform float side_pinch_amount : hint_range(
	0.0,
	1.0,
	0.01
) = 0.50;


// === pixelation ===

uniform float pixel_size_px : hint_range(
	1.0,
	32.0,
	1.0
) = 1.0;


// === outer bloom ===

uniform float bloom_strength : hint_range(
	0.0,
	3.0,
	0.01
) = 0.45;

uniform float bloom_radius_px : hint_range(
	0.0,
	32.0,
	0.1
) = 3.0;

uniform float bloom_alpha : hint_range(
	0.0,
	1.0,
	0.01
) = 0.45;


// === crt scanlines ===

uniform float scanline_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.10;

uniform float scanline_density : hint_range(
	1.0,
	2000.0,
	1.0
) = 520.0;

uniform float grille_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.03;

uniform float grille_density : hint_range(
	1.0,
	2000.0,
	1.0
) = 360.0;

uniform float flicker_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.01;

uniform float flicker_speed : hint_range(
	0.0,
	60.0,
	0.1
) = 15.0;

uniform float noise_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.008;

uniform float noise_density : hint_range(
	1.0,
	4000.0,
	1.0
) = 900.0;

uniform float chromatic_offset_px : hint_range(
	0.0,
	8.0,
	0.01
) = 0.12;


// === vhs signal distortion ===

uniform float vhs_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.0;

uniform float vhs_color_offset_px : hint_range(
	-16.0,
	16.0,
	0.1
) = 2.0;

uniform float vhs_color_wiggle_px : hint_range(
	0.0,
	24.0,
	0.1
) = 4.0;

uniform float vhs_luma_wiggle_px : hint_range(
	0.0,
	12.0,
	0.1
) = 0.8;

uniform float vhs_color_blur_px : hint_range(
	0.0,
	12.0,
	0.1
) = 1.5;

uniform float vhs_line_density : hint_range(
	1.0,
	1200.0,
	1.0
) = 487.0;

uniform float vhs_noise_fps : hint_range(
	1.0,
	60.0,
	1.0
) = 15.0;


float hash(
	vec2 value
) {
	return fract(
		sin(
			dot(
				value,
				vec2(
					127.1,
					311.7
				)
			)
		)
		* 43758.5453123
	);
}


vec3 rgb_to_hsv(
	vec3 color
) {
	vec4 k = vec4(
		0.0,
		-1.0 / 3.0,
		2.0 / 3.0,
		-1.0
	);

	vec4 p = mix(
		vec4(
			color.bg,
			k.wz
		),
		vec4(
			color.gb,
			k.xy
		),
		step(
			color.b,
			color.g
		)
	);

	vec4 q = mix(
		vec4(
			p.xyw,
			color.r
		),
		vec4(
			color.r,
			p.yzx
		),
		step(
			p.x,
			color.r
		)
	);

	float delta = q.x - min(
		q.w,
		q.y
	);

	float epsilon = 0.000001;

	return vec3(
		abs(
			q.z
			+ (
				q.w
				- q.y
			)
			/ (
				6.0
				* delta
				+ epsilon
			)
		),
		delta / (
			q.x
			+ epsilon
		),
		q.x
	);
}


vec3 hsv_to_rgb(
	vec3 color
) {
	vec3 rgb_wave = abs(
		fract(
			color.xxx
			+ vec3(
				0.0,
				2.0 / 3.0,
				1.0 / 3.0
			)
		)
		* 6.0
		- 3.0
	);

	return color.z * mix(
		vec3(1.0),
		clamp(
			rgb_wave
			- vec3(1.0),
			0.0,
			1.0
		),
		color.y
	);
}


vec3 apply_hue_shift(
	vec3 color
) {
	if (
		abs(
			hue_shift_degrees
		) <= 0.001
	) {
		return color;
	}

	vec3 hsv = rgb_to_hsv(
		max(
			color,
			vec3(0.0)
		)
	);

	hsv.x = fract(
		hsv.x
		+ (
			hue_shift_degrees
			/ 360.0
			* effect_intensity
		)
	);

	return hsv_to_rgb(
		hsv
	);
}


vec2 get_bulged_screen_uv(
	vec2 uv
) {
	vec2 centered_uv = (
		uv
		- vec2(0.5)
	);

	float horizontal_side_weight = (
		1.0
		- pow(
			abs(
				centered_uv.y
			)
			* 2.0,
			2.0
		)
	);

	float vertical_side_weight = (
		1.0
		- pow(
			abs(
				centered_uv.x
			)
			* 2.0,
			2.0
		)
	);

	vec2 side_pinch = vec2(
		centered_uv.x
		* horizontal_side_weight,

		centered_uv.y
		* vertical_side_weight
	);

	return (
		uv
		+ side_pinch
		* side_pinch_amount
		* effect_intensity
	);
}


vec2 get_pixelated_uv(
	vec2 uv
) {
	float effective_pixel_size_px = mix(
		1.0,
		pixel_size_px,
		effect_intensity
	);

	vec2 pixel_size_uv = (
		ui_texture_pixel_size
		* max(
			effective_pixel_size_px,
			1.0
		)
	);

	return (
		floor(
			uv
			/ pixel_size_uv
		)
		+ vec2(0.5)
	)
	* pixel_size_uv;
}


vec4 sample_ui(
	vec2 uv
) {
	if (
		uv.x < 0.0
		|| uv.x > 1.0
		|| uv.y < 0.0
		|| uv.y > 1.0
	) {
		return vec4(0.0);
	}

	return texture(
		ui_texture,
		uv
	);
}


float get_vhs_line_noise(
	float uv_y,
	float seed
) {
	float line_index = floor(
		uv_y
		* vhs_line_density
	);

	float frame_index = floor(
		TIME
		* vhs_noise_fps
	);

	return (
		hash(
			vec2(
				line_index,
				frame_index
				+ seed
			)
		)
		* 2.0
		- 1.0
	);
}


vec3 rgb_to_yuv(
	vec3 rgb
) {
	return vec3(
		dot(
			rgb,
			vec3(
				0.299,
				0.587,
				0.114
			)
		),

		dot(
			rgb,
			vec3(
				-0.14713,
				-0.28886,
				0.436
			)
		),

		dot(
			rgb,
			vec3(
				0.615,
				-0.51499,
				-0.10001
			)
		)
	);
}


vec3 yuv_to_rgb(
	vec3 yuv
) {
	return max(
		vec3(
			yuv.x
			+ 1.13983
			* yuv.z,

			yuv.x
			- 0.39465
			* yuv.y
			- 0.58060
			* yuv.z,

			yuv.x
			+ 2.03211
			* yuv.y
		),
		vec3(0.0)
	);
}


vec4 sample_vhs_ui(
	vec2 uv
) {
	if (
		vhs_strength <= 0.0
	) {
		return sample_ui(
			uv
		);
	}

	float luma_noise = get_vhs_line_noise(
		uv.y,
		13.0
	);

	float color_noise = get_vhs_line_noise(
		uv.y,
		69.420
	);

	float luma_offset_px = (
		luma_noise
		* vhs_luma_wiggle_px
	);

	float color_offset_px = (
		vhs_color_offset_px
		+ color_noise
		* vhs_color_wiggle_px
	);

	vec2 luma_uv = (
		uv
		+ vec2(
			luma_offset_px
			* ui_texture_pixel_size.x,
			0.0
		)
	);

	vec2 color_uv = (
		uv
		+ vec2(
			color_offset_px
			* ui_texture_pixel_size.x,
			0.0
		)
	);

	vec4 luma_sample = sample_ui(
		luma_uv
	);

	vec4 color_center = sample_ui(
		color_uv
	);

	vec4 color_sample = color_center;

	if (
		vhs_color_blur_px > 0.0
	) {
		vec2 blur_offset = vec2(
			vhs_color_blur_px
			* ui_texture_pixel_size.x,
			0.0
		);

		vec4 color_left = sample_ui(
			color_uv
			- blur_offset
		);

		vec4 color_right = sample_ui(
			color_uv
			+ blur_offset
		);

		color_sample = (
			color_center
			* 0.50
			+ color_left
			* 0.25
			+ color_right
			* 0.25
		);
	}

	vec3 luma_yuv = rgb_to_yuv(
		luma_sample.rgb
	);

	vec3 color_yuv = rgb_to_yuv(
		color_sample.rgb
	);

	vec3 vhs_rgb = yuv_to_rgb(
		vec3(
			luma_yuv.x,
			color_yuv.y,
			color_yuv.z
		)
	);

	vec4 vhs_sample = vec4(
		vhs_rgb,
		luma_sample.a
	);

	return mix(
		luma_sample,
		vhs_sample,
		vhs_strength
		* effect_intensity
	);
}


void fragment() {
	vec2 warped_uv = get_bulged_screen_uv(
		UV
	);

	vec2 pixelated_uv = get_pixelated_uv(
		warped_uv
	);

	vec4 source = sample_vhs_ui(
		pixelated_uv
	);

	vec2 chromatic_offset_uv = (
		vec2(
			chromatic_offset_px,
			0.0
		)
		* ui_texture_pixel_size
	);

	vec3 source_rgb = source.rgb;

	if (
		source.a > 0.0001
		&& chromatic_offset_px > 0.0
	) {
		float red = sample_vhs_ui(
			pixelated_uv
			- chromatic_offset_uv
		).r;

		float green = source.g;

		float blue = sample_vhs_ui(
			pixelated_uv
			+ chromatic_offset_uv
		).b;

		source_rgb = vec3(
			red,
			green,
			blue
		);
	}

	float scanline = (
		sin(
			FRAGCOORD.y
			* scanline_density
			* 0.01
		)
		* 0.5
		+ 0.5
	);

	float scanline_multiplier = mix(
		1.0,
		0.58
		+ scanline
		* 0.42,
		scanline_strength
	);

	float grille = (
		sin(
			FRAGCOORD.x
			* grille_density
			* 0.01
		)
		* 0.5
		+ 0.5
	);

	float grille_multiplier = mix(
		1.0,
		0.75
		+ grille
		* 0.25,
		grille_strength
	);

	float flicker = (
		sin(
			TIME
			* flicker_speed
		)
		* 0.5
		+ 0.5
	);

	float flicker_multiplier = mix(
		1.0,
		0.96
		+ flicker
		* 0.04,
		flicker_strength
	);

	float noise = (
		hash(
			floor(
				FRAGCOORD.xy
				* noise_density
				* 0.001
			)
			+ fract(TIME)
		)
		- 0.5
	);

	vec3 crt_color = (
		source_rgb
		* scanline_multiplier
		* grille_multiplier
		* flicker_multiplier
	);

	crt_color += (
		noise
		* noise_strength
		* source.a
	);

	vec2 bloom_offset = (
		ui_texture_pixel_size
		* bloom_radius_px
	);

	vec4 bloom_left = sample_ui(
		pixelated_uv
		- vec2(
			bloom_offset.x,
			0.0
		)
	);

	vec4 bloom_right = sample_ui(
		pixelated_uv
		+ vec2(
			bloom_offset.x,
			0.0
		)
	);

	vec4 bloom_up = sample_ui(
		pixelated_uv
		- vec2(
			0.0,
			bloom_offset.y
		)
	);

	vec4 bloom_down = sample_ui(
		pixelated_uv
		+ vec2(
			0.0,
			bloom_offset.y
		)
	);

	vec4 bloom_up_left = sample_ui(
		pixelated_uv
		- bloom_offset
	);

	vec4 bloom_up_right = sample_ui(
		pixelated_uv
		+ vec2(
			bloom_offset.x,
			-bloom_offset.y
		)
	);

	vec4 bloom_down_left = sample_ui(
		pixelated_uv
		+ vec2(
			-bloom_offset.x,
			bloom_offset.y
		)
	);

	vec4 bloom_down_right = sample_ui(
		pixelated_uv
		+ bloom_offset
	);

	vec4 bloom_sample = (
		bloom_left
		* 0.12
		+ bloom_right
		* 0.12
		+ bloom_up
		* 0.12
		+ bloom_down
		* 0.12
		+ bloom_up_left
		* 0.10
		+ bloom_up_right
		* 0.10
		+ bloom_down_left
		* 0.10
		+ bloom_down_right
		* 0.10
	);

	float outer_bloom_alpha = max(
		bloom_sample.a
		- source.a,
		0.0
	);

	outer_bloom_alpha *= (
		bloom_strength
		* bloom_alpha
		* effect_intensity
	);

	vec3 bloom_color = (
		bloom_sample.rgb
		* bloom_strength
		* bloom_alpha
		* effect_intensity
	);

	vec3 final_color = (
		crt_color
		+ bloom_color
	);

	final_color = apply_hue_shift(
		final_color
	);

	float output_alpha = max(
		source.a,
		outer_bloom_alpha
	);

	COLOR = vec4(
		final_color,
		output_alpha
	);
}
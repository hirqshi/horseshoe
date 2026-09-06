shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D color_palette : source_color, filter_nearest, repeat_disable;

// === master ===

uniform float effect_intensity : hint_range(0.0, 1.0, 0.01) = 1.0;

// === pixelization ===

uniform bool pixelization_enabled = true;
uniform float pixel_size_px : hint_range(1.0, 32.0, 1.0) = 4.0;

// === edge chromatic aberration ===

uniform float chromatic_aberration_px : hint_range(0.0, 16.0, 0.01) = 0.0;
uniform float chromatic_edge_start : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float chromatic_edge_end : hint_range(0.01, 1.5, 0.01) = 0.95;
uniform float chromatic_edge_power : hint_range(0.1, 8.0, 0.01) = 2.40;

// === sharpness ===

uniform float sharpness : hint_range(0.0, 3.0, 0.01) = 0.25;

// === palette and posterization ===

uniform bool palette_enabled = false;

uniform float palette_strength_dark : hint_range(0.0, 1.0, 0.01) = 0.90;
uniform float palette_strength_light : hint_range(0.0, 1.0, 0.01) = 0.20;

uniform int dark_levels : hint_range(2, 12, 1) = 3;
uniform int light_levels : hint_range(2, 64, 1) = 8;

uniform float darkness_threshold : hint_range(0.1, 0.9, 0.01) = 0.30;
uniform float posterization_dither_amount : hint_range(0.0, 0.1, 0.001) = 0.02;

// === bayer dithering ===

uniform bool bayer_dithering_enabled = true;
uniform float bayer_dither_strength : hint_range(0.0, 1.0, 0.01) = 0.10;
uniform float bayer_dither_gamma : hint_range(1.0, 3.0, 0.01) = 1.87;

// === glitch ===

uniform float glitch_intensity : hint_range(0.0, 1.0, 0.01) = 0.0;

// === vhs signal distortion ===

// 0.0 disables VHS
uniform float vhs_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.0;

// constant horizontal shift of color information
uniform float vhs_color_offset_px : hint_range(
	-16.0,
	16.0,
	0.1
) = 2.0;

// per-line random horizontal displacement of color
uniform float vhs_color_wiggle_px : hint_range(
	0.0,
	24.0,
	0.1
) = 4.0;

// weaker random displacement of brightness
uniform float vhs_luma_wiggle_px : hint_range(
	0.0,
	12.0,
	0.1
) = 0.8;

// horizontal color smearing
uniform float vhs_color_blur_px : hint_range(
	0.0,
	12.0,
	0.1
) = 1.5;

// amount of independently distorted horizontal lines
uniform float vhs_line_density : hint_range(
	1.0,
	1200.0,
	1.0
) = 487.0;

// how frequently line offsets change
uniform float vhs_noise_fps : hint_range(
	1.0,
	60.0,
	1.0
) = 15.0;

// === crt ===

uniform float brightness : hint_range(0.0, 3.0, 0.01) = 1.02;

uniform float scanline_strength : hint_range(0.0, 1.0, 0.01) = 0.12;
uniform float scanline_density : hint_range(1.0, 2000.0, 1.0) = 520.0;
uniform float scanline_width : hint_range(0.01, 1.0, 0.01) = 0.32;

uniform float grille_strength : hint_range(0.0, 1.0, 0.01) = 0.06;
uniform float grille_density : hint_range(1.0, 2000.0, 1.0) = 640.0;

uniform float static_noise_strength : hint_range(0.0, 0.5, 0.001) = 0.015;
uniform float grain_strength : hint_range(0.0, 0.2, 0.001) = 0.010;

// === discoloration ===

uniform float discoloration_strength : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float discoloration_contrast : hint_range(0.5, 2.0, 0.01) = 1.12;

// === vignette ===

uniform float vignette_intensity : hint_range(0.0, 1.0, 0.01) = 0.08;
uniform float vignette_smoothness : hint_range(0.1, 2.0, 0.01) = 0.60;

// === final ===

uniform float final_gamma : hint_range(0.5, 2.0, 0.01) = 1.05;

const mat4 BAYER_MATRIX = mat4(
	vec4(0.0 / 16.0, 8.0 / 16.0, 2.0 / 16.0, 10.0 / 16.0),
	vec4(12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0, 6.0 / 16.0),
	vec4(3.0 / 16.0, 11.0 / 16.0, 1.0 / 16.0, 9.0 / 16.0),
	vec4(15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0, 5.0 / 16.0)
);

float hash(vec2 value) {
	return fract(
		sin(
			dot(
				value,
				vec2(12.9898, 78.233)
			)
		)
		* 43758.5453
	);
}

float crt_random(vec2 uv) {
	return fract(
		cos(
			uv.x * 83.4827
			+ uv.y * 92.2842
		)
		* 43758.5453123
	);
}

float get_luminance(vec3 color) {
	return dot(
		color,
		vec3(0.299, 0.587, 0.114)
	);
}

vec2 get_screen_texel_size() {
	ivec2 screen_size = textureSize(
		screen_texture,
		0
	);

	return 1.0 / vec2(
		max(
			screen_size,
			ivec2(1)
		)
	);
}

vec2 get_pixelized_uv(vec2 uv) {
	if (!pixelization_enabled) {
		return uv;
	}

	vec2 screen_texel_size = get_screen_texel_size();

	vec2 pixel_uv_size = (
		screen_texel_size
		* pixel_size_px
	);

	return (
		floor(
			uv / pixel_uv_size
		)
		* pixel_uv_size
		+ pixel_uv_size * 0.5
	);
}

vec2 get_effect_texel_size() {
	vec2 screen_texel_size = get_screen_texel_size();

	if (!pixelization_enabled) {
		return screen_texel_size;
	}

	return (
		screen_texel_size
		* pixel_size_px
	);
}

vec2 get_glitch_offset(vec2 uv) {
	if (glitch_intensity <= 0.0) {
		return vec2(0.0);
	}

	float block = floor(
		uv.y * 22.0
		+ TIME * 10.0
	);

	float block_noise = hash(
		vec2(
			block,
			floor(TIME * 12.0)
		)
	);

	float is_glitching = step(
		0.965,
		block_noise
	);

	float offset = (
		(block_noise - 0.5)
		* 0.035
		* glitch_intensity
		* is_glitching
	);

	return vec2(offset, 0.0);
}

float get_chromatic_edge_mask(vec2 uv) {
	vec2 centered_uv = uv - vec2(0.5);

	vec2 screen_texel_size = get_screen_texel_size();

	centered_uv.x *= (
		screen_texel_size.y
		/ screen_texel_size.x
	);

	float distance_from_center = length(
		centered_uv
	);

	float edge_mask = smoothstep(
		chromatic_edge_start,
		chromatic_edge_end,
		distance_from_center
	);

	return pow(
		edge_mask,
		chromatic_edge_power
	);
}

vec3 sample_chromatic(vec2 uv) {
	if (chromatic_aberration_px <= 0.0) {
		return texture(
			screen_texture,
			uv
		).rgb;
	}

	float edge_mask = get_chromatic_edge_mask(uv);

	vec2 effect_texel_size = get_effect_texel_size();

	vec2 chromatic_offset = (
		vec2(
			chromatic_aberration_px,
			0.0
		)
		* effect_texel_size
		* edge_mask
		* effect_intensity
	);

	float red = texture(
		screen_texture,
		uv + chromatic_offset
	).r;

	float green = texture(
		screen_texture,
		uv
	).g;

	float blue = texture(
		screen_texture,
		uv - chromatic_offset
	).b;

	return vec3(
		red,
		green,
		blue
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


vec3 sample_vhs_chromatic(
	vec2 uv
) {
	if (
		vhs_strength <= 0.0
	) {
		return sample_chromatic(
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

	vec2 effect_texel_size = get_effect_texel_size();

	vec2 luma_uv = clamp(
		uv
		+ vec2(
			luma_offset_px
			* effect_texel_size.x,
			0.0
		),
		vec2(0.0),
		vec2(1.0)
	);

	vec2 color_uv = clamp(
		uv
		+ vec2(
			color_offset_px
			* effect_texel_size.x,
			0.0
		),
		vec2(0.0),
		vec2(1.0)
	);

	vec3 luma_color = sample_chromatic(
		luma_uv
	);

	vec3 color_center = sample_chromatic(
		color_uv
	);

	vec3 color_signal = color_center;

	if (
		vhs_color_blur_px > 0.0
	) {
		vec2 blur_offset = vec2(
			vhs_color_blur_px
			* effect_texel_size.x,
			0.0
		);

		vec3 color_left = sample_chromatic(
			clamp(
				color_uv
				- blur_offset,
				vec2(0.0),
				vec2(1.0)
			)
		);

		vec3 color_right = sample_chromatic(
			clamp(
				color_uv
				+ blur_offset,
				vec2(0.0),
				vec2(1.0)
			)
		);

		color_signal = (
			color_center
			* 0.50
			+ color_left
			* 0.25
			+ color_right
			* 0.25
		);
	}

	vec3 luma_yuv = rgb_to_yuv(
		luma_color
	);

	vec3 color_yuv = rgb_to_yuv(
		color_signal
	);

	vec3 vhs_color = yuv_to_rgb(
		vec3(
			luma_yuv.x,
			color_yuv.y,
			color_yuv.z
		)
	);

	return mix(
		luma_color,
		vhs_color,
		vhs_strength
		* effect_intensity
	);
}

vec3 apply_sharpen(
	vec2 uv,
	vec3 center_color
) {
	if (sharpness <= 0.0) {
		return center_color;
	}

	vec2 texel_offset = get_effect_texel_size();

	vec3 left = texture(
		screen_texture,
		uv - vec2(texel_offset.x, 0.0)
	).rgb;

	vec3 right = texture(
		screen_texture,
		uv + vec2(texel_offset.x, 0.0)
	).rgb;

	vec3 up = texture(
		screen_texture,
		uv - vec2(0.0, texel_offset.y)
	).rgb;

	vec3 down = texture(
		screen_texture,
		uv + vec2(0.0, texel_offset.y)
	).rgb;

	vec3 blurred = (
		left
		+ right
		+ up
		+ down
	)
	* 0.25;

	return max(
		center_color
		+ (
			center_color
			- blurred
		)
		* sharpness,
		vec3(0.0)
	);
}

vec3 apply_posterization(
	vec3 color,
	vec2 uv
) {
	float luminance = get_luminance(color);

	float lightness_blend = smoothstep(
		darkness_threshold * 0.5,
		darkness_threshold * 1.5,
		luminance
	);

	int levels = int(
		mix(
			float(dark_levels),
			float(light_levels),
			lightness_blend
		)
	);

	vec2 pixel_uv_size = get_effect_texel_size();

	float dither = (
		hash(
			floor(
				uv / pixel_uv_size
			)
		)
		* 2.0
		- 1.0
	)
	* posterization_dither_amount;

	vec3 posterized = floor(
		color * float(levels)
		+ dither
	)
	/ float(levels);

	float posterization_strength = smoothstep(
		0.3,
		0.7,
		luminance
	);

	return mix(
		color,
		posterized,
		posterization_strength
	);
}

vec3 apply_palette(vec3 color) {
	float luminance = get_luminance(color);

	float palette_influence = mix(
		palette_strength_dark,
		palette_strength_light,
		smoothstep(
			darkness_threshold * 0.8,
			darkness_threshold * 1.2,
			luminance
		)
	);

	vec3 palette_color = texture(
		color_palette,
		vec2(luminance, 0.5)
	).rgb;

	return mix(
		color,
		palette_color,
		palette_influence
		* (1.0 - luminance)
	);
}

vec3 apply_bayer_dither(
	vec3 color,
	vec2 uv
) {
	if (!bayer_dithering_enabled) {
		return color;
	}

	vec2 bayer_pixel_size = get_effect_texel_size();

	ivec2 pixel_coordinate = ivec2(
		floor(
			uv / bayer_pixel_size
		)
	);

	int x = pixel_coordinate.x % 4;
	int y = pixel_coordinate.y % 4;

	float threshold = BAYER_MATRIX[x][y];

	vec3 corrected_color = (
		pow(
			max(
				color,
				vec3(0.0)
			),
			vec3(bayer_dither_gamma)
		)
		- vec3(0.004)
	);

	vec3 dithered = vec3(
		step(threshold, corrected_color.r),
		step(threshold, corrected_color.g),
		step(threshold, corrected_color.b)
	);

	return mix(
		color,
		dithered,
		bayer_dither_strength
	);
}

vec3 apply_crt(
	vec3 color,
	vec2 screen_uv,
	vec2 pixelized_uv
) {
	float scan_wave = abs(
		sin(
			screen_uv.y
			* scanline_density
			* 3.14159265
		)
	);

	float scanline = smoothstep(
		scanline_width,
		1.0,
		scan_wave
	);

	color *= mix(
		1.0,
		scanline,
		scanline_strength
	);

	float grille_red = smoothstep(
		0.80,
		0.98,
		abs(
			sin(
				screen_uv.x
				* grille_density
				* 3.14159265
			)
		)
	);

	float grille_green = smoothstep(
		0.80,
		0.98,
		abs(
			sin(
				1.04719755
				+ screen_uv.x
				* grille_density
				* 3.14159265
			)
		)
	);

	float grille_blue = smoothstep(
		0.80,
		0.98,
		abs(
			sin(
				2.09439510
				+ screen_uv.x
				* grille_density
				* 3.14159265
			)
		)
	);

	vec3 grille = vec3(
		grille_red,
		grille_green,
		grille_blue
	);

	color *= mix(
		vec3(1.0),
		grille,
		grille_strength
	);

	vec2 pixel_uv_size = get_effect_texel_size();

	vec2 static_noise_uv = (
		floor(
			pixelized_uv / pixel_uv_size
		)
		* pixel_uv_size
	);

	float static_noise = (
		crt_random(
			static_noise_uv
			+ fract(TIME)
		)
		* static_noise_strength
	);

	color += static_noise;

	vec2 screen_texel_size = get_screen_texel_size();

	float grain = (
		hash(
			floor(
				screen_uv
				/ screen_texel_size
			)
			+ vec2(
				floor(TIME * 12.0)
			)
		)
		- 0.5
	)
	* grain_strength;

	color += grain;

	return color * brightness;
}

vec3 apply_discoloration(vec3 color) {
	if (discoloration_strength <= 0.0) {
		return color;
	}

	vec3 grayscale = vec3(
		dot(
			color,
			vec3(0.33333333)
		)
	);

	vec3 discolored = mix(
		color,
		grayscale,
		0.5
	);

	vec3 midpoint = vec3(
		pow(0.5, 2.2)
	);

	discolored = (
		discolored
		- midpoint
	)
	* discoloration_contrast
	+ midpoint;

	return mix(
		color,
		discolored,
		discoloration_strength
	);
}

float get_vignette(vec2 uv) {
	vec2 vignette_uv = uv * 2.0 - 1.0;

	float vignette = (
		1.0
		- dot(
			vignette_uv,
			vignette_uv
		)
	);

	vignette = smoothstep(
		0.0,
		vignette_smoothness,
		vignette
	);

	return mix(
		1.0,
		vignette,
		vignette_intensity
	);
}

void fragment() {
	vec2 screen_uv = SCREEN_UV;

	screen_uv += get_glitch_offset(screen_uv);

	screen_uv = clamp(
		screen_uv,
		vec2(0.0),
		vec2(1.0)
	);

	vec2 pixelized_uv = get_pixelized_uv(
		screen_uv
	);

	vec3 color = sample_vhs_chromatic(
		pixelized_uv
	);

	color = apply_sharpen(
		pixelized_uv,
		color
	);

	if (palette_enabled) {
		color = apply_posterization(
			color,
			pixelized_uv
		);

		color = apply_palette(color);
	}

	color = apply_bayer_dither(
		color,
		pixelized_uv
	);

	color = apply_crt(
		color,
		screen_uv,
		pixelized_uv
	);

	color = apply_discoloration(color);

	color *= get_vignette(screen_uv);

	color = pow(
		max(
			color,
			vec3(0.0)
		),
		vec3(final_gamma)
	);

	color = clamp(
		color,
		vec3(0.0),
		vec3(1.0)
	);

	COLOR = vec4(
		color,
		1.0
	);
}
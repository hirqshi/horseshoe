shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform sampler2D ui_texture : filter_linear, repeat_disable;

// === master ===

uniform float effect_intensity : hint_range(0.0, 1.0, 0.01) = 1.0;

// === convex ui projection ===

// negative values pull edges inward and make the center feel closer
uniform float side_pinch_amount : hint_range(0.0, 1.0, 0.01) = 0.50;
// === outer bloom ===

uniform float bloom_strength : hint_range(0.0, 3.0, 0.01) = 0.45;
uniform float bloom_radius_px : hint_range(0.0, 32.0, 0.1) = 3.0;
uniform float bloom_alpha : hint_range(0.0, 1.0, 0.01) = 0.45;

// === crt scanlines ===

uniform float scanline_strength : hint_range(0.0, 1.0, 0.01) = 0.10;
uniform float scanline_density : hint_range(1.0, 2000.0, 1.0) = 520.0;

uniform float grille_strength : hint_range(0.0, 1.0, 0.01) = 0.03;
uniform float grille_density : hint_range(1.0, 2000.0, 1.0) = 360.0;

uniform float flicker_strength : hint_range(0.0, 1.0, 0.01) = 0.01;
uniform float flicker_speed : hint_range(0.0, 60.0, 0.1) = 15.0;

uniform float noise_strength : hint_range(0.0, 1.0, 0.01) = 0.008;
uniform float noise_density : hint_range(1.0, 4000.0, 1.0) = 900.0;

uniform float chromatic_offset_px : hint_range(0.0, 8.0, 0.01) = 0.12;
uniform float brightness : hint_range(0.0, 3.0, 0.01) = 1.03;

float hash(vec2 value) {
	return fract(
		sin(
			dot(
				value,
				vec2(127.1, 311.7)
			)
		)
		* 43758.5453123
	);
}

vec2 get_bulged_screen_uv(vec2 uv) {
	vec2 centered_uv = uv - vec2(0.5);

	float horizontal_side_weight = (
		1.0
		- pow(
			abs(centered_uv.y) * 2.0,
			2.0
		)
	);

	float vertical_side_weight = (
		1.0
		- pow(
			abs(centered_uv.x) * 2.0,
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

vec4 sample_ui(vec2 uv) {
	if (
		uv.x < 0.0
		|| uv.x > 1.0
		|| uv.y < 0.0
		|| uv.y > 1.0
	) {
		return vec4(0.0);
	}

	return texture(ui_texture, uv);
}

void fragment() {
	vec2 warped_uv = get_bulged_screen_uv(UV);

	vec4 source = sample_ui(warped_uv);

	vec2 chromatic_offset_uv = (
		vec2(chromatic_offset_px, 0.0)
		* TEXTURE_PIXEL_SIZE
	);

	vec3 source_rgb = source.rgb;

	if (
		source.a > 0.0001
		&& chromatic_offset_px > 0.0
	) {
		float red = sample_ui(
			warped_uv - chromatic_offset_uv
		).r;

		float green = source.g;

		float blue = sample_ui(
			warped_uv + chromatic_offset_uv
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
		0.58 + scanline * 0.42,
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
		0.75 + grille * 0.25,
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
		0.96 + flicker * 0.04,
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

	crt_color *= brightness;

	vec2 bloom_offset = (
		TEXTURE_PIXEL_SIZE
		* bloom_radius_px
	);

	vec4 bloom_left = sample_ui(
		warped_uv - vec2(bloom_offset.x, 0.0)
	);

	vec4 bloom_right = sample_ui(
		warped_uv + vec2(bloom_offset.x, 0.0)
	);

	vec4 bloom_up = sample_ui(
		warped_uv - vec2(0.0, bloom_offset.y)
	);

	vec4 bloom_down = sample_ui(
		warped_uv + vec2(0.0, bloom_offset.y)
	);

	vec4 bloom_up_left = sample_ui(
		warped_uv - bloom_offset
	);

	vec4 bloom_up_right = sample_ui(
		warped_uv
		+ vec2(
			bloom_offset.x,
			-bloom_offset.y
		)
	);

	vec4 bloom_down_left = sample_ui(
		warped_uv
		+ vec2(
			-bloom_offset.x,
			bloom_offset.y
		)
	);

	vec4 bloom_down_right = sample_ui(
		warped_uv + bloom_offset
	);

	vec4 bloom_sample = (
		bloom_left * 0.12
		+ bloom_right * 0.12
		+ bloom_up * 0.12
		+ bloom_down * 0.12
		+ bloom_up_left * 0.10
		+ bloom_up_right * 0.10
		+ bloom_down_left * 0.10
		+ bloom_down_right * 0.10
	);

	float outer_bloom_alpha = max(
		bloom_sample.a - source.a,
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
		* effect_intensity
	);

	vec3 final_color = (
		crt_color
		+ bloom_color
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
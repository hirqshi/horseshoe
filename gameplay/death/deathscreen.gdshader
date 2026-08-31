shader_type canvas_item;

uniform float animation_speed : hint_range(
	0.0,
	5.0,
	0.01
) = 1.0;

uniform vec4 color_low : source_color = vec4(
	0.01,
	0.41,
	0.51,
	1.0
);

uniform vec4 color_mid_red : source_color = vec4(
	0.5,
	0.1,
	0.3,
	1.0
);

uniform vec4 color_high : source_color = vec4(
	1.0,
	1.0,
	1.0,
	1.0
);

group_uniforms Reveal;

uniform float reveal_progress : hint_range(
	0.0,
	1.1,
	0.001
) = 0.0;

uniform float reveal_softness : hint_range(
	0.001,
	0.5,
	0.001
) = 0.06;

uniform bool use_reveal_texture = false;

uniform sampler2D reveal_texture : repeat_enable;

uniform float reveal_texture_scale : hint_range(
	0.1,
	16.0,
	0.01
) = 1.0;

uniform float reveal_noise_scale : hint_range(
	0.1,
	16.0,
	0.01
) = 2.2;

uniform float reveal_noise_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.6;

uniform vec2 reveal_origin = vec2(
	0.5,
	0.5
);

uniform float radial_reveal_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.35;


const mat2 ROTATION_MATRIX = mat2(
	vec2(0.8, -0.6),
	vec2(0.6, 0.8)
);


float random(vec2 value) {
	return fract(
		sin(
			dot(
				value,
				vec2(
					12.9898,
					4.1414
				)
			)
		)
		* 43758.5453
	);
}


float noise(vec2 position) {
	vec2 integer_position = floor(position);
	vec2 fractional_position = fract(position);

	fractional_position = fractional_position
		* fractional_position
		* (
			3.0
			- 2.0 * fractional_position
		);

	float bottom = mix(
		random(integer_position),
		random(
			integer_position
			+ vec2(1.0, 0.0)
		),
		fractional_position.x
	);

	float top = mix(
		random(
			integer_position
			+ vec2(0.0, 1.0)
		),
		random(
			integer_position
			+ vec2(1.0, 1.0)
		),
		fractional_position.x
	);

	float result = mix(
		bottom,
		top,
		fractional_position.y
	);

	return result * result;
}


float fbm(vec2 position) {
	float time = TIME * animation_speed;
	float value = 0.0;

	value += 0.5 * noise(
		position + time
	);

	position = ROTATION_MATRIX * position * 2.02;

	value += 0.03125 * noise(position);

	position = ROTATION_MATRIX * position * 2.01;

	value += 0.25 * noise(position);

	position = ROTATION_MATRIX * position * 2.03;

	value += 0.125 * noise(position);

	position = ROTATION_MATRIX * position * 2.01;

	value += 0.0625 * noise(position);

	position = ROTATION_MATRIX * position * 2.04;

	value += 0.015625 * noise(
		position
		+ sin(time)
	);

	return value / 0.96875;
}


float pattern(vec2 position) {
	return fbm(
		position
		+ fbm(
			position
			+ fbm(position)
		)
	);
}


vec4 get_death_color(float value) {
	if (value < 0.24) {
		return mix(
			color_low,
			color_mid_red,
			value / 0.24
		);
	}

	return mix(
		color_mid_red,
		color_high,
		(value - 0.24) / 0.76
	);
}


float get_reveal_mask(vec2 uv) {
	if (use_reveal_texture) {
		return texture(
			reveal_texture,
			uv * reveal_texture_scale
		).r;
	}

	return pattern(
		uv * reveal_noise_scale
	);
}


float get_radial_mask(vec2 uv) {
	vec2 centered_uv = uv - reveal_origin;

	return clamp(
		length(centered_uv) / 0.72,
		0.0,
		1.0
	);
}


void fragment() {
	float animation_time = TIME * animation_speed;

	vec2 pattern_uv = UV * vec2(
		1.0,
		SCREEN_PIXEL_SIZE.y
		/ SCREEN_PIXEL_SIZE.x
	);

	float shade = pattern(
		pattern_uv
		+ vec2(
			animation_time * 0.03,
			-animation_time * 0.02
		)
	);

	vec4 death_color = get_death_color(shade);

	float noise_mask = get_reveal_mask(UV);

	float radial_mask = get_radial_mask(UV);

	float noisy_radial_mask = clamp(
		radial_mask
		+ (
			noise_mask
			- 0.5
		)
		* reveal_noise_strength,
		0.0,
		1.0
	);

	float reveal_mask = mix(
		noise_mask,
		noisy_radial_mask,
		radial_reveal_strength
	);

	reveal_mask = mix(
		0.12,
		1.0,
		reveal_mask
	);

	float cover_amount = smoothstep(
		reveal_progress - reveal_softness,
		reveal_progress + reveal_softness,
		reveal_mask
	);

	death_color.a = cover_amount;

	COLOR = death_color;
}
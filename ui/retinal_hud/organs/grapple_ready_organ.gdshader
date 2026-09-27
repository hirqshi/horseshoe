shader_type canvas_item;
render_mode blend_mix;

uniform bool preview_enabled = true;
uniform float preview_ready_amount = 1.0;
uniform float preview_pulse_amount = 0.06;

uniform float ready_amount = 0.0;
uniform float pulse_amount = 0.0;

uniform vec4 inner_color : source_color = vec4(0.22, 0.92, 0.80, 1.0);
uniform vec4 outer_color : source_color = vec4(0.58, 0.18, 1.00, 1.0);
uniform vec4 outline_color : source_color = vec4(1.00, 0.56, 0.16, 1.0);

uniform float arc_radius = 0.35;
uniform float arc_width = 0.035;
uniform float arc_softness = 0.028;
uniform float noise_scale = 10.0;
uniform float edge_noise_strength = 0.025;
uniform float outline_width = 0.050;
uniform float opacity = 0.86;

float hash21(vec2 value) {
	value = fract(value * vec2(123.34, 456.21));
	value += dot(value, value + 45.32);
	return fract(value.x * value.y);
}

float value_noise_tiled(vec2 value, vec2 period) {
	vec2 cell = floor(value);
	vec2 local = fract(value);
	local = local * local * (3.0 - 2.0 * local);

	vec2 cell_00 = mod(cell, period);
	vec2 cell_10 = mod(cell + vec2(1.0, 0.0), period);
	vec2 cell_01 = mod(cell + vec2(0.0, 1.0), period);
	vec2 cell_11 = mod(cell + vec2(1.0, 1.0), period);

	float bottom = mix(hash21(cell_00), hash21(cell_10), local.x);
	float top = mix(hash21(cell_01), hash21(cell_11), local.x);
	return mix(bottom, top, local.y);
}

float fbm_tiled(vec2 value, vec2 base_period) {
	float result = 0.0;
	float amplitude = 0.5;
	vec2 period = base_period;

	for (int octave = 0; octave < 3; octave++) {
		result += value_noise_tiled(value, period) * amplitude;
		value *= 2.0;
		period *= 2.0;
		amplitude *= 0.5;
	}

	return result;
}

void fragment() {
	float resolved_ready_amount = ready_amount;
	float resolved_pulse_amount = pulse_amount;

	if (preview_enabled) {
		resolved_ready_amount = preview_ready_amount;
		resolved_pulse_amount = preview_pulse_amount;
	}

	vec2 point = UV * 2.0 - 1.0;
	vec2 arc_center = vec2(0.0, 0.62);
	vec2 from_center = point - arc_center;
	float distance_to_center = length(from_center);

	float noise_value = fbm_tiled(
		UV * noise_scale + vec2(TIME * 0.18, -TIME * 0.12),
		vec2(noise_scale)
	);

	float noisy_radius = (
		arc_radius
		+ (noise_value - 0.5) * edge_noise_strength
		+ resolved_pulse_amount
	);

	float ring_distance = abs(distance_to_center - noisy_radius);

	float outer_arc = 1.0 - smoothstep(
		arc_width,
		arc_width + arc_softness,
		ring_distance
	);

	float inner_arc = 1.0 - smoothstep(
		arc_width * 0.42,
		arc_width * 0.42 + arc_softness,
		ring_distance
	);

	float outline_arc = 1.0 - smoothstep(
		arc_width + outline_width,
		arc_width + outline_width + arc_softness,
		ring_distance
	);

	float upper_half = 1.0 - smoothstep(0.00, 0.16, point.y - arc_center.y);
	float center_reveal = 1.0 - abs(point.x);

	float horizontal_reveal = smoothstep(
		1.0 - resolved_ready_amount,
		1.0,
		center_reveal
	);

	float arc_mask = outer_arc * upper_half * horizontal_reveal;
	float interior_mask = inner_arc * upper_half * horizontal_reveal;

	float outline_mask = max(outline_arc - outer_arc, 0.0);
	outline_mask *= upper_half * horizontal_reveal;

	float color_progress = clamp(
		UV.x + (noise_value - 0.5) * 0.18,
		0.0,
		1.0
	);

	vec3 arc_color = mix(outer_color.rgb, inner_color.rgb, color_progress);

	float sharp_grain = mix(
		0.45,
		1.0,
		smoothstep(
			0.28,
			0.72,
			fbm_tiled(
				UV * (noise_scale * 2.8) + vec2(TIME * 0.22),
				vec2(noise_scale * 2.8)
			)
		)
	);

	vec3 color = vec3(0.0);
	float alpha = 0.0;

	color += arc_color * interior_mask * opacity;
	alpha = max(alpha, interior_mask * opacity);

	color += arc_color * arc_mask * (1.0 - interior_mask) * 0.34;
	alpha = max(alpha, arc_mask * 0.42);

	color += outline_color.rgb * outline_mask * sharp_grain;
	alpha = max(alpha, outline_mask * sharp_grain);

	COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
}
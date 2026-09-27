shader_type canvas_item;
render_mode blend_mix;

uniform bool preview_enabled = true;
uniform float preview_charge_ratio = 0.72;

uniform float charge_ratio = 1.0;

uniform vec4 strand_root_color : source_color = vec4(0.22, 0.90, 0.82, 1.0);
uniform vec4 strand_middle_color : source_color = vec4(0.22, 0.42, 1.00, 1.0);
uniform vec4 strand_tip_color : source_color = vec4(0.72, 0.18, 1.00, 1.0);
uniform vec4 healthy_outline_color : source_color = vec4(0.96, 0.80, 1.00, 1.0);

uniform vec4 danger_inner_color : source_color = vec4(1.00, 0.96, 1.00, 1.0);
uniform vec4 danger_outer_color : source_color = vec4(1.00, 0.10, 0.62, 1.0);
uniform vec4 danger_pulse_color : source_color = vec4(1.00, 0.42, 0.04, 1.0);
uniform vec4 danger_outline_color : source_color = vec4(1.00, 0.76, 0.90, 1.0);

uniform float arc_radius = 0.61;
uniform float helix_turns = 4.4;
uniform float strand_separation = 0.030;
uniform float strand_width = 0.017;
uniform float strand_softness = 0.018;
uniform float rung_width = 0.012;
uniform float rung_softness = 0.014;
uniform float rung_sharpness = 9.0;

uniform float charge_edge_softness = 0.075;
uniform float low_charge_start = 0.46;
uniform float critical_charge_start = 0.20;
uniform float healthy_opacity = 0.82;
uniform float danger_opacity = 0.98;

uniform float pulse_frequency_hz = 2.0;
uniform float pulse_radius_amount = 0.016;
uniform float noise_scale = 16.0;
uniform float outline_noise_scale = 31.0;
uniform float edge_noise_strength = 0.014;
uniform float outline_opacity = 0.92;

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

float band_mask(float distance_to_band, float width, float softness) {
	return 1.0 - smoothstep(width, width + softness, distance_to_band);
}

vec3 three_color_gradient(vec3 root_color, vec3 middle_color, vec3 tip_color, float progress) {
	float first_blend = smoothstep(0.0, 0.55, progress);
	float second_blend = smoothstep(0.36, 1.0, progress);
	vec3 color = mix(root_color, middle_color, first_blend);
	return mix(color, tip_color, second_blend);
}

void fragment() {
	float resolved_charge_ratio = charge_ratio;

	if (preview_enabled) {
		resolved_charge_ratio = preview_charge_ratio;
	}

	vec2 point = UV * 2.0 - 1.0;
	vec2 arc_center = vec2(0.0, -0.34);
	vec2 relative = point - arc_center;

	float radial_distance = length(relative);
	float angle = atan(relative.y, relative.x);
	float lower_half = smoothstep(-0.02, 0.08, relative.y);
	float arc_progress = clamp(angle / PI, 0.0, 1.0);
	float distance_from_bottom = abs(arc_progress - 0.5) * 2.0;

	float charge_mask = 1.0 - smoothstep(
		resolved_charge_ratio,
		resolved_charge_ratio + charge_edge_softness,
		distance_from_bottom
	);

	float danger_ratio = 1.0 - resolved_charge_ratio;
	float low_charge_amount = smoothstep(1.0 - low_charge_start, 1.0, danger_ratio);
	float critical_charge_amount = smoothstep(1.0 - critical_charge_start, 1.0, danger_ratio);

	float pulse = 0.5 + 0.5 * sin(TIME * TAU * pulse_frequency_hz);
	float danger_pulse = pulse * critical_charge_amount;

	float surface_noise = fbm_tiled(
		UV * noise_scale + vec2(TIME * 0.20, -TIME * 0.15),
		vec2(noise_scale)
	);

	float outline_noise = fbm_tiled(
		UV * outline_noise_scale + vec2(-TIME * 0.34, TIME * 0.28),
		vec2(outline_noise_scale)
	);

	float noisy_radius = (
		arc_radius
		+ (surface_noise - 0.5) * edge_noise_strength
		+ danger_pulse * pulse_radius_amount
	);

	float helix_phase = (
		arc_progress * helix_turns * TAU
		- TIME * (0.70 + danger_ratio * 1.15)
	);

	float strand_offset = sin(helix_phase) * strand_separation;
	float strand_a_distance = abs(radial_distance - (noisy_radius + strand_offset));
	float strand_b_distance = abs(radial_distance - (noisy_radius - strand_offset));

	float strand_a_outer = band_mask(
		strand_a_distance,
		strand_width * (1.0 + danger_pulse * 0.55),
		strand_softness
	);

	float strand_b_outer = band_mask(
		strand_b_distance,
		strand_width * (1.0 + danger_pulse * 0.55),
		strand_softness
	);

	float strand_a_inner = band_mask(
		strand_a_distance,
		strand_width * 0.42,
		strand_softness * 0.55
	);

	float strand_b_inner = band_mask(
		strand_b_distance,
		strand_width * 0.42,
		strand_softness * 0.55
	);

	float rung_wave = pow(max(cos(helix_phase), 0.0), rung_sharpness);
	float rung_distance = abs(radial_distance - noisy_radius);
	float rungs = band_mask(rung_distance, rung_width, rung_softness) * rung_wave;

	float outer_helix = max(strand_a_outer, max(strand_b_outer, rungs));
	float inner_helix = max(strand_a_inner, strand_b_inner);

	outer_helix *= lower_half * charge_mask;
	inner_helix *= lower_half * charge_mask;

	float outline = max(outer_helix - inner_helix, 0.0);
	float sharp_outline = outline * smoothstep(
		0.28,
		0.82,
		outline_noise + (outer_helix - 0.5) * 0.45
	);

	vec3 healthy_color = three_color_gradient(
		strand_root_color.rgb,
		strand_middle_color.rgb,
		strand_tip_color.rgb,
		arc_progress
	);

	vec3 danger_color = mix(danger_outer_color.rgb, danger_inner_color.rgb, surface_noise);
	danger_color = mix(danger_color, danger_pulse_color.rgb, danger_pulse);

	vec3 helix_color = mix(healthy_color, danger_color, low_charge_amount);
	vec3 current_outline_color = mix(
		healthy_outline_color.rgb,
		danger_outline_color.rgb,
		low_charge_amount
	);

	float current_opacity = mix(healthy_opacity, danger_opacity, low_charge_amount);
	float interior_pulse = (
		0.90
		+ 0.16
		* sin(arc_progress * 23.0 - TIME * (1.1 + danger_ratio * 2.0))
		* low_charge_amount
	);

	vec3 color = vec3(0.0);
	float alpha = 0.0;

	color += helix_color * inner_helix * current_opacity * interior_pulse;
	alpha = max(alpha, inner_helix * current_opacity);

	color += helix_color * outer_helix * (1.0 - inner_helix) * 0.34;
	alpha = max(alpha, outer_helix * 0.38);

	color += current_outline_color * sharp_outline * outline_opacity;
	alpha = max(alpha, sharp_outline * outline_opacity);

	COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
}
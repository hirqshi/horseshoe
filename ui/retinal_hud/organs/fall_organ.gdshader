shader_type canvas_item;
render_mode blend_mix;

uniform bool preview_enabled = true;
uniform float preview_risk_ratio = 0.64;
uniform bool preview_is_lethal = false;

uniform float risk_ratio = 0.0;
uniform bool is_lethal = false;

uniform vec4 safe_color : source_color = vec4(0.18, 0.70, 1.00, 1.0);
uniform vec4 warning_color : source_color = vec4(0.70, 0.14, 1.00, 1.0);
uniform vec4 lethal_color : source_color = vec4(1.00, 0.10, 0.48, 1.0);
uniform vec4 lethal_pulse_color : source_color = vec4(1.00, 0.50, 0.08, 1.0);
uniform vec4 outline_color : source_color = vec4(1.00, 0.82, 0.94, 1.0);

uniform float base_radius = 0.13;
uniform float risk_radius_bonus = 0.20;
uniform float lobe_strength = 0.11;
uniform float edge_softness = 0.045;

uniform float noise_scale = 8.0;
uniform float outline_noise_scale = 22.0;
uniform float outline_opacity = 0.88;
uniform float idle_opacity = 0.13;

uniform float lethal_pulse_frequency_hz = 3.2;
uniform float lethal_pulse_radius = 0.060;

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
	float resolved_risk_ratio = risk_ratio;
	bool resolved_is_lethal = is_lethal;

	if (preview_enabled) {
		resolved_risk_ratio = preview_risk_ratio;
		resolved_is_lethal = preview_is_lethal;
	}

	vec2 point = UV * 2.0 - 1.0;
	float radius_from_center = length(point);
	float angle = atan(point.y, point.x);

	float surface_noise = fbm_tiled(
		UV * noise_scale + vec2(TIME * 0.14, -TIME * 0.09),
		vec2(noise_scale)
	);

	float outline_noise = fbm_tiled(
		UV * outline_noise_scale + vec2(-TIME * 0.31, TIME * 0.22),
		vec2(outline_noise_scale)
	);

	float display_intensity = mix(idle_opacity, 1.0, resolved_risk_ratio);
	float lethal_amount = 0.0;

	if (resolved_is_lethal) {
		lethal_amount = 1.0;
	}

	float pulse = 0.5 + 0.5 * sin(TIME * TAU * lethal_pulse_frequency_hz);
	float lobe_count = mix(3.0, 10.0, resolved_risk_ratio);

	float lobe_pattern = sin(
		angle * lobe_count
		+ surface_noise * 5.0
		+ TIME * (0.8 + resolved_risk_ratio * 1.4)
	);

	float noisy_radius = (
		base_radius
		+ resolved_risk_ratio * risk_radius_bonus
		+ lobe_pattern * lobe_strength * (0.32 + resolved_risk_ratio)
		+ (surface_noise - 0.5) * 0.060
		+ pulse * lethal_amount * lethal_pulse_radius
	);

	float outer_body = 1.0 - smoothstep(
		noisy_radius,
		noisy_radius + edge_softness,
		radius_from_center
	);

	float inner_hole = 1.0 - smoothstep(
		noisy_radius * (0.22 + resolved_risk_ratio * 0.12),
		noisy_radius * (0.32 + resolved_risk_ratio * 0.12),
		radius_from_center
	);

	float body = max(
		outer_body - inner_hole * (0.35 + resolved_risk_ratio * 0.42),
		0.0
	);

	float inner_body = 1.0 - smoothstep(
		noisy_radius * (0.62 + resolved_risk_ratio * 0.10),
		noisy_radius * (0.87 + resolved_risk_ratio * 0.08),
		radius_from_center
	);

	inner_body *= body;

	float outline = max(body - inner_body, 0.0);
	float sharp_outline = outline * smoothstep(0.28, 0.84, outline_noise);

	vec3 warning_mix = mix(
		safe_color.rgb,
		warning_color.rgb,
		smoothstep(0.20, 0.72, resolved_risk_ratio)
	);

	vec3 body_color = mix(warning_mix, lethal_color.rgb, lethal_amount);
	body_color = mix(body_color, lethal_pulse_color.rgb, pulse * lethal_amount);

	float internal_noise = fbm_tiled(
		UV * (noise_scale * 2.2) + vec2(TIME * 0.17),
		vec2(noise_scale * 2.2)
	);

	body_color = mix(body_color, outline_color.rgb, internal_noise * 0.14);

	vec3 color = vec3(0.0);
	float alpha = 0.0;

	color += body_color * inner_body * 0.84 * display_intensity;
	alpha = max(alpha, inner_body * 0.84 * display_intensity);

	color += body_color * body * (1.0 - inner_body) * 0.36 * display_intensity;
	alpha = max(alpha, body * 0.42 * display_intensity);

	color += outline_color.rgb * sharp_outline * outline_opacity * display_intensity;
	alpha = max(alpha, sharp_outline * outline_opacity * display_intensity);

	COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
}
shader_type canvas_item;
render_mode blend_mix;

uniform vec2 organism_size_px = vec2(320.0, 320.0);

uniform vec2 membrane_offset_px = vec2(0.0, 0.0);
uniform vec2 core_offset_px = vec2(0.0, 0.0);

uniform float turn_speed = 0.0;
uniform bool is_gliding = false;

uniform bool preview_enabled = true;
uniform vec2 preview_direction = vec2(1.0, -0.25);
uniform float preview_membrane_lag_px = 14.0;
uniform float preview_core_lead_px = 82.0;
uniform float preview_turn_speed = 28.0;
uniform bool preview_is_gliding = false;

uniform vec4 membrane_color : source_color = vec4(0.20, 0.86, 1.00, 1.0);
uniform vec4 membrane_edge_color : source_color = vec4(0.62, 0.28, 1.00, 1.0);

uniform vec4 core_color : source_color = vec4(1.00, 0.20, 0.68, 1.0);
uniform vec4 core_hot_color : source_color = vec4(1.00, 0.62, 0.08, 1.0);

uniform vec4 tether_root_color : source_color = vec4(0.96, 0.10, 0.49, 1.0);
uniform vec4 tether_middle_color : source_color = vec4(1.00, 0.57, 0.08, 1.0);
uniform vec4 tether_tip_color : source_color = vec4(0.16, 0.92, 0.82, 1.0);

uniform vec4 branch_root_color : source_color = vec4(0.72, 0.16, 1.00, 1.0);
uniform vec4 branch_tip_color : source_color = vec4(0.18, 0.72, 1.00, 1.0);

uniform vec4 outline_color : source_color = vec4(1.00, 0.76, 0.95, 1.0);

uniform float membrane_radius = 0.29;
uniform float membrane_opacity = 0.18;
uniform float membrane_edge_width = 0.030;
uniform float membrane_edge_opacity = 0.52;

uniform float core_radius = 0.088;
uniform float core_opacity = 0.90;

uniform float branch_turn_speed_multiplier = 5.0;
uniform float branch_start_turn_speed = 1.5;
uniform float branch_full_turn_speed = 18.0;

uniform float growth_length_bonus = 0.42;
uniform float base_tissue_half_width = 0.056;
uniform float growth_spread_width = 0.205;
uniform float diagonal_bias = 0.56;

uniform float ridged_scale_along = 7.0;
uniform float ridged_scale_across = 15.0;
uniform float ridged_threshold = 0.53;
uniform float ridged_softness = 0.13;

uniform float macro_noise_scale = 3.5;
uniform float edge_noise_scale = 10.0;
uniform float grain_noise_scale = 28.0;

uniform float flow_warp_strength = 0.055;
uniform float edge_warp_strength = 0.13;
uniform float outline_width = 0.17;
uniform float outline_noise_strength = 0.72;

uniform float pulse_speed = 1.40;
uniform float tissue_opacity = 0.82;
uniform float outline_opacity = 0.92;


float hash21(
	vec2 value
) {
	value = fract(
		value * vec2(
			123.34,
			456.21
		)
	);

	value += dot(
		value,
		value + 45.32
	);

	return fract(
		value.x * value.y
	);
}


float value_noise_tiled(
	vec2 value,
	vec2 period
) {
	vec2 cell = floor(value);
	vec2 local = fract(value);

	local = local * local * (
		3.0 - 2.0 * local
	);

	vec2 cell_00 = mod(
		cell,
		period
	);

	vec2 cell_10 = mod(
		cell + vec2(
			1.0,
			0.0
		),
		period
	);

	vec2 cell_01 = mod(
		cell + vec2(
			0.0,
			1.0
		),
		period
	);

	vec2 cell_11 = mod(
		cell + vec2(
			1.0,
			1.0
		),
		period
	);

	float bottom = mix(
		hash21(cell_00),
		hash21(cell_10),
		local.x
	);

	float top = mix(
		hash21(cell_01),
		hash21(cell_11),
		local.x
	);

	return mix(
		bottom,
		top,
		local.y
	);
}


float ridged_fbm_tiled(
	vec2 value,
	vec2 base_period
) {
	float result = 0.0;
	float amplitude = 0.5;
	vec2 period = base_period;

	for (int octave = 0; octave < 4; octave++) {
		float noise_value = value_noise_tiled(
			value,
			period
		);

		float ridge = 1.0 - abs(
			noise_value * 2.0 - 1.0
		);

		ridge *= ridge;

		result += ridge * amplitude;

		value *= 2.0;
		period *= 2.0;
		amplitude *= 0.5;
	}

	return result;
}


float fbm_tiled(
	vec2 value,
	vec2 base_period
) {
	float result = 0.0;
	float amplitude = 0.5;
	vec2 period = base_period;

	for (int octave = 0; octave < 4; octave++) {
		result += value_noise_tiled(
			value,
			period
		) * amplitude;

		value *= 2.0;
		period *= 2.0;
		amplitude *= 0.5;
	}

	return result;
}


float circle_mask(
	vec2 point,
	vec2 center,
	float radius,
	float softness
) {
	float distance_to_center = length(
		point - center
	);

	return 1.0 - smoothstep(
		radius - softness,
		radius + softness,
		distance_to_center
	);
}


vec2 safe_normalize(
	vec2 direction
) {
	float direction_length = length(direction);

	if (direction_length <= 0.00001) {
		return vec2(
			1.0,
			0.0
		);
	}

	return direction / direction_length;
}


vec3 nerve_gradient(
	float progress,
	float branch_mix,
	float color_noise
) {
	float root_to_middle = smoothstep(
		0.0,
		0.54,
		progress
	);

	float middle_to_tip = smoothstep(
		0.34,
		1.0,
		progress
	);

	vec3 main_color = mix(
		tether_root_color.rgb,
		tether_middle_color.rgb,
		root_to_middle
	);

	main_color = mix(
		main_color,
		tether_tip_color.rgb,
		middle_to_tip
	);

	vec3 branch_color = mix(
		branch_root_color.rgb,
		tether_middle_color.rgb,
		root_to_middle
	);

	branch_color = mix(
		branch_color,
		branch_tip_color.rgb,
		middle_to_tip
	);

	vec3 color = mix(
		main_color,
		branch_color,
		branch_mix
	);

	float iridescence = (
		sin(
			progress * 20.0
			+ color_noise * 8.0
			+ TIME * 1.45
		) * 0.085
	);

	return max(
		color + vec3(
			iridescence,
			iridescence * 0.25,
			-iridescence * 0.40
		),
		vec3(0.0)
	);
}


void fragment() {
	vec2 aspect = vec2(
		organism_size_px.x
		/ max(
			organism_size_px.y,
			1.0
		),
		1.0
	);

	vec2 point = (
		UV * 2.0 - 1.0
	) * aspect;

	vec2 resolved_membrane_offset_px = membrane_offset_px;
	vec2 resolved_core_offset_px = core_offset_px;

	float resolved_turn_speed = turn_speed;
	bool resolved_is_gliding = is_gliding;

	if (preview_enabled) {
		vec2 preview_axis = safe_normalize(
			preview_direction
		);

		resolved_membrane_offset_px = (
			-preview_axis
			* preview_membrane_lag_px
		);

		resolved_core_offset_px = (
			preview_axis
			* preview_core_lead_px
		);

		resolved_turn_speed = preview_turn_speed;
		resolved_is_gliding = preview_is_gliding;
	}

	vec2 membrane_center = (
		resolved_membrane_offset_px
		/ max(
			organism_size_px.y,
			1.0
		)
		* 2.0
	);

	vec2 core_center = (
		resolved_core_offset_px
		/ max(
			organism_size_px.y,
			1.0
		)
		* 2.0
	);

	vec2 tether_vector = (
		core_center
		- membrane_center
	);

	float tether_length = length(
		tether_vector
	);

	vec2 tether_axis = safe_normalize(
		tether_vector
	);

	vec2 tether_perpendicular = vec2(
		-tether_axis.y,
		tether_axis.x
	);

	float tether_activity = smoothstep(
		0.014,
		0.15,
		tether_length
	);

	float branch_activity = (
		resolved_turn_speed
		* branch_turn_speed_multiplier
	);

	float turn_growth = smoothstep(
		branch_start_turn_speed,
		branch_full_turn_speed,
		branch_activity
	);

	float time_s = TIME * 0.35;

	float macro_noise = fbm_tiled(
		UV * macro_noise_scale
		+ vec2(
			time_s * 0.25,
			-time_s * 0.18
		),
		vec2(macro_noise_scale)
	);

	float edge_noise = fbm_tiled(
		UV * edge_noise_scale
		+ vec2(
			-TIME * 0.17,
			TIME * 0.13
		),
		vec2(edge_noise_scale)
	);

	float grain_noise = fbm_tiled(
		UV * grain_noise_scale
		+ vec2(
			TIME * 0.45,
			-TIME * 0.38
		),
		vec2(grain_noise_scale)
	);

	float membrane_noise = (
		macro_noise
		- 0.5
	) * 0.060;

	float membrane_outer = circle_mask(
		point,
		membrane_center,
		membrane_radius + membrane_noise,
		0.040
	);

	float membrane_inner = circle_mask(
		point,
		membrane_center,
		membrane_radius
		- membrane_edge_width
		+ membrane_noise,
		0.026
	);

	float membrane_edge = max(
		membrane_outer
		- membrane_inner,
		0.0
	);

	float core_noise = (
		edge_noise
		- 0.5
	) * 0.030;

	float core_outer = circle_mask(
		point,
		core_center,
		core_radius + core_noise,
		0.036
	);

	float core_inner = circle_mask(
		point,
		core_center,
		core_radius * 0.48
		+ core_noise * 0.45,
		0.018
	);

	vec2 relative_to_membrane = (
		point
		- membrane_center
	);

	float local_along = dot(
		relative_to_membrane,
		tether_axis
	) / max(
		tether_length,
		0.0001
	);

	float local_across = dot(
		relative_to_membrane,
		tether_perpendicular
	);

	float growth_length = (
		1.0
		+ turn_growth
		* growth_length_bonus
	);

	float growth_begin = smoothstep(
		-0.10,
		0.06,
		local_along
	);

	float growth_end = (
		1.0
		- smoothstep(
			growth_length
			- 0.10,
			growth_length
			+ 0.035,
			local_along
		)
	);

	float growth_envelope = (
		growth_begin
		* growth_end
		* tether_activity
	);

	float forward_spread = smoothstep(
		0.04,
		growth_length,
		local_along
	);

	float tissue_half_width = (
		base_tissue_half_width
		+ forward_spread
		* growth_spread_width
		* turn_growth
	);

	float diagonal_shift = (
		sin(
			local_along * 8.0
			+ TIME * 1.12
		) * diagonal_bias
		* turn_growth
		* 0.055
	);

	float warp_along = (
		edge_noise
		- 0.5
	) * flow_warp_strength;

	float warp_across = (
		macro_noise
		- 0.5
	) * flow_warp_strength
	* 1.8;

	vec2 ridge_coordinates = vec2(
		(
			local_along
			+ warp_along
		)
		* ridged_scale_along,
		(
			local_across
			+ diagonal_shift
			+ warp_across
		)
		* ridged_scale_across
	);

	float ridge_main = ridged_fbm_tiled(
		ridge_coordinates
		+ vec2(
			TIME * 0.18,
			-TIME * 0.11
		),
		vec2(
			ridged_scale_along,
			ridged_scale_across
		)
	);

	float ridge_branch_a = ridged_fbm_tiled(
		ridge_coordinates
		* vec2(
			0.72,
			1.54
		)
		+ vec2(
			5.7,
			13.9
		)
		+ vec2(
			-TIME * 0.12,
			TIME * 0.20
		),
		vec2(
			ridged_scale_along * 0.72,
			ridged_scale_across * 1.54
		)
	);

	float ridge_branch_b = ridged_fbm_tiled(
		ridge_coordinates
		* vec2(
			1.34,
			0.68
		)
		+ vec2(
			17.1,
			4.3
		)
		+ vec2(
			TIME * 0.09,
			TIME * 0.14
		),
		vec2(
			ridged_scale_along * 1.34,
			ridged_scale_across * 0.68
		)
	);

	float ridge_field = max(
		ridge_main,
		max(
			ridge_branch_a
			* (
				0.62
				+ turn_growth
				* 0.30
			),
			ridge_branch_b
			* (
				0.44
				+ turn_growth
				* 0.44
			)
		)
	);

	float body_shape = 1.0 - smoothstep(
		tissue_half_width,
		tissue_half_width
		+ 0.065,
		abs(
			local_across
			+ diagonal_shift
			+ warp_across
		)
	);

	float field_warp = (
		edge_noise
		- 0.5
	) * edge_warp_strength;

	float outer_tissue = smoothstep(
		ridged_threshold
		- ridged_softness,
		ridged_threshold
		+ ridged_softness,
		ridge_field
		+ field_warp
	);

	outer_tissue *= (
		body_shape
		* growth_envelope
	);

	float inner_tissue = smoothstep(
		ridged_threshold
		+ outline_width,
		ridged_threshold
		+ outline_width
		+ ridged_softness,
		ridge_field
		+ field_warp
	);

	inner_tissue *= (
		body_shape
		* growth_envelope
	);

	float tissue_outline = max(
		outer_tissue
		- inner_tissue,
		0.0
	);

	float noisy_outline = (
		tissue_outline
		* smoothstep(
			0.26,
			0.86,
			grain_noise
			+ (
				ridge_field
				- ridged_threshold
			)
			* outline_noise_strength
		)
	);

	float color_progress = clamp(
		local_along
		/ max(
			growth_length,
			0.0001
		),
		0.0,
		1.0
	);

	float branch_mix = smoothstep(
		0.32,
		0.88,
		ridge_branch_a
		+ ridge_branch_b
	) * turn_growth;

	vec3 tissue_color = nerve_gradient(
		color_progress,
		branch_mix,
		grain_noise
	);

	float pulse = (
		0.84
		+ 0.24
		* sin(
			color_progress * 19.0
			- TIME * pulse_speed
			* 2.2
			+ grain_noise * 6.0
		)
	);

	float core_glide_multiplier = 0.94;

	if (resolved_is_gliding) {
		core_glide_multiplier = 1.10;
	}

	vec3 color = vec3(0.0);
	float alpha = 0.0;

	color += (
		membrane_color.rgb
		* membrane_inner
		* membrane_opacity
	);

	alpha = max(
		alpha,
		membrane_inner
		* membrane_opacity
	);

	color += (
		membrane_edge_color.rgb
		* membrane_edge
		* membrane_edge_opacity
	);

	alpha = max(
		alpha,
		membrane_edge
		* membrane_edge_opacity
	);

	color += (
		tissue_color
		* inner_tissue
		* tissue_opacity
		* pulse
	);

	alpha = max(
		alpha,
		inner_tissue
		* tissue_opacity
	);

	color += (
		tissue_color
		* outer_tissue
		* (
			1.0
			- inner_tissue
		)
		* 0.36
	);

	alpha = max(
		alpha,
		outer_tissue
		* 0.42
	);

	color += (
		outline_color.rgb
		* noisy_outline
		* outline_opacity
	);

	alpha = max(
		alpha,
		noisy_outline
		* outline_opacity
	);

	color += (
		core_color.rgb
		* core_outer
		* core_opacity
	);

	alpha = max(
		alpha,
		core_outer
		* core_opacity
	);

	color += (
		core_hot_color.rgb
		* core_inner
		* core_glide_multiplier
	);

	alpha = max(
		alpha,
		core_inner
		* 0.96
	);

	COLOR = vec4(
		color,
		clamp(
			alpha,
			0.0,
			1.0
		)
	);
}
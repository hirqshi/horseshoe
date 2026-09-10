shader_type spatial;

render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;


// === wire shape ===

uniform float wire_width : hint_range(
	0.0,
	40.0,
	0.01
) = 5.0;

uniform float wire_smoothness : hint_range(
	0.0,
	0.1,
	0.001
) = 0.01;

uniform float wire_opacity : hint_range(
	0.0,
	1.0,
	0.01
) = 1.0;

uniform float emission_energy : hint_range(
	0.0,
	16.0,
	0.01
) = 3.0;

// === geometry jitter ===

uniform float geometry_jitter_m : hint_range(
	0.0,
	0.5,
	0.001
) = 0.0;

uniform float geometry_jitter_scale : hint_range(
	0.01,
	30.0,
	0.01
) = 3.0;

uniform float geometry_jitter_step_rate : hint_range(
	0.1,
	60.0,
	0.1
) = 8.0;


// === vertical fade ===

uniform float vertical_fade_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.0;

uniform float mesh_bottom_y : hint_range(
	-20.0,
	0.0,
	0.01
) = -1.0;

uniform float mesh_top_y : hint_range(
	0.0,
	20.0,
	0.01
) = 1.0;

uniform float vertical_fade_bottom : hint_range(
	0.0,
	1.0,
	0.01
) = 0.0;

uniform float vertical_fade_top : hint_range(
	0.0,
	1.0,
	0.01
) = 0.0;

uniform float vertical_fade_softness : hint_range(
	0.001,
	0.5,
	0.001
) = 0.12;

// === distance thinning ===

uniform float distance_thinning_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 1.0;

uniform float wire_reference_distance_m : hint_range(
	0.1,
	100.0,
	0.1
) = 5.0;

uniform float wire_min_distance_multiplier : hint_range(
	0.01,
	1.0,
	0.01
) = 0.10;


// === wire colors ===

uniform vec4 color_a : source_color = vec4(
	0.10,
	0.55,
	1.0,
	1.0
);

uniform vec4 color_b : source_color = vec4(
	0.72,
	0.16,
	1.0,
	1.0
);

uniform vec4 color_c : source_color = vec4(
	1.0,
	0.20,
	0.55,
	1.0
);


// === color movement ===

uniform vec3 color_direction_local = vec3(
	0.0,
	1.0,
	0.0
);

uniform float color_position_scale : hint_range(
	0.0,
	10.0,
	0.01
) = 0.35;

uniform float color_scroll_speed : hint_range(
	-4.0,
	4.0,
	0.01
) = 0.0;

uniform float view_angle_color_influence : hint_range(
	0.0,
	1.0,
	0.01
) = 0.35;

uniform float color_offset : hint_range(
	0.0,
	1.0,
	0.01
) = 0.0;


varying vec3 barys;
varying vec3 local_position;
varying vec3 view_position;

float hash_31(
	vec3 value
) {
	return fract(
		sin(
			dot(
				value,
				vec3(
					127.1,
					311.7,
					74.7
				)
			)
		)
		* 43758.5453123
	);
}


float get_distance_wire_width_multiplier() {
	float distance_to_camera_m = length(
		view_position
	);

	float reference_distance_m = max(
		wire_reference_distance_m,
		0.001
	);

	float perspective_multiplier = clamp(
		reference_distance_m
		/ max(
			distance_to_camera_m,
			reference_distance_m
		),
		wire_min_distance_multiplier,
		1.0
	);

	return mix(
		1.0,
		perspective_multiplier,
		distance_thinning_strength
	);
}

void vertex() {
	int index = VERTEX_ID % 3;

	if (index == 0) {
		barys = vec3(
			1.0,
			0.0,
			0.0
		);
	} else if (index == 1) {
		barys = vec3(
			0.0,
			1.0,
			0.0
		);
	} else {
		barys = vec3(
			0.0,
			0.0,
			1.0
		);
	}

	vec3 original_vertex = VERTEX;

	local_position = original_vertex;
	
	view_position = (
		MODELVIEW_MATRIX
		* vec4(
			original_vertex,
			1.0
		)
	).xyz;
	
	if (
		geometry_jitter_m > 0.0
	) {
		float safe_step_rate = max(
			geometry_jitter_step_rate,
			0.1
		);

		float stepped_time = floor(
			TIME
			* safe_step_rate
		) / safe_step_rate;

		vec3 jitter_cell = floor(
			original_vertex
			* geometry_jitter_scale
		);

		float jitter_noise = (
			hash_31(
				jitter_cell
				+ vec3(
					stepped_time,
					stepped_time * 1.37,
					stepped_time * 2.11
				)
			)
			* 2.0
			- 1.0
		);

		VERTEX += normalize(
			NORMAL
		) * jitter_noise * geometry_jitter_m;
	}
}


vec3 get_gradient_color(
	float value
) {
	float gradient_position = fract(
		value
	);

	float segment = gradient_position * 3.0;

	if (segment < 1.0) {
		return mix(
			color_a.rgb,
			color_b.rgb,
			segment
		);
	}

	if (segment < 2.0) {
		return mix(
			color_b.rgb,
			color_c.rgb,
			segment - 1.0
		);
	}

	return mix(
		color_c.rgb,
		color_a.rgb,
		segment - 2.0
	);
}

float get_vertical_fade(
	float local_y
) {
	if (
		vertical_fade_strength <= 0.0
	) {
		return 1.0;
	}

	float height_01 = clamp(
		(
			local_y
			- mesh_bottom_y
		)
		/ max(
			mesh_top_y
			- mesh_bottom_y,
			0.001
		),
		0.0,
		1.0
	);

	float bottom_mask = smoothstep(
		vertical_fade_bottom
		- vertical_fade_softness,
		vertical_fade_bottom
		+ vertical_fade_softness,
		height_01
	);

	float top_mask = 1.0 - smoothstep(
		1.0
		- vertical_fade_top
		- vertical_fade_softness,
		1.0
		- vertical_fade_top
		+ vertical_fade_softness,
		height_01
	);

	float fade_mask = bottom_mask * top_mask;

	return mix(
		1.0,
		fade_mask,
		vertical_fade_strength
	);
}

float get_view_angle_factor(
	vec3 normal_value,
	vec3 view_value
) {
	vec3 normal_direction = normalize(
		normal_value
	);

	vec3 view_direction = normalize(
		view_value
	);

	return 1.0 - clamp(
		dot(
			normal_direction,
			view_direction
		),
		0.0,
		1.0
	);
}


void fragment() {
	float distance_width_multiplier = (
		get_distance_wire_width_multiplier()
	);

	vec3 edge_width = fwidth(
		barys
	) * max(
		wire_width
		* distance_width_multiplier,
		0.001
	);

	vec3 edge_mask = smoothstep(
		edge_width - wire_smoothness,
		edge_width + wire_smoothness,
		barys
	);

	float interior_mask = min(
		edge_mask.x,
		min(
			edge_mask.y,
			edge_mask.z
		)
	);

	float wire_mask = 1.0 - interior_mask;

	float vertical_fade = get_vertical_fade(
		local_position.y
	);

	wire_mask *= vertical_fade;

	if (wire_mask <= 0.001) {
		discard;
	}

	vec3 safe_color_direction = normalize(
		max(
			abs(
				color_direction_local
			),
			vec3(0.001)
		)
		* sign(
			color_direction_local
		)
	);

	float position_color = dot(
		local_position,
		safe_color_direction
	) * color_position_scale;

	float view_color = get_view_angle_factor(
		NORMAL,
		VIEW
	) * (
		view_angle_color_influence
	);

	float color_position = (
		color_offset
		+ position_color
		+ view_color
		+ TIME * color_scroll_speed
	);

	vec3 wire_color = get_gradient_color(
		color_position
	);

	ALBEDO = wire_color;

	EMISSION = wire_color * emission_energy;

	ALPHA = wire_mask * wire_opacity;
}
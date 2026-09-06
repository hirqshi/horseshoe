shader_type sky;


// === base ceiling ===

// must be higher than the camera
uniform float ceiling_height_m : hint_range(
	50.0,
	5000.0,
	1.0
) = 700.0;

uniform sampler2D ceiling_texture : source_color, repeat_enable, filter_nearest;

uniform vec4 ceiling_tint : source_color = vec4(
	0.38,
	0.48,
	0.60,
	1.0
);

uniform float ceiling_texture_scale : hint_range(
	0.001,
	2.0,
	0.001
) = 0.08;

uniform float ceiling_brightness : hint_range(
	0.0,
	4.0,
	0.01
) = 1.0;

// 0.0 disables world-space pixel snapping
uniform float ceiling_pixel_world_size_m : hint_range(
	0.0,
	4.0,
	0.01
) = 0.0;


// === cloud layer 1 ===

// must stay below ceiling_height_m
uniform float cloud_layer_1_height_m : hint_range(
	10.0,
	4999.0,
	1.0
) = 520.0;

uniform sampler2D cloud_layer_1_texture : repeat_enable, filter_nearest;

uniform vec4 cloud_layer_1_color : source_color = vec4(
	0.10,
	0.17,
	0.28,
	1.0
);

uniform float cloud_layer_1_scale : hint_range(
	0.001,
	2.0,
	0.001
) = 0.035;

uniform vec2 cloud_layer_1_direction = vec2(
	0.70,
	0.25
);

uniform float cloud_layer_1_speed : hint_range(
	0.0,
	2.0,
	0.001
) = 0.018;

uniform float cloud_layer_1_opacity : hint_range(
	0.0,
	1.0,
	0.01
) = 0.70;

uniform float cloud_layer_1_threshold : hint_range(
	0.0,
	1.0,
	0.01
) = 0.48;

uniform float cloud_layer_1_softness : hint_range(
	0.001,
	0.5,
	0.001
) = 0.12;


// === cloud layer 2 ===

// must stay below ceiling_height_m
uniform float cloud_layer_2_height_m : hint_range(
	10.0,
	4999.0,
	1.0
) = 440.0;

uniform sampler2D cloud_layer_2_texture : repeat_enable, filter_nearest;

uniform vec4 cloud_layer_2_color : source_color = vec4(
	0.18,
	0.26,
	0.38,
	1.0
);

uniform float cloud_layer_2_scale : hint_range(
	0.001,
	2.0,
	0.001
) = 0.062;

uniform vec2 cloud_layer_2_direction = vec2(
	-0.35,
	0.55
);

uniform float cloud_layer_2_speed : hint_range(
	0.0,
	2.0,
	0.001
) = 0.032;

uniform float cloud_layer_2_opacity : hint_range(
	0.0,
	1.0,
	0.01
) = 0.45;

uniform float cloud_layer_2_threshold : hint_range(
	0.0,
	1.0,
	0.01
) = 0.52;

uniform float cloud_layer_2_softness : hint_range(
	0.001,
	0.5,
	0.001
) = 0.10;


// === cloud layer 3 ===

// must stay below ceiling_height_m
uniform float cloud_layer_3_height_m : hint_range(
	10.0,
	4999.0,
	1.0
) = 350.0;

uniform sampler2D cloud_layer_3_texture : repeat_enable, filter_nearest;

uniform vec4 cloud_layer_3_color : source_color = vec4(
	0.28,
	0.36,
	0.48,
	1.0
);

uniform float cloud_layer_3_scale : hint_range(
	0.001,
	2.0,
	0.001
) = 0.110;

uniform vec2 cloud_layer_3_direction = vec2(
	0.20,
	-0.75
);

uniform float cloud_layer_3_speed : hint_range(
	0.0,
	2.0,
	0.001
) = 0.048;

uniform float cloud_layer_3_opacity : hint_range(
	0.0,
	1.0,
	0.01
) = 0.28;

uniform float cloud_layer_3_threshold : hint_range(
	0.0,
	1.0,
	0.01
) = 0.58;

uniform float cloud_layer_3_softness : hint_range(
	0.001,
	0.5,
	0.001
) = 0.08;


// === fog ===

uniform vec4 fog_color : source_color = vec4(
	0.09,
	0.13,
	0.20,
	1.0
);

uniform float fog_start_distance_m : hint_range(
	1.0,
	5000.0,
	1.0
) = 280.0;

uniform float fog_end_distance_m : hint_range(
	2.0,
	10000.0,
	1.0
) = 1050.0;

uniform float fog_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.92;


// === lightning ===

uniform bool lightning_enabled = true;

// average duration between possible lightning events
uniform float lightning_interval_seconds : hint_range(
	1.0,
	120.0,
	0.1
) = 12.0;

// actual chance for one interval to contain lightning
uniform float lightning_chance : hint_range(
	0.0,
	1.0,
	0.01
) = 0.55;

uniform float lightning_duration_seconds : hint_range(
	0.01,
	2.0,
	0.01
) = 0.18;

uniform vec4 lightning_color : source_color = vec4(
	0.62,
	0.86,
	1.00,
	1.0
);

uniform float lightning_flash_strength : hint_range(
	0.0,
	8.0,
	0.01
) = 2.20;

uniform float lightning_bolt_strength : hint_range(
	0.0,
	12.0,
	0.01
) = 4.50;

// lower means the lightning occupies a bigger area
uniform float lightning_world_scale : hint_range(
	0.001,
	1.0,
	0.001
) = 0.025;

uniform float lightning_line_width : hint_range(
	0.001,
	0.20,
	0.001
) = 0.018;

uniform float lightning_fog_visibility : hint_range(
	0.0,
	1.0,
	0.01
) = 0.65;

// max distance from the player where a bolt may spawn
uniform float lightning_spawn_radius_m : hint_range(
	10.0,
	3000.0,
	1.0
) = 450.0;

// radius of the cloud illumination around the bolt
uniform float lightning_flash_radius_m : hint_range(
	10.0,
	3000.0,
	1.0
) = 260.0;

// === sky fallback ===

// visible when looking below the virtual cloud planes
uniform vec4 lower_sky_color : source_color = vec4(
	0.06,
	0.09,
	0.14,
	1.0
);


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


float value_noise(
	vec2 value
) {
	vec2 cell = floor(
		value
	);

	vec2 cell_uv = fract(
		value
	);

	cell_uv = (
		cell_uv
		* cell_uv
		* (
			3.0
			- 2.0
			* cell_uv
		)
	);

	float bottom = mix(
		hash(
			cell
		),
		hash(
			cell
			+ vec2(
				1.0,
				0.0
			)
		),
		cell_uv.x
	);

	float top = mix(
		hash(
			cell
			+ vec2(
				0.0,
				1.0
			)
		),
		hash(
			cell
			+ vec2(1.0)
		),
		cell_uv.x
	);

	return mix(
		bottom,
		top,
		cell_uv.y
	);
}


vec2 rotate_2d(
	vec2 value,
	float angle
) {
	float cosine = cos(
		angle
	);

	float sine = sin(
		angle
	);

	return vec2(
		value.x
		* cosine
		- value.y
		* sine,

		value.x
		* sine
		+ value.y
		* cosine
	);
}


float get_plane_distance(
	float plane_height_m,
	vec3 camera_position,
	vec3 eye_direction
) {
	float vertical_distance = max(
		plane_height_m
		- camera_position.y,
		0.001
	);

	return vertical_distance / max(
		eye_direction.y,
		0.001
	);
}


vec2 get_plane_world_xz(
	float plane_height_m,
	vec3 camera_position,
	vec3 eye_direction
) {
	float plane_distance = get_plane_distance(
		plane_height_m,
		camera_position,
		eye_direction
	);

	return (
		camera_position.xz
		+ eye_direction.xz
		* plane_distance
	);
}


vec2 get_pixel_snapped_world_xz(
	vec2 world_xz
) {
	if (
		ceiling_pixel_world_size_m <= 0.0
	) {
		return world_xz;
	}

	return (
		floor(
			world_xz
			/ ceiling_pixel_world_size_m
		)
		+ vec2(0.5)
	)
	* ceiling_pixel_world_size_m;
}


float get_cloud_mask(
	float noise_value,
	float threshold,
	float softness
) {
	return smoothstep(
		threshold,
		threshold
		+ softness,
		noise_value
	);
}


float get_lightning_event_strength(
	out float event_seed
) {
	if (
		!lightning_enabled
	) {
		event_seed = 0.0;
		return 0.0;
	}

	float safe_interval = max(
		lightning_interval_seconds,
		0.01
	);

	float event_index = floor(
		TIME
		/ safe_interval
	);

	float event_phase = fract(
		TIME
		/ safe_interval
	);

	float event_random = hash(
		vec2(
			event_index,
			41.0
		)
	);

	float event_exists = step(
		1.0
		- lightning_chance,
		event_random
	);

	float normalized_duration = min(
		lightning_duration_seconds
		/ safe_interval,
		0.95
	);

	float is_active = 1.0 - step(
		normalized_duration,
		event_phase
	);

	float fade = 1.0 - smoothstep(
		0.0,
		normalized_duration,
		event_phase
	);

	event_seed = event_index
	+ event_random
	* 100.0;

	return (
		event_exists
		* is_active
		* fade
	);
}

vec2 get_lightning_origin_xz(
	vec3 camera_position,
	float event_seed
) {
	float lightning_angle = hash(
		vec2(
			event_seed,
			23.0
		)
	)
	* 6.28318530;

	float lightning_radius = sqrt(
		hash(
			vec2(
				event_seed,
				31.0
			)
		)
	)
	* lightning_spawn_radius_m;

	vec2 lightning_offset = vec2(
		cos(
			lightning_angle
		),
		sin(
			lightning_angle
		)
	)
	* lightning_radius;

	return (
		camera_position.xz
		+ lightning_offset
	);
}


float get_lightning_flash_mask(
	vec2 ceiling_world_xz,
	vec2 lightning_origin_xz
) {
	float distance_to_lightning = distance(
		ceiling_world_xz,
		lightning_origin_xz
	);

	return 1.0 - smoothstep(
		lightning_flash_radius_m
		* 0.35,
		lightning_flash_radius_m,
		distance_to_lightning
	);
}


float get_lightning_bolt_mask(
	vec2 ceiling_world_xz,
	vec2 lightning_origin_xz,
	float event_seed
) {
	vec2 local_bolt_position = (
		ceiling_world_xz
		- lightning_origin_xz
	)
	* lightning_world_scale;

	float bolt_rotation = hash(
		vec2(
			event_seed,
			7.0
		)
	)
	* 6.28318530;

	vec2 bolt_uv = rotate_2d(
		local_bolt_position,
		bolt_rotation
	);

	float main_line_mask = smoothstep(
		0.72,
		0.08,
		abs(
			bolt_uv.y
		)
	);

	float line_noise = (
		value_noise(
			vec2(
				bolt_uv.y
				* 9.0,
				event_seed
			)
		)
		* 2.0
		- 1.0
	)
	* 0.20;

	float main_line_distance = abs(
		bolt_uv.x
		- line_noise
	);

	float main_bolt = 1.0 - smoothstep(
		lightning_line_width,
		lightning_line_width
		* 2.5,
		main_line_distance
	);

	main_bolt *= main_line_mask;

	float branch_line_mask = smoothstep(
		0.65,
		0.15,
		abs(
			bolt_uv.y
			- 0.15
		)
	);

	float branch_distance = abs(
		bolt_uv.x
		- line_noise
		- (
			bolt_uv.y
			- 0.15
		)
		* 0.75
	);

	float branch_bolt = 1.0 - smoothstep(
		lightning_line_width
		* 1.4,
		lightning_line_width
		* 3.0,
		branch_distance
	);

	branch_bolt *= branch_line_mask;

	return max(
		main_bolt,
		branch_bolt
	);
}


void sky() {
	vec3 camera_position = POSITION;
	vec3 eye_direction = EYEDIR;

	vec3 sky_color = lower_sky_color.rgb;

	if (
		eye_direction.y > 0.001
	) {
		vec2 ceiling_world_xz = get_plane_world_xz(
			ceiling_height_m,
			camera_position,
			eye_direction
		);

		vec2 snapped_ceiling_world_xz = get_pixel_snapped_world_xz(
			ceiling_world_xz
		);

		vec2 ceiling_uv = (
			snapped_ceiling_world_xz
			* ceiling_texture_scale
		);

		vec3 ceiling_color = (
			texture(
				ceiling_texture,
				ceiling_uv
			).rgb
			* ceiling_tint.rgb
			* ceiling_brightness
		);

		vec2 cloud_layer_1_world_xz = get_plane_world_xz(
			cloud_layer_1_height_m,
			camera_position,
			eye_direction
		);

		vec2 cloud_layer_1_uv = (
			cloud_layer_1_world_xz
			* cloud_layer_1_scale
			+ cloud_layer_1_direction
			* TIME
			* cloud_layer_1_speed
		);

		float cloud_layer_1_noise = texture(
			cloud_layer_1_texture,
			cloud_layer_1_uv
		).r;

		float cloud_layer_1_mask = (
			get_cloud_mask(
				cloud_layer_1_noise,
				cloud_layer_1_threshold,
				cloud_layer_1_softness
			)
			* cloud_layer_1_opacity
		);

		vec2 cloud_layer_2_world_xz = get_plane_world_xz(
			cloud_layer_2_height_m,
			camera_position,
			eye_direction
		);

		vec2 cloud_layer_2_uv = (
			cloud_layer_2_world_xz
			* cloud_layer_2_scale
			+ cloud_layer_2_direction
			* TIME
			* cloud_layer_2_speed
		);

		float cloud_layer_2_noise = texture(
			cloud_layer_2_texture,
			cloud_layer_2_uv
		).r;

		float cloud_layer_2_mask = (
			get_cloud_mask(
				cloud_layer_2_noise,
				cloud_layer_2_threshold,
				cloud_layer_2_softness
			)
			* cloud_layer_2_opacity
		);

		vec2 cloud_layer_3_world_xz = get_plane_world_xz(
			cloud_layer_3_height_m,
			camera_position,
			eye_direction
		);

		vec2 cloud_layer_3_uv = (
			cloud_layer_3_world_xz
			* cloud_layer_3_scale
			+ cloud_layer_3_direction
			* TIME
			* cloud_layer_3_speed
		);

		float cloud_layer_3_noise = texture(
			cloud_layer_3_texture,
			cloud_layer_3_uv
		).r;

		float cloud_layer_3_mask = (
			get_cloud_mask(
				cloud_layer_3_noise,
				cloud_layer_3_threshold,
				cloud_layer_3_softness
			)
			* cloud_layer_3_opacity
		);

		sky_color = ceiling_color;

		sky_color = mix(
			sky_color,
			cloud_layer_1_color.rgb,
			cloud_layer_1_mask
		);

		sky_color = mix(
			sky_color,
			cloud_layer_2_color.rgb,
			cloud_layer_2_mask
		);

		sky_color = mix(
			sky_color,
			cloud_layer_3_color.rgb,
			cloud_layer_3_mask
		);

		float lightning_seed = 0.0;

		float lightning_strength = get_lightning_event_strength(
			lightning_seed
		);

		vec2 lightning_origin_xz = get_lightning_origin_xz(
			camera_position,
			lightning_seed
		);

		float lightning_bolt_mask = get_lightning_bolt_mask(
			ceiling_world_xz,
			lightning_origin_xz,
			lightning_seed
		);

		float lightning_flash_mask = get_lightning_flash_mask(
			ceiling_world_xz,
			lightning_origin_xz
		);

		float cloud_coverage = max(
			cloud_layer_1_mask,
			max(
				cloud_layer_2_mask,
				cloud_layer_3_mask
			)
		);

		float lightning_flash = (
			lightning_strength
			* lightning_flash_mask
			* lightning_flash_strength
			* max(
				cloud_coverage,
				0.20
			)
		);

		float lightning_bolt = (
			lightning_bolt_mask
			* lightning_strength
			* lightning_bolt_strength
		);

		sky_color += (
			lightning_color.rgb
			* (
				lightning_flash
				+ lightning_bolt
			)
		);

		float ceiling_distance = get_plane_distance(
			ceiling_height_m,
			camera_position,
			eye_direction
		);

		float fog_amount = smoothstep(
			fog_start_distance_m,
			fog_end_distance_m,
			ceiling_distance
		);

		fog_amount *= fog_strength;

		float lightning_fog_boost = mix(
			1.0,
			lightning_fog_visibility,
			fog_amount
		);

		sky_color = mix(
			sky_color,
			fog_color.rgb,
			fog_amount
		);

		sky_color += (
			lightning_color.rgb
			* lightning_bolt
			* lightning_fog_boost
		);
	}

	COLOR = sky_color;
}
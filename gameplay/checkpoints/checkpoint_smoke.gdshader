shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;

uniform sampler2D smoke_texture : repeat_enable;

uniform vec4 primary_color : source_color = vec4(
	0.06,
	0.1,
	0.24,
	1.0
);

uniform vec4 secondary_color : source_color = vec4(
	0.12,
	0.3,
	0.52,
	1.0
);

uniform vec4 bottom_color : source_color = vec4(
	0.02,
	0.01,
	0.08,
	1.0
);

uniform float secondary_color_mix : hint_range(
	0.0,
	1.0,
	0.01
) = 0.45;

group_uniforms Surface;

uniform float opacity : hint_range(
	0.0,
	1.0,
	0.01
) = 0.55;

uniform float emission_energy : hint_range(
	0.0,
	8.0,
	0.01
) = 1.25;

uniform float smoke_tiling : hint_range(
	0.1,
	8.0,
	0.01
) = 1.4;

uniform vec2 smoke_scroll_direction = vec2(
	0.08,
	-0.05
);

uniform float smoke_sharpness : hint_range(
	0.01,
	1.0,
	0.01
) = 0.72;

group_uniforms Vertical_Fade;

uniform float mesh_bottom_y : hint_range(
	-10.0,
	0.0,
	0.01
) = -0.8;

uniform float mesh_top_y : hint_range(
	0.0,
	10.0,
	0.01
) = 0.8;

uniform float bottom_cutoff : hint_range(
	0.0,
	1.0,
	0.01
) = 0.0;

uniform float top_cutoff : hint_range(
	0.0,
	1.0,
	0.01
) = 0.0;

uniform float cutoff_softness : hint_range(
	0.001,
	0.5,
	0.001
) = 0.12;

group_uniforms Geometry_Pulse;

uniform float geometry_bottom_offset : hint_range(
	0.0,
	1.0,
	0.001
) = 0.12;

uniform float pulse_speed : hint_range(
	0.0,
	8.0,
	0.01
) = 1.2;

uniform float pulse_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.1;

uniform float edge_pulse : hint_range(
	0.0,
	0.5,
	0.001
) = 0.07;

uniform float geometry_jitter : hint_range(
	0.0,
	0.5,
	0.001
) = 0.02;

uniform float geometry_step_rate : hint_range(
	0.1,
	30.0,
	0.1
) = 3.0;

group_uniforms Bottom_Gradient;

uniform float bottom_gradient_height : hint_range(
	0.001,
	1.0,
	0.001
) = 0.38;

uniform float bottom_color_strength : hint_range(
	0.0,
	1.0,
	0.01
) = 0.65;

uniform float bottom_opacity_multiplier : hint_range(
	1.0,
	4.0,
	0.01
) = 1.45;

uniform float bottom_emission_boost : hint_range(
	0.0,
	8.0,
	0.01
) = 0.8;

group_uniforms Fresnel;

uniform float inner_fresnel_power : hint_range(
	0.1,
	8.0,
	0.01
) = 2.0;

uniform float inner_fresnel_strength : hint_range(
	0.0,
	8.0,
	0.01
) = 4.0;

uniform float outer_fresnel_power : hint_range(
	0.1,
	12.0,
	0.01
) = 5.0;

uniform float outer_fresnel_strength : hint_range(
	0.0,
	8.0,
	0.01
) = 2.0;

group_uniforms Signal;

uniform float wipe_scale : hint_range(
	0.0,
	16.0,
	0.01
) = 3.0;

uniform float wipe_speed : hint_range(
	0.0,
	8.0,
	0.01
) = 0.5;

uniform float wipe_blend : hint_range(
	0.0,
	1.0,
	0.01
) = 0.25;

uniform float signal_scale : hint_range(
	0.0,
	100.0,
	0.01
) = 22.0;

uniform float signal_speed : hint_range(
	0.0,
	8.0,
	0.01
) = 1.0;

uniform float signal_random_scale : hint_range(
	0.0,
	1.0,
	0.01
) = 0.25;

uniform float signal_blend : hint_range(
	0.0,
	1.0,
	0.01
) = 0.35;

uniform float flicker_amount : hint_range(
	0.0,
	1.0,
	0.01
) = 0.08;

uniform float flicker_speed : hint_range(
	0.0,
	30.0,
	0.01
) = 8.0;

uniform float grain_amount : hint_range(
	0.0,
	1.0,
	0.01
) = 0.08;

uniform float effect_strength : hint_range(
	0.0,
	4.0,
	0.01
) = 0.7;


varying vec3 local_vertex;
varying float local_height_01;


float saturatef(float value) {
	return clamp(
		value,
		0.0,
		1.0
	);
}


float random(vec2 value) {
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


float get_fresnel(
	float power,
	vec3 normal,
	vec3 view_direction
) {
	return pow(
		1.0 - saturatef(
			dot(
				normalize(normal),
				normalize(view_direction)
			)
		),
		power
	);
}


float get_vertical_mask(float height_01) {
	float visible_bottom = bottom_cutoff;
	float visible_top = 1.0 - top_cutoff;

	float bottom_mask = smoothstep(
		visible_bottom - cutoff_softness,
		visible_bottom + cutoff_softness,
		height_01
	);

	float top_mask = 1.0 - smoothstep(
		visible_top - cutoff_softness,
		visible_top + cutoff_softness,
		height_01
	);

	return bottom_mask * top_mask;
}


float get_wipe(float height_01) {
	return 1.0 - fract(
		height_01 * wipe_scale
		+ TIME * wipe_speed
	);
}


void vertex() {
	vec3 original_vertex = VERTEX;

	VERTEX.y += geometry_bottom_offset;

	float safe_step_rate = max(
		geometry_step_rate,
		0.1
	);

	float stepped_time = floor(
		TIME * safe_step_rate
	) / safe_step_rate;

	vec2 vertex_smoke_uv = (
		UV * smoke_tiling
		+ smoke_scroll_direction * TIME
	);

	float smoke_sample = texture(
		smoke_texture,
		vertex_smoke_uv
	).r;

	float vertical_shape = sin(
		UV.y * PI
	);

	float smooth_pulse = sin(
		TIME * pulse_speed
		+ UV.y * PI * 2.0
	);

	float pulse_offset = (
		smoke_sample
		* vertical_shape
		* edge_pulse
		* smooth_pulse
	);

	float stepped_jitter = (
		random(
			original_vertex.xz
			+ vec2(stepped_time)
		)
		* 2.0
		- 1.0
	)
	* geometry_jitter
	* smoke_sample;

	VERTEX += NORMAL * (
		pulse_offset
		+ stepped_jitter
	);

	local_vertex = original_vertex;

	local_height_01 = saturatef(
		(
			original_vertex.y
			- mesh_bottom_y
		)
		/ max(
			mesh_top_y - mesh_bottom_y,
			0.001
		)
	);
}


void fragment() {
	vec2 smoke_uv = (
		UV * smoke_tiling
		+ smoke_scroll_direction * TIME
	);

	float smoke_sample = texture(
		smoke_texture,
		smoke_uv
	).r;

	float smoke_mask = smoothstep(
		0.0,
		smoke_sharpness,
		smoke_sample
	);

	vec3 face_normal = NORMAL;

	if (!FRONT_FACING) {
		face_normal *= -1.0;
	}

	float inner_fresnel = get_fresnel(
		inner_fresnel_power,
		face_normal,
		VIEW
	);

	inner_fresnel = 1.0 - saturatef(
		inner_fresnel
		* inner_fresnel_strength
	);

	float outer_fresnel = saturatef(
		get_fresnel(
			outer_fresnel_power,
			face_normal,
			VIEW
		)
		* outer_fresnel_strength
	);

	float fresnel_overlay = mix(
		inner_fresnel,
		0.5,
		smoke_mask
	);

	fresnel_overlay = mix(
		outer_fresnel,
		1.0,
		fresnel_overlay
	);

	float safe_signal_scale = max(
		signal_scale,
		0.001
	);

	float stepped_time = floor(
		TIME * 4.0
	) / 4.0;

	float noise_xz = texture(
		smoke_texture,
		local_vertex.xz * 0.7
		+ vec2(stepped_time)
	).r;

	float noise_zy = texture(
		smoke_texture,
		local_vertex.zy * 0.7
		- vec2(stepped_time)
	).r;

	float combined_noise = noise_xz * noise_zy;

	float signal_random = 1.0 + (
		random(
			floor(
				local_vertex.xz * 3.0
			)
		)
		* 2.0
		- 1.0
	)
	* signal_random_scale;

	float signal_wave = abs(
		fract(
			local_height_01
			* signal_random
			* safe_signal_scale
			- TIME * signal_speed
		)
		* 2.0
		- 1.0
	);

	float signal = pow(
		signal_wave,
		0.5
	);

	float wipe = get_wipe(
		local_height_01
	);

	float grain = random(
		floor(
			local_vertex.xz * 80.0
		)
		+ vec2(
			floor(TIME * 4.0)
		)
	);

	float signal_highlight = outer_fresnel;

	signal_highlight = mix(
		signal_highlight,
		signal_highlight / max(
			signal + 0.1,
			0.1
		),
		signal_blend
	);

	signal_highlight *= mix(
		1.0,
		wipe,
		wipe_blend
	);

	signal_highlight *= mix(
		1.0,
		grain,
		grain_amount
	);

	signal_highlight *= mix(
		1.0,
		combined_noise,
		0.35
	);

	float flicker_wave = sin(
		TIME * flicker_speed
		+ cos(TIME * PI * 2.0)
	);

	float flicker = 1.0 - (
		(
			flicker_wave * 0.5
			+ 0.5
		)
		* flicker_amount
	);

	float vertical_mask = get_vertical_mask(
		local_height_01
	);

	float pulse = 1.0 + (
		sin(TIME * pulse_speed)
		* pulse_strength
	);

	float secondary_mix = (
		fresnel_overlay
		* secondary_color_mix
	);

	vec3 base_color = mix(
		primary_color.rgb,
		secondary_color.rgb,
		secondary_mix
	);

	float bottom_gradient = 1.0 - smoothstep(
		0.0,
		bottom_gradient_height,
		local_height_01
	);

	float bottom_color_mix = (
		bottom_gradient
		* bottom_color_strength
	);

	base_color = mix(
		base_color,
		bottom_color.rgb,
		bottom_color_mix
	);

	vec3 signal_color = secondary_color.rgb * (
		signal_highlight
		* effect_strength
	);

	vec3 final_color = (
		base_color
		+ signal_color
	)
	* flicker;

	float bottom_opacity = mix(
		1.0,
		bottom_opacity_multiplier,
		bottom_gradient
	);

	float final_alpha = (
		smoke_mask
		* vertical_mask
		* opacity
		* bottom_opacity
		* pulse
	);

	float bottom_emission_multiplier = 1.0 + (
		bottom_gradient
		* bottom_emission_boost
	);

	ALBEDO = final_color;

	EMISSION = final_color
		* emission_energy
		* bottom_emission_multiplier
		* (
			0.4
			+ outer_fresnel * 0.6
		);

	ALPHA = final_alpha;
}
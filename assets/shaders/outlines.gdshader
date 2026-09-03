shader_type spatial;

render_mode unshaded;
render_mode fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable;

uniform float sensitivity : hint_range(
	0.0,
	3.0,
	0.01
) = 1.0;

uniform float outline_thickness : hint_range(
	0.0,
	2.0,
	0.01
) = 1.0;

uniform float step_threshold : hint_range(
	0.0,
	2.0,
	0.01
) = 0.12;

uniform vec3 outline_color : source_color = vec3(
	0.0,
	0.0,
	0.0
);


void vertex() {
	POSITION = vec4(
		VERTEX.xy,
		1.0,
		1.0
	);
}


float depth_vs(
	vec2 uv,
	mat4 inverse_projection_matrix
) {
	float depth = texture(
		depth_texture,
		uv
	).r;

	return 1.0 / (
		depth
		* inverse_projection_matrix[2].w
		+ inverse_projection_matrix[3].w
	);
}


void fragment() {
	float thickness = (
		outline_thickness
		* 0.001
	);

	float center_depth = depth_vs(
		SCREEN_UV,
		INV_PROJECTION_MATRIX
	);

	float border_r = abs(
		depth_vs(
			SCREEN_UV
			+ vec2(thickness, 0.0),
			INV_PROJECTION_MATRIX
		)
		- center_depth
	);

	float border_l = abs(
		depth_vs(
			SCREEN_UV
			+ vec2(-thickness, 0.0),
			INV_PROJECTION_MATRIX
		)
		- center_depth
	);

	float border_t = abs(
		depth_vs(
			SCREEN_UV
			+ vec2(0.0, thickness),
			INV_PROJECTION_MATRIX
		)
		- center_depth
	);

	float border_b = abs(
		depth_vs(
			SCREEN_UV
			+ vec2(0.0, -thickness),
			INV_PROJECTION_MATRIX
		)
		- center_depth
	);

	float border_rt = abs(
		depth_vs(
			SCREEN_UV
			+ vec2(thickness, thickness),
			INV_PROJECTION_MATRIX
		)
		- center_depth
	);

	float border_rb = abs(
		depth_vs(
			SCREEN_UV
			+ vec2(thickness, -thickness),
			INV_PROJECTION_MATRIX
		)
		- center_depth
	);

	float border_lt = abs(
		depth_vs(
			SCREEN_UV
			+ vec2(-thickness, thickness),
			INV_PROJECTION_MATRIX
		)
		- center_depth
	);

	float border_lb = abs(
		depth_vs(
			SCREEN_UV
			+ vec2(-thickness, -thickness),
			INV_PROJECTION_MATRIX
		)
		- center_depth
	);

	float depth_difference = max(
		max(
			max(border_r, border_l),
			max(border_t, border_b)
		),
		max(
			max(border_rt, border_rb),
			max(border_lt, border_lb)
		)
	);

	float outline = smoothstep(
		step_threshold,
		step_threshold
		+ 0.02,
		depth_difference
		* sensitivity
	);

	ALBEDO = outline_color;
	ALPHA = outline;
}
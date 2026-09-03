shader_type spatial;

render_mode cull_disabled;
render_mode diffuse_burley;
render_mode specular_disabled;

uniform sampler2D rope_texture : source_color, repeat_enable;
uniform vec4 rope_color : source_color = vec4(
	0.92,
	0.92,
	0.92,
	1.0
);

uniform float texture_scale = 2.0;
uniform float triplanar_sharpness = 4.0;
uniform float roughness_value = 0.78;

varying vec3 rope_world_position;
varying vec3 rope_world_normal;


void vertex() {
	rope_world_position = (
		MODEL_MATRIX
		* vec4(VERTEX, 1.0)
	).xyz;

	rope_world_normal = normalize(
		(
			MODEL_MATRIX
			* vec4(NORMAL, 0.0)
		).xyz
	);
}


void fragment() {
	vec3 normal_weights = pow(
		abs(
			normalize(
				rope_world_normal
			)
		),
		vec3(triplanar_sharpness)
	);

	normal_weights /= max(
		normal_weights.x
		+ normal_weights.y
		+ normal_weights.z,
		0.0001
	);

	vec3 scaled_position = (
		rope_world_position
		* texture_scale
	);

	vec3 x_projection = texture(
		rope_texture,
		scaled_position.zy
	).rgb;

	vec3 y_projection = texture(
		rope_texture,
		scaled_position.xz
	).rgb;

	vec3 z_projection = texture(
		rope_texture,
		scaled_position.xy
	).rgb;

	vec3 triplanar_color = (
		x_projection
		* normal_weights.x
		+ y_projection
		* normal_weights.y
		+ z_projection
		* normal_weights.z
	);

	ALBEDO = (
		triplanar_color
		* rope_color.rgb
	);

	ROUGHNESS = roughness_value;
}
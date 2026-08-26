shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;

uniform float panini_distance : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float crop_to_fit : hint_range(0.5, 2.0, 0.01) = 1.0;

vec2 panini_project(vec2 view_position, float distance) {
	float view_distance: float = 1.0 + distance;

	float view_hypotenuse_squared: float = (
		view_position.x * view_position.x
		+ view_distance * view_distance
	);

	float intersection_distance: float = (
		view_position.x * distance
	);

	float discriminant: float = max(
		view_hypotenuse_squared
		- intersection_distance * intersection_distance,
		0.0
	);

	float cylinder_distance_minus_distance: float = (
		(
			-intersection_distance * view_position.x
			+ view_distance * sqrt(discriminant)
		)
		/ view_hypotenuse_squared
	);

	float cylinder_distance: float = (
		cylinder_distance_minus_distance + distance
	);

	vec2 cylinder_position: vec2 = (
		view_position
		* (cylinder_distance / view_distance)
	);

	return cylinder_position / max(
		cylinder_distance - distance,
		0.0001
	);
}

void fragment() {
	vec2 viewport_size: vec2 = 1.0 / SCREEN_PIXEL_SIZE;
	float aspect_ratio: float = (
		viewport_size.x / viewport_size.y
	);

	vec2 output_ndc: vec2 = (
		SCREEN_UV * 2.0 - 1.0
	);

	vec2 projection_scale: vec2 = (
		vec2(aspect_ratio, 1.0)
		* crop_to_fit
	);

	vec2 view_position: vec2 = (
		output_ndc * projection_scale
	);

	vec2 source_position: vec2 = panini_project(
		view_position,
		panini_distance
	);

	vec2 source_ndc: vec2 = (
		source_position / projection_scale
	);

	vec2 source_uv: vec2 = (
		source_ndc * 0.5 + 0.5
	);

	COLOR = texture(screen_texture, source_uv);
}
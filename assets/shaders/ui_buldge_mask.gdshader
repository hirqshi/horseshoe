shader_type canvas_item;
render_mode unshaded;

uniform float intensity : hint_range(0.0, 1.0, 0.01) = 1.0;

uniform float bulge_amount : hint_range(-1.0, 1.0, 0.01) = 0.18;
uniform float bulge_radius : hint_range(0.05, 2.0, 0.01) = 0.85;
uniform float edge_softness : hint_range(0.0, 1.0, 0.01) = 0.25;

uniform float alpha_cutoff : hint_range(0.0, 0.5, 0.001) = 0.002;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);

	float radius = length(centered_uv);
	float radius_normalized = radius / bulge_radius;

	float bulge_mask = 1.0 - smoothstep(
		0.0,
		1.0,
		radius_normalized
	);

	float distortion = (
		bulge_amount
		* bulge_mask
		* bulge_mask
		* intensity
	);

	vec2 distorted_uv = (
		vec2(0.5)
		+ centered_uv
		* (
			1.0
			- distortion
		)
	);

	vec2 clamped_uv = clamp(
		distorted_uv,
		vec2(0.0),
		vec2(1.0)
	);

	vec4 source = texture(
		TEXTURE,
		clamped_uv
	);

	float alpha = source.a * COLOR.a;

	if (alpha <= alpha_cutoff) {
		discard;
	}

	vec3 final_color = source.rgb * COLOR.rgb;

	COLOR = vec4(
		final_color,
		alpha
	);
}
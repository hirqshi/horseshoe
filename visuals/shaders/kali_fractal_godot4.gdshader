shader_type canvas_item;

// Port of Kali fractal (kaliset-style 2D fractal)
// Original Shadertoy source unattributed in snippet - kaliset technique

uniform float zoom_amount : hint_range(0.1, 10.0) = 3.0;
uniform float scale_amount : hint_range(0.01, 1.0) = 0.1;
uniform int max_iterations : hint_range(1, 200) = 63;

vec2 kali_func(vec2 v) {
	float x = abs(v.x);
	float y = abs(v.y);
	float m = x * x + y * y;
	x = x / m;
	y = y / m;
	return vec2(x, y);
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = (FRAGCOORD.xy - resolution * 0.5) / resolution.y;
	uv *= zoom_amount;

	vec2 center = -vec2(
		2.0 * abs(sin(0.2 * TIME + 1.0)) - 0.2,
		3.0 * abs(cos(0.3 * TIME + 2.0)) - 0.2
	);

	int count = max_iterations;
	vec2 v = uv;
	for (int i = 0; i < max_iterations; i++) {
		v = center + kali_func(v);
		if (dot(v, v) > 10.0) {
			count = i;
			break;
		}
	}

	COLOR = vec4(vec3(float(count) * scale_amount), 1.0);
}

shader_type canvas_item;

// Port of domain-warping plasma, twigl variant with exposed params
// Adapted from https://twigl.app/?ol=true&ss=-NNIajM4aEzy75lqtAUd

uniform float detail_count : hint_range(1.0, 40.0) = 20.0;
uniform float time_speed : hint_range(0.0, 8.0) = 2.0;
uniform float brightness : hint_range(0.0, 1.0) = 0.2;
uniform float structure_smoothness : hint_range(1.0, 2.0) = 1.2;
uniform float saturation : hint_range(0.0, 1.0) = 0.2;
uniform float pan_angle : hint_range(0.0, 6.283) = 5.0;
uniform float pan_speed_offset : hint_range(-1.0, 1.0) = 0.01;

mat2 rotate2d(float r) {
	return mat2(vec2(cos(r), sin(r)), vec2(-sin(r), cos(r)));
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = (FRAGCOORD.xy - 0.5 * resolution) / resolution.y;
	float dist_squared = dot(p, p);
	float s = 9.0;
	mat2 m = rotate2d(pan_angle + sin(TIME) * pan_speed_offset);

	float a = 0.0;
	vec2 n = vec2(0.0);
	vec2 q = vec2(0.0);

	for (float j = 0.0; j < detail_count; j += 1.0) {
		p *= m;
		n *= m;
		q = p * s + TIME * time_speed + sin(TIME * time_speed - dist_squared * 6.0) * 0.8 + j + n;
		a += dot(cos(q) / s, vec2(saturation));
		n -= sin(q);
		s *= structure_smoothness;
	}

	float result = 0.2 * ((a + brightness) + a + a);
	COLOR = vec4(vec3(result), 1.0);
}

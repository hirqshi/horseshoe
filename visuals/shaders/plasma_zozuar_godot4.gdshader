shader_type canvas_item;

// Port of domain-warping plasma (zozuar twitter technique)
// https://twitter.com/zozuar/status/1621229990267310081

uniform float detail_count : hint_range(1.0, 40.0) = 20.0;
uniform float time_speed : hint_range(0.0, 8.0) = 4.0;
uniform float scale_start : hint_range(1.0, 30.0) = 12.0;
uniform float scale_growth : hint_range(1.0, 2.0) = 1.2;
uniform vec3 tint_color : source_color = vec3(4.0, 2.0, 1.0);

mat2 rotate2d(float r) {
	return mat2(vec2(cos(r), sin(r)), vec2(-sin(r), cos(r)));
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = (FRAGCOORD.xy - 0.5 * resolution) / resolution.y;
	float t = TIME;

	vec2 n = vec2(0.0);
	vec2 q = vec2(0.0);
	vec2 p = uv;
	float d = dot(p, p);
	float scale = scale_start;
	float a = 0.0;
	mat2 m = rotate2d(5.0);

	for (float j = 0.0; j < detail_count; j += 1.0) {
		p *= m;
		n *= m;
		q = p * scale + t * time_speed + sin(t * time_speed - d * 6.0) * 0.8 + j + n;
		a += dot(cos(q) / scale, vec2(0.2));
		n -= sin(q);
		scale *= scale_growth;
	}

	vec3 col = tint_color * (a + 0.2) + a + a - d;
	COLOR = vec4(col, 1.0);
}

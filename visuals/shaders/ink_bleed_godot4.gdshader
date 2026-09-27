shader_type canvas_item;

// Port of ink bleed / Rorschach blot shader
// Simplex 3D noise by Ian McEwan, Ashima Arts
// Original technique by David Gallardo (xjorma), 2020
// License: CC BY-NC-SA 3.0

uniform int octave_count : hint_range(1, 8) = 7;
uniform float time_speed : hint_range(0.0, 0.5) = 0.05;
uniform float grain_amount : hint_range(0.0, 0.2) = 0.05;
uniform vec3 ink_color_1 : source_color = vec3(0.109804, 0.109804, 0.156863);
uniform vec3 ink_color_2 : source_color = vec3(1.000000, 0.266667, 0.090196);
uniform vec3 paper_color : source_color = vec3(0.988235, 0.909804, 0.882353);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;

vec4 permute(vec4 x) { return mod(((x * 34.0) + 1.0) * x, 289.0); }
vec4 taylor_inv_sqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) {
	const vec2 c = vec2(1.0 / 6.0, 1.0 / 3.0);
	const vec4 d = vec4(0.0, 0.5, 1.0, 2.0);

	vec3 i = floor(v + dot(v, c.yyy));
	vec3 x0 = v - i + dot(i, c.xxx);

	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min(g.xyz, l.zxy);
	vec3 i2 = max(g.xyz, l.zxy);

	vec3 x1 = x0 - i1 + 1.0 * c.xxx;
	vec3 x2 = x0 - i2 + 2.0 * c.xxx;
	vec3 x3 = x0 - 1.0 + 3.0 * c.xxx;

	i = mod(i, 289.0);
	vec4 p = permute(permute(permute(
		i.z + vec4(0.0, i1.z, i2.z, 1.0))
		+ i.y + vec4(0.0, i1.y, i2.y, 1.0))
		+ i.x + vec4(0.0, i1.x, i2.x, 1.0));

	float n_ = 1.0 / 7.0;
	vec3 ns = n_ * d.wyz - d.xzx;

	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_);

	vec4 x = x_ * ns.x + ns.yyyy;
	vec4 y = y_ * ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);

	vec4 b0 = vec4(x.xy, y.xy);
	vec4 b1 = vec4(x.zw, y.zw);

	vec4 s0 = floor(b0) * 2.0 + 1.0;
	vec4 s1 = floor(b1) * 2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));

	vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
	vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

	vec3 p0 = vec3(a0.xy, h.x);
	vec3 p1 = vec3(a0.zw, h.y);
	vec3 p2 = vec3(a1.xy, h.z);
	vec3 p3 = vec3(a1.zw, h.w);

	vec4 norm = taylor_inv_sqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;

	vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
	m = m * m;
	return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

float fbm(vec3 p, int octave_num) {
	float acc = 0.0;
	float amp = 0.5;
	for (int i = 0; i < octave_num; i++) {
		acc += snoise(p) * amp;
		p = p * 2.0;
		amp *= 0.5;
	}
	return acc;
}

float hash21(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(532.1231, 1378.3453))) * 53211.1223);
}

vec3 vignette(vec3 color, vec2 q, float v) {
	color *= 0.3 + 0.8 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), v);
	return color;
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = (2.0 * FRAGCOORD.xy - resolution) / resolution.y;
	vec2 sp = p;
	sp.x = abs(sp.x);

	vec3 col = paper_color;
	col += hash21(p) * grain_amount;

	float i1 = smoothstep(0.03, 0.0, fbm(vec3(sp, TIME * time_speed + 30.0), octave_count) - 0.2 + length(p) * 0.5);
	float i2 = smoothstep(0.03, 0.0, fbm(vec3(sp, TIME * time_speed * 0.8 + 16.0), octave_count) + length(p) * 0.5);

	col = mix(col, ink_color_2, i2 * (0.4 + 0.6 * fbm(vec3(p * 0.75, TIME * time_speed * 0.8 + 256.0), 5)));
	col = mix(col, ink_color_1, i1 * (0.4 + 0.6 * fbm(vec3(p * 0.75, TIME * time_speed * 0.8 + 2445.0), 5)));

	col = vignette(col, FRAGCOORD.xy / resolution, vignette_strength);

	COLOR = vec4(col, 1.0);
}
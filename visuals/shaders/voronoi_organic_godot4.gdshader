shader_type canvas_item;

// Port of voronoi3d organic pattern
// Voronoi noise from: https://github.com/MaxBittker/glsl-voronoi-noise

uniform sampler2D organic_texture;
uniform float zoom_amount : hint_range(1.0, 30.0) = 10.0;
uniform float time_speed : hint_range(0.0, 2.0) = 0.25;
uniform float organic_power : hint_range(1.0, 60.0) = 30.0;
uniform float voronoi_scale : hint_range(0.01, 1.0) = 0.1;

vec3 hash3(vec3 p) {
	return fract(
		sin(vec3(
			dot(p, vec3(1.0, 57.0, 113.0)),
			dot(p, vec3(57.0, 113.0, 1.0)),
			dot(p, vec3(113.0, 1.0, 57.0))
		)) * 43758.5453
	);
}

vec3 voronoi3d(const in vec3 x) {
	vec3 p = floor(x);
	vec3 f = fract(x);

	float id = 0.0;
	vec2 res = vec2(100.0);

	for (int k = -1; k <= 1; k++) {
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				vec3 b = vec3(float(i), float(j), float(k));
				vec3 r = vec3(b) - f + hash3(p + b);
				float d = dot(r, r);

				float cond = max(sign(res.x - d), 0.0);
				float n_cond = 1.0 - cond;

				float cond2 = n_cond * max(sign(res.y - d), 0.0);
				float n_cond2 = 1.0 - cond2;

				id = (dot(p + b, vec3(1.0, 57.0, 113.0)) * cond) + (id * n_cond);
				res = vec2(d, res.x) * cond + res * n_cond;

				res.y = cond2 * d + n_cond2 * res.y;
			}
		}
	}

	return vec3(sqrt(res), abs(id));
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = FRAGCOORD.xy / resolution;

	float organic = texture(organic_texture, uv).x;

	uv.x *= resolution.x / resolution.y;
	uv = vec2(sin(TIME * time_speed)) + uv * zoom_amount;

	vec3 voronoi = voronoi3d(vec3(TIME - 6.0, uv));
	float final_val = pow(voronoi.r * voronoi_scale, organic * organic_power) * 0.5;

	COLOR = vec4(
		final_val * (sin(TIME * 0.5) + 1.0),
		final_val * (cos(TIME + 1.0) + 1.0),
		final_val * (cos(TIME) + 1.0),
		1.0
	);
}

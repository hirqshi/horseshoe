shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D color_palette : source_color;

// === CHROMATIC ABERRATION ===
uniform float chromatic_aberration_separation : hint_range(0.0, 0.02) = 0.0;
uniform float chromatic_aberration_intensity : hint_range(0.0, 3.0) = 1.5;
uniform float chromatic_aberration_blur : hint_range(0.0, 2.0) = 0.0;

// === EDGE DETECTION ===
uniform bool edges_enabled = true;
uniform float edge_thickness : hint_range(0.5, 3.0) = 1.0;
uniform float edge_brightness_factor : hint_range(0.0, 2.0) = 1.0;
uniform float edge_contrast_boost : hint_range(1.0, 5.0) = 2.0;

// === STYLIZATION (original palette stuff) ===
uniform float palette_strength_dark : hint_range(0.0, 1.0) = 0.9;
uniform float palette_strength_light : hint_range(0.0, 1.0) = 0.2;
uniform int dark_levels : hint_range(2, 12) = 3;
uniform int light_levels : hint_range(8, 64) = 16;
uniform float darkness_threshold : hint_range(0.1, 0.6) = 0.3;
uniform float dither_amount : hint_range(0.0, 0.1) = 0.02;

// === BAYER DITHERING ===
uniform bool dithering_enabled = true;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.5;
uniform float dither_gamma : hint_range(1.0, 3.0) = 2.2;

// === INFECTION GLITCH EFFECTS ===
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float scan_line_intensity : hint_range(0.0, 1.0) = 0.0;

// === POST EFFECTS ===
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_smoothness : hint_range(0.1, 2.0) = 0.5;
uniform float grain_amount : hint_range(0.0, 0.2) = 0.05;

// === BAYER MATRIX 4x4 ===
const mat4 bayerMatrix = mat4(
	vec4(0.0/16.0, 12.0/16.0, 3.0/16.0, 15.0/16.0),
	vec4(8.0/16.0, 4.0/16.0, 11.0/16.0, 7.0/16.0),
	vec4(2.0/16.0, 14.0/16.0, 1.0/16.0, 13.0/16.0),
	vec4(10.0/16.0, 6.0/16.0, 9.0/16.0, 5.0/16.0)
);

// Simple fast random (original)
float rand(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Luminance
float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

// Glitch displacement
vec2 glitch_offset(vec2 uv, float time) {
	float block = floor(uv.y * 20.0 + time * 10.0);
	float noise = rand(vec2(block, time));
	float offset = step(0.95, noise) * (noise - 0.5) * glitch_intensity * 0.05;
	return vec2(offset, 0.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// === 1. GLITCH DISPLACEMENT ===
	if (glitch_intensity > 0.0) {
		uv += glitch_offset(uv, TIME);
	}

	// === 2. CHROMATIC ABERRATION ===
	vec3 color;
	if (chromatic_aberration_separation > 0.0) {
		float dist_from_center = distance(uv, vec2(0.5));
		float strength = chromatic_aberration_separation * dist_from_center;

		vec2 uv_r = (uv - vec2(0.5)) * (1.0 + strength) + vec2(0.5);
		vec2 uv_b = (uv - vec2(0.5)) * (1.0 - strength) + vec2(0.5);

		float red = textureLod(SCREEN_TEXTURE, uv_r, chromatic_aberration_blur).r;
		float green = textureLod(SCREEN_TEXTURE, uv, chromatic_aberration_blur).g;
		float blue = textureLod(SCREEN_TEXTURE, uv_b, chromatic_aberration_blur).b;

		color = vec3(red, green, blue);
	} else {
		color = texture(SCREEN_TEXTURE, uv).rgb;
	}

	// === 3. EDGE DETECTION (Sobel) ===
	if (edges_enabled) {
		vec2 offset = SCREEN_PIXEL_SIZE * edge_thickness;

		float tl = luminance(texture(SCREEN_TEXTURE, uv + vec2(-offset.x, -offset.y)).rgb);
		float t  = luminance(texture(SCREEN_TEXTURE, uv + vec2(0.0, -offset.y)).rgb);
		float tr = luminance(texture(SCREEN_TEXTURE, uv + vec2(offset.x, -offset.y)).rgb);
		float l  = luminance(texture(SCREEN_TEXTURE, uv + vec2(-offset.x, 0.0)).rgb);
		float c  = luminance(color);
		float r  = luminance(texture(SCREEN_TEXTURE, uv + vec2(offset.x, 0.0)).rgb);
		float bl = luminance(texture(SCREEN_TEXTURE, uv + vec2(-offset.x, offset.y)).rgb);
		float b  = luminance(texture(SCREEN_TEXTURE, uv + vec2(0.0, offset.y)).rgb);
		float br = luminance(texture(SCREEN_TEXTURE, uv + vec2(offset.x, offset.y)).rgb);

		float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
		float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
		float edge_strength = sqrt(gx * gx + gy * gy);

		if (edge_strength > 0.1) {
			float neighbor_avg = (tl + t + tr + l + r + bl + b + br) / 8.0;
			float contrast = abs(c - neighbor_avg);

			vec3 edge_color;
			if (contrast > 0.2) {
				if (c > neighbor_avg) {
					edge_color = vec3(1.0) * edge_brightness_factor;
				} else {
					edge_color = vec3(0.0);
				}
			} else {
				edge_color = vec3(c) * edge_brightness_factor;
			}

			float edge_factor = clamp(edge_strength * edge_contrast_boost, 0.0, 1.0);
			color = mix(color, edge_color, edge_factor);
		}
	}

	// === 4. SCAN LINES (infection effect) ===
	if (scan_line_intensity > 0.0) {
		float scan = sin(uv.y * 800.0 + TIME * 10.0) * 0.5 + 0.5;
		color *= mix(1.0, scan, scan_line_intensity * 0.3);
	}

	// === 5. PALETTE + POSTERIZATION ===
	float lum = luminance(color);

	// Posterization levels
	int levels = int(mix(
		float(dark_levels),
		float(light_levels),
		smoothstep(darkness_threshold * 0.5, darkness_threshold * 1.5, lum)
	));

	// Palette influence
	float palette_influence = mix(
		palette_strength_dark,
		palette_strength_light,
		smoothstep(darkness_threshold * 0.8, darkness_threshold * 1.2, lum)
	);

	// Posterize with original dither
	vec3 posterized = color;
	if (levels > 1) {
		float dither = (rand(uv + TIME * 0.001) * 2.0 - 1.0) * dither_amount;
		posterized = floor(color * float(levels) + dither) / float(levels);
	}

	// Palette color
	vec3 palette_color = texture(color_palette, vec2(lum, 0.0)).rgb;

	// Mix posterized + palette
	vec3 result = mix(
		color,
		posterized,
		smoothstep(0.3, 0.7, lum)
	);

	result = mix(
		result,
		palette_color,
		palette_influence * (1.0 - lum)
	);

	// === 6. BAYER DITHERING (additional layer) ===
	if (dithering_enabled) {
		vec3 dithered = pow(result, vec3(dither_gamma)) - 0.004;

		int x = int(FRAGCOORD.x) % 4;
		int y = int(FRAGCOORD.y) % 4;
		float threshold = bayerMatrix[y][x];

		vec3 final_dither = vec3(
			step(threshold, dithered.r),
			step(threshold, dithered.g),
			step(threshold, dithered.b)
		);

		result = mix(result, final_dither, dither_strength);
	}

	// === 7. VIGNETTE ===
	vec2 vignette_uv = uv * 2.0 - 1.0;
	float vignette = 1.0 - dot(vignette_uv, vignette_uv);
	vignette = smoothstep(0.0, vignette_smoothness, vignette);
	vignette = mix(1.0, vignette, vignette_intensity);
	result *= vignette;

	// === 8. FILM GRAIN (original fast method) ===
	float grain = rand(uv + TIME * 0.5) * grain_amount;
	result += grain - grain_amount * 0.5;

	// === 9. FINAL CONTRAST & CLAMP ===
	result = pow(result, vec3(1.05));
	result = clamp(result, vec3(0.0), vec3(1.0));

	COLOR = vec4(result, 1.0);
}
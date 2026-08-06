shader_type spatial;
render_mode blend_mix, depth_draw_alpha_prepass, cull_disabled, unshaded;

uniform sampler2D eye_texture : source_color, filter_linear_mipmap;
uniform vec4 sclera_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 pupil_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 iris_color : source_color = vec4(0.18, 0.55, 0.85, 1.0);

void fragment() {
	vec4 tex = texture(eye_texture, UV);
	if (tex.a < 0.05) {
		discard;
	}

	float r = tex.r;
	float g = tex.g;
	float b = tex.b;
	float alpha = tex.a;
	float max_c = max(r, max(g, b));

	if (max_c < 0.20) {
		ALBEDO = vec3(0.05, 0.05, 0.05);
		ALPHA = alpha;
	} else {
		vec3 col = vec3(1.0);
		if (g > r && g > b) {
			col = mix(sclera_color.rgb, vec3(g), 0.15);
		} else if (r > g && r > b && (r - b) > 0.15) {
			col = pupil_color.rgb;
		} else if (b > g || (r > 0.35 && b > 0.35)) {
			col = iris_color.rgb;
		} else {
			col = mix(vec3(0.1), sclera_color.rgb, max_c);
		}
		ALBEDO = col;
		ALPHA = alpha;
	}
}

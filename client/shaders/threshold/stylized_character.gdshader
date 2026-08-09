// res://shaders/threshold/stylized_character.gdshader
// Tomodachi Life style character shader: Clean 2-tone diffuse + high face readability + silhouette rim
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 shadow_tint : source_color = vec4(0.82, 0.78, 0.75, 1.0);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.6;
uniform vec4 rim_tint : source_color = vec4(1.0, 0.96, 0.88, 0.4);

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = tex.rgb * albedo_color.rgb;
	ROUGHNESS = 0.8;
	METALLIC = 0.0;
	SPECULAR = 0.1;

	// Soft Character Silhouette Rim
	float rim = 1.0 - max(0.0, dot(NORMAL, VIEW));
	rim = smoothstep(rim_threshold, 0.95, rim);
	EMISSION = rim_tint.rgb * rim * rim_tint.a;
}

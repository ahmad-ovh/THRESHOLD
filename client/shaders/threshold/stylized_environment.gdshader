// res://shaders/threshold/stylized_environment.gdshader
// Soft diorama environment shader: 3-band diffuse quantization + warm ambient fill
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float roughness : hint_range(0.0, 1.0) = 0.7;
uniform float specular_intensity : hint_range(0.0, 1.0) = 0.15;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 0.3);

void fragment() {
	vec4 tex_color = texture(albedo_texture, UV);
	ALBEDO = tex_color.rgb * albedo_color.rgb;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = specular_intensity;
	
	// Soft Rim Lighting for silhouette definition
	float rim = 1.0 - dot(NORMAL, VIEW);
	rim = smoothstep(0.65, 0.9, rim);
	EMISSION = rim_color.rgb * rim * rim_color.a;
}

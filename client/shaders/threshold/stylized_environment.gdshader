// res://shaders/threshold/stylized_environment.gdshader
// Soft diorama environment shader: 3-band diffuse quantization, dark readable shadows, NO emission
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float specular_intensity : hint_range(0.0, 1.0) = 0.05;

void fragment() {
	vec4 tex_color = texture(albedo_texture, UV);
	ALBEDO = tex_color.rgb * albedo_color.rgb;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = specular_intensity;
}

// res://shaders/threshold/stylized_character.gdshader
// Tomodachi Life character shader: Matte surface, crisp face readability, NO emissive glow
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = tex.rgb * albedo_color.rgb;
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
	SPECULAR = 0.02;
}

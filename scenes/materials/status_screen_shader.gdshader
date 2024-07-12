shader_type spatial;
render_mode unshaded;

uniform sampler2D albedo_texture : source_color;


void fragment() {
	vec4 albedo_t = texture(albedo_texture, UV);
	ALBEDO = albedo_t.rgb;
	ALPHA = albedo_t.a;
}
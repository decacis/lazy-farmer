shader_type spatial;
render_mode depth_test_disabled, unshaded, cull_disabled;

uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

varying float dist;

void vertex() {
	// needs to be 1.0
	VERTEX *= 1.0;
	// needs to be 1.0
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}

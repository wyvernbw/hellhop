shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D color_ramp;

void fragment() {
	vec4 tint = texture(color_ramp, UV);
	ALBEDO *= tint.rgb;
}

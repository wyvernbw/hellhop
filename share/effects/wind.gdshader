shader_type spatial;
render_mode cull_front, unshaded;

uniform sampler2D tex;
uniform float threshold: hint_range(0.0, 1.0, 0.02);
uniform float threshold_min: hint_range(0.0, 1.0, 0.02);
uniform float speed: hint_range(0.0, 0.2, 0.05);

void fragment() {
	float value = texture(tex, vec2(UV.x, TIME * speed)).r * (UV.y + 0.3);
	float edge = max(threshold, threshold_min);
	value = smoothstep(edge, edge, value);
	ALBEDO = vec3(value);
	ALPHA = value;
}

void light() {
	DIFFUSE_LIGHT = vec3(1.0);
}
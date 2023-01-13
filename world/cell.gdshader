shader_type spatial;
render_mode diffuse_toon;

uniform sampler2D tonemap;
uniform float threshold: hint_range(0.0, 1.0, 0.1);

void fragment() {

}

void light() {
	vec3 light_value = dot(NORMAL, LIGHT) * ATTENUATION * ALBEDO;
	DIFFUSE_LIGHT = step(threshold, light_value);
}

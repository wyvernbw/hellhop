shader_type canvas_item;

uniform vec4 color: source_color;
uniform float tint_amount: hint_range(0.0, 1.0, 0.1);
uniform float blur_amount: hint_range(0.0, 10.0, 0.1);

void fragment() {
	vec4 sample = texture(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
	COLOR = mix(sample, color, tint_amount);
}

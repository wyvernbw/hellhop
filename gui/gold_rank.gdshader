shader_type canvas_item;

uniform sampler2D color_ramp;

void fragment() {
	vec4 tint = texture(color_ramp, UV);
	
	vec4 color = texture(TEXTURE, UV);
	COLOR = tint * color.a * color;

}

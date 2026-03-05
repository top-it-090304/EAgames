shader_type canvas_item;

uniform float intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	COLOR.rgb = color.rgb * intensity;
	COLOR.a = color.a;
}
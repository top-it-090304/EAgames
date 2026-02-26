shader_type canvas_item;

uniform sampler2D mask_texture;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	// В Godot текстуры вьюпортов перевернуты по вертикали
	vec2 mask_uv = vec2(UV.x, 1.0 - UV.y);
	float mask_alpha = texture(mask_texture, mask_uv).a;
	
	// Стираем: где нарисована маска, там прозрачность 0
	color.a *= (1.0 - mask_alpha);
	COLOR = color;
}
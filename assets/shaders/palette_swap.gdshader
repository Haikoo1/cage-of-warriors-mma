// Troca de paleta das camadas de sprite (criador de visual). As camadas saem do pipeline com cores EXATAS
// da paleta de origem; cada cor de origem é substituída pela cor escolhida (pele, cabelo, calção, luvas).
shader_type canvas_item;

uniform vec3 src_colors[40];
uniform vec3 dst_colors[40];
uniform int color_count = 0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	for (int i = 0; i < 40; i++) {
		if (i >= color_count) {
			break;
		}
		if (distance(c.rgb, src_colors[i]) < 0.02) {
			c.rgb = dst_colors[i];
			break;
		}
	}
	COLOR = c * COLOR;
}

// Troca de paleta das camadas de sprite (criador de visual, D-019). As camadas saem do pipeline com cores EXATAS
// da paleta de origem; cada cor de origem é substituída pela cor escolhida (pele, cabelo, calção, luvas).
// Atenção (medido na Godot 4.7): em fragment() o COLOR de entrada já é textura × modulate; não multiplicar
// a textura de novo. vec4 (e não vec3) nos arrays: arrays de vec3 em uniform ficam desalinhados (std140).
shader_type canvas_item;

uniform vec4 src_colors[40];
uniform vec4 dst_colors[40];
uniform int color_count = 0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float best = 0.02;
	vec3 out_rgb = c.rgb;
	for (int i = 0; i < 40; i++) {
		if (i >= color_count) {
			break;
		}
		float d = distance(c.rgb, src_colors[i].rgb);
		if (d < best) {
			best = d;
			out_rgb = dst_colors[i].rgb;
		}
	}
	COLOR = vec4(out_rgb, c.a);
}

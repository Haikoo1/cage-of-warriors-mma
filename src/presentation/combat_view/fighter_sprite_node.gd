class_name FighterSpriteNode
extends Node2D
## Desenha um lutador em camadas (corpo + cabelo + barba) com troca de paleta pela aparência dele.
## Um nó por lutador porque cada um precisa do próprio material (cores próprias).

const SHADER: Shader = preload("res://assets/shaders/palette_swap.gdshader")

var sprites: SpriteSet
var appearance: Appearance
var anim: String = "guard"
var index: int = 0
var flip: float = 1.0
var scale_px: float = 1.0
var cut: int = 0


func configure(sprite_set: SpriteSet, look: Appearance) -> void:
	sprites = sprite_set
	appearance = look
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = SHADER
	var pairs: Array = look.palette_pairs(sprites.palette, sprites.far_darken)
	var src: PackedVector3Array = []
	var dst: PackedVector3Array = []
	for k: int in (pairs[0] as PackedColorArray).size():
		var a: Color = pairs[0][k]
		var b: Color = pairs[1][k]
		src.append(Vector3(a.r, a.g, a.b))
		dst.append(Vector3(b.r, b.g, b.b))
	mat.set_shader_parameter("src_colors", src)
	mat.set_shader_parameter("dst_colors", dst)
	mat.set_shader_parameter("color_count", src.size())
	material = mat


func present(base: Vector2, pick: Array, facing: float, scale_factor: float, cut_level: int) -> void:
	position = base
	anim = pick[0]
	index = pick[1]
	flip = facing
	scale_px = scale_factor
	cut = cut_level
	queue_redraw()


func _draw() -> void:
	if sprites == null or not sprites.textures.has(anim):
		return
	var size: Vector2 = Vector2(sprites.frame_size)
	var src: Rect2 = Rect2(Vector2(size.x * index, 0), size)
	var dest: Rect2 = Rect2(-sprites.anchor, size)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(flip * scale_px, scale_px))
	draw_texture_rect_region(sprites.textures[anim], dest, src)
	if appearance != null and appearance.hair_style > 0:
		var hair: Texture2D = sprites.hair_layer(appearance.hair_style, anim)
		if hair != null:
			draw_texture_rect_region(hair, dest, src)
	if appearance != null and appearance.beard:
		var beard: Texture2D = sprites.beard_layer(anim)
		if beard != null:
			draw_texture_rect_region(beard, dest, src)
	draw_set_transform(Vector2.ZERO)
	if cut > 0 and Settings.store.show_blood:
		var head: Vector2 = Vector2(flip * 6, -sprites.anchor.y * scale_px + 22 * scale_px)
		for k: int in cut * 2:
			draw_rect(Rect2(roundf(head.x + k % 3 - 1), roundf(head.y + k * 2), 1, 2), Color(0.6, 0.02, 0.03))

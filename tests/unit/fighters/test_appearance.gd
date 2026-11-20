extends TestCase
## Criador de visual (CHARACTER §8, P-004): aparência por camadas + troca de paleta.


func test_round_trip_and_defaults() -> void:
	var a: Appearance = Appearance.new()
	a.skin = 5
	a.hair_style = 2
	a.hair_color = 3
	a.beard = 3
	a.build = 2
	a.shorts = 6
	a.gloves = 1
	var copy: Appearance = Appearance.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	assert_eq(copy.to_dict(), a.to_dict())
	assert_eq(Appearance.from_dict({}).to_dict(), Appearance.new().to_dict(), "padrões")


func test_random_appearance_stays_in_range() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for k: int in 50:
		rng.seed = k
		var a: Appearance = Appearance.random(rng, k % 2 == 0)
		assert_true(a.skin >= 0 and a.skin < Appearance.SKIN_TONES.size(), "pele")
		assert_true(a.hair_style >= 0 and a.hair_style < Appearance.HAIR_STYLE_NAMES.size(), "cabelo")
		assert_true(a.build >= 0 and a.build < Appearance.BUILD_NAMES.size(), "físico")
		assert_true(a.beard >= 0 and a.beard < Appearance.BEARD_NAMES.size(), "barba")
		assert_true(a.shorts >= 0 and a.shorts < Appearance.SHORTS_COLORS.size(), "calção")
		if k % 2 == 1:
			assert_eq(a.beard, 0, "lutadoras sem barba")


func test_palette_pairs_map_every_source_tone() -> void:
	var palette: Dictionary = {}
	for mat: String in ["skin", "hair", "shorts", "glove", "accent"]:
		var ramp: Array = []
		for k: int in 6:
			ramp.append([0.1 * k, 0.05 * k, 0.02 * k])
		palette[mat] = ramp
	var a: Appearance = Appearance.new()
	a.skin = 6
	var pairs: Array = a.palette_pairs(palette, 1.0)
	var src: PackedColorArray = pairs[0]
	var dst: PackedColorArray = pairs[1]
	assert_eq(src.size(), 30, "5 materiais x 6 tons (sem variante de lado longe)")
	assert_eq(src.size(), dst.size())
	assert_true(dst[0].r < dst[5].r, "rampa de destino vai do escuro ao claro")
	assert_eq(a.palette_pairs(palette, 0.72)[0].size(), 60, "com lado longe: o dobro")


func test_fighters_carry_appearance_through_save_and_snapshot() -> void:
	var f: FighterState = FighterState.create_blank(&"F-1", 50.0)
	f.appearance.hair_style = 3
	var copy: FighterState = FighterState.from_dict(JSON.parse_string(JSON.stringify(f.to_dict())))
	assert_eq(copy.appearance.hair_style, 3)
	assert_eq(FighterSnapshot.from_fighter(f).appearance.hair_style, 3)


func test_sprite_layers_exist_for_every_animation() -> void:
	var s: SpriteSet = SpriteSet.load_biotype("res://assets/sprites/fighters/m_medium", "m_medium")
	for anim: String in s.textures:
		for style: int in range(1, Appearance.HAIR_STYLE_NAMES.size()):
			assert_true(s.hair_layer(style, anim) != null, "cabelo %d em %s" % [style, anim])
		for b: int in range(1, Appearance.BEARD_NAMES.size()):
			assert_true(s.beard_layer(b, anim) != null, "barba %d em %s" % [b, anim])
		for build: int in Appearance.BUILD_NAMES.size():
			assert_true(s.body_layer(build, anim) != null, "físico %d em %s" % [build, anim])
	assert_false(s.palette.is_empty(), "paleta de origem no JSON")


func test_sprite_family_by_biotype() -> void:
	assert_eq(SpriteSet.family_for(&"f_light"), "f_medium")
	assert_eq(SpriteSet.family_for(&"f_medium"), "f_medium")
	assert_eq(SpriteSet.family_for(&"m_heavy"), "m_medium")
	assert_eq(SpriteSet.family_for(&""), "m_medium")
	var f: SpriteSet = SpriteSet.for_biotype(&"f_medium")
	assert_true(f != null, "sprites femininos gerados pelo pipeline")
	assert_true(SpriteSet.for_biotype(&"f_light") == f, "cache por família")


## Regressões medidas com janela (não reproduzíveis em headless): COLOR de entrada já contém a textura
## (multiplicar de novo escurecia tudo) e arrays de vec3 em uniform ficam desalinhados (troca de cor errada).
func test_palette_shader_avoids_known_pitfalls() -> void:
	var code: String = (load("res://assets/shaders/palette_swap.gdshader") as Shader).code
	assert_false(code.contains("* COLOR"), "não multiplicar a textura duas vezes")
	assert_false(code.contains("uniform vec3"), "arrays de cor em vec4")

extends TestCase
## Criador de visual (CHARACTER §8, P-004): aparência por camadas + troca de paleta.


func test_round_trip_and_defaults() -> void:
	var a: Appearance = Appearance.new()
	a.skin = 5
	a.hair_style = 2
	a.hair_color = 3
	a.beard = true
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
		assert_true(a.hair_style >= 0 and a.hair_style <= 3, "cabelo")
		assert_true(a.shorts >= 0 and a.shorts < Appearance.SHORTS_COLORS.size(), "calção")
		if k % 2 == 1:
			assert_false(a.beard, "lutadoras sem barba")


func test_palette_pairs_map_every_source_tone_including_far_side() -> void:
	var palette: Dictionary = {"skin": [[0.4, 0.2, 0.1], [0.6, 0.4, 0.2], [0.8, 0.5, 0.4], [0.9, 0.7, 0.6]],
		"hair": [[0.1, 0.0, 0.0], [0.2, 0.1, 0.0], [0.3, 0.2, 0.1], [0.5, 0.3, 0.2]],
		"shorts": [[0.0, 0.0, 0.3], [0.1, 0.1, 0.5], [0.1, 0.2, 0.8], [0.3, 0.4, 1.0]],
		"stripe": [[0.5, 0.5, 0.5], [0.7, 0.7, 0.7], [0.9, 0.9, 0.9], [1.0, 1.0, 1.0]],
		"glove": [[0.3, 0.0, 0.0], [0.5, 0.0, 0.0], [0.8, 0.1, 0.1], [1.0, 0.3, 0.3]]}
	var pairs: Array = Appearance.new().palette_pairs(palette, 0.72)
	var src: PackedColorArray = pairs[0]
	var dst: PackedColorArray = pairs[1]
	assert_eq(src.size(), 40, "5 materiais x 4 tons x (perto + longe)")
	assert_eq(src.size(), dst.size())
	assert_true(dst[1].r < dst[0].r or dst[0].r == 0.0, "lado longe mais escuro")


func test_fighters_carry_appearance_through_save_and_snapshot() -> void:
	var f: FighterState = FighterState.create_blank(&"F-1", 50.0)
	f.appearance.hair_style = 3
	var copy: FighterState = FighterState.from_dict(JSON.parse_string(JSON.stringify(f.to_dict())))
	assert_eq(copy.appearance.hair_style, 3)
	assert_eq(FighterSnapshot.from_fighter(f).appearance.hair_style, 3)


func test_sprite_layers_exist_for_every_animation() -> void:
	var s: SpriteSet = SpriteSet.load_biotype("res://assets/sprites/fighters/m_medium", "m_medium")
	for anim: String in s.textures:
		for style: int in [1, 2, 3]:
			assert_true(s.hair_layer(style, anim) != null, "cabelo %d em %s" % [style, anim])
		assert_true(s.beard_layer(anim) != null, "barba em %s" % anim)
	assert_false(s.palette.is_empty(), "paleta de origem no JSON")


func test_sprite_family_by_biotype() -> void:
	assert_eq(SpriteSet.family_for(&"f_light"), "f_medium")
	assert_eq(SpriteSet.family_for(&"f_medium"), "f_medium")
	assert_eq(SpriteSet.family_for(&"m_heavy"), "m_medium")
	assert_eq(SpriteSet.family_for(&""), "m_medium")
	var f: SpriteSet = SpriteSet.for_biotype(&"f_medium")
	assert_true(f != null, "sprites femininos gerados pelo pipeline")
	assert_true(SpriteSet.for_biotype(&"f_light") == f, "cache por família")

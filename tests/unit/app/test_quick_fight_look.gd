extends TestCase
## Luta Rápida usa o visual escolhido pelo jogador (D-019) e mantém o adversário com calção contrastante.


func test_player_look_is_applied_and_opponent_contrasts() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	var look: Appearance = Appearance.new()
	look.hair_style = 2
	look.shorts = 5
	var cfg: QuickFight.Config = QuickFight.build(defs, 0, 1, 1, false, 0, false, 42, look)
	assert_eq(cfg.setup.fighter_a.appearance.hair_style, 2)
	assert_eq(cfg.setup.fighter_a.appearance.shorts, 5)
	assert_true(cfg.setup.fighter_b.appearance.shorts != 5, "calção do adversário diferente do jogador")


func test_default_look_when_none_given() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	var cfg: QuickFight.Config = QuickFight.build(defs, 0, 1, 1, false, 0, false, 7)
	assert_eq(cfg.setup.fighter_a.appearance.to_dict(), Appearance.new().to_dict())
	assert_true(cfg.setup.fighter_b.appearance.shorts != 0)

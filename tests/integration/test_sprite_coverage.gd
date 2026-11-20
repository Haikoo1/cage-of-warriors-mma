extends TestCase
## Cobertura de sprites (bug relatado no M2: "às vezes o sprite não funciona" = ações sem animação).


func _sprites() -> SpriteSet:
	return SpriteSet.load_biotype("res://assets/sprites/fighters/m_medium", "m_medium")


func _fighter(action: FighterCombatState.Action) -> FighterCombatState:
	var f: FighterCombatState = FighterCombatState.new()
	f.snapshot = FighterSnapshot.from_fighter(FighterState.create_blank(&"F", 50.0))
	f.action = action
	return f


func test_every_strike_in_data_has_an_animation() -> void:
	var s: SpriteSet = _sprites()
	for id: StringName in DataLoader.load_from("res://data").strikes:
		assert_true(s.textures.has(String(id)), "sprite para o golpe %s" % id)


func test_striking_never_falls_back_to_guard() -> void:
	var s: SpriteSet = _sprites()
	for strike: StrikeDef in DataLoader.load_from("res://data").strikes.values():
		var f: FighterCombatState = _fighter(FighterCombatState.Action.STRIKE_ACTIVE)
		f.strike = strike
		f.action_frames_left = 1
		assert_eq(s.pick(f, 0)[0], String(strike.id))


func test_evasions_have_their_own_animation() -> void:
	var s: SpriteSet = _sprites()
	var expected: Dictionary = {
		FighterCombatState.Evade.SLIP: "slip", FighterCombatState.Evade.DUCK: "duck", FighterCombatState.Evade.PULL: "pull",
	}
	for ev: int in expected:
		var f: FighterCombatState = _fighter(FighterCombatState.Action.EVADING)
		f.evade = ev
		assert_eq(s.pick(f, 0)[0], expected[ev])


func test_knocked_down_fighter_uses_down_sprite() -> void:
	assert_eq(_sprites().pick(_fighter(FighterCombatState.Action.DOWN), 0)[0], "down")


func test_takedowns_use_takedown_animation_and_clinch_entry_does_not() -> void:
	var s: SpriteSet = _sprites()
	var defs: Definitions = DataLoader.load_from("res://data")
	for case: Array in [[&"double_leg", "double_leg"], [&"single_leg", "double_leg"], [&"enter_clinch", "guard"]]:
		var f: FighterCombatState = _fighter(FighterCombatState.Action.GRAPPLING)
		f.action_frames_left = 5
		var anim: String = s.pick(f, 0, defs.grapple_technique(case[0]))[0]
		assert_eq(anim, case[1], String(case[0]))


func test_grappling_positions_use_their_own_poses() -> void:
	for fam: StringName in [&"m_medium", &"f_medium"]:
		var s: SpriteSet = SpriteSet.for_biotype(fam)
		assert_eq(s.pick_grapple(&"CL", false, 0)[0], "clinch", "%s clinch" % fam)
		assert_eq(s.pick_grapple(&"CG", true, 30)[0], "clinch")
		for pos: StringName in [&"SG", &"SM", &"SL", &"SO", &"SC"]:
			assert_eq(s.pick_grapple(pos, true, 0)[0], "ground_top", "%s %s por cima" % [fam, pos])
			assert_eq(s.pick_grapple(pos, false, 0)[0], "ground_bottom", "%s %s por baixo" % [fam, pos])
		assert_true(s.pick_grapple(&"SR", true, 0).is_empty(), "SR segue em greybox")

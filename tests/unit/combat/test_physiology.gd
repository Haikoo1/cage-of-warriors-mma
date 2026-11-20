extends TestCase


func test_strike_spends_stamina_and_lowers_reserve() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 3.0)
	s.step(CombatFixture.hit(StrikeDef.Limb.LEAD_HAND), CombatFixture.idle())
	assert_true(s.fighters[0].stamina < 100.0, "Fôlego gasto")
	assert_true(s.fighters[0].reserve < 100.0, "Reserva cai com o esforço")


func test_stamina_regenerates_but_never_above_reserve() -> void:
	var s: CombatSim = CombatFixture.sim()
	var f: FighterCombatState = s.fighters[0]
	f.reserve = 70.0
	f.stamina = 40.0
	for i: int in 1200:
		s.step(CombatFixture.idle(), CombatFixture.idle())
	assert_almost(f.stamina, 70.0, 0.001, "limitado pela Reserva")


func test_low_stamina_slows_strikes() -> void:
	var fresh: CombatSim = CombatFixture.sim()
	var tired: CombatSim = CombatFixture.sim()
	tired.fighters[0].stamina = 10.0
	fresh.step(CombatFixture.hit(StrikeDef.Limb.LEAD_HAND), CombatFixture.idle())
	tired.step(CombatFixture.hit(StrikeDef.Limb.LEAD_HAND), CombatFixture.idle())
	assert_true(tired.fighters[0].action_frames_left > fresh.fighters[0].action_frames_left, "cansado prepara mais devagar")


func test_shock_ratio_maps_to_states() -> void:
	assert_eq(CombatPhysiology.shock_state_for(0.3, false), FighterCombatState.Action.IDLE)
	assert_eq(CombatPhysiology.shock_state_for(0.8, false), FighterCombatState.Action.ROCKED)
	assert_eq(CombatPhysiology.shock_state_for(1.2, false), FighterCombatState.Action.STUNNED)
	assert_eq(CombatPhysiology.shock_state_for(1.7, false), FighterCombatState.Action.DOWN)
	assert_eq(CombatPhysiology.shock_state_for(2.5, false), FighterCombatState.Action.OUT)
	assert_eq(CombatPhysiology.shock_state_for(1.1, true), FighterCombatState.Action.OUT, "golpe limpo em atordoado apaga")


func test_better_chin_raises_shock_threshold() -> void:
	var weak: CombatSim = CombatFixture.sim(50.0, 20.0)
	var strong: CombatSim = CombatFixture.sim(50.0, 90.0)
	assert_true(CombatPhysiology.shock_threshold(strong.fighters[1], strong.balance)
		> CombatPhysiology.shock_threshold(weak.fighters[1], weak.balance), "queixo maior aguenta mais")


func test_head_damage_lowers_shock_threshold() -> void:
	var s: CombatSim = CombatFixture.sim()
	var before: float = CombatPhysiology.shock_threshold(s.fighters[1], s.balance)
	s.fighters[1].acute[&"head"] = 60.0
	assert_true(CombatPhysiology.shock_threshold(s.fighters[1], s.balance) < before)


func test_body_damage_lowers_reserve() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 0.8)
	CombatFixture.run_until_resolved(s, CombatFixture.hit(StrikeDef.Limb.LEAD_HAND, true))
	assert_true(s.fighters[1].reserve < 100.0, "golpe no corpo reduz a Reserva")


func test_knockout_finishes_fight() -> void:
	var s: CombatSim = CombatFixture.sim()
	s.fighters[1].action = FighterCombatState.Action.OUT
	s.step(CombatFixture.idle(), CombatFixture.idle())
	assert_true(s.is_finished(), "luta termina com apagão")
	assert_eq(s.winner(), 0)

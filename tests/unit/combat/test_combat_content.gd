extends TestCase
## Conteúdo da 1.0 (V-009): todas as finalizações, meia-guarda e golpes no clinch.


func test_every_submission_can_finish_with_its_own_name() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	var count: int = 0
	for t: GrappleTechniqueDef in defs.grapple_techniques.values():
		if t.kind != &"submission":
			continue
		count += 1
		var s: CombatSim = CombatFixture.sim(90.0, 30.0)
		CombatFixture.set_position(s, t.from_state, 0 if t.role == &"top" else 1)
		var e: CombatEvent = CombatFixture.run_until_grapple(s, CombatFixture.grapple(t.direction))
		assert_true(e != null and e.grapple_outcome == CombatEvent.GrappleOutcome.SUCCESS, "%s encaixou" % t.id)
		for i: int in 1500:
			if s.is_finished():
				break
			s.step(CombatFixture.idle(), CombatFixture.idle())
		assert_eq(s.finish_method, &"submission", "%s finaliza" % t.id)
		assert_eq(s.build_result(&"B").method_detail, t.id, "nome da finalização no resultado")
	assert_eq(count, 6, "6 finalizações (COMBAT §4.6)")


func test_half_guard_ground_and_pound_between_guard_and_side_control() -> void:
	var dmg: Dictionary = {}
	for pos: StringName in [&"SG", &"SM", &"SL"]:
		var s: CombatSim = CombatFixture.sim()
		CombatFixture.set_position(s, pos, 0)
		s.step(CombatFixture.hit(StrikeDef.Limb.REAR_HAND), CombatFixture.idle())
		dmg[pos] = s.fighters[1].zone_damage(&"head")
	assert_true(dmg[&"SG"] < dmg[&"SM"] and dmg[&"SM"] < dmg[&"SL"], str(dmg))


func test_knees_and_elbows_in_the_clinch() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.set_position(s, &"CL", -1)
	s.step(CombatFixture.hit(StrikeDef.Limb.REAR_LEG), CombatFixture.idle())
	assert_true(s.fighters[1].zone_damage(&"body") > 0.0, "joelhada no corpo")
	for i: int in 40:
		s.step(CombatFixture.idle(), CombatFixture.idle())
	s.step(CombatFixture.hit(StrikeDef.Limb.REAR_HAND, false, true), CombatFixture.idle())
	assert_true(s.fighters[1].zone_damage(&"head") > 0.0, "cotovelada na cabeça")


func test_covering_up_in_the_clinch_blocks_elbows() -> void:
	var open: CombatSim = CombatFixture.sim()
	var covered: CombatSim = CombatFixture.sim()
	for s: CombatSim in [open, covered]:
		CombatFixture.set_position(s, &"CL", -1)
	var guard: FighterCommand = FighterCommand.new()
	guard.guard = true
	open.step(CombatFixture.hit(StrikeDef.Limb.REAR_HAND, false, true), CombatFixture.idle())
	covered.step(CombatFixture.hit(StrikeDef.Limb.REAR_HAND, false, true), guard)
	assert_true(covered.fighters[1].zone_damage(&"head") < open.fighters[1].zone_damage(&"head"), "guarda reduz")

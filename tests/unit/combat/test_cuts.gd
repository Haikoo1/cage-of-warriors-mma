extends TestCase
## Cortes e parada médica (COMBAT_DESIGN §6.4).


func test_elbows_open_cuts_over_time() -> void:
	var s: CombatSim = CombatFixture.sim(80.0, 50.0)
	CombatFixture.set_position(s, &"CL", -1)
	for i: int in 900:
		var cmd: FighterCommand = CombatFixture.hit(StrikeDef.Limb.REAR_HAND, false, true) if i % 31 == 0 else CombatFixture.idle()
		s.step(cmd, CombatFixture.idle())
		if s.fighters[1].cut > 0 or s.is_finished():
			break
	assert_true(s.fighters[1].cut > 0, "cotoveladas repetidas abrem corte")


func test_severe_cut_can_end_the_fight_at_the_break() -> void:
	var stopped: int = 0
	var continued: int = 0
	for seed: int in 30:
		var s: CombatSim = CombatFixture.sim(50.0, 50.0, seed, 1)
		s.fighters[1].cut = 3
		CombatFixture.idle_steps(s, 60)
		if s.is_finished():
			stopped += 1
			assert_eq(s.finish_method, &"tko")
			assert_eq(s.build_result(&"B").method_detail, &"doctor_stoppage")
		else:
			continued += 1
	assert_true(stopped > 0 and continued > 0, "o médico às vezes para (%d) e às vezes libera (%d)" % [stopped, continued])

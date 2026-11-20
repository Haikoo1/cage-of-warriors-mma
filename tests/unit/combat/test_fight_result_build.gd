extends TestCase


func test_knockout_result() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.idle_steps(s, 90)
	s.fighters[1].set_action(FighterCombatState.Action.OUT, 0)
	s.step(CombatFixture.idle(), CombatFixture.idle())
	var r: FightResult = s.build_result(&"B-000001")
	assert_eq(r.method, FightResult.Method.KO)
	assert_eq(r.winner, FightResult.FighterSlot.A)
	assert_eq(r.round, 1)
	assert_eq(r.time_seconds, 1)
	assert_eq(r.bout_id, &"B-000001")
	assert_true(r.medical.has("a") and r.medical.has("b"), "relatório médico")


func test_decision_result_carries_round_scorecards() -> void:
	var s: CombatSim = CombatFixture.sim(50.0, 50.0, 1, 1)
	for r: int in 3:
		CombatFixture.idle_steps(s, 60)
		if not s.is_finished():
			s.begin_next_round(CombatSim.Focus.NORMAL, CombatSim.Focus.NORMAL)
	var res: FightResult = s.build_result(&"B-1")
	assert_eq(res.scorecards.size(), 3, "3 juízes")
	assert_eq(res.scorecards[0], [30, 30], "rounds vazios: 10-10")
	assert_eq(res.method, FightResult.Method.DRAW)
	assert_eq((res.stats["rounds"] as Array).size(), 3, "placar por round")
	# JSON não distingue int de float nas estatísticas livres: exige-se estabilidade a partir da 1ª carga.
	var copy: FightResult = FightResult.from_dict(JSON.parse_string(JSON.stringify(res.to_dict())))
	var again: FightResult = FightResult.from_dict(JSON.parse_string(JSON.stringify(copy.to_dict())))
	assert_eq(again.to_dict(), copy.to_dict(), "estável após serialização")
	assert_eq(copy.scorecards, res.scorecards, "cartelas inteiras preservadas")
	assert_eq(copy.method, res.method)

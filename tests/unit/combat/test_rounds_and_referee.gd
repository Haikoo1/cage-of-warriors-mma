extends TestCase


func test_round_ends_after_round_time_and_enters_break() -> void:
	var s: CombatSim = CombatFixture.sim(50.0, 50.0, 1, 2)
	CombatFixture.idle_steps(s, 119)
	assert_eq(s.phase, CombatSim.Phase.ROUND)
	CombatFixture.idle_steps(s, 1)
	assert_eq(s.phase, CombatSim.Phase.ROUND_BREAK)
	assert_eq(s.round_scores.size(), 1, "juízes pontuaram o round")


func test_no_simulation_during_break() -> void:
	var s: CombatSim = CombatFixture.sim(50.0, 50.0, 1, 1)
	CombatFixture.idle_steps(s, 60)
	var x: float = s.fighters[0].x
	var move: FighterCommand = FighterCommand.new()
	move.move_x = 1
	s.step(move, CombatFixture.idle())
	assert_almost(s.fighters[0].x, x, 0.0001, "parado no intervalo")


func test_break_recovers_stamina_and_acute_damage_but_not_residual() -> void:
	var s: CombatSim = CombatFixture.sim(50.0, 50.0, 1, 1)
	var f: FighterCombatState = s.fighters[0]
	CombatFixture.idle_steps(s, 60)
	f.stamina = 20.0
	f.acute[&"head"] = 40.0
	f.residual[&"head"] = 10.0
	s.begin_next_round(CombatSim.Focus.NORMAL, CombatSim.Focus.NORMAL)
	assert_true(f.stamina > 20.0, "Fôlego volta")
	assert_true(f.acute[&"head"] < 40.0, "dano agudo cai")
	assert_almost(f.residual[&"head"], 10.0, 0.0001, "residual fica")
	assert_eq(s.round, 2)
	assert_eq(s.phase, CombatSim.Phase.ROUND)


func test_recover_focus_trades_damage_recovery_for_stamina() -> void:
	var normal: CombatSim = CombatFixture.sim(50.0, 50.0, 1, 1)
	var rest: CombatSim = CombatFixture.sim(50.0, 50.0, 1, 1)
	for s: CombatSim in [normal, rest]:
		CombatFixture.idle_steps(s, 60)
		s.fighters[0].reserve = 90.0
		s.fighters[0].stamina = 10.0
		s.fighters[0].acute[&"head"] = 40.0
	normal.begin_next_round(CombatSim.Focus.NORMAL, CombatSim.Focus.NORMAL)
	rest.begin_next_round(CombatSim.Focus.RECOVER, CombatSim.Focus.NORMAL)
	assert_true(rest.fighters[0].stamina > normal.fighters[0].stamina, "mais Fôlego")
	assert_true(rest.fighters[0].acute[&"head"] > normal.fighters[0].acute[&"head"], "menos recuperação de dano")


func test_fight_goes_to_decision_after_last_round() -> void:
	var s: CombatSim = CombatFixture.sim(50.0, 50.0, 1, 1)
	for r: int in 3:
		CombatFixture.idle_steps(s, 60)
		if r < 2:
			assert_eq(s.phase, CombatSim.Phase.ROUND_BREAK)
			s.begin_next_round(CombatSim.Focus.NORMAL, CombatSim.Focus.NORMAL)
	assert_true(s.is_finished(), "fim após 3 rounds")
	assert_eq(s.finish_method, &"decision")


func test_title_fight_has_five_rounds() -> void:
	var s: CombatSim = CombatFixture.sim(50.0, 50.0, 1, 1, true)
	assert_eq(s.total_rounds, 5)


func test_referee_breaks_inactive_clinch() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.set_position(s, &"CL", -1)
	CombatFixture.idle_steps(s, roundi(s.rules.clinch_inactivity_seconds * 60) + 1)
	assert_eq(s.grappling.position, &"EP")


func test_referee_stands_up_inactive_ground_fight() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.set_position(s, &"SG", 0)
	CombatFixture.idle_steps(s, roundi(s.rules.ground_inactivity_seconds * 60) + 1)
	assert_eq(s.grappling.position, &"EP")


func test_ground_and_pound_counts_as_activity() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.set_position(s, &"SG", 0)
	var limit: int = roundi(s.rules.ground_inactivity_seconds * 60)
	for i: int in limit + 30:
		var cmd: FighterCommand = CombatFixture.hit(StrikeDef.Limb.LEAD_HAND) if i % 120 == 0 else CombatFixture.idle()
		s.step(cmd, CombatFixture.idle())
	assert_eq(s.grappling.position, &"SG", "luta ativa no chão continua")


func test_tko_after_unanswered_strikes_on_defenseless_fighter() -> void:
	var s: CombatSim = CombatFixture.sim(90.0, 90.0)
	CombatFixture.set_position(s, &"SO", 0)
	for i: int in 200:
		if s.is_finished():
			break
		s.fighters[1].set_action(FighterCombatState.Action.STUNNED, 300)  # mantém sem defesa
		var cmd: FighterCommand = CombatFixture.hit(StrikeDef.Limb.REAR_HAND) if i % 25 == 0 else CombatFixture.idle()
		s.step(cmd, CombatFixture.idle())
	assert_true(s.is_finished(), "árbitro interrompeu")
	assert_eq(s.finish_method, &"tko")
	assert_eq(s.winner(), 0)


func test_covering_up_prevents_tko() -> void:
	var s: CombatSim = CombatFixture.sim(90.0, 90.0)
	CombatFixture.set_position(s, &"SO", 0)
	var cover: FighterCommand = FighterCommand.new()
	cover.guard = true
	for i: int in 200:
		var cmd: FighterCommand = CombatFixture.hit(StrikeDef.Limb.REAR_HAND) if i % 25 == 0 else CombatFixture.idle()
		s.step(cmd, cover)
	assert_false(s.is_finished(), "defesa inteligente: sem TKO")

extends TestCase

const D: Dictionary = {
	"NONE": FighterCommand.Direction.NONE, "FWD": FighterCommand.Direction.FORWARD,
	"BACK": FighterCommand.Direction.BACK, "UP": FighterCommand.Direction.UP, "DOWN": FighterCommand.Direction.DOWN,
}


func test_double_leg_succeeds_by_pressure_without_read() -> void:
	var s: CombatSim = CombatFixture.sim(80.0, 30.0)
	CombatFixture.place(s, 1.0)
	var e: CombatEvent = CombatFixture.run_until_grapple(s, CombatFixture.grapple(D["DOWN"]))
	assert_eq(e.grapple_outcome, CombatEvent.GrappleOutcome.SUCCESS)
	assert_eq(s.grappling.position, &"SG")
	assert_eq(s.grappling.top, 0, "quem derrubou fica por cima")


func test_correct_read_always_defends_even_weaker_fighter() -> void:
	var s: CombatSim = CombatFixture.sim(90.0, 20.0)
	CombatFixture.place(s, 1.0)
	s.step(CombatFixture.grapple(D["DOWN"]), CombatFixture.idle())
	for i: int in 8:  # lê depois do início da janela (não perfeita)
		s.step(CombatFixture.idle(), CombatFixture.idle())
	var e: CombatEvent = CombatFixture.run_until_grapple(s, CombatFixture.idle(), CombatFixture.direction(D["DOWN"]))
	assert_eq(e.grapple_outcome, CombatEvent.GrappleOutcome.READ)
	assert_eq(s.grappling.position, &"EP")


func test_perfect_sprawl_counters_double_leg_to_back() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 1.0)
	s.step(CombatFixture.grapple(D["DOWN"]), CombatFixture.direction(D["DOWN"]))
	var e: CombatEvent = CombatFixture.run_until_grapple(s, CombatFixture.idle())
	assert_eq(e.grapple_outcome, CombatEvent.GrappleOutcome.PERFECT_READ)
	assert_eq(s.grappling.position, &"SC")
	assert_eq(s.grappling.top, 1, "quem defendeu pega as costas")


func test_weak_attacker_fails_and_pays_more_stamina() -> void:
	var strong: CombatSim = CombatFixture.sim(90.0, 30.0)
	var weak: CombatSim = CombatFixture.sim(20.0, 90.0)
	CombatFixture.place(strong, 1.0)
	CombatFixture.place(weak, 1.0)
	CombatFixture.run_until_grapple(strong, CombatFixture.grapple(D["DOWN"]))
	var e: CombatEvent = CombatFixture.run_until_grapple(weak, CombatFixture.grapple(D["DOWN"]))
	assert_eq(e.grapple_outcome, CombatEvent.GrappleOutcome.FAIL)
	assert_eq(weak.grappling.position, &"EP")
	assert_true(weak.fighters[0].stamina < strong.fighters[0].stamina, "falha custa mais Fôlego")


func test_close_contest_gives_partial_progress_that_helps_next_try() -> void:
	var s: CombatSim = CombatFixture.sim(50.0, 55.0)
	CombatFixture.place(s, 1.0)
	var first: CombatEvent = CombatFixture.run_until_grapple(s, CombatFixture.grapple(D["DOWN"]))
	assert_eq(first.grapple_outcome, CombatEvent.GrappleOutcome.PARTIAL)
	for i: int in 30:
		s.step(CombatFixture.idle(), CombatFixture.idle())
	CombatFixture.place(s, 1.0)
	var second: CombatEvent = CombatFixture.run_until_grapple(s, CombatFixture.grapple(D["DOWN"]))
	assert_eq(second.grapple_outcome, CombatEvent.GrappleOutcome.SUCCESS, "progresso parcial acumulado")


func test_takedown_out_of_range_does_not_start() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 3.0)
	s.step(CombatFixture.grapple(D["DOWN"]), CombatFixture.idle())
	assert_eq(s.fighters[0].action, FighterCombatState.Action.IDLE)


func test_push_to_cage_requires_clinch_advantage() -> void:
	var s: CombatSim = CombatFixture.sim(80.0, 30.0)
	CombatFixture.set_position(s, &"CL", -1)
	s.step(CombatFixture.grapple(D["FWD"]), CombatFixture.idle())
	assert_eq(s.fighters[0].action, FighterCombatState.Action.IDLE, "sem vantagem não empurra")
	CombatFixture.run_until_grapple(s, CombatFixture.grapple(D["UP"]))  # pummel
	assert_eq(s.grappling.clinch_owner, 0)
	CombatFixture.run_until_grapple(s, CombatFixture.grapple(D["FWD"]))
	assert_eq(s.grappling.position, &"CG")
	assert_eq(s.grappling.top, 0)
	assert_true(s.fighters[1].is_cornered(s.balance), "prensado contra a grade")


func test_sweep_inverts_roles() -> void:
	var s: CombatSim = CombatFixture.sim(30.0, 90.0)
	CombatFixture.set_position(s, &"SG", 0)
	CombatFixture.run_until_grapple(s, CombatFixture.idle(), CombatFixture.grapple(D["UP"]))
	assert_eq(s.grappling.position, &"SG")
	assert_eq(s.grappling.top, 1, "quem estava por baixo agora está por cima")


func test_cannot_walk_or_throw_standing_strikes_on_ground() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.set_position(s, &"SG", 0)
	var x0: float = s.fighters[0].x
	var move: FighterCommand = FighterCommand.new()
	move.move_x = 1
	s.step(move, CombatFixture.idle())
	assert_almost(s.fighters[0].x, x0, 0.0001, "sem locomoção no solo")
	s.step(CombatFixture.idle(), CombatFixture.hit(StrikeDef.Limb.LEAD_HAND))
	assert_false(s.fighters[1].is_striking(), "quem está por baixo não dá jab")


func test_ground_and_pound_hits_harder_from_mount_than_guard() -> void:
	var guard: CombatSim = CombatFixture.sim()
	var mount: CombatSim = CombatFixture.sim()
	CombatFixture.set_position(guard, &"SG", 0)
	CombatFixture.set_position(mount, &"SO", 0)
	guard.step(CombatFixture.hit(StrikeDef.Limb.REAR_HAND), CombatFixture.idle())
	mount.step(CombatFixture.hit(StrikeDef.Limb.REAR_HAND), CombatFixture.idle())
	assert_true(mount.fighters[1].zone_damage(&"head") > guard.fighters[1].zone_damage(&"head"), "montada > guarda")


func test_rear_naked_choke_finishes_when_defender_never_reads() -> void:
	var s: CombatSim = CombatFixture.sim(80.0, 30.0)
	CombatFixture.set_position(s, &"SC", 0)
	var e: CombatEvent = CombatFixture.run_until_grapple(s, CombatFixture.grapple(D["DOWN"]))
	assert_eq(e.grapple_outcome, CombatEvent.GrappleOutcome.SUCCESS, "encaixou")
	assert_true(s.grappling.submission != null, "Medidor de Aperto ativo")
	for i: int in 1200:
		if s.is_finished():
			break
		s.step(CombatFixture.idle(), CombatFixture.idle())
	assert_true(s.is_finished(), "finalizou")
	assert_eq(s.winner(), 0)
	assert_eq(s.finish_method, &"submission")


func test_reading_squeeze_direction_escapes_choke() -> void:
	var s: CombatSim = CombatFixture.sim(50.0, 50.0)
	CombatFixture.set_position(s, &"SC", 0)
	CombatFixture.run_until_grapple(s, CombatFixture.grapple(D["DOWN"]))
	for i: int in 900:
		if s.grappling.submission == null:
			break
		var d: FighterCommand = CombatFixture.direction(s.grappling.submission.attacker_dir)  # sempre lê certo
		s.step(CombatFixture.idle(), d)
	assert_false(s.is_finished(), "não finalizou")
	assert_eq(s.grappling.position, &"SG", "escapou para a guarda")
	assert_eq(s.grappling.top, 1, "quem escapou ficou por cima")

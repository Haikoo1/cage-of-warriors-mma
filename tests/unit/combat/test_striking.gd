extends TestCase

const LEAD: int = StrikeDef.Limb.LEAD_HAND
const REAR_LEG: int = StrikeDef.Limb.REAR_LEG


func test_jab_in_range_lands_clean_on_head() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 0.8)
	var e: CombatEvent = CombatFixture.run_until_resolved(s, CombatFixture.hit(LEAD))
	assert_eq(e.outcome, CombatEvent.Outcome.CLEAN)
	assert_eq(e.zone, &"head")
	assert_true(s.fighters[1].zone_damage(&"head") > 0.0, "dano na cabeça")


func test_strike_out_of_reach_misses_range() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 2.0)
	var e: CombatEvent = CombatFixture.run_until_resolved(s, CombatFixture.hit(LEAD))
	assert_eq(e.outcome, CombatEvent.Outcome.MISS_RANGE)


func test_straight_strike_misses_by_depth_but_curved_lands() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 0.55, 0.45)
	assert_eq(CombatFixture.run_until_resolved(s, CombatFixture.hit(LEAD)).outcome, CombatEvent.Outcome.MISS_ANGLE, "jab erra o ângulo")
	var s2: CombatSim = CombatFixture.sim()
	CombatFixture.place(s2, 0.55, 0.45)
	assert_eq(CombatFixture.run_until_resolved(s2, CombatFixture.hit(LEAD, false, true)).outcome, CombatEvent.Outcome.CLEAN, "gancho acerta")


func test_body_modifier_targets_body() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 0.8)
	var e: CombatEvent = CombatFixture.run_until_resolved(s, CombatFixture.hit(LEAD, true))
	assert_eq(e.zone, &"body")


func test_high_guard_blocks_head_and_reduces_damage() -> void:
	var clean_sim: CombatSim = CombatFixture.sim()
	CombatFixture.place(clean_sim, 0.8)
	CombatFixture.run_until_resolved(clean_sim, CombatFixture.hit(LEAD))
	var guarded: CombatSim = CombatFixture.sim()
	CombatFixture.place(guarded, 0.8)
	var guard: FighterCommand = FighterCommand.new()
	guard.guard = true
	var e: CombatEvent = CombatFixture.run_until_resolved(guarded, CombatFixture.hit(LEAD), guard)
	assert_eq(e.outcome, CombatEvent.Outcome.BLOCKED)
	assert_true(guarded.fighters[1].zone_damage(&"head") < clean_sim.fighters[1].zone_damage(&"head"), "bloqueio reduz dano")


func test_high_guard_does_not_protect_legs() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 1.0)
	var guard: FighterCommand = FighterCommand.new()
	guard.guard = true
	var e: CombatEvent = CombatFixture.run_until_resolved(s, CombatFixture.hit(REAR_LEG), guard)
	assert_eq(e.outcome, CombatEvent.Outcome.CLEAN)
	assert_eq(e.zone, &"legs")


func test_hitting_opponent_during_startup_is_counter_and_interrupts() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 0.55)
	# B inicia um gancho lento (preparação 10); A responde com jab (preparação 6) no passo seguinte.
	s.step(CombatFixture.idle(), CombatFixture.hit(LEAD, false, true))
	var e: CombatEvent = CombatFixture.run_until_resolved(s, CombatFixture.hit(LEAD))
	assert_eq(e.outcome, CombatEvent.Outcome.COUNTER)
	assert_true(s.fighters[1].action != FighterCombatState.Action.STRIKE_ACTIVE, "golpe de B interrompido")


func test_cannot_start_new_strike_during_recovery() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 0.8)
	s.step(CombatFixture.hit(LEAD), CombatFixture.idle())
	var started: int = s.fighters[0].stats["attempts"]
	for i: int in 10:
		s.step(CombatFixture.hit(LEAD), CombatFixture.idle())
	assert_eq(s.fighters[0].stats["attempts"], started, "não reinicia durante o golpe")


func test_slip_evades_straight_strike() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 0.8)
	var slip: FighterCommand = FighterCommand.new()
	slip.technique_direction = FighterCommand.Direction.UP
	s.step(CombatFixture.hit(LEAD), slip)
	var e: CombatEvent = CombatFixture.run_until_resolved(s, CombatFixture.idle())
	assert_eq(e.outcome, CombatEvent.Outcome.EVADED)


func test_higher_speed_shortens_startup() -> void:
	var slow: CombatSim = CombatFixture.sim(20.0)
	var fast: CombatSim = CombatFixture.sim(90.0)
	CombatFixture.place(slow, 0.8)
	CombatFixture.place(fast, 0.8)
	slow.step(CombatFixture.hit(LEAD), CombatFixture.idle())
	fast.step(CombatFixture.hit(LEAD), CombatFixture.idle())
	assert_true(fast.fighters[0].action_frames_left < slow.fighters[0].action_frames_left, "rápido prepara em menos quadros")

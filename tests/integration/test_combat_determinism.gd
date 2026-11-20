extends TestCase
## Mesma semente + mesmos comandos = mesmo estado (T-013). Base do teste de replay.


func _script_commands(i: int) -> Array[FighterCommand]:
	var a: FighterCommand = FighterCommand.new()
	var b: FighterCommand = FighterCommand.new()
	a.move_x = 1 if i % 40 < 20 else 0
	if i % 25 == 0:
		a.strike_limb = StrikeDef.Limb.LEAD_HAND
	if i % 37 == 0:
		b.strike_limb = StrikeDef.Limb.REAR_LEG
	b.guard = i % 50 > 30
	return [a, b]


func _run(seed: int) -> String:
	var s: CombatSim = CombatFixture.sim(50.0, 50.0, seed)
	for i: int in 900:
		var cmds: Array[FighterCommand] = _script_commands(i)
		s.step(cmds[0], cmds[1])
	return s.state_hash()


func test_same_seed_same_result() -> void:
	assert_eq(_run(7), _run(7))


func test_long_scripted_fight_keeps_invariants() -> void:
	var s: CombatSim = CombatFixture.sim()
	for i: int in 1800:
		var cmds: Array[FighterCommand] = _script_commands(i)
		s.step(cmds[0], cmds[1])
		for f: FighterCombatState in s.fighters:
			if f.stamina < 0.0 or f.stamina > f.reserve + 0.0001:
				assert_true(false, "Fôlego fora de [0, Reserva] no passo %d" % i)
				return
	assert_true(s.fighters[0].x < s.fighters[1].x, "ordem em X preservada")

extends TestCase
## IA com as mesmas regras do jogador (REQ-07, COMBAT §9): só comandos, percepção com atraso, sem bônus.


func _ai(s: CombatSim, idx: int, arch: StringName, profile: StringName, seed: int = 1) -> CombatAI:
	return CombatAI.new(s.defs.archetype(arch), s.defs.cognitive_profile(profile), idx, seed)


func test_ai_data_is_valid() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	assert_eq(defs.archetypes.size(), 2, "2 arquétipos")
	assert_eq(defs.cognitive_profiles.size(), 3, "3 perfis")
	assert_eq(defs.validate_all().size(), 0, str(defs.validate_all()))


func test_perception_below_minimum_is_rejected() -> void:
	var p: CognitiveProfileDef = CognitiveProfileDef.new()
	p.id = &"cheater"
	p.perception_delay_ms = 50
	assert_has_error(p.validate(), "mínimo")


func test_ai_never_reads_a_takedown_before_its_perception_delay() -> void:
	var earliest: int = 999
	for seed: int in 20:
		var s: CombatSim = CombatFixture.sim(50.0, 50.0, seed)
		CombatFixture.place(s, 1.0)
		var ai: CombatAI = _ai(s, 1, &"arch_striker", &"cog_elite", seed)
		ai.observe(s)
		s.step(CombatFixture.grapple(FighterCommand.Direction.DOWN), ai.get_command(s))
		for i: int in 20:
			ai.observe(s)
			var c: FighterCommand = ai.get_command(s)
			s.step(CombatFixture.idle(), c)
			if s.grappling.pending == null:
				break
			if s.grappling.pending.read_frame >= 0:
				earliest = mini(earliest, s.grappling.pending.read_frame)
				break
	var delay: int = DataLoader.load_from("res://data").cognitive_profile(&"cog_elite").perception_delay_frames()
	assert_true(earliest >= delay - 1, "primeira leitura no quadro %d, atraso %d" % [earliest, delay])


func test_elite_defends_more_takedowns_than_beginner() -> void:
	var defended: Dictionary = {&"cog_beginner": 0, &"cog_elite": 0}
	for profile: StringName in defended.keys():
		for seed: int in 40:
			var s: CombatSim = CombatFixture.sim(50.0, 50.0, seed)
			CombatFixture.place(s, 1.0)
			var ai: CombatAI = _ai(s, 1, &"arch_striker", profile, seed)
			ai.observe(s)
			var cmd_a: FighterCommand = CombatFixture.grapple(FighterCommand.Direction.UP)  # single leg, 12 quadros
			cmd_a = CombatFixture.grapple(FighterCommand.Direction.DOWN)
			s.step(cmd_a, ai.get_command(s))
			for i: int in 30:
				ai.observe(s)
				var events: Array[CombatEvent] = s.step(CombatFixture.idle(), ai.get_command(s))
				var done: bool = false
				for e: CombatEvent in events:
					if e.type == CombatEvent.Type.GRAPPLE_RESOLVED:
						done = true
						if e.grapple_outcome == CombatEvent.GrappleOutcome.READ or e.grapple_outcome == CombatEvent.GrappleOutcome.PERFECT_READ:
							defended[profile] += 1
				if done:
					break
	assert_true(defended[&"cog_elite"] > defended[&"cog_beginner"], "elite %d > iniciante %d" % [defended[&"cog_elite"], defended[&"cog_beginner"]])


func test_striker_throws_strikes_and_wrestler_shoots_takedowns() -> void:
	var counts: Dictionary = {}
	for arch: StringName in [&"arch_striker", &"arch_wrestler"]:
		var s: CombatSim = CombatFixture.sim(60.0, 60.0, 3)
		var ai: CombatAI = _ai(s, 1, arch, &"cog_intermediate", 3)
		var strikes: int = 0
		var takedowns: int = 0
		for i: int in 1200:
			ai.observe(s)
			for e: CombatEvent in s.step(CombatFixture.idle(), ai.get_command(s)):
				if e.attacker != 1:
					continue
				if e.type == CombatEvent.Type.STRIKE_STARTED:
					strikes += 1
				if e.type == CombatEvent.Type.GRAPPLE_STARTED and (e.technique_id == &"double_leg" or e.technique_id == &"single_leg"):
					takedowns += 1
		counts[arch] = [strikes, takedowns]
	assert_true(counts[&"arch_striker"][0] > counts[&"arch_wrestler"][0], "trocador golpeia mais: %s" % str(counts))
	# Proporção do ataque (o wrestler que derruba passa o resto do tempo no chão e tenta menos quedas em número absoluto).
	var share: Callable = func(c: Array) -> float: return float(c[1]) / maxf(1.0, float(c[0] + c[1]))
	assert_true(share.call(counts[&"arch_wrestler"]) > share.call(counts[&"arch_striker"]) * 2.0, "wrestler usa mais quedas: %s" % str(counts))


func test_ai_vs_ai_full_fight_ends_with_valid_result() -> void:
	var s: CombatSim = CombatFixture.sim(60.0, 60.0, 11, 60)
	var a: CombatAI = _ai(s, 0, &"arch_striker", &"cog_intermediate", 11)
	var b: CombatAI = _ai(s, 1, &"arch_wrestler", &"cog_intermediate", 12)
	var guard: int = 0
	while not s.is_finished() and guard < 20000:
		guard += 1
		if s.phase == CombatSim.Phase.ROUND_BREAK:
			s.begin_next_round(a.choose_focus(s), b.choose_focus(s))
			continue
		a.observe(s)
		b.observe(s)
		s.step(a.get_command(s), b.get_command(s))
	assert_true(s.is_finished(), "luta terminou")
	var r: FightResult = s.build_result(&"B-AI")
	assert_true(r.round >= 1 and r.round <= 3, "round válido")
	assert_eq(FightResult.from_dict(r.to_dict()).to_dict(), r.to_dict())


func test_ai_is_deterministic_with_seed() -> void:
	var hashes: Array[String] = []
	for k: int in 2:
		var s: CombatSim = CombatFixture.sim(60.0, 60.0, 5)
		var a: CombatAI = _ai(s, 0, &"arch_striker", &"cog_elite", 21)
		var b: CombatAI = _ai(s, 1, &"arch_wrestler", &"cog_elite", 22)
		for i: int in 900:
			a.observe(s)
			b.observe(s)
			s.step(a.get_command(s), b.get_command(s))
		hashes.append(s.state_hash())
	assert_eq(hashes[0], hashes[1])

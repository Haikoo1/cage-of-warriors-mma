class_name FightResolver
extends RefCounted
## Resolvedor estatístico (CAREER_DESIGN §11.4, R-017): lutas sem rodar o motor de combate.
## Produz o mesmo FightResult do combate jogado. Fórmulas [PROV]: calibrar contra lotes IA x IA (marco M3).


static func resolve(a: FighterState, b: FighterState, rounds: int, rng: RandomNumberGenerator) -> FightResult:
	var r: FightResult = FightResult.new()
	var plan_a: Array = _edge(a, b)  # [vantagem, golpeia?]
	var plan_b: Array = _edge(b, a)
	var totals: Array = [[0, 0], [0, 0], [0, 0]]
	var head: Array[float] = [0.0, 0.0]
	var cards_rounds: Array = []
	for round: int in range(1, rounds + 1):
		var cardio: float = (_at(a, &"condicionamento") - _at(b, &"condicionamento")) / 40.0 * (round - 1)
		var d: float = (float(plan_a[0]) - float(plan_b[0])) / 8.0 + cardio + rng.randfn(0.0, 1.0)
		var w: int = 0 if d > 0.0 else 1
		var winner_plan: Array = plan_a if w == 0 else plan_b
		var loser: FighterState = b if w == 0 else a
		var striking: bool = winner_plan[1]
		head[1 - w] += absf(d) * (10.0 if striking else 4.0)
		var resist: float = _at(loser, &"queixo") if striking else _at(loser, &"defesa_finalizacao")
		var p_finish: float = clampf(0.08 + 0.09 * absf(d), 0.0, 0.45) * (1.4 - resist / 100.0)
		if rng.randf() < p_finish:
			r.winner = FightResult.FighterSlot.A if w == 0 else FightResult.FighterSlot.B
			if striking:
				r.method = FightResult.Method.KO if rng.randf() < 0.5 else FightResult.Method.TKO
			else:
				r.method = FightResult.Method.SUBMISSION if rng.randf() < 0.7 else FightResult.Method.TKO
				if r.method == FightResult.Method.SUBMISSION:
					r.method_detail = &"rear_naked_choke"
			r.round = round
			r.time_seconds = rng.randi_range(10, 299)
			break
		var cards: Array = []
		for j: int in 3:
			var dj: float = d + rng.randfn(0.0, 0.4)
			var card: Array = [10, 10] if absf(dj) < 0.15 else ([10, 8 if dj > 2.2 else 9] if dj > 0.0 else [8 if dj < -2.2 else 9, 10])
			cards.append(card)
			totals[j][0] += card[0]
			totals[j][1] += card[1]
		cards_rounds.append({"cards": cards})
		r.round = round
		r.time_seconds = 300
	if r.method == FightResult.Method.DECISION_UNANIMOUS and r.winner == FightResult.FighterSlot.NONE:
		var dec: Array = Judging.decide(totals)
		r.method = dec[0]
		r.winner = dec[1]
	r.scorecards = totals
	r.stats = {"simulated": true, "rounds": cards_rounds}
	r.medical = {"a": {"head": snappedf(head[0], 0.1)}, "b": {"head": snappedf(head[1], 0.1)}}
	return r


## Vantagem ofensiva de x contra y: melhor entre trocação e grappling (o lutador escolhe o plano).
static func _edge(x: FighterState, y: FighterState) -> Array:
	var strike: float = 0.35 * _at(x, &"boxe") + 0.35 * _at(x, &"kickboxing") + 0.15 * _at(x, &"velocidade") + 0.15 * _at(x, &"forca")
	var grapple: float = 0.4 * _at(x, &"wrestling_ofensivo") + 0.3 * _at(x, &"controle_solo") + 0.3 * _at(x, &"jiu_jitsu")
	var s_edge: float = strike - 0.5 * _at(y, &"defesa_em_pe")
	var g_edge: float = grapple - 0.6 * _at(y, &"wrestling_defensivo")
	return [maxf(s_edge, g_edge), s_edge >= g_edge]


static func _at(f: FighterState, attr: StringName) -> float:
	return float(f.attributes.get(attr, 50.0))

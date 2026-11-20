class_name ResultApplier
extends RefCounted
## Ponto de entrada ÚNICO para resultados de luta, jogada ou simulada (CAREER_ARCHITECTURE §4).
## bout = {"a", "b", "org", "title", "show", "win"} — "a" corresponde a FightResult.FighterSlot.A.


static func apply(c: CareerState, defs: Definitions, bout: Dictionary, r: FightResult) -> void:
	var bal: CareerBalanceDef = defs.career_balance if defs.career_balance != null else CareerBalanceDef.new()
	var a: FighterState = c.get_fighter(StringName(bout["a"]))
	var b: FighterState = c.get_fighter(StringName(bout["b"]))
	assert(a != b, "um lutador não pode enfrentar a si mesmo")
	if a == b:
		return
	var org: StringName = StringName(bout.get("org", a.org_id))
	var title: bool = bool(bout.get("title", false))
	var finish: bool = r.method in [FightResult.Method.KO, FightResult.Method.TKO, FightResult.Method.SUBMISSION]
	var score_a: float = 0.5
	if r.winner == FightResult.FighterSlot.A:
		score_a = 1.0
	elif r.winner == FightResult.FighterSlot.B:
		score_a = 0.0
	_record(a, b, score_a, r, c, org, title)
	_record(b, a, 1.0 - score_a, r, c, org, title)
	# Rating tipo Elo (base do ranking, CAREER §9).
	var expected: float = 1.0 / (1.0 + pow(10.0, (b.rating - a.rating) / 400.0))
	var k: float = bal.elo_k * (bal.finish_k_bonus if finish else 1.0)
	a.rating += k * (score_a - expected)
	b.rating -= k * (score_a - expected)
	# Saúde: suspensão médica, desgaste, lesão (CAREER §5.2).
	var rng: RandomNumberGenerator = CareerRng.make(c, &"fight_health", hash(bout["a"]) ^ hash(bout["b"]))
	for pair: Array in [[a, score_a, "a"], [b, 1.0 - score_a, "b"]]:
		var f: FighterState = pair[0]
		var lost: bool = float(pair[1]) < 0.5
		var weeks: int = bal.decision_suspension_weeks
		if lost and r.method == FightResult.Method.KO:
			weeks = bal.ko_suspension_weeks
			f.career_wear += bal.wear_per_ko
		elif lost and r.method == FightResult.Method.TKO:
			weeks = bal.tko_suspension_weeks
			f.career_wear += bal.wear_per_tko
		var head: float = float((r.medical.get(pair[2], {}) as Dictionary).get("head", 0.0))
		f.career_wear += head / 25.0
		f.unavailable_until = maxi(f.unavailable_until, c.week_index + weeks)
		if lost and finish and rng.randf() < 0.15:
			HealthSystem.inflict_injury(c, f, rng, true)
		f.contract_fights_left = maxi(0, f.contract_fights_left - 1)
		var pop: float = 0.0
		if float(pair[1]) > 0.5:
			pop = bal.popularity_win + (bal.popularity_finish if finish else 0.0)
		elif lost:
			pop = bal.popularity_loss
		f.popularity = clampf(f.popularity + pop * (1.5 if title else 1.0), 0.0, 100.0)
	# Cinturão.
	if title and score_a != 0.5:
		var champ: FighterState = a if score_a > 0.5 else b
		var wc: StringName = champ.weight_class_id
		var org_def: OrganizationDef = defs.organization(org)
		if c.champion(org, wc) != champ.id:
			c.set_champion(org, wc, champ.id)
			champ.titles += 1
			c.add_news("%s é o novo campeão %s do %s!" % [champ.display_name, _wc_name(defs, wc), org_def.display_name if org_def else String(org)])
	# Dinheiro do jogador (CAREER §10.2–10.3).
	var player: FighterState = c.player()
	if player == a or player == b:
		var won: bool = (player == a and score_a > 0.5) or (player == b and score_a < 0.5)
		var gross: float = float(bout.get("show", 0.0)) + (float(bout.get("win", 0.0)) if won else 0.0)
		c.money += gross * (1.0 - bal.team_cut)
		c.pending_interview = true
		var opp: FighterState = b if player == a else a
		c.add_news("%s %s %s por %s (R%d)." % [player.display_name, "vence" if won else ("empata com" if score_a == 0.5 else "perde para"),
			opp.display_name, method_name(r.method), r.round])


static func method_name(m: FightResult.Method) -> String:
	return {
		FightResult.Method.KO: "nocaute", FightResult.Method.TKO: "nocaute técnico", FightResult.Method.SUBMISSION: "finalização",
		FightResult.Method.DECISION_UNANIMOUS: "decisão unânime", FightResult.Method.DECISION_SPLIT: "decisão dividida",
		FightResult.Method.DECISION_MAJORITY: "decisão majoritária", FightResult.Method.DRAW: "empate",
	}.get(m, "decisão")


static func _record(me: FighterState, opp: FighterState, score: float, r: FightResult, c: CareerState, org: StringName, title: bool) -> void:
	var result: String = "D"
	if score > 0.5:
		me.wins += 1
		me.streak = maxi(1, me.streak + 1)
		result = "W"
	elif score < 0.5:
		me.losses += 1
		me.streak = mini(-1, me.streak - 1)
		result = "L"
	else:
		me.draws += 1
		me.streak = 0
	me.history.append({"week": c.week_index, "opponent": String(opp.id), "opponent_name": opp.display_name,
		"result": result, "method": method_name(r.method), "round": r.round, "org": String(org), "title": title})
	if me.history.size() > 60:
		me.history.pop_front()


static func _wc_name(defs: Definitions, wc: StringName) -> String:
	var d: WeightClassDef = defs.weight_class(wc)
	return d.display_key if d != null else String(wc)

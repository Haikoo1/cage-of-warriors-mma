class_name CombatSim
extends RefCounted
## Orquestra a luta em passo fixo de 60 Hz (T-004, COMBAT_ARCHITECTURE §2). Sem Nodes: testável headless.
## E-03 trocação · E-04 grappling · E-05 rounds, intervalo, árbitro, juízes e FightResult.

enum Phase { ROUND, ROUND_BREAK, FINISHED }
## Foco tático do intervalo (COMBAT §5.3): sem bônus de atributo, só troca de recuperação.
enum Focus { NORMAL, RECOVER }

var defs: Definitions
var balance: CombatBalanceDef
var rules: RuleSetDef
var weight_class: WeightClassDef
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var fighters: Array[FighterCombatState] = []
var grappling: CombatGrappling = CombatGrappling.new()
var referee: CombatReferee = CombatReferee.new()
var frame: int = 0
var phase: Phase = Phase.ROUND
var round: int = 1
var round_frame: int = 0
var total_rounds: int = 3
var round_seconds: int = 300
var round_stats: Array[Judging.FighterRoundStats] = []
## Por round: cartelas dos 3 juízes [[a, b], ...].
var round_scores: Array = []
var round_stat_history: Array = []
var fight_stats: Array = [{}, {}]
var finish_method: StringName = &""
var finish_detail: StringName = &""  # ex.: id da finalização
var decision: Array = []  # [FightResult.Method, FighterSlot] quando vai aos juízes
var _finished: bool = false
var _winner: int = -1


func _init(setup: FightSetup, definitions: Definitions) -> void:
	defs = definitions
	balance = definitions.combat_balance if definitions.combat_balance != null else CombatBalanceDef.new()
	rules = definitions.rule_set(setup.ruleset_id)
	if rules == null:
		rules = RuleSetDef.new()
	total_rounds = rules.rounds_title if setup.is_title else rules.rounds_normal
	round_seconds = setup.round_seconds_override if setup.round_seconds_override > 0 else rules.round_seconds
	weight_class = definitions.weight_class(setup.weight_class_id)
	rng.seed = setup.seed
	for snap: FighterSnapshot in [setup.fighter_a, setup.fighter_b]:
		var f: FighterCombatState = FighterCombatState.new()
		f.snapshot = snap
		f.reserve = 100.0 * snap.reserve_start
		f.stamina = f.reserve
		fighters.append(f)
	_reset_positions()
	_new_round_stats()


## Ordem fixa do passo (COMBAT_ARCHITECTURE §2): técnicas → leituras → golpes → movimento → fases → fisiologia → árbitro → relógio.
func step(cmd_a: FighterCommand, cmd_b: FighterCommand) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	if _finished or phase != Phase.ROUND:
		return events
	var cmds: Array[FighterCommand] = [cmd_a, cmd_b]
	# Ordem alternada a cada quadro: em ações simultâneas, nenhum lado tem prioridade fixa.
	var first: int = frame % 2
	var order: Array[int] = [first, 1 - first]
	# Cobertura no clinch/solo vale no mesmo passo do golpe recebido.
	if grappling.position != &"EP":
		for i: int in 2:
			grappling.apply_ground_guard(self, i, cmds[i])
	for i: int in order:
		grappling.apply_command(self, i, cmds[i], events)
	var consumed: Array[bool] = [grappling.register_read(0, cmd_a), grappling.register_read(1, cmd_b)]
	var standing: bool = grappling.position == &"EP"
	for i: int in order:
		if standing and not consumed[i]:
			CombatStriking.apply_command(self, i, cmds[i], events)
		elif not standing:
			grappling.apply_ground_guard(self, i, cmds[i])
	if standing:
		for i: int in 2:
			CombatMovement.update(self, i, cmds[i], cmds[1 - i])
	else:
		for f: FighterCombatState in fighters:
			f.moved_this_step = false
	for i: int in 2:
		if fighters[i].action != FighterCombatState.Action.GRAPPLING:
			CombatStriking.advance(self, i, events)
	grappling.advance(self, events)
	for f: FighterCombatState in fighters:
		CombatPhysiology.regenerate(f, balance)
		f.angle_frames = maxi(0, f.angle_frames - 1)
	CombatMovement.update_facing(self)
	frame += 1
	round_frame += 1
	_record_stats(events)
	referee.observe(self, events)
	for i: int in 2:
		if not _finished and fighters[i].action == FighterCombatState.Action.OUT:
			finish(1 - i, &"ko")
	if not _finished and round_frame >= round_seconds * 60:
		_end_round()
	if _finished:
		events.append(CombatEvent.make(CombatEvent.Type.FIGHT_OVER, _winner, 1 - _winner))
	return events


## Recuperação do intervalo (COMBAT §6.5) e início do próximo round.
func begin_next_round(focus_a: Focus, focus_b: Focus) -> void:
	if phase != Phase.ROUND_BREAK:
		return
	var foci: Array[Focus] = [focus_a, focus_b]
	for i: int in 2:
		var f: FighterCombatState = fighters[i]
		var recovery: float = f.attr(&"recuperacao")
		var resting: bool = foci[i] == Focus.RECOVER
		f.reserve = minf(100.0, f.reserve + 5.0 + recovery / 10.0)
		var fraction: float = 0.6 + recovery / 250.0 + (0.15 if resting else 0.0)
		f.stamina = maxf(f.stamina, minf(f.reserve, f.reserve * fraction))
		var keep_acute: float = 0.8 if resting else 0.6  # descansar o fôlego tira tempo do cutman/gelo
		for zone: StringName in FighterCombatState.ZONES:
			f.acute[zone] = float(f.acute[zone]) * keep_acute
	round += 1
	round_frame = 0
	phase = Phase.ROUND
	grappling.submission = null
	grappling.transition(self, &"EP", -1)
	_reset_positions()
	_new_round_stats()
	referee.reset_round(self)


func finish(winner_index: int, method: StringName) -> void:
	if _finished:
		return
	_finished = true
	_winner = winner_index
	finish_method = method
	phase = Phase.FINISHED


func is_finished() -> bool:
	return _finished


func winner() -> int:
	return _winner


func round_seconds_elapsed() -> int:
	return round_frame / 60


## Monta o contrato de saída para a carreira (GAME_SYSTEMS §3.2).
func build_result(bout_id: StringName) -> FightResult:
	var r: FightResult = FightResult.new()
	r.bout_id = bout_id
	r.round = round
	r.time_seconds = round_seconds_elapsed()
	match finish_method:
		&"ko":
			r.method = FightResult.Method.KO
		&"tko":
			r.method = FightResult.Method.TKO
		&"submission":
			r.method = FightResult.Method.SUBMISSION
			r.method_detail = finish_detail
		&"decision":
			r.method = decision[0]
	if finish_method == &"decision":
		r.winner = decision[1]
	else:
		r.winner = FightResult.FighterSlot.A if _winner == 0 else (FightResult.FighterSlot.B if _winner == 1 else FightResult.FighterSlot.NONE)
	r.scorecards = _judge_totals()
	var rounds: Array = []
	for k: int in round_scores.size():
		rounds.append({"cards": round_scores[k], "stats": round_stat_history[k]})
	r.stats = {"rounds": rounds, "a": fighters[0].stats.duplicate(), "b": fighters[1].stats.duplicate()}
	for k: int in 2:
		var f: FighterCombatState = fighters[k]
		r.medical["a" if k == 0 else "b"] = {
			"head": snappedf(f.zone_damage(&"head"), 0.1), "body": snappedf(f.zone_damage(&"body"), 0.1),
			"legs": snappedf(f.zone_damage(&"legs"), 0.1), "knockdowns": int(fight_stats[1 - k].get("knockdowns", 0)),
		}
	return r


func state_hash() -> String:
	return var_to_str([frame, round, phase, grappling.position, grappling.top,
		fighters[0].to_hash_dict(), fighters[1].to_hash_dict()]).sha256_text()


func _end_round() -> void:
	round_scores.append(Judging.score_round(round_stats[0], round_stats[1], rng))
	round_stat_history.append([round_stats[0].to_dict(), round_stats[1].to_dict()])
	if round >= total_rounds:
		decision = Judging.decide(_judge_totals())
		var w: int = 0 if decision[1] == FightResult.FighterSlot.A else (1 if decision[1] == FightResult.FighterSlot.B else -1)
		finish(w, &"decision")
	else:
		phase = Phase.ROUND_BREAK


func _judge_totals() -> Array:
	var totals: Array = []
	for j: int in Judging.JUDGES.size():
		var t: Array = [0, 0]
		for card_set: Array in round_scores:
			t[0] += int(card_set[j][0])
			t[1] += int(card_set[j][1])
		totals.append(t)
	return totals


func _record_stats(events: Array[CombatEvent]) -> void:
	for e: CombatEvent in events:
		match e.type:
			CombatEvent.Type.STRIKE_RESOLVED:
				if e.outcome == CombatEvent.Outcome.CLEAN or e.outcome == CombatEvent.Outcome.COUNTER:
					round_stats[e.attacker].damage_dealt += e.damage
			CombatEvent.Type.SHOCK:
				if e.shock_state == FighterCombatState.Action.DOWN:
					round_stats[e.attacker].knockdowns += 1
					fight_stats[e.attacker]["knockdowns"] = int(fight_stats[e.attacker].get("knockdowns", 0)) + 1
			CombatEvent.Type.GRAPPLE_RESOLVED:
				if e.grapple_outcome == CombatEvent.GrappleOutcome.SUCCESS:
					round_stats[e.attacker].grapple_successes += 1
				elif e.grapple_outcome == CombatEvent.GrappleOutcome.PERFECT_READ:
					round_stats[e.defender].grapple_successes += 1
	var g: CombatGrappling = grappling
	if g.top >= 0 and g.position != &"SR":
		round_stats[g.top].control_frames += 1
	elif g.position == &"CL" and g.clinch_owner >= 0:
		round_stats[g.clinch_owner].control_frames += 1


func _new_round_stats() -> void:
	round_stats = [Judging.FighterRoundStats.new(), Judging.FighterRoundStats.new()]


func _reset_positions() -> void:
	fighters[0].x = -1.5
	fighters[1].x = 1.5
	fighters[0].z = 0.0
	fighters[1].z = 0.0
	for f: FighterCombatState in fighters:
		if f.action != FighterCombatState.Action.OUT:
			f.set_action(FighterCombatState.Action.IDLE, 0)
	CombatMovement.update_facing(self)

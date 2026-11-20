class_name CombatGrappling
extends RefCounted
## Estado de posição do PAR de lutadores e a Disputa (COMBAT_DESIGN §4, COMBAT_ARCHITECTURE §3 e §6, T-005).
## `transition()` é a ÚNICA função que muda a posição. Combinações inválidas não são representáveis:
## existe um só estado para os dois lutadores, mais o índice de quem está "por cima".

const POSITIONS: Array[StringName] = [&"EP", &"CL", &"CG", &"SG", &"SM", &"SL", &"SO", &"SC", &"SR"]
const NEUTRAL: Array[StringName] = [&"EP", &"CL"]
const GROUND: Array[StringName] = [&"SG", &"SM", &"SL", &"SO", &"SC"]
const CLINCH: Array[StringName] = [&"CL", &"CG"]


class Attempt:
	var technique: GrappleTechniqueDef
	var attacker: int
	var elapsed: int = 0
	var read_dir: FighterCommand.Direction = FighterCommand.Direction.NONE
	var read_frame: int = -1


class Submission:
	var technique: GrappleTechniqueDef
	var attacker: int
	var meter: float = 0.0
	var escapes: int = 0
	var attacker_dir: FighterCommand.Direction = FighterCommand.Direction.DOWN
	var defender_dir: FighterCommand.Direction = FighterCommand.Direction.NONE
	var timer: int = 0


var position: StringName = &"EP"
## Índice de quem está por cima / prensando / nas costas; -1 em posições neutras.
var top: int = -1
## Quem tem a Vantagem de Clinch (pegadas); -1 ninguém.
var clinch_owner: int = -1
var pending: Attempt
var submission: Submission
## Progresso parcial acumulado: "<atacante>:<técnica>" -> número de tentativas parciais.
var _partials: Dictionary = {}


func role_of(i: int) -> StringName:
	if NEUTRAL.has(position):
		return &"any"
	return &"top" if i == top else &"bottom"


## Inicia técnicas (Agarrar + direção) e golpes de solo (ground and pound).
func apply_command(sim: CombatSim, i: int, cmd: FighterCommand, events: Array[CombatEvent]) -> void:
	var f: FighterCombatState = sim.fighters[i]
	if submission != null:
		_update_submission_input(i, cmd)
		return
	if f.action != FighterCombatState.Action.IDLE:
		return
	if GROUND.has(position) and i == top and (cmd.strike_limb == StrikeDef.Limb.LEAD_HAND or cmd.strike_limb == StrikeDef.Limb.REAR_HAND):
		_ground_and_pound(sim, i, events)
		return
	if CLINCH.has(position) and cmd.strike_limb >= 0 and not cmd.grapple:
		_clinch_strike(sim, i, cmd, events)
		return
	if not cmd.grapple or pending != null:
		return
	var t: GrappleTechniqueDef = sim.defs.find_grapple(position, role_of(i), cmd.technique_direction)
	if t == null:
		return
	var other: FighterCombatState = sim.fighters[1 - i]
	if t.max_range_m > 0.0 and absf(other.x - f.x) > t.max_range_m:
		return
	if t.requires_advantage and clinch_owner != i:
		return
	if other.action == FighterCombatState.Action.DOWN or other.action == FighterCombatState.Action.OUT:
		return
	pending = Attempt.new()
	pending.technique = t
	pending.attacker = i
	f.set_action(FighterCombatState.Action.GRAPPLING, t.startup_frames)
	var e: CombatEvent = CombatEvent.make(CombatEvent.Type.GRAPPLE_STARTED, i, 1 - i)
	e.technique_id = t.id
	events.append(e)


## Registra a leitura do defensor. Devolve true se a direção foi consumida como defesa (não vira esquiva).
func register_read(i: int, cmd: FighterCommand) -> bool:
	if pending == null or pending.attacker == i or cmd.technique_direction == FighterCommand.Direction.NONE:
		return false
	if pending.read_frame >= 0:
		return true
	pending.read_dir = cmd.technique_direction
	pending.read_frame = pending.elapsed
	return true


func advance(sim: CombatSim, events: Array[CombatEvent]) -> void:
	for f: FighterCombatState in sim.fighters:
		f.gnp_cooldown = maxi(0, f.gnp_cooldown - 1)
	if submission != null:
		_advance_submission(sim, events)
		return
	if pending == null:
		return
	pending.elapsed += 1
	if pending.elapsed >= pending.technique.startup_frames:
		_resolve(sim, events)


func _resolve(sim: CombatSim, events: Array[CombatEvent]) -> void:
	var a: Attempt = pending
	pending = null
	var t: GrappleTechniqueDef = a.technique
	var att: FighterCombatState = sim.fighters[a.attacker]
	var def: FighterCombatState = sim.fighters[1 - a.attacker]
	var bal: CombatBalanceDef = sim.balance
	att.set_action(FighterCombatState.Action.IDLE, 0)
	var e: CombatEvent = CombatEvent.make(CombatEvent.Type.GRAPPLE_RESOLVED, a.attacker, 1 - a.attacker)
	e.technique_id = t.id
	events.append(e)
	if a.read_frame >= 0 and a.read_dir == t.defense_direction:
		CombatPhysiology.spend(att, t.stamina_cost * bal.fail_stamina_mult, bal)
		var perfect: bool = a.read_frame <= t.startup_frames * bal.perfect_read_fraction
		if perfect and t.counter_state != &"":
			e.grapple_outcome = CombatEvent.GrappleOutcome.PERFECT_READ
			transition(sim, t.counter_state, _top_index(t.counter_top, a.attacker))
		else:
			e.grapple_outcome = CombatEvent.GrappleOutcome.READ
		return
	var key: String = "%d:%s" % [a.attacker, t.id]
	var pressure: float = att.attr(t.pressure_attr) * _stamina_factor(att) * (1.0 + bal.partial_bonus * int(_partials.get(key, 0)))
	var weight_ratio: float = clampf(def.snapshot.fight_weight_kg / maxf(1.0, att.snapshot.fight_weight_kg), 0.8, 1.25)
	var resistance: float = def.attr(t.resistance_attr) * _stamina_factor(def) * weight_ratio
	var ratio: float = pressure / maxf(0.001, resistance)
	if ratio >= 1.0:
		e.grapple_outcome = CombatEvent.GrappleOutcome.SUCCESS
		_partials.erase(key)
		CombatPhysiology.spend(att, t.stamina_cost, bal)
		CombatPhysiology.spend(def, t.stamina_cost * 0.5, bal)
		if t.kind == &"submission":
			_start_submission(sim, t, a.attacker)
		elif t.grants_advantage:
			clinch_owner = a.attacker
		else:
			transition(sim, t.to_state, _top_index(t.result_top, a.attacker))
	elif ratio >= bal.partial_ratio:
		e.grapple_outcome = CombatEvent.GrappleOutcome.PARTIAL
		_partials[key] = int(_partials.get(key, 0)) + 1
		CombatPhysiology.spend(att, t.stamina_cost, bal)
	else:
		e.grapple_outcome = CombatEvent.GrappleOutcome.FAIL
		CombatPhysiology.spend(att, t.stamina_cost * bal.fail_stamina_mult, bal)


## Muda a posição e reposiciona os lutadores no plano. Única porta de entrada para mudar `position`.
func transition(sim: CombatSim, to: StringName, new_top: int) -> void:
	assert(POSITIONS.has(to), "posição inválida %s" % to)
	position = to
	top = -1 if NEUTRAL.has(to) else new_top
	if to != &"CL":
		clinch_owner = -1
	pending = null
	for f: FighterCombatState in sim.fighters:
		if f.action != FighterCombatState.Action.OUT:
			f.set_action(FighterCombatState.Action.IDLE, 0)
		f.guard_high = false
		f.guard_low = false
	_place(sim)


func _place(sim: CombatSim) -> void:
	var a: FighterCombatState = sim.fighters[0]
	var b: FighterCombatState = sim.fighters[1]
	var bal: CombatBalanceDef = sim.balance
	var left_is_a: bool = a.x <= b.x
	var half_gap: float
	match position:
		&"EP":
			half_gap = 0.5
		&"CL", &"CG", &"SR":
			half_gap = bal.body_min_distance_m / 2.0
		_:
			half_gap = 0.25
	var limit: float = bal.cage_half_width_m - half_gap
	var mid: float = clampf((a.x + b.x) / 2.0, -limit, limit)
	if position == &"CG":
		# Quem é prensado fica de costas para a grade do lado em que já estava.
		var pressed: FighterCombatState = sim.fighters[1 - top]
		var presser: FighterCombatState = sim.fighters[top]
		var side: float = -1.0 if pressed.x < presser.x else 1.0
		pressed.x = side * (bal.cage_half_width_m - 0.2)
		presser.x = pressed.x - side * bal.body_min_distance_m
	else:
		var left: FighterCombatState = a if left_is_a else b
		var right: FighterCombatState = b if left_is_a else a
		left.x = mid - half_gap
		right.x = mid + half_gap
	var z: float = (a.z + b.z) / 2.0
	a.z = z
	b.z = z


func _top_index(rule: StringName, attacker: int) -> int:
	match rule:
		&"attacker":
			return attacker
		&"defender":
			return 1 - attacker
		&"keep":
			return top
	return -1


func _stamina_factor(f: FighterCombatState) -> float:
	return 0.6 + 0.4 * f.stamina_ratio()


func _ground_and_pound(sim: CombatSim, i: int, events: Array[CombatEvent]) -> void:
	var f: FighterCombatState = sim.fighters[i]
	var d: FighterCombatState = sim.fighters[1 - i]
	var bal: CombatBalanceDef = sim.balance
	if f.gnp_cooldown > 0:
		return
	f.gnp_cooldown = bal.gnp_cooldown_frames
	var mult: float = {&"SG": bal.gnp_mult_guard, &"SM": bal.gnp_mult_half, &"SL": bal.gnp_mult_side, &"SO": bal.gnp_mult_mount, &"SC": bal.gnp_mult_back}[position]
	var variance: float = sim.rng.randf_range(1.0 - bal.power_variance, 1.0 + bal.power_variance)
	var power: float = bal.gnp_power * mult * (0.7 + f.attr(&"forca") * 0.006) * (0.8 + f.attr(&"controle_solo") * 0.004) \
		* CombatPhysiology.power_multiplier(f) * variance
	CombatPhysiology.spend(f, 2.0, bal)
	f.stats["attempts"] += 1
	var e: CombatEvent = CombatEvent.make(CombatEvent.Type.STRIKE_RESOLVED, i, 1 - i)
	e.strike_id = &"ground_and_pound"
	e.zone = &"head"
	var blocked: bool = d.guard_high and position != &"SC"
	e.outcome = CombatEvent.Outcome.BLOCKED if blocked else CombatEvent.Outcome.CLEAN
	f.stats["blocked" if blocked else "landed"] += 1
	events.append(e)
	CombatPhysiology.apply_hit(sim, d, e, power, blocked, events)
	# Choque no solo não derruba de novo: knockdown vira atordoamento (já está no chão).
	if d.action == FighterCombatState.Action.DOWN:
		d.set_action(FighterCombatState.Action.STUNNED, bal.stunned_frames)


## Joelhadas (perna) e cotoveladas (mão) no clinch (COMBAT §4.3). Quem tem a pegada joelha a cabeça;
## sem pegada, a joelhada vai ao corpo. Cobrir-se (Shift) reduz como bloqueio.
func _clinch_strike(sim: CombatSim, i: int, cmd: FighterCommand, events: Array[CombatEvent]) -> void:
	var f: FighterCombatState = sim.fighters[i]
	var d: FighterCombatState = sim.fighters[1 - i]
	var bal: CombatBalanceDef = sim.balance
	if f.gnp_cooldown > 0:
		return
	f.gnp_cooldown = bal.clinch_strike_cooldown_frames
	var knee: bool = cmd.strike_limb == StrikeDef.Limb.LEAD_LEG or cmd.strike_limb == StrikeDef.Limb.REAR_LEG
	var e: CombatEvent = CombatEvent.make(CombatEvent.Type.STRIKE_RESOLVED, i, 1 - i)
	e.strike_id = &"clinch_knee" if knee else &"clinch_elbow"
	e.zone = &"head" if (not knee or clinch_owner == i) else &"body"
	var blocked: bool = d.guard_high and e.zone == &"head"
	e.outcome = CombatEvent.Outcome.BLOCKED if blocked else CombatEvent.Outcome.CLEAN
	var variance: float = sim.rng.randf_range(1.0 - bal.power_variance, 1.0 + bal.power_variance)
	var power: float = (bal.clinch_knee_power if knee else bal.clinch_elbow_power) * (0.7 + f.attr(&"forca") * 0.006) 		* (0.8 + f.attr(&"kickboxing") * 0.004) * CombatPhysiology.power_multiplier(f) * variance
	CombatPhysiology.spend(f, 2.5 if knee else 2.0, bal)
	f.stats["attempts"] += 1
	f.stats["blocked" if blocked else "landed"] += 1
	events.append(e)
	CombatPhysiology.apply_hit(sim, d, e, power, blocked, events)
	# No clinch o knockdown separa a dupla: a posição volta a "em pé".
	if d.action == FighterCombatState.Action.DOWN:
		transition(sim, &"EP", -1)
		d.set_action(FighterCombatState.Action.DOWN, bal.knockdown_frames)


## Cobertura por baixo no solo (contra ground and pound) e no clinch (contra cotoveladas/joelhadas).
func apply_ground_guard(sim: CombatSim, i: int, cmd: FighterCommand) -> void:
	var f: FighterCombatState = sim.fighters[i]
	var can_cover: bool = (GROUND.has(position) and i != top) or CLINCH.has(position)
	f.guard_high = can_cover and cmd.guard and f.action == FighterCombatState.Action.IDLE


func _start_submission(sim: CombatSim, t: GrappleTechniqueDef, attacker: int) -> void:
	submission = Submission.new()
	submission.technique = t
	submission.attacker = attacker
	submission.meter = sim.balance.squeeze_start
	submission.timer = sim.balance.squeeze_cycle_frames
	var dirs: Array[FighterCommand.Direction] = [FighterCommand.Direction.FORWARD, FighterCommand.Direction.BACK,
		FighterCommand.Direction.UP, FighterCommand.Direction.DOWN]
	submission.attacker_dir = dirs[sim.rng.randi_range(0, 3)]
	for f: FighterCombatState in sim.fighters:
		f.set_action(FighterCombatState.Action.GRAPPLING, 0)


func _update_submission_input(i: int, cmd: FighterCommand) -> void:
	if cmd.technique_direction == FighterCommand.Direction.NONE:
		return
	if i == submission.attacker:
		submission.attacker_dir = cmd.technique_direction
	else:
		submission.defender_dir = cmd.technique_direction


## Aperto (COMBAT §4.6): a cada ciclo, escape na direção do ajuste do atacante derruba o medidor;
## errar ou não reagir faz o medidor subir conforme Jiu-jitsu × Defesa de Finalização e o Fôlego do defensor.
func _advance_submission(sim: CombatSim, events: Array[CombatEvent]) -> void:
	var s: Submission = submission
	var t: GrappleTechniqueDef = s.technique
	var att: FighterCombatState = sim.fighters[s.attacker]
	var def: FighterCombatState = sim.fighters[1 - s.attacker]
	var bal: CombatBalanceDef = sim.balance
	s.timer -= 1
	if s.timer > 0:
		return
	s.timer = bal.squeeze_cycle_frames
	if s.defender_dir == s.attacker_dir:
		s.meter -= bal.squeeze_escape_drop
		s.escapes += 1
	else:
		var skill: float = att.attr(t.pressure_attr) / maxf(1.0, def.attr(t.resistance_attr))
		s.meter += t.squeeze_rate * skill * (1.5 - 0.5 * def.stamina_ratio())
	s.defender_dir = FighterCommand.Direction.NONE
	CombatPhysiology.spend(att, 1.5, bal)
	CombatPhysiology.spend(def, 0.5, bal)
	var e: CombatEvent = CombatEvent.make(CombatEvent.Type.SQUEEZE_TICK, s.attacker, 1 - s.attacker)
	e.technique_id = t.id
	e.squeeze_meter = s.meter
	events.append(e)
	if s.meter >= 100.0:
		e.grapple_outcome = CombatEvent.GrappleOutcome.TAPPED
		submission = null
		sim.finish_detail = t.id
		sim.finish(s.attacker, &"submission")
	elif s.meter <= 0.0 or s.escapes >= t.escapes_needed:
		e.grapple_outcome = CombatEvent.GrappleOutcome.ESCAPED
		submission = null
		transition(sim, t.escape_state, _top_index(t.escape_top, s.attacker))

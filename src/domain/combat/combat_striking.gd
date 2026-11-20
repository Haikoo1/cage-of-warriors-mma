class_name CombatStriking
extends RefCounted
## Golpes em pé: escolha do golpe, fases, geometria do acerto, defesa e contra-golpe (COMBAT_DESIGN §3).

const STRAIGHT: StrikeDef.Variant = StrikeDef.Variant.STRAIGHT
const CURVED: StrikeDef.Variant = StrikeDef.Variant.CURVED
const BODY: StrikeDef.Variant = StrikeDef.Variant.BODY


## Interpreta o comando: guarda, esquiva ou início de golpe. Só age a partir do neutro.
static func apply_command(sim: CombatSim, i: int, cmd: FighterCommand, events: Array[CombatEvent]) -> void:
	var f: FighterCombatState = sim.fighters[i]
	var bal: CombatBalanceDef = sim.balance
	var idle: bool = f.action == FighterCombatState.Action.IDLE
	f.guard_high = idle and cmd.guard and not cmd.mod_body
	f.guard_low = idle and cmd.guard and cmd.mod_body
	if not idle or cmd.grapple:  # Agarrar + direção é técnica de grappling, nunca esquiva
		return
	if cmd.technique_direction != FighterCommand.Direction.NONE:
		var ev: FighterCombatState.Evade = _evade_for(cmd.technique_direction)
		if ev != FighterCombatState.Evade.NONE:
			f.set_action(FighterCombatState.Action.EVADING, bal.evade_frames)
			f.evade = ev
			f.guard_high = false
			f.guard_low = false
			CombatPhysiology.spend(f, bal.evade_stamina, bal)
		return
	if cmd.strike_limb < 0 or cmd.guard:
		return
	var s: StrikeDef = select_strike(sim.defs, cmd)
	if s == null:
		return
	var startup: int = maxi(1, roundi(s.startup_frames * speed_multiplier(f)) - (2 if f.angle_frames > 0 else 0))
	f.set_action(FighterCombatState.Action.STRIKE_STARTUP, startup)
	f.strike = s
	f.strike_zone = _zone_for(s, cmd.mod_body)
	f.stats["attempts"] += 1
	CombatPhysiology.spend(f, s.stamina_cost, bal)
	var e: CombatEvent = CombatEvent.make(CombatEvent.Type.STRIKE_STARTED, i, 1 - i)
	e.strike_id = s.id
	events.append(e)


## Membro + modificadores → golpe definido em dados. Corpo usa a variante BODY se existir; senão o mesmo golpe no corpo.
static func select_strike(defs: Definitions, cmd: FighterCommand) -> StrikeDef:
	var wanted: StrikeDef.Variant = CURVED if cmd.mod_curved else (BODY if cmd.mod_body else STRAIGHT)
	var fallback: StrikeDef = null
	for s: StrikeDef in defs.strikes.values():
		if s.limb != cmd.strike_limb:
			continue
		if s.variant == wanted:
			return s
		if s.variant == STRAIGHT and wanted == BODY and s.targets.has("body"):
			fallback = s
	return fallback


## Avança fases; golpes que entram em execução são resolvidos neste passo.
static func advance(sim: CombatSim, i: int, events: Array[CombatEvent]) -> void:
	var f: FighterCombatState = sim.fighters[i]
	if f.action == FighterCombatState.Action.IDLE or f.action == FighterCombatState.Action.OUT:
		return
	f.action_frames_left -= 1
	if f.action_frames_left > 0:
		return
	match f.action:
		FighterCombatState.Action.STRIKE_STARTUP:
			f.action = FighterCombatState.Action.STRIKE_ACTIVE
			f.action_frames_left = f.strike.active_frames
			resolve(sim, i, events)
		FighterCombatState.Action.STRIKE_ACTIVE:
			f.action = FighterCombatState.Action.STRIKE_RECOVERY
			f.action_frames_left = roundi(f.strike.recovery_frames * speed_multiplier(f))
		_:
			f.set_action(FighterCombatState.Action.IDLE, 0)


static func resolve(sim: CombatSim, i: int, events: Array[CombatEvent]) -> void:
	var f: FighterCombatState = sim.fighters[i]
	var d: FighterCombatState = sim.fighters[1 - i]
	var bal: CombatBalanceDef = sim.balance
	var s: StrikeDef = f.strike
	var e: CombatEvent = CombatEvent.make(CombatEvent.Type.STRIKE_RESOLVED, i, 1 - i)
	e.strike_id = s.id
	e.zone = f.strike_zone
	events.append(e)
	var head: bool = f.strike_zone == &"head"
	var dx: float = absf(d.x - f.x)
	if head and d.evade == FighterCombatState.Evade.PULL:
		dx += bal.pull_range_m
	var reach: float = s.base_reach_m * f.snapshot.reach_cm / bal.reference_reach_cm
	if dx > reach:
		e.outcome = CombatEvent.Outcome.EVADED if (head and d.evade == FighterCombatState.Evade.PULL and dx - bal.pull_range_m <= reach) else CombatEvent.Outcome.MISS_RANGE
		_count(f, e.outcome)
		return
	if head and d.evade == FighterCombatState.Evade.DUCK and s.variant == CURVED:
		e.outcome = CombatEvent.Outcome.EVADED
		_count(f, e.outcome)
		return
	var tolerance: float = s.depth_tolerance_m
	if d.angle_frames > 0 and s.variant == STRAIGHT:
		tolerance *= bal.angle_tolerance_factor
	var dz: float = absf(d.z - f.z)
	var slipped: bool = head and d.evade == FighterCombatState.Evade.SLIP and s.variant == STRAIGHT
	if dz + (bal.slip_offset_m if slipped else 0.0) > tolerance:
		e.outcome = CombatEvent.Outcome.EVADED if slipped and dz <= tolerance else CombatEvent.Outcome.MISS_ANGLE
		_count(f, e.outcome)
		return
	var blocked: bool = (head and d.guard_high) or (f.strike_zone == &"body" and d.guard_low)
	var counter: bool = not blocked and (d.action == FighterCombatState.Action.STRIKE_STARTUP or d.action == FighterCombatState.Action.STRIKE_ACTIVE)
	var power: float = strike_power(sim, f, s)
	if counter:
		power *= bal.counter_mult
		d.set_action(FighterCombatState.Action.IDLE, 0)  # interrompe o golpe do defensor
	e.outcome = CombatEvent.Outcome.BLOCKED if blocked else (CombatEvent.Outcome.COUNTER if counter else CombatEvent.Outcome.CLEAN)
	_count(f, e.outcome)
	CombatPhysiology.apply_hit(sim, d, e, power, blocked, events)


static func strike_power(sim: CombatSim, f: FighterCombatState, s: StrikeDef) -> float:
	var weight: float = sim.weight_class.damage_mult if sim.weight_class != null else 1.0
	var variance: float = sim.rng.randf_range(1.0 - sim.balance.power_variance, 1.0 + sim.balance.power_variance)
	return s.power * (0.7 + f.attr(&"forca") * 0.006) * (0.8 + f.attr(s.technique_attribute) * 0.004) \
		* CombatPhysiology.power_multiplier(f) * weight * variance


## Velocidade encurta preparação/recuperação em faixa limitada (COMBAT §3.3); Fôlego baixo alonga.
static func speed_multiplier(f: FighterCombatState) -> float:
	return (1.15 - f.attr(&"velocidade") * 0.003) * CombatPhysiology.frame_multiplier(f)


static func _zone_for(s: StrikeDef, body: bool) -> StringName:
	if body and s.targets.has("body"):
		return &"body"
	if s.targets.has("head"):
		return &"head"
	return StringName(s.targets[0])


static func _evade_for(dir: FighterCommand.Direction) -> FighterCombatState.Evade:
	match dir:
		FighterCommand.Direction.UP:
			return FighterCombatState.Evade.SLIP
		FighterCommand.Direction.DOWN:
			return FighterCombatState.Evade.DUCK
		FighterCommand.Direction.BACK:
			return FighterCombatState.Evade.PULL
	return FighterCombatState.Evade.NONE


static func _count(f: FighterCombatState, outcome: CombatEvent.Outcome) -> void:
	match outcome:
		CombatEvent.Outcome.CLEAN:
			f.stats["landed"] += 1
		CombatEvent.Outcome.COUNTER:
			f.stats["landed"] += 1
			f.stats["counters"] += 1
		CombatEvent.Outcome.BLOCKED:
			f.stats["blocked"] += 1
		CombatEvent.Outcome.EVADED:
			f.stats["evaded"] += 1
		_:
			f.stats["missed"] += 1

class_name CombatAI
extends RefCounted
## IA de combate por utilidade (COMBAT_DESIGN §9, COMBAT_ARCHITECTURE §9).
## Justiça por construção (REQ-07): emite o mesmo FighterCommand do jogador, não recebe bônus de atributo,
## e reage ao adversário só pelo que FICOU VISÍVEL há `perception_delay` quadros (histórico de percepção).
## Não lê o comando do jogador nem atributos ocultos dele.

var archetype: ArchetypeDef
var profile: CognitiveProfileDef
var me: int
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _history: Array[Dictionary] = []  # percepção do adversário, um registro por quadro
var _next_decision: int = 0
var _held: FighterCommand = FighterCommand.new()
var _guard_frames: int = 0
var _guard_low: bool = false
var _reacted_strike_at: int = -1
var _read_attempt: Object = null
var _next_squeeze_input: int = 0
## Memória de hábitos (COMBAT §9.4): direções de técnica do adversário por posição + quanto ele guarda alto.
var _habit_dirs: Dictionary = {}
var _seen_attempt: Object = null
var _guard_samples: int = 0
var _guard_high_samples: int = 0


func _init(arch: ArchetypeDef, prof: CognitiveProfileDef, index: int, seed: int) -> void:
	archetype = arch
	profile = prof
	me = index
	rng.seed = seed
	_next_decision = rng.randi_range(0, prof.decision_interval_frames())  # relógios de decisão desalinhados


## Chamado a cada quadro antes de get_command: registra o que é visível do adversário.
func observe(sim: CombatSim) -> void:
	var o: FighterCombatState = sim.fighters[1 - me]
	var g: CombatGrappling = sim.grappling
	var rec: Dictionary = {
		"frame": sim.frame, "action": o.action, "zone": o.strike_zone,
		"straight": o.strike != null and o.strike.variant == StrikeDef.Variant.STRAIGHT,
		"guard_high": o.guard_high,
		"attempt": g.pending if (g.pending != null and g.pending.attacker != me) else null,
		"squeeze_dir": g.submission.attacker_dir if (g.submission != null and g.submission.attacker != me) else FighterCommand.Direction.NONE,
	}
	_history.append(rec)
	var keep: int = profile.perception_delay_frames() + 2
	if _history.size() > keep:
		_history.pop_front()
	if g.pending != null and g.pending.attacker != me and g.pending != _seen_attempt:
		_seen_attempt = g.pending
		var by_pos: Dictionary = _habit_dirs.get(g.position, {})
		var d: int = g.pending.technique.direction
		by_pos[d] = int(by_pos.get(d, 0)) + 1
		_habit_dirs[g.position] = by_pos
	if g.position == &"EP":
		_guard_samples += 1
		if o.guard_high:
			_guard_high_samples += 1


func get_command(sim: CombatSim) -> FighterCommand:
	var c: FighterCommand = FighterCommand.new()
	if sim.phase != CombatSim.Phase.ROUND or sim.is_finished():
		return c
	var f: FighterCombatState = sim.fighters[me]
	var g: CombatGrappling = sim.grappling
	var seen: Dictionary = _perceived()
	if _defend_grapple(g, seen, c) or _handle_submission(sim, g, seen, c):
		return c
	if g.position == &"EP" and _react_to_strike(seen, c):
		return c
	if _guard_frames > 0:
		_guard_frames -= 1
		c.guard = true
		c.mod_body = _guard_low
		return c
	if sim.frame < _next_decision or f.action != FighterCombatState.Action.IDLE:
		c.move_x = _held.move_x
		c.move_z = _held.move_z
		c.guard = _held.guard
		return c
	_next_decision = sim.frame + profile.decision_interval_frames()
	var options: Array = []  # [utilidade, FighterCommand]
	if g.position == &"EP":
		_standing_options(sim, f, options)
	else:
		_grapple_options(sim, g, f, options)
	var chosen: FighterCommand = _choose(options)
	_held = FighterCommand.new()
	_held.move_x = chosen.move_x
	_held.move_z = chosen.move_z
	_held.guard = chosen.guard
	return chosen


## Foco do intervalo: recuperar quando o Fôlego está baixo.
func choose_focus(sim: CombatSim) -> CombatSim.Focus:
	return CombatSim.Focus.RECOVER if sim.fighters[me].stamina_ratio() < 0.5 else CombatSim.Focus.NORMAL


func _perceived() -> Dictionary:
	var idx: int = _history.size() - 1 - profile.perception_delay_frames()
	return _history[idx] if idx >= 0 else {}


## Lê uma técnica do adversário depois que ela ficou visível há tempo suficiente; erra conforme o perfil.
func _defend_grapple(g: CombatGrappling, seen: Dictionary, c: FighterCommand) -> bool:
	var attempt: Object = seen.get("attempt")
	if attempt == null or attempt != g.pending or attempt == _read_attempt:
		return false
	_read_attempt = attempt
	if rng.randf() >= profile.read_error:
		c.technique_direction = g.pending.technique.defense_direction
	else:
		c.technique_direction = _habit_guess(g.position)
	return true


func _handle_submission(sim: CombatSim, g: CombatGrappling, seen: Dictionary, c: FighterCommand) -> bool:
	if g.submission == null:
		return false
	if sim.frame < _next_squeeze_input:
		return true
	_next_squeeze_input = sim.frame + maxi(profile.decision_interval_frames(), 20)
	if g.submission.attacker == me:
		if rng.randf() < 0.3:
			c.technique_direction = _random_dir()
		return true
	var felt: int = seen.get("squeeze_dir", FighterCommand.Direction.NONE)
	if felt != FighterCommand.Direction.NONE:
		c.technique_direction = (felt if rng.randf() >= profile.read_error else _random_dir()) as FighterCommand.Direction
	return true


func _react_to_strike(seen: Dictionary, c: FighterCommand) -> bool:
	if seen.is_empty() or seen["action"] != FighterCombatState.Action.STRIKE_STARTUP or seen["frame"] == _reacted_strike_at:
		return false
	_reacted_strike_at = seen["frame"]
	if rng.randf() < profile.read_error:
		return false
	if seen["straight"] and seen["zone"] == &"head" and rng.randf() < 0.35:
		c.technique_direction = FighterCommand.Direction.UP  # slip
		return true
	_guard_frames = 18
	_guard_low = seen["zone"] == &"body"
	c.guard = true
	c.mod_body = _guard_low
	return true


func _standing_options(sim: CombatSim, f: FighterCombatState, options: Array) -> void:
	var o: FighterCombatState = sim.fighters[1 - me]
	var dist: float = absf(o.x - f.x)
	var tired: bool = f.stamina_ratio() < profile.stamina_discipline
	var pref: float = archetype.preferred_distance_m
	if dist > pref + 0.15:
		options.append([1.0, _move(1, 0)])
	elif dist < pref - 0.25:
		options.append([0.5, _move(-1, 0)])
	if f.is_cornered(sim.balance):
		options.append([1.1, _move(0, -1 if f.z > 0.0 else 1)])
	if tired:
		var rest: FighterCommand = _move(-1, 0)
		rest.guard = true
		options.append([2.0, rest])
	var body_bias: float = 1.5 if (_guard_samples >= profile.habit_min_samples * 30 and _guard_high_samples * 2 > _guard_samples) else 0.7
	for s: StrikeDef in sim.defs.strikes.values():
		var reach: float = s.base_reach_m * f.snapshot.reach_cm / sim.balance.reference_reach_cm
		if dist > reach:
			continue
		var hand: bool = s.limb == StrikeDef.Limb.LEAD_HAND or s.limb == StrikeDef.Limb.REAR_HAND
		var w: float = (archetype.punch_weight if hand else archetype.kick_weight) * (0.5 + f.attr(s.technique_attribute) / 100.0)
		if tired:
			w *= 0.3
		var c: FighterCommand = FighterCommand.new()
		c.strike_limb = s.limb
		c.mod_curved = s.variant == StrikeDef.Variant.CURVED
		c.mod_body = s.variant == StrikeDef.Variant.BODY
		options.append([w, c])
		if s.variant == StrikeDef.Variant.STRAIGHT and s.targets.has("body"):
			var body: FighterCommand = FighterCommand.new()
			body.strike_limb = s.limb
			body.mod_body = true
			options.append([w * 0.5 * body_bias, body])
	if dist <= 1.25 and not tired:
		var td: FighterCommand = FighterCommand.new()
		td.grapple = true
		td.technique_direction = FighterCommand.Direction.DOWN if rng.randf() < 0.6 else FighterCommand.Direction.UP
		options.append([archetype.takedown_weight * (0.5 + f.attr(&"wrestling_ofensivo") / 100.0), td])
	if dist <= 0.9:
		var cl: FighterCommand = FighterCommand.new()
		cl.grapple = true
		options.append([archetype.clinch_weight, cl])
	if dist < 1.3:
		var guard: FighterCommand = FighterCommand.new()
		guard.guard = true
		options.append([archetype.guard_tendency, guard])
	options.append([0.2, FighterCommand.new()])  # hesitação


func _grapple_options(sim: CombatSim, g: CombatGrappling, f: FighterCombatState, options: Array) -> void:
	var role: StringName = g.role_of(me)
	for t: GrappleTechniqueDef in sim.defs.grapple_techniques.values():
		if t.from_state != g.position or t.role != role:
			continue
		if t.requires_advantage and g.clinch_owner != me:
			continue
		var w: float
		if t.kind == &"submission":
			w = archetype.ground_top_weight * 1.3
		elif t.to_state == &"EP":
			w = archetype.ground_bottom_escape_weight
		elif t.grants_advantage:
			w = (archetype.clinch_weight + 0.5) if g.clinch_owner != me else 0.1
		elif t.result_top == &"attacker" or role == &"top":
			w = archetype.ground_top_weight
		else:
			w = 0.8
		var c: FighterCommand = FighterCommand.new()
		c.grapple = true
		c.technique_direction = t.direction
		options.append([w * (0.5 + f.attr(t.pressure_attr) / 100.0), c])
	if CombatGrappling.GROUND.has(g.position):
		if g.top == me:
			var gnp: FighterCommand = FighterCommand.new()
			gnp.strike_limb = StrikeDef.Limb.REAR_HAND
			options.append([archetype.ground_top_weight * 0.9, gnp])
		else:
			var cover: FighterCommand = FighterCommand.new()
			cover.guard = true
			options.append([0.6, cover])
	options.append([0.15, FighterCommand.new()])


## Softmax com temperatura do perfil: nunca determinística, nunca totalmente aleatória.
func _choose(options: Array) -> FighterCommand:
	if options.is_empty():
		return FighterCommand.new()
	var weights: Array[float] = []
	var total: float = 0.0
	for opt: Array in options:
		var w: float = exp(float(opt[0]) / profile.temperature)
		weights.append(w)
		total += w
	var r: float = rng.randf() * total
	for k: int in options.size():
		r -= weights[k]
		if r <= 0.0:
			return options[k][1]
	return options[-1][1]


func _habit_guess(position: StringName) -> FighterCommand.Direction:
	var by_pos: Dictionary = _habit_dirs.get(position, {})
	var best: int = FighterCommand.Direction.NONE
	var best_n: int = 0
	var total: int = 0
	for d: int in by_pos:
		total += int(by_pos[d])
		if int(by_pos[d]) > best_n:
			best_n = by_pos[d]
			best = d
	if total >= profile.habit_min_samples:
		return best as FighterCommand.Direction
	return _random_dir()


func _move(x: int, z: int) -> FighterCommand:
	var c: FighterCommand = FighterCommand.new()
	c.move_x = x
	c.move_z = z
	return c


func _random_dir() -> FighterCommand.Direction:
	return rng.randi_range(1, 4) as FighterCommand.Direction

class_name CombatPhysiology
extends RefCounted
## Fôlego, Reserva, dano por zona e Limiar de Choque (COMBAT_DESIGN §6). Única fonte de alteração desses valores.

const DT: float = 1.0 / 60.0


static func spend(f: FighterCombatState, amount: float, bal: CombatBalanceDef) -> void:
	f.stamina = maxf(0.0, f.stamina - amount)
	f.reserve = maxf(bal.reserve_floor, f.reserve - amount * bal.reserve_loss_ratio)
	f.stamina = minf(f.stamina, f.reserve)


## Regenera só quando o lutador não está gastando (sem movimento, golpe ou esquiva).
static func regenerate(f: FighterCombatState, bal: CombatBalanceDef) -> void:
	if f.action != FighterCombatState.Action.IDLE or f.moved_this_step:
		return
	var rate: float = bal.regen_per_s * (0.6 + f.attr(&"condicionamento") / 125.0)
	if f.guard_high or f.guard_low:
		rate *= 0.5
	f.stamina = minf(f.reserve, f.stamina + rate * DT)


## Fôlego baixo alonga as fases (COMBAT §6.1): >50% normal, 25–50% +10%, <25% +25%.
static func frame_multiplier(f: FighterCombatState) -> float:
	var r: float = f.stamina_ratio()
	return 1.0 if r > 0.5 else (1.1 if r >= 0.25 else 1.25)


static func power_multiplier(f: FighterCombatState) -> float:
	var r: float = f.stamina_ratio()
	return 1.0 if r > 0.5 else (0.9 if r >= 0.25 else 0.75)


static func shock_threshold(f: FighterCombatState, bal: CombatBalanceDef) -> float:
	var stamina_factor: float = 0.85 + 0.15 * f.stamina_ratio()
	return bal.shock_base * (0.5 + f.attr(&"queixo") / 100.0) * (1.0 - f.zone_damage(&"head") / 150.0) \
		* stamina_factor * (0.9 + f.attr(&"compostura") / 1000.0)


## Tabela de COMBAT §6.3. `already_hurt`: defensor atordoado ou caído.
static func shock_state_for(ratio: float, already_hurt: bool, bal: CombatBalanceDef = null) -> FighterCombatState.Action:
	var b: CombatBalanceDef = bal if bal != null else CombatBalanceDef.new()
	if ratio >= b.knockout_ratio or (already_hurt and ratio >= b.stunned_ratio):
		return FighterCombatState.Action.OUT
	if ratio >= b.knockdown_ratio:
		return FighterCombatState.Action.DOWN
	if ratio >= b.stunned_ratio:
		return FighterCombatState.Action.STUNNED
	if ratio >= b.rocked_ratio:
		return FighterCombatState.Action.ROCKED
	return FighterCombatState.Action.IDLE


static func apply_hit(sim: CombatSim, d: FighterCombatState, e: CombatEvent, power: float, blocked: bool,
		events: Array[CombatEvent]) -> void:
	var bal: CombatBalanceDef = sim.balance
	var impact: float = power * (bal.block_damage_ratio if blocked else 1.0)
	if blocked:
		spend(d, power * bal.block_stamina_ratio, bal)
	var mitigation_attr: StringName = &"queixo" if e.zone == &"head" else &"robustez"
	var damage: float = impact * bal.damage_scale * (1.3 - d.attr(mitigation_attr) * 0.006)
	d.acute[e.zone] = float(d.acute[e.zone]) + damage * 0.7
	d.residual[e.zone] = float(d.residual[e.zone]) + damage * 0.3
	e.damage = damage
	if e.zone == &"body":
		d.reserve = maxf(bal.reserve_floor, d.reserve - damage * bal.body_damage_reserve_ratio)
		d.stamina = minf(d.stamina, d.reserve)
	if e.zone != &"head":
		return
	_maybe_cut(sim, d, e, blocked, events)
	var hurt: bool = d.action == FighterCombatState.Action.STUNNED or d.action == FighterCombatState.Action.DOWN
	var ratio: float = impact / shock_threshold(d, bal)
	e.impact_ratio = ratio
	var state: FighterCombatState.Action = shock_state_for(ratio, hurt, bal)
	if state == FighterCombatState.Action.IDLE:
		return
	var frames: int = {
		FighterCombatState.Action.ROCKED: bal.rocked_frames,
		FighterCombatState.Action.STUNNED: roundi(bal.stunned_frames * (1.3 - d.attr(&"compostura") * 0.006)),
		FighterCombatState.Action.DOWN: bal.knockdown_frames,
		FighterCombatState.Action.OUT: 0,
	}[state]
	d.set_action(state, frames)
	var shock: CombatEvent = CombatEvent.make(CombatEvent.Type.SHOCK, e.attacker, e.defender)
	shock.shock_state = state
	shock.impact_ratio = ratio
	events.append(shock)


## Cortes: cotoveladas cortam muito, golpes potentes às vezes; exige dano na cabeça acumulado.
static func _maybe_cut(sim: CombatSim, d: FighterCombatState, e: CombatEvent, blocked: bool, events: Array[CombatEvent]) -> void:
	var bal: CombatBalanceDef = sim.balance
	if blocked or d.cut >= 3 or d.zone_damage(&"head") < bal.cut_min_head_damage:
		return
	var chance: float = bal.cut_chance_other
	if e.strike_id == &"clinch_elbow":
		chance = bal.cut_chance_elbow
	elif e.strike_id in [&"cross", &"lead_hook", &"uppercut", &"high_kick", &"ground_and_pound"]:
		chance = bal.cut_chance_power
	if sim.rng.randf() < chance:
		d.cut += 1
		var ev: CombatEvent = CombatEvent.make(CombatEvent.Type.CUT, e.attacker, e.defender)
		ev.shock_state = d.cut
		events.append(ev)

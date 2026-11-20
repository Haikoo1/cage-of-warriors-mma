class_name TrainingSystem
extends RefCounted
## Plano semanal de 12 blocos (CAREER_DESIGN §4, R-016) aplicado ao lutador do jogador.
## Garantias contra evolução ilimitada (CHARACTER §7.1): teto de Potencial, Fadiga, idade, decaimento sem treino.

const PHYSICAL_DECAY: Array[StringName] = [&"condicionamento"]


static func run_week(c: CareerState, defs: Definitions, rng: RandomNumberGenerator) -> Array[String]:
	var notes: Array[String] = []
	var p: FighterState = c.player()
	if p == null or p.retired:
		return notes
	var bal: CareerBalanceDef = _balance(defs)
	var gym: GymDef = defs.gym(c.gym_id)
	var structure: int = gym.structure if gym != null else 2
	var trained: Dictionary = {}
	var age: float = p.age_years(c.week_index)
	var age_factor: float = 1.15 if age < bal.development_age else (1.0 if age < p.peak_age else 0.6)
	var injury_factor: float = 0.3 if not p.injury.is_empty() else 1.0
	for act_id: StringName in c.training_plan:
		var act: TrainingActivityDef = defs.training_activity(act_id)
		if act == null or (act.requires_fight and c.booked.is_empty()):
			continue
		if act.requires_fight:
			c.scouting_blocks += 1
		# Acima do limite o treinador recusa treino pesado (CAREER §4.2): o bloco vira descanso.
		if act.load > 5.0 and p.fatigue >= bal.fatigue_block_heavy:
			act = defs.training_activity(&"rest")
		var fatigue_factor: float = 1.0 if p.fatigue < bal.fatigue_penalty_start else maxf(0.25, 1.0 - (p.fatigue - bal.fatigue_penalty_start) / 60.0)
		var specialty: float = float(gym.specialties.get(String(act.area), 1.0)) if gym != null else 1.0
		for attr: Variant in act.gains:
			var key: StringName = StringName(attr)
			var cur: float = float(p.attributes.get(key, 0.0))
			var ceiling: float = clampf((p.potential - cur) / bal.potential_softness, 0.0, 1.0)
			var gain: float = float(act.gains[attr]) * specialty * fatigue_factor * age_factor * ceiling * injury_factor
			p.attributes[key] = minf(cur + gain, maxf(cur, p.potential))
			trained[key] = true
		p.fatigue = clampf(p.fatigue + act.load, 0.0, 100.0)
		c.money += act.money_per_block
		if act.injury_risk > 0.0 and p.injury.is_empty():
			var risk: float = act.injury_risk * (1.0 + maxf(0.0, p.fatigue - 40.0) / 30.0) * (1.2 - structure * 0.08) * bal.training_injury_scale
			if rng.randf() < risk:
				HealthSystem.inflict_injury(c, p, rng, false)
				notes.append("Lesão no treino: %s (%d semanas)." % [p.injury["name"], p.injury["weeks"]])
	# Sem treino, o condicionamento cai rápido e os técnicos devagar (CHARACTER §2).
	for attr: StringName in AttributeIds.ALL:
		if trained.has(attr):
			continue
		var decay: float = bal.conditioning_decay if PHYSICAL_DECAY.has(attr) else bal.untrained_decay
		p.attributes[attr] = maxf(1.0, float(p.attributes[attr]) - decay)
	var recovery: float = (bal.weekly_fatigue_recovery + p.fatigue * bal.fatigue_recovery_ratio) \
		* (0.6 + p.attributes[&"recuperacao"] / 125.0) * (0.9 + structure * 0.05)
	p.fatigue = clampf(p.fatigue - recovery, 0.0, 100.0)
	return notes


## Previsão de fadiga da semana para a UI (sem alterar o estado).
static func forecast_load(c: CareerState, defs: Definitions) -> float:
	var total: float = 0.0
	for act_id: StringName in c.training_plan:
		var act: TrainingActivityDef = defs.training_activity(act_id)
		if act != null:
			total += act.load
	return total


static func _balance(defs: Definitions) -> CareerBalanceDef:
	return defs.career_balance if defs.career_balance != null else CareerBalanceDef.new()

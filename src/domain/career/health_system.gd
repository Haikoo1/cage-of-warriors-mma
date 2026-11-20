class_name HealthSystem
extends RefCounted
## Lesões, cura, envelhecimento e evolução mensal dos NPCs (CAREER_DESIGN §5, CHARACTER §7).

const INJURIES_MINOR: Array[String] = ["Contusão na costela", "Entorse no tornozelo", "Corte no supercílio", "Dor no ombro"]
const INJURIES_MODERATE: Array[String] = ["Fratura na mão", "Entorse no joelho", "Costela trincada", "Lesão no punho"]
const PHYSICAL: Array[StringName] = [&"velocidade", &"recuperacao", &"mobilidade", &"condicionamento", &"forca"]


static func inflict_injury(c: CareerState, f: FighterState, rng: RandomNumberGenerator, from_fight: bool) -> void:
	var moderate: bool = rng.randf() < (0.45 if from_fight else 0.25)
	var names: Array[String] = INJURIES_MODERATE if moderate else INJURIES_MINOR
	var weeks: int = rng.randi_range(4, 10) if moderate else rng.randi_range(1, 3)
	f.injury = {"name": names[rng.randi_range(0, names.size() - 1)], "weeks": weeks}
	f.unavailable_until = maxi(f.unavailable_until, c.week_index + weeks)


static func heal_week(c: CareerState) -> Array[String]:
	var notes: Array[String] = []
	for f: FighterState in c.fighters.values():
		if f.injury.is_empty():
			continue
		f.injury["weeks"] = int(f.injury["weeks"]) - 1
		if int(f.injury["weeks"]) <= 0:
			if f.id == c.player_fighter_id:
				notes.append("Liberado pelo médico: %s curada." % f.injury["name"])
			f.injury = {}
	return notes


## Aplicado no 1º tick de cada mês: declínio após o pico (todos) e evolução agregada dos NPCs (LOD, CAREER §11.3).
static func age_month(c: CareerState, defs: Definitions, rng: RandomNumberGenerator) -> void:
	var bal: CareerBalanceDef = defs.career_balance if defs.career_balance != null else CareerBalanceDef.new()
	for f: FighterState in c.fighters.values():
		if f.retired:
			continue
		var age: float = f.age_years(c.week_index)
		if age > f.peak_age:
			var years_past: float = age - f.peak_age
			for attr: StringName in PHYSICAL:
				var loss: float = bal.physical_decline_per_month * (1.0 + years_past * 0.15) * rng.randf_range(0.7, 1.3)
				f.attributes[attr] = maxf(1.0, float(f.attributes[attr]) - loss)
			f.attributes[&"defesa_em_pe"] = maxf(1.0, float(f.attributes[&"defesa_em_pe"]) - bal.physical_decline_per_month * 0.5)
		elif f.id != c.player_fighter_id:
			for k: int in 3:
				var attr: StringName = AttributeIds.ALL[rng.randi_range(0, AttributeIds.ALL.size() - 1)]
				var cur: float = float(f.attributes[attr])
				if cur < f.potential:
					f.attributes[attr] = minf(f.potential, cur + rng.randf_range(0.3, 1.2))
		# Desgaste acumulado reduz o queixo de forma permanente (CHARACTER §7.4).
		if f.career_wear > 30.0:
			f.attributes[&"queixo"] = maxf(1.0, float(f.attributes[&"queixo"]) - f.career_wear / 400.0)

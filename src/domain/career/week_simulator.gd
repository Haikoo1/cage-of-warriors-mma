class_name WeekSimulator
extends RefCounted
## Tick semanal em ordem fixa (CAREER_ARCHITECTURE §2, GAME_SYSTEMS §4): treino → saúde → mundo → matchmaking →
## economia → reputação → avanço da data. Não passa por cima de uma luta marcada do jogador.


static func simulate_week(c: CareerState, defs: Definitions) -> Dictionary:
	var report: Dictionary = {"blocked": false, "notes": [], "stop": false}
	if not c.booked.is_empty() and int(c.booked["week"]) <= c.week_index:
		report["blocked"] = true
		report["stop"] = true
		return report
	var notes: Array = []
	notes.append_array(TrainingSystem.run_week(c, defs, CareerRng.make(c, &"training")))
	notes.append_array(HealthSystem.heal_week(c))
	notes.append_array(WorldSimulator.run_week(c, defs))
	var offers_before: int = c.offers.size()
	notes.append_array(Matchmaking.run_week(c, defs, CareerRng.make(c, &"matchmaking")))
	var bal: CareerBalanceDef = defs.career_balance if defs.career_balance != null else CareerBalanceDef.new()
	var gym: GymDef = defs.gym(c.gym_id)
	c.money -= bal.cost_of_living_week + (gym.monthly_cost / 4.0 if gym != null else 0.0)
	var p: FighterState = c.player()
	if p != null:
		p.popularity = maxf(0.0, p.popularity - bal.popularity_decay_week)
	c.week_index += 1
	for n: String in notes:
		c.add_news(n)
	report["notes"] = notes
	# Paradas do avanço rápido (CAREER §3.2): oferta nova, lesão, semana da luta.
	var fight_week: bool = not c.booked.is_empty() and int(c.booked["week"]) <= c.week_index
	report["stop"] = c.offers.size() > offers_before or fight_week or (p != null and not p.injury.is_empty() and notes.size() > 0)
	return report

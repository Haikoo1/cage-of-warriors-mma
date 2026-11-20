class_name Judging
extends RefCounted
## Três juízes simulados no sistema de 10 pontos (COMBAT_DESIGN §7.4, R-019). Função pura.
## Critérios em ordem: golpes/grappling efetivos, agressividade efetiva, controle. Pesos por juiz = [PROV].


class FighterRoundStats:
	var damage_dealt: float = 0.0
	var knockdowns: int = 0
	var grapple_successes: int = 0
	var control_frames: int = 0

	func to_dict() -> Dictionary:
		return {"damage": snappedf(damage_dealt, 0.1), "knockdowns": knockdowns,
			"grapple": grapple_successes, "control_s": snappedf(control_frames / 60.0, 0.1)}


## Pesos (golpes, grappling, controle) e ruído relativo de cada juiz [PROV].
const JUDGES: Array = [
	{"strike": 1.0, "grapple": 1.0, "control": 0.2, "noise": 0.05},  # equilibrado
	{"strike": 1.0, "grapple": 0.5, "control": 0.05, "noise": 0.05},  # valoriza trocação
	{"strike": 0.8, "grapple": 1.2, "control": 0.3, "noise": 0.05},  # valoriza grappling
]
const POINTS_PER_GRAPPLE: float = 4.0
const KNOCKDOWN_POINTS: float = 15.0
const EVEN_MARGIN: float = 1.0
const DOMINANCE_RATIO: float = 4.0
const DOMINANCE_MIN: float = 80.0


## Devolve uma cartela [pontos A, pontos B] por juiz.
static func score_round(a: FighterRoundStats, b: FighterRoundStats, rng: RandomNumberGenerator) -> Array:
	var cards: Array = []
	for j: Dictionary in JUDGES:
		var sa: float = _total(a, j)
		var sb: float = _total(b, j)
		var scale: float = maxf(sa, sb)
		sa += rng.randf_range(-j["noise"], j["noise"]) * scale
		sb += rng.randf_range(-j["noise"], j["noise"]) * scale
		if absf(sa - sb) < EVEN_MARGIN:
			cards.append([10, 10])
			continue
		var a_wins: bool = sa > sb
		var w: FighterRoundStats = a if a_wins else b
		var l: FighterRoundStats = b if a_wins else a
		var hi: float = maxf(sa, sb)
		var lo: float = maxf(0.0, minf(sa, sb))
		var dominant: bool = (w.knockdowns - l.knockdowns) >= 2 or (hi > DOMINANCE_MIN and hi > lo * DOMINANCE_RATIO)
		var loser_points: int = 8 if dominant else 9
		cards.append([10, loser_points] if a_wins else [loser_points, 10])
	return cards


## Totais por juiz → [FightResult.Method, FightResult.FighterSlot].
static func decide(totals: Array) -> Array:
	var votes_a: int = 0
	var votes_b: int = 0
	var draws: int = 0
	for card: Array in totals:
		if card[0] > card[1]:
			votes_a += 1
		elif card[1] > card[0]:
			votes_b += 1
		else:
			draws += 1
	for side: Array in [[votes_a, votes_b, FightResult.FighterSlot.A], [votes_b, votes_a, FightResult.FighterSlot.B]]:
		var mine: int = side[0]
		var theirs: int = side[1]
		if mine == 3:
			return [FightResult.Method.DECISION_UNANIMOUS, side[2]]
		if mine == 2 and theirs == 1:
			return [FightResult.Method.DECISION_SPLIT, side[2]]
		if mine == 2 and draws == 1:
			return [FightResult.Method.DECISION_MAJORITY, side[2]]
	return [FightResult.Method.DRAW, FightResult.FighterSlot.NONE]


static func _total(s: FighterRoundStats, j: Dictionary) -> float:
	return j["strike"] * (s.damage_dealt + KNOCKDOWN_POINTS * s.knockdowns) \
		+ j["grapple"] * POINTS_PER_GRAPPLE * s.grapple_successes \
		+ j["control"] * s.control_frames / 60.0

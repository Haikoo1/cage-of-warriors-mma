class_name WeightSystem
extends RefCounted
## Corte de peso e pesagem (CAREER_DESIGN §6): desidratação reduz Reserva e Queixo efetivos só no dia da luta.


static func cut_fraction(f: FighterState, wc: WeightClassDef, short_notice: bool) -> float:
	var walk: float = f.physique.walk_weight_kg
	var cut: float = maxf(0.0, (walk - wc.limit_kg()) / walk)
	return cut + (0.02 if short_notice else 0.0)


static func reserve_multiplier(cut: float, bal: CareerBalanceDef) -> float:
	if cut <= bal.cut_soft:
		return 1.0
	if cut <= bal.cut_hard:
		return 0.95
	if cut <= bal.cut_extreme:
		return 0.9
	return 0.8


static func chin_modifier(cut: float, bal: CareerBalanceDef) -> float:
	if cut > bal.cut_extreme:
		return -6.0
	if cut > bal.cut_hard:
		return -3.0
	return 0.0


## Resultado da pesagem: {cut, reserve, chin, made_weight}.
static func weigh_in(f: FighterState, wc: WeightClassDef, bal: CareerBalanceDef, short_notice: bool,
		rng: RandomNumberGenerator) -> Dictionary:
	var cut: float = cut_fraction(f, wc, short_notice)
	var miss_chance: float = 0.3 if cut > bal.cut_extreme else (0.05 if cut > bal.cut_hard else 0.0)
	return {
		"cut": cut, "reserve": reserve_multiplier(cut, bal), "chin": chin_modifier(cut, bal),
		"made_weight": rng.randf() >= miss_chance,
	}

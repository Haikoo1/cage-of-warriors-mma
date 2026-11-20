class_name Rankings
extends RefCounted
## Consultas de ranking (CAREER_DESIGN §9): por organização e categoria, campeão primeiro, depois rating.
## Rankings não são salvos: são derivados do estado (uma fonte de verdade só).


static func roster(c: CareerState, org: StringName, wc: StringName) -> Array[FighterState]:
	var list: Array[FighterState] = []
	for f: FighterState in c.fighters.values():
		if not f.retired and f.org_id == org and f.weight_class_id == wc:
			list.append(f)
	var champ: StringName = c.champion(org, wc)
	list.sort_custom(func(x: FighterState, y: FighterState) -> bool:
		if x.id == champ:
			return true
		if y.id == champ:
			return false
		if not is_equal_approx(x.rating, y.rating):
			return x.rating > y.rating
		return String(x.id) < String(y.id))
	return list


## Posição 0 = campeão; -1 se não está no elenco.
static func rank_of(c: CareerState, f: FighterState) -> int:
	return roster(c, f.org_id, f.weight_class_id).find(f)

class_name Matchmaking
extends RefCounted
## Ofertas de luta e de contrato ao jogador (CAREER_DESIGN §8). Oferta = Dictionary serializável:
## {kind: "fight"|"contract", opponent, org, week, title, show, win, expires, short, fights}


static func run_week(c: CareerState, defs: Definitions, rng: RandomNumberGenerator) -> Array[String]:
	var notes: Array[String] = []
	c.offers = c.offers.filter(func(o: Dictionary) -> bool: return int(o["expires"]) >= c.week_index)
	var p: FighterState = c.player()
	if p == null or p.retired:
		return notes
	var bal: CareerBalanceDef = defs.career_balance if defs.career_balance != null else CareerBalanceDef.new()
	var org: OrganizationDef = defs.organization(p.org_id)
	# Convite da organização do nível acima (CAREER §8.5–8.6).
	var next_org: OrganizationDef = _next_tier(defs, org)
	var rank: int = Rankings.rank_of(c, p)
	var has_contract_offer: bool = c.offers.any(func(o: Dictionary) -> bool: return o["kind"] == "contract")
	if next_org != null and not has_contract_offer and rank >= 0 and rank <= 3 and p.streak >= 2 and p.rating >= next_org.min_rating:
		c.offers.append({"kind": "contract", "org": String(next_org.id), "fights": next_org.contract_fights,
			"show": next_org.show_purse, "win": next_org.win_purse, "expires": c.week_index + 4, "opponent": "", "week": 0,
			"title": false, "short": false, "rivalry": false, "countered": false})
		notes.append("Convite: contrato de %d lutas com o %s." % [next_org.contract_fights, next_org.display_name])
	var fight_offers: int = c.offers.filter(func(o: Dictionary) -> bool: return o["kind"] == "fight").size()
	var chance: float = bal.offer_chance * (0.6 + c.relationship(p.org_id) / 125.0)
	if not c.booked.is_empty() or not p.is_available(c.week_index + 3) or fight_offers > 0 or rng.randf() > chance:
		return notes
	var candidates: Array[FighterState] = []
	for f: FighterState in Rankings.roster(c, p.org_id, p.weight_class_id):
		if f != p and f.is_available(c.week_index + bal.camp_weeks_min):
			candidates.append(f)
	candidates.sort_custom(func(x: FighterState, y: FighterState) -> bool: return absf(x.rating - p.rating) < absf(y.rating - p.rating))
	# Rival disponível vai para o topo da lista (CAREER §10.6).
	for k: int in candidates.size():
		if c.rivals.has(String(candidates[k].id)):
			var rival: FighterState = candidates[k]
			candidates.remove_at(k)
			candidates.push_front(rival)
			break
	var champ: StringName = c.champion(p.org_id, p.weight_class_id)
	var count: int = mini(rng.randi_range(1, 3), candidates.size())
	var fame: float = 1.0 + p.popularity / 100.0
	for k: int in count:
		var opp: FighterState = candidates[k]
		var short: bool = k == 0 and rng.randf() < 0.15
		var title: bool = opp.id == champ and rank >= 0 and rank <= 2
		var rivalry: bool = c.rivals.has(String(opp.id))
		var mult: float = fame * (1.0 + bal.short_notice_bonus if short else 1.0) * (2.0 if title else 1.0) * (1.3 if rivalry else 1.0) \
			* (0.9 + c.relationship(p.org_id) / 500.0)
		c.offers.append({"kind": "fight", "opponent": String(opp.id), "org": String(p.org_id),
			"week": c.week_index + (3 if short else rng.randi_range(bal.camp_weeks_min, bal.camp_weeks_max)),
			"title": title, "short": short, "show": snappedf(org.show_purse * mult, 1.0), "win": snappedf(org.win_purse * mult, 1.0),
			"expires": c.week_index + 2, "fights": 0, "rivalry": rivalry, "countered": false})
	if count > 0:
		notes.append("%d nova(s) oferta(s) de luta." % count)
	return notes


static func accept_offer(c: CareerState, index: int) -> bool:
	if index < 0 or index >= c.offers.size():
		return false
	var o: Dictionary = c.offers[index]
	var p: FighterState = c.player()
	if o["kind"] == "contract":
		p.org_id = StringName(o["org"])
		p.contract_fights_left = int(o["fights"])
		c.booked = {}
		c.offers.clear()
		c.add_news("%s assina com o %s." % [p.display_name, o["org"]])
		return true
	if not c.booked.is_empty():
		return false
	var opp: FighterState = c.get_fighter(StringName(o["opponent"]))
	if opp == null or not opp.is_available(c.week_index):
		c.offers.remove_at(index)
		return false
	c.booked = o.duplicate()
	c.scouting_blocks = 0
	if bool(o.get("short", false)):
		c.change_relationship(StringName(o["org"]), 5.0)  # salvar o card rende boa vontade
	c.offers = c.offers.filter(func(x: Dictionary) -> bool: return x["kind"] == "contract")
	c.add_news("Luta marcada contra %s na semana %d." % [opp.display_name, int(o["week"]) + 1])
	return true


## Recusar custa relação com a organização (CAREER §8.1).
static func decline_offer(c: CareerState, index: int) -> void:
	if index >= 0 and index < c.offers.size():
		c.change_relationship(StringName(c.offers[index]["org"]), -3.0)
		c.offers.remove_at(index)


## Contraproposta (CAREER §8.3): uma por oferta. Aceita -> bolsa maior; recusada -> oferta retirada e relação cai.
static func counter_offer(c: CareerState, index: int, rng: RandomNumberGenerator) -> bool:
	if index < 0 or index >= c.offers.size():
		return false
	var o: Dictionary = c.offers[index]
	if bool(o.get("countered", false)):
		return false
	var org: StringName = StringName(o["org"])
	var accept: float = 0.35 + c.relationship(org) / 250.0 + c.player().popularity / 400.0
	if rng.randf() < accept:
		var raise: float = 1.2 if o["kind"] == "fight" else 1.15
		o["show"] = snappedf(float(o["show"]) * raise, 1.0)
		o["win"] = snappedf(float(o["win"]) * raise, 1.0)
		o["countered"] = true
		c.add_news("Contraproposta aceita: bolsa melhorou.")
		return true
	c.change_relationship(org, -5.0)
	c.offers.remove_at(index)
	c.add_news("Contraproposta recusada: a oferta foi retirada.")
	return false


static func _next_tier(defs: Definitions, org: OrganizationDef) -> OrganizationDef:
	if org == null:
		return null
	for o: OrganizationDef in defs.organizations_by_tier():
		if o.tier == org.tier + 1:
			return o
	return null

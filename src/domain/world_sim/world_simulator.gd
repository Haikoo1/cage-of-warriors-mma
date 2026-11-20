class_name WorldSimulator
extends RefCounted
## O mundo continua sem o jogador (CAREER_DESIGN §11): eventos, lutas simuladas, títulos, transferências,
## aposentadorias e novos atletas. Custo baixo: resolvedor estatístico, sem motor de combate.


static func run_week(c: CareerState, defs: Definitions) -> Array[String]:
	var notes: Array[String] = []
	var rng: RandomNumberGenerator = CareerRng.make(c, &"world")
	var reserved: Dictionary = {}
	reserved[c.player_fighter_id] = true
	if not c.booked.is_empty():
		reserved[StringName(c.booked["opponent"])] = true
	for org: OrganizationDef in defs.organizations_by_tier():
		if (c.week_index + org.tier) % org.event_interval_weeks != 0:
			continue
		var event_no: int = (c.week_index + org.tier) / org.event_interval_weeks
		for wc: StringName in defs.weight_classes:
			_run_event_class(c, defs, org, wc, event_no, reserved, rng)
	if c.week_index % 4 == 0:
		HealthSystem.age_month(c, defs, CareerRng.make(c, &"aging"))
		prune_retired(c)
		notes.append_array(_monthly_population(c, defs, rng))
	return notes


static func _run_event_class(c: CareerState, defs: Definitions, org: OrganizationDef, wc: StringName, event_no: int,
		reserved: Dictionary, rng: RandomNumberGenerator) -> void:
	var available: Array[FighterState] = []
	for f: FighterState in Rankings.roster(c, org.id, wc):
		if f.is_available(c.week_index) and not reserved.has(f.id):
			available.append(f)
	var rules: RuleSetDef = defs.rule_set(org.ruleset_id)
	var bouts: int = 0
	# Disputa de título a cada 4 eventos: campeão x melhor desafiante disponível (CAREER §7.3).
	var champ: StringName = c.champion(org.id, wc)
	if event_no % 4 == 0 and available.size() >= 2 and available[0].id == champ:
		_fight(c, defs, available[0], available[1], org, true, rules.rounds_title if rules else 5, rng)
		reserved[available[0].id] = true
		reserved[available[1].id] = true
		available = available.slice(2)
		bouts += 1
	var i: int = rng.randi_range(0, maxi(0, available.size() - 2))
	while bouts < org.bouts_per_class and i + 1 < available.size():
		_fight(c, defs, available[i], available[i + 1], org, false, rules.rounds_normal if rules else 3, rng)
		reserved[available[i].id] = true
		reserved[available[i + 1].id] = true
		i += 2
		bouts += 1


static func _fight(c: CareerState, defs: Definitions, a: FighterState, b: FighterState, org: OrganizationDef, title: bool,
		rounds: int, rng: RandomNumberGenerator) -> void:
	var r: FightResult = FightResolver.resolve(a, b, rounds, rng)
	ResultApplier.apply(c, defs, {"a": String(a.id), "b": String(b.id), "org": String(org.id), "title": title,
		"show": org.show_purse, "win": org.win_purse}, r)


## Mensal: aposentadorias, transferências de fim de contrato, títulos vagos e novos atletas.
static func _monthly_population(c: CareerState, defs: Definitions, rng: RandomNumberGenerator) -> Array[String]:
	var notes: Array[String] = []
	var bal: CareerBalanceDef = defs.career_balance if defs.career_balance != null else CareerBalanceDef.new()
	var tiers: Array[OrganizationDef] = defs.organizations_by_tier()
	for f: FighterState in c.fighters.values():
		if f.retired or f.id == c.player_fighter_id:
			continue
		var age: float = f.age_years(c.week_index)
		if age > bal.npc_retire_age + rng.randi_range(0, 4) or f.career_wear > bal.retirement_wear:
			f.retired = true
			f.retired_week = c.week_index
			continue
		if f.contract_fights_left > 0:
			continue
		var tier: int = defs.organization(f.org_id).tier if defs.organization(f.org_id) else 1
		var rank: int = Rankings.rank_of(c, f)
		if tier < 4 and rank >= 0 and rank <= 2 and f.streak >= 2:
			var up: OrganizationDef = tiers[tier]
			f.org_id = up.id
			f.contract_fights_left = up.contract_fights
		elif tier > 1 and f.streak <= -3:
			var down: OrganizationDef = tiers[tier - 2]
			f.org_id = down.id
			f.contract_fights_left = down.contract_fights
		else:
			f.contract_fights_left = defs.organization(f.org_id).contract_fights
	for wc: WeightClassDef in defs.weight_classes.values():
		for org: OrganizationDef in tiers:
			var champ: FighterState = c.get_fighter(c.champion(org.id, wc.id))
			if champ == null or champ.retired or champ.org_id != org.id:
				var roster: Array[FighterState] = Rankings.roster(c, org.id, wc.id)
				var best: FighterState = null
				for f: FighterState in roster:
					if f.id != (champ.id if champ else &"") and (best == null or f.rating > best.rating):
						best = f
				if best != null:
					c.set_champion(org.id, wc.id, best.id)
					best.titles += 1
			var count: int = Rankings.roster(c, org.id, wc.id).size()
			if org.tier == 1:
				for k: int in bal.prospects_per_month:
					if count < org.roster_per_class + 2:
						c.add_fighter(CareerFactory.generate_npc(c, defs, wc, org, rng, rng.randi_range(19, 23)))
						count += 1
			elif count < org.roster_per_class - 2:
				# Organização com elenco curto contrata do nível de baixo (simplificação de LOD).
				var below: Array[FighterState] = Rankings.roster(c, tiers[org.tier - 2].id, wc.id)
				for f: FighterState in below:
					if f.id != c.player_fighter_id:
						f.org_id = org.id
						f.contract_fights_left = org.contract_fights
						break
	return notes


## Poda de memória (M3: o save crescia sem limite). Remove NPCs aposentados há mais de 2 anos que não sejam
## campeões nem ex-adversários/rivais do jogador. O histórico do jogador guarda o nome do adversário.
static func prune_retired(c: CareerState) -> void:
	var keep: Dictionary = {}
	var p: FighterState = c.player()
	if p != null:
		for h: Dictionary in p.history:
			keep[String(h["opponent"])] = true
	for rid: String in c.rivals:
		keep[rid] = true
	for champ: Variant in c.champions.values():
		keep[String(champ)] = true
	if not c.booked.is_empty():
		keep[String(c.booked["opponent"])] = true
	for id: StringName in c.fighters.keys():
		var f: FighterState = c.fighters[id]
		if f.retired and id != c.player_fighter_id and c.week_index - f.retired_week > 104 and not keep.has(String(id)):
			c.fighters.erase(id)

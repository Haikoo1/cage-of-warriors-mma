class_name CareerFactory
extends RefCounted
## Cria uma carreira nova: o lutador do jogador e o mundo inicial (CAREER_DESIGN §2, §11.2).
## Mundo gerado proceduralmente com semente: lutadores fictícios em todas as categorias e organizações (D-010).

const FIRST_NAMES_M: Array[String] = ["Rafael", "Diego", "Marcus", "Kenji", "Ivan", "Tomás", "Lucas", "André", "Yusuf", "Jamal",
	"Pedro", "Sergei", "Kai", "Mateo", "Omar", "Viktor", "Bruno", "Theo", "Hugo", "Caio", "Nico", "Felipe", "Arjun", "Leon"]
const FIRST_NAMES_F: Array[String] = ["Ana", "Lia", "Sofia", "Aiko", "Marina", "Elena", "Jade", "Nadia", "Carla", "Yara",
	"Bianca", "Irina", "Mei", "Lucía", "Zara", "Paula", "Tamires", "Hana", "Olga", "Rita"]
const LAST_NAMES: Array[String] = ["Silva", "Rocha", "Moreira", "Tanaka", "Petrov", "Duarte", "Okafor", "Reyes", "Costa", "Novak",
	"Ferreira", "Kim", "Almeida", "Haddad", "Santos", "Varga", "Lima", "Castro", "Nakamura", "Ruiz", "Brandão", "Kowalski",
	"Mendes", "Okoye", "Barros", "Ivanova", "Teixeira", "Morales", "Sato", "Pires"]
const NATIONS: Array[String] = ["Brasil", "EUA", "México", "Japão", "Rússia", "Polônia", "Nigéria", "Argentina", "Coreia", "Portugal"]
const STYLE_FOCUS: Dictionary = {
	&"arch_striker": [&"boxe", &"kickboxing", &"defesa_em_pe", &"velocidade"],
	&"arch_wrestler": [&"wrestling_ofensivo", &"wrestling_defensivo", &"controle_solo", &"forca"],
}


static func new_career(defs: Definitions, setup: CareerSetup) -> CareerState:
	var c: CareerState = CareerState.new()
	c.career_seed = setup.seed
	c.round_seconds = setup.round_seconds
	var rng: RandomNumberGenerator = CareerRng.make(c, &"world_gen")
	for wc: WeightClassDef in defs.weight_classes.values():
		for org: OrganizationDef in defs.organizations.values():
			for k: int in org.roster_per_class:
				c.add_fighter(generate_npc(c, defs, wc, org, rng))
	_crown_initial_champions(c, defs)
	var origin: OriginDef = defs.origin(setup.origin_id)
	var p: FighterState = FighterState.create_blank(c.next_id("F"), origin.default_attribute)
	p.display_name = setup.name
	p.nationality = setup.nationality
	p.weight_class_id = setup.weight_class_id
	var wcp: WeightClassDef = defs.weight_class(setup.weight_class_id)
	p.division = FighterState.Division.FEMALE if wcp.division == WeightClassDef.Division.FEMALE else FighterState.Division.MALE
	for attr: Variant in origin.base_attributes:
		p.attributes[StringName(attr)] = float(origin.base_attributes[attr])
	# Idade: mais velho começa melhor, com menos tempo até o pico (CAREER §2.2).
	var age_bonus: float = clampf((setup.age - 22) * 1.2, -5.0, 9.0)
	for attr: StringName in p.attributes:
		p.attributes[attr] = clampf(float(p.attributes[attr]) + age_bonus, 1.0, 100.0)
	p.birth_week = -setup.age * 52
	p.archetype_id = origin.archetype
	p.potential = 70.0 + rng.randf_range(0.0, 16.0)  # oculto (R-035)
	p.peak_age = rng.randi_range(28, 32)
	p.org_id = &"org_local"
	p.rating = 900.0
	p.popularity = 5.0
	_physique(p, wcp, rng)
	p.appearance = setup.appearance.duplicate_appearance()
	c.add_fighter(p)
	c.player_fighter_id = p.id
	c.money = origin.starting_money
	c.gym_id = origin.starting_gym
	c.training_plan = default_plan()
	c.add_news("%s estreia no %s." % [p.display_name, defs.organization(&"org_local").display_name])
	return c


static func default_plan() -> Array[StringName]:
	var plan: Array[StringName] = [&"boxing", &"wrestling", &"jiujitsu", &"conditioning", &"kickboxing", &"rest",
		&"sparring", &"movement", &"tactics", &"side_job", &"side_job", &"rest"]
	return plan


static func generate_npc(c: CareerState, defs: Definitions, wc: WeightClassDef, org: OrganizationDef,
		rng: RandomNumberGenerator, age_override: int = -1) -> FighterState:
	var f: FighterState = FighterState.create_blank(c.next_id("F"), 0.0)
	var female: bool = wc.division == WeightClassDef.Division.FEMALE
	f.division = FighterState.Division.FEMALE if female else FighterState.Division.MALE
	var first: Array[String] = FIRST_NAMES_F if female else FIRST_NAMES_M
	f.display_name = "%s %s" % [first[rng.randi_range(0, first.size() - 1)], LAST_NAMES[rng.randi_range(0, LAST_NAMES.size() - 1)]]
	f.nationality = NATIONS[rng.randi_range(0, NATIONS.size() - 1)]
	f.weight_class_id = wc.id
	f.archetype_id = &"arch_striker" if rng.randf() < 0.55 else &"arch_wrestler"
	var mean: float = org.attribute_mean + rng.randf_range(-5.0, 5.0)
	for attr: StringName in AttributeIds.ALL:
		f.attributes[attr] = clampf(mean + rng.randf_range(-9.0, 9.0), 10.0, 95.0)
	for attr: StringName in STYLE_FOCUS[f.archetype_id]:
		f.attributes[attr] = clampf(float(f.attributes[attr]) + rng.randf_range(6.0, 14.0), 10.0, 97.0)
	var age: int = age_override if age_override > 0 else rng.randi_range(20, 34)
	f.birth_week = c.week_index - age * 52 - rng.randi_range(0, 51)
	f.peak_age = rng.randi_range(27, 33)
	f.potential = clampf(mean + rng.randf_range(4.0, 18.0), 40.0, 96.0)
	f.org_id = org.id
	f.contract_fights_left = rng.randi_range(1, org.contract_fights)
	f.rating = 700.0 + org.tier * 150.0 + (mean - org.attribute_mean) * 10.0 + rng.randf_range(-60.0, 60.0)
	f.popularity = org.tier * 8.0 + rng.randf_range(0.0, 10.0)
	f.wins = rng.randi_range(org.tier, org.tier * 5)
	f.losses = rng.randi_range(0, org.tier * 2)
	_physique(f, wc, rng)
	f.appearance = Appearance.random(rng, not female)
	return f


static func _physique(f: FighterState, wc: WeightClassDef, rng: RandomNumberGenerator) -> void:
	var lb: float = wc.limit_lb
	var base_h: float = (150.0 if f.division == FighterState.Division.FEMALE else 158.0) + (lb - 115.0) * 0.17
	f.physique.height_cm = roundi(base_h + rng.randf_range(-6.0, 6.0))
	f.physique.reach_cm = f.physique.height_cm + rng.randi_range(-4, 10)
	f.physique.walk_weight_kg = snappedf(wc.limit_kg() * rng.randf_range(1.04, 1.13), 0.1)
	f.physique.biotype_id = StringName(wc.allowed_biotypes[0])
	f.physique.stance = Physique.Stance.SOUTHPAW if rng.randf() < 0.2 else Physique.Stance.ORTHODOX


static func _crown_initial_champions(c: CareerState, defs: Definitions) -> void:
	for wc: StringName in defs.weight_classes:
		for org: StringName in defs.organizations:
			var best: FighterState = null
			for f: FighterState in c.fighters.values():
				if f.org_id == org and f.weight_class_id == wc and (best == null or f.rating > best.rating):
					best = f
			if best != null:
				c.set_champion(org, wc, best.id)
				best.titles = 1

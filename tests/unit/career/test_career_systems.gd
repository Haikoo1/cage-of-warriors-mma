extends TestCase
## Regras da carreira (E-07 a E-09): criação, treino, idade, peso, resolvedor, aplicação de resultado, semana.


func _defs() -> Definitions:
	return DataLoader.load_from("res://data")


func _career(defs: Definitions, seed: int = 7) -> CareerState:
	var setup: CareerSetup = CareerSetup.new()
	setup.name = "Teste"
	setup.weight_class_id = &"m_lightweight"
	setup.origin_id = &"origin_mma"
	setup.age = 22
	setup.seed = seed
	return CareerFactory.new_career(defs, setup)


func _other(c: CareerState, p: FighterState) -> FighterState:
	for f: FighterState in Rankings.roster(c, p.org_id, p.weight_class_id):
		if f != p:
			return f
	return null


func _plan(activity: StringName) -> Array[StringName]:
	var p: Array[StringName] = []
	for i: int in 12:
		p.append(activity)
	return p


func test_new_career_populates_world_and_player() -> void:
	var defs: Definitions = _defs()
	var c: CareerState = _career(defs)
	var p: FighterState = c.player()
	assert_true(p != null, "lutador do jogador")
	assert_eq(p.org_id, &"org_local", "começa no circuito local")
	for wc: StringName in defs.weight_classes:
		for org: OrganizationDef in defs.organizations.values():
			assert_true(Rankings.roster(c, org.id, wc).size() >= org.roster_per_class, "%s/%s povoado" % [org.id, wc])
			assert_true(c.champion(org.id, wc) != &"", "campeão em %s/%s" % [org.id, wc])


func test_focused_training_raises_trained_attribute_and_fatigue() -> void:
	var defs: Definitions = _defs()
	var c: CareerState = _career(defs)
	var p: FighterState = c.player()
	var before: float = p.attributes[&"boxe"]
	c.training_plan = _plan(&"boxing")
	TrainingSystem.run_week(c, defs, CareerRng.make(c, &"training"))
	assert_true(p.attributes[&"boxe"] > before, "boxe subiu")
	assert_true(p.fatigue > 0.0, "fadiga")


func test_cannot_maximize_everything_heavy_plan_loses_to_balanced() -> void:
	var defs: Definitions = _defs()
	var heavy: CareerState = _career(defs)
	var balanced: CareerState = _career(defs)
	heavy.training_plan = _plan(&"sparring")
	var bp: Array[StringName] = _plan(&"boxing")
	for k: int in [3, 7, 11]:
		bp[k] = &"rest"
	balanced.training_plan = bp
	var gain: Array[float] = [0.0, 0.0]
	var k2: int = 0
	for c: CareerState in [heavy, balanced]:
		var before: float = c.player().attributes[&"boxe"]
		for w: int in 6:
			TrainingSystem.run_week(c, defs, CareerRng.make(c, &"training"))
			c.player().injury = {}
		gain[k2] = c.player().attributes[&"boxe"] - before
		k2 += 1
	# Acima de 90 o treinador converte treino pesado em descanso (CAREER §4.2): a fadiga oscila alta, não trava em 100.
	assert_true(heavy.player().fatigue > 45.0, "plano pesado mantém fadiga alta (%f)" % heavy.player().fatigue)
	assert_true(balanced.player().fatigue + 20.0 < heavy.player().fatigue, "equilibrado cansa bem menos (%f x %f)" % [balanced.player().fatigue, heavy.player().fatigue])


func test_rest_lowers_fatigue() -> void:
	var defs: Definitions = _defs()
	var c: CareerState = _career(defs)
	c.player().fatigue = 80.0
	c.training_plan = _plan(&"rest")
	TrainingSystem.run_week(c, defs, CareerRng.make(c, &"training"))
	assert_true(c.player().fatigue < 40.0, "descanso recupera")


func test_attribute_does_not_pass_potential() -> void:
	var defs: Definitions = _defs()
	var c: CareerState = _career(defs)
	var p: FighterState = c.player()
	p.potential = 50.0
	p.attributes[&"boxe"] = 49.9
	c.training_plan = _plan(&"boxing")
	for w: int in 10:
		p.fatigue = 0.0
		p.injury = {}
		TrainingSystem.run_week(c, defs, CareerRng.make(c, &"training"))
	assert_true(p.attributes[&"boxe"] <= 50.0 + 0.001, "teto do Potencial (%f)" % p.attributes[&"boxe"])


func test_aging_past_peak_lowers_speed() -> void:
	var defs: Definitions = _defs()
	var c: CareerState = _career(defs)
	var p: FighterState = c.player()
	p.birth_week = c.week_index - 35 * 52
	p.peak_age = 30
	var before: float = p.attributes[&"velocidade"]
	HealthSystem.age_month(c, defs, CareerRng.make(c, &"aging"))
	assert_true(p.attributes[&"velocidade"] < before, "velocidade cai após o pico")


func test_weight_cut_bands() -> void:
	var bal: CareerBalanceDef = CareerBalanceDef.new()
	assert_almost(WeightSystem.reserve_multiplier(0.03, bal), 1.0)
	assert_true(WeightSystem.reserve_multiplier(0.10, bal) < 1.0, "corte pesado tira Reserva")
	assert_true(WeightSystem.reserve_multiplier(0.14, bal) < WeightSystem.reserve_multiplier(0.10, bal), "extremo tira mais")


func test_resolver_favors_better_fighter_and_finishes_some_fights() -> void:
	var defs: Definitions = _defs()
	var strong: FighterState = FighterState.create_blank(&"S", 70.0)
	var weak: FighterState = FighterState.create_blank(&"W", 52.0)
	var even_a: FighterState = FighterState.create_blank(&"A", 60.0)
	var even_b: FighterState = FighterState.create_blank(&"B", 60.0)
	var wins: int = 0
	var finishes: int = 0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for k: int in 100:
		rng.seed = k
		if FightResolver.resolve(strong, weak, 3, rng).winner == FightResult.FighterSlot.A:
			wins += 1
		var r: FightResult = FightResolver.resolve(even_a, even_b, 3, rng)
		if r.method in [FightResult.Method.KO, FightResult.Method.TKO, FightResult.Method.SUBMISSION]:
			finishes += 1
	assert_true(wins >= 75, "favorito vence %d/100" % wins)
	assert_true(finishes >= 20 and finishes <= 70, "finalizações entre lutas parelhas: %d/100" % finishes)


func test_applying_result_updates_records_rating_money_and_suspension() -> void:
	var defs: Definitions = _defs()
	var c: CareerState = _career(defs)
	var p: FighterState = c.player()
	var opp: FighterState = _other(c, p)
	var money: float = c.money
	var rating: float = p.rating
	var opp_losses: int = opp.losses
	var r: FightResult = FightResult.new()
	r.winner = FightResult.FighterSlot.A
	r.method = FightResult.Method.KO
	r.round = 1
	r.time_seconds = 90
	var bout: Dictionary = {"a": String(p.id), "b": String(opp.id), "org": "org_local", "title": false, "show": 600.0, "win": 600.0}
	ResultApplier.apply(c, defs, bout, r)
	assert_eq(p.wins, 1)
	assert_eq(opp.losses, opp_losses + 1, "derrota do adversário")
	assert_true(p.rating > rating, "rating sobe")
	assert_true(c.money > money, "bolsa recebida")
	assert_true(opp.unavailable_until > c.week_index, "suspensão médica após KO")
	assert_eq(p.history.size(), 1, "histórico")


func test_world_keeps_running_without_player() -> void:
	var defs: Definitions = _defs()
	var c: CareerState = _career(defs)
	var fights_before: int = 0
	for f: FighterState in c.fighters.values():
		fights_before += f.wins + f.losses
	for w: int in 12:
		c.booked = {}
		WeekSimulator.simulate_week(c, defs)
	var fights_after: int = 0
	for f: FighterState in c.fighters.values():
		fights_after += f.wins + f.losses
	assert_eq(c.week_index, 12)
	assert_true(fights_after > fights_before + 50, "NPCs lutaram (%d → %d)" % [fights_before, fights_after])


func test_player_receives_offers_and_can_book_a_fight() -> void:
	var defs: Definitions = _defs()
	var c: CareerState = _career(defs)
	for w: int in 10:
		if not c.offers.is_empty():
			break
		WeekSimulator.simulate_week(c, defs)
	assert_false(c.offers.is_empty(), "recebeu oferta")
	assert_true(Matchmaking.accept_offer(c, 0), "aceitou")
	assert_false(c.booked.is_empty(), "luta marcada")
	assert_true(int(c.booked["week"]) > c.week_index, "luta no futuro")


func test_week_does_not_pass_a_booked_fight() -> void:
	var defs: Definitions = _defs()
	var c: CareerState = _career(defs)
	var opp: FighterState = _other(c, c.player())
	c.booked = {"opponent": String(opp.id), "org": "org_local", "week": c.week_index, "title": false, "show": 600.0, "win": 600.0}
	var report: Dictionary = WeekSimulator.simulate_week(c, defs)
	assert_true(report["blocked"], "semana da luta: precisa lutar antes")
	assert_eq(c.week_index, 0)


func test_career_save_round_trip_is_stable() -> void:
	var defs: Definitions = _defs()
	var c: CareerState = _career(defs)
	for w: int in 6:
		c.booked = {}
		WeekSimulator.simulate_week(c, defs)
	var once: CareerState = CareerState.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())))
	var twice: CareerState = CareerState.from_dict(JSON.parse_string(JSON.stringify(once.to_dict())))
	assert_eq(JSON.stringify(twice.to_dict()), JSON.stringify(once.to_dict()), "estável após salvar")
	assert_eq(once.fighters.size(), c.fighters.size())
	assert_eq(once.player().wins, c.player().wins)

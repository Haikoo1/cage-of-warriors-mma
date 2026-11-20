extends TestCase
## Profundidade da carreira: scouting, rivalidade, contraproposta e relação com a organização.


func _cc(seed: int = 21) -> CareerController:
	var setup: CareerSetup = CareerSetup.new()
	setup.seed = seed
	return CareerController.create(DataLoader.load_from("res://data"), setup, 5)


func _book(cc: CareerController) -> FighterState:
	var p: FighterState = cc.state.player()
	for f: FighterState in Rankings.roster(cc.state, p.org_id, p.weight_class_id):
		if f != p:
			cc.state.booked = {"kind": "fight", "opponent": String(f.id), "org": String(p.org_id), "week": cc.state.week_index + 6,
				"title": false, "short": false, "show": 600.0, "win": 600.0, "expires": 0, "fights": 0}
			cc.state.scouting_blocks = 0
			return f
	return null


func test_scouting_precision_grows_with_study_blocks() -> void:
	var cc: CareerController = _cc()
	_book(cc)
	var blind: Dictionary = cc.scouting_report()
	assert_eq(blind["precision"], 0, "sem estudo")
	for i: int in 12:
		cc.set_plan_block(i, &"study")
	cc.simulate_week()
	var studied: Dictionary = cc.scouting_report()
	assert_true(int(studied["precision"]) > 0, "estudo revela informação")
	assert_true((studied["attributes"] as Array).size() >= 3, "atributos de destaque")
	assert_true(String(studied["style"]) != "?", "estilo revelado")


func test_provocation_creates_rivalry_and_rival_offers_pay_more() -> void:
	var cc: CareerController = _cc()
	cc.state.pending_interview = true
	cc.answer_interview(2)
	assert_eq(cc.state.rivals.size(), 1, "rival criado")
	var rival_id: StringName = StringName(cc.state.rivals.keys()[0])
	var found: bool = false
	for w: int in 12:
		cc.state.offers.clear()
		cc.state.booked = {}
		Matchmaking.run_week(cc.state, cc.defs, CareerRng.make(cc.state, &"mm", w))
		for o: Dictionary in cc.state.offers:
			if o["kind"] == "fight" and StringName(o["opponent"]) == rival_id:
				found = true
				assert_true(bool(o.get("rivalry", false)), "oferta marcada como rivalidade")
		if found:
			break
		cc.state.week_index += 1
	assert_true(found, "matchmaking oferece a luta contra o rival")


func test_counter_offer_either_improves_purse_or_withdraws() -> void:
	var improved: int = 0
	var withdrawn: int = 0
	for seed: int in 30:
		var cc: CareerController = _cc(seed)
		var opp: FighterState = _book(cc)
		cc.state.booked = {}
		cc.state.offers = [{"kind": "fight", "opponent": String(opp.id), "org": "org_local", "week": 8, "title": false,
			"short": false, "show": 1000.0, "win": 1000.0, "expires": 5, "fights": 0}]
		var rel: float = cc.state.relationship(&"org_local")
		cc.counter_offer(0)
		if cc.state.offers.is_empty():
			withdrawn += 1
			assert_true(cc.state.relationship(&"org_local") < rel, "relação cai quando recusam a contraproposta")
		else:
			improved += 1
			assert_true(float(cc.state.offers[0]["show"]) > 1000.0, "bolsa melhorou")
			assert_true(bool(cc.state.offers[0]["countered"]), "só uma contraproposta")
	assert_true(improved > 5 and withdrawn > 5, "as duas saídas acontecem (%d/%d)" % [improved, withdrawn])


func test_declining_offers_hurts_relationship() -> void:
	var cc: CareerController = _cc()
	var opp: FighterState = _book(cc)
	cc.state.booked = {}
	cc.state.offers = [{"kind": "fight", "opponent": String(opp.id), "org": "org_local", "week": 8, "title": false,
		"short": false, "show": 600.0, "win": 600.0, "expires": 5, "fights": 0}]
	var rel: float = cc.state.relationship(&"org_local")
	cc.decline_offer(0)
	assert_true(cc.state.relationship(&"org_local") < rel)


func test_new_fields_survive_save() -> void:
	var cc: CareerController = _cc()
	cc.state.rivals = {"F-000001": 40.0}
	cc.state.org_relationship = {"org_local": 61.0}
	cc.state.scouting_blocks = 3
	var copy: CareerState = CareerState.from_dict(JSON.parse_string(JSON.stringify(cc.state.to_dict())))
	assert_almost(float(copy.rivals["F-000001"]), 40.0)
	assert_almost(copy.relationship(&"org_local"), 61.0)
	assert_eq(copy.scouting_blocks, 3)

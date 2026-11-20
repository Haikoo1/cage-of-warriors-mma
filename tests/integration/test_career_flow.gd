extends TestCase
## Fluxo de carreira de ponta a ponta pelo controlador (CAREER_ARCHITECTURE §7), sem telas.

const SLOT: int = 9  # slot de teste


func _new() -> CareerController:
	var setup: CareerSetup = CareerSetup.new()
	setup.name = "Fluxo"
	setup.weight_class_id = &"f_strawweight"
	setup.origin_id = &"origin_bjj"
	setup.seed = 99
	return CareerController.create(DataLoader.load_from("res://data"), setup, SLOT)


func test_offer_book_fight_week_simulate_and_continue() -> void:
	var cc: CareerController = _new()
	var guard: int = 0
	while cc.state.offers.is_empty() and guard < 20:
		cc.simulate_week()
		guard += 1
	assert_false(cc.state.offers.is_empty(), "oferta recebida")
	var idx: int = 0
	for k: int in cc.state.offers.size():
		if cc.state.offers[k]["kind"] == "fight":
			idx = k
	assert_true(cc.accept_offer(idx), "aceitou")
	var report: Dictionary = cc.advance_until_event(30)
	assert_true(cc.is_fight_week(), "chegou à semana da luta (%s)" % str(report))
	var wins_losses: int = cc.state.player().wins + cc.state.player().losses + cc.state.player().draws
	var result: FightResult = cc.simulate_player_fight()
	assert_true(result != null, "luta simulada")
	assert_eq(cc.state.player().wins + cc.state.player().losses + cc.state.player().draws, wins_losses + 1, "cartel atualizado")
	assert_true(cc.state.booked.is_empty(), "luta consumida")
	assert_true(cc.state.pending_interview, "entrevista pós-luta pendente")
	cc.answer_interview(2)
	assert_false(cc.state.pending_interview)
	var week: int = cc.state.week_index
	cc.simulate_week()
	assert_eq(cc.state.week_index, week + 1, "carreira continua")


func test_prepare_fight_builds_valid_setup_with_weigh_in() -> void:
	var cc: CareerController = _new()
	var p: FighterState = cc.state.player()
	var opp: FighterState = null
	for f: FighterState in Rankings.roster(cc.state, p.org_id, p.weight_class_id):
		if f != p:
			opp = f
			break
	cc.state.booked = {"kind": "fight", "opponent": String(opp.id), "org": String(p.org_id), "week": cc.state.week_index,
		"title": false, "short": false, "show": 600.0, "win": 600.0, "expires": 0, "fights": 0}
	var prep: Dictionary = cc.prepare_fight()
	var cfg: QuickFight.Config = prep["config"]
	assert_eq(cfg.setup.validate(cc.defs).size(), 0, "FightSetup válido")
	assert_eq(cfg.setup.round_seconds_override, cc.state.round_seconds)
	assert_true(cfg.ai_b != null, "adversário controlado pela IA")
	assert_true((prep["weigh_in"] as Dictionary).has("made_weight"), "pesagem")


func test_save_and_load_slot() -> void:
	var cc: CareerController = _new()
	cc.simulate_week()
	assert_eq(cc.save(), OK)
	var loaded: CareerController = CareerController.load_slot(DataLoader.load_from("res://data"), SLOT)
	assert_true(loaded != null, "carregou")
	assert_eq(loaded.state.week_index, cc.state.week_index)
	assert_eq(loaded.state.player().display_name, "Fluxo")
	CareerController.delete_slot(SLOT)


func test_retirement_produces_legacy() -> void:
	var cc: CareerController = _new()
	var legacy: Dictionary = cc.retire()
	assert_true(cc.state.player().retired, "aposentado")
	assert_true(legacy.has("score"), "pontuação de legado")

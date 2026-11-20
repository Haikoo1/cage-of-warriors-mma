extends TestCase


func test_example_data_loads_without_errors() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	var errors: Array[String] = defs.validate_all()
	assert_eq(errors.size(), 0, "erros: %s" % str(errors))
	assert_eq(defs.weight_classes.size(), 12, "12 categorias (D-007)")
	assert_eq(defs.strikes.size(), 5, "golpes")
	assert_eq(defs.rule_sets.size(), 1, "rulesets")


func test_definitions_are_not_mutated_by_career_flow() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	var before: String = defs.content_hash()
	var career: CareerState = CareerState.new()
	var f: FighterState = FighterState.create_blank(career.next_id("F"), 50.0)
	f.weight_class_id = &"m_lightweight"
	career.add_fighter(f)
	var setup: FightSetup = FightSetup.new()
	setup.fighter_a = FighterSnapshot.from_fighter(f)
	setup.fighter_b = FighterSnapshot.from_fighter(f)
	setup.ruleset_id = &"rs_standard"
	setup.weight_class_id = &"m_lightweight"
	assert_eq(setup.validate(defs).size(), 0, "setup válido")
	CareerState.from_dict(career.to_dict())
	assert_eq(defs.content_hash(), before, "definições inalteradas")


func test_twelve_weight_classes_eight_male_four_female() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	var male: int = 0
	var female: int = 0
	for wc: WeightClassDef in defs.weight_classes.values():
		if wc.division == WeightClassDef.Division.MALE:
			male += 1
		else:
			female += 1
	assert_eq(male, 8)
	assert_eq(female, 4)


func test_career_data_present() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	assert_eq(defs.organizations.size(), 4, "4 níveis de organização")
	assert_eq(defs.origins.size(), 4, "4 origens")
	assert_true(defs.training_activities.size() >= 12, "atividades de treino")
	assert_true(defs.gyms.size() >= 3, "academias")
	assert_true(defs.career_balance != null, "balanceamento da carreira")

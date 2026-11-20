extends TestCase


func test_example_data_loads_without_errors() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	var errors: Array[String] = defs.validate_all()
	assert_eq(errors.size(), 0, "erros: %s" % str(errors))
	assert_eq(defs.weight_classes.size(), 1, "categorias")
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

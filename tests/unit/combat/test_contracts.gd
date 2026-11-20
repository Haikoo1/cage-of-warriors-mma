extends TestCase


func test_snapshot_copies_attributes() -> void:
	var f: FighterState = FighterState.create_blank(&"F-000001", 50.0)
	var snap: FighterSnapshot = FighterSnapshot.from_fighter(f)
	snap.attributes[&"boxe"] = 99.0
	assert_almost(f.attributes[&"boxe"], 50.0, 0.0001, "alterar snapshot não altera o lutador")


func test_fight_setup_validation_checks_ruleset() -> void:
	var setup: FightSetup = FightSetup.new()
	setup.fighter_a = FighterSnapshot.from_fighter(FighterState.create_blank(&"F-1", 50.0))
	setup.fighter_b = FighterSnapshot.from_fighter(FighterState.create_blank(&"F-2", 50.0))
	setup.ruleset_id = &"inexistente"
	assert_has_error(setup.validate(Definitions.new()), "ruleset")


func test_fight_result_round_trip() -> void:
	var r: FightResult = FightResult.new()
	r.bout_id = &"B-000001"
	r.winner = FightResult.FighterSlot.A
	r.method = FightResult.Method.SUBMISSION
	r.method_detail = &"rear_naked_choke"
	r.round = 3
	r.time_seconds = 161
	r.scorecards = [[10, 9], [9, 10]]
	r.medical = {"a": {"head": 12.0}, "b": {"head": 40.0}}
	var copy: FightResult = FightResult.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))
	assert_eq(copy.to_dict(), r.to_dict())
	assert_eq(r.to_dict()["method"], "SUBMISSION")


func test_neutral_command() -> void:
	assert_true(FighterCommand.new().is_neutral())

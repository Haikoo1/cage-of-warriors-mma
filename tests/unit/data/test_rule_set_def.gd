extends TestCase


func _valid() -> RuleSetDef:
	var r: RuleSetDef = RuleSetDef.new()
	r.id = &"rs_test"
	r.rounds_normal = 3
	r.rounds_title = 5
	r.round_seconds = 300
	r.break_seconds = 60
	return r


func test_valid_ruleset_has_no_errors() -> void:
	assert_eq(_valid().validate(Definitions.new()).size(), 0, "erros")


func test_title_rounds_cannot_be_fewer_than_normal() -> void:
	var r: RuleSetDef = _valid()
	r.rounds_title = 2
	assert_has_error(r.validate(Definitions.new()), "rounds_title")


func test_prohibited_strike_must_exist() -> void:
	var r: RuleSetDef = _valid()
	r.prohibited_strikes = PackedStringArray(["soccer_kick"])
	assert_has_error(r.validate(Definitions.new()), "soccer_kick")

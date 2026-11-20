extends TestCase


func _valid() -> StrikeDef:
	var s: StrikeDef = StrikeDef.new()
	s.id = &"jab"
	s.targets = PackedStringArray(["head", "body"])
	s.base_reach_m = 0.8
	s.depth_tolerance_m = 0.3
	s.startup_frames = 6
	s.active_frames = 3
	s.recovery_frames = 10
	s.feint_cutoff = 0.6
	s.power = 10.0
	s.stamina_cost = 2.0
	s.technique_attribute = &"boxe"
	return s


func test_valid_strike_has_no_errors() -> void:
	assert_eq(_valid().validate().size(), 0, "erros")


func test_unknown_technique_attribute_is_rejected() -> void:
	var s: StrikeDef = _valid()
	s.technique_attribute = &"precisao"
	assert_has_error(s.validate(), "technique_attribute")


func test_unknown_target_is_rejected() -> void:
	var s: StrikeDef = _valid()
	s.targets = PackedStringArray(["head", "neck"])
	assert_has_error(s.validate(), "targets")


func test_frames_must_be_positive() -> void:
	var s: StrikeDef = _valid()
	s.startup_frames = 0
	assert_has_error(s.validate(), "startup_frames")


func test_total_frames_sums_phases() -> void:
	assert_eq(_valid().total_frames(), 19)

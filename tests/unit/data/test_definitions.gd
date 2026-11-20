extends TestCase


func _strike(id: StringName) -> StrikeDef:
	var s: StrikeDef = StrikeDef.new()
	s.id = id
	s.targets = PackedStringArray(["head"])
	s.base_reach_m = 0.8
	s.depth_tolerance_m = 0.3
	s.startup_frames = 6
	s.active_frames = 3
	s.recovery_frames = 10
	s.technique_attribute = &"boxe"
	return s


func test_duplicate_id_is_reported() -> void:
	var defs: Definitions = Definitions.new()
	defs.add(_strike(&"jab"))
	defs.add(_strike(&"jab"))
	assert_has_error(defs.validate_all(), "duplicado")


func test_lookup_by_id() -> void:
	var defs: Definitions = Definitions.new()
	defs.add(_strike(&"jab"))
	assert_eq(defs.strike(&"jab").id, &"jab")
	assert_true(defs.strike(&"nao_existe") == null, "id inexistente retorna null")


func test_validate_all_collects_definition_errors() -> void:
	var defs: Definitions = Definitions.new()
	var bad: StrikeDef = _strike(&"bad")
	bad.recovery_frames = 0
	defs.add(bad)
	assert_has_error(defs.validate_all(), "recovery_frames")


func test_content_hash_changes_when_definition_changes() -> void:
	var defs: Definitions = Definitions.new()
	var s: StrikeDef = _strike(&"jab")
	defs.add(s)
	var before: String = defs.content_hash()
	assert_eq(defs.content_hash(), before, "hash estável")
	s.power = 99.0
	assert_true(defs.content_hash() != before, "hash deve mudar")

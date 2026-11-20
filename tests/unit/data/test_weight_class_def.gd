extends TestCase


func _valid() -> WeightClassDef:
	var d: WeightClassDef = WeightClassDef.new()
	d.id = &"m_lightweight"
	d.division = WeightClassDef.Division.MALE
	d.limit_lb = 155.0
	d.tolerance_lb = 1.0
	d.allowed_biotypes = PackedStringArray(["m_medium"])
	return d


func test_valid_definition_has_no_errors() -> void:
	assert_eq(_valid().validate().size(), 0, "erros")


func test_limit_must_be_positive() -> void:
	var d: WeightClassDef = _valid()
	d.limit_lb = 0.0
	assert_has_error(d.validate(), "limit_lb")


func test_requires_biotype() -> void:
	var d: WeightClassDef = _valid()
	d.allowed_biotypes = PackedStringArray()
	assert_has_error(d.validate(), "allowed_biotypes")


func test_limit_in_kg_converts_pounds() -> void:
	assert_almost(_valid().limit_kg(), 70.307, 0.01)

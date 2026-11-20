extends TestCase


func _fighter() -> FighterState:
	var f: FighterState = FighterState.new()
	f.id = &"F-000001"
	f.display_name = "Lia Moreira"
	f.division = FighterState.Division.FEMALE
	f.weight_class_id = &"f_strawweight"
	f.birth_week = -1092
	f.attributes = {&"boxe": 42.5, &"jiu_jitsu": 62.0}
	f.physique.height_cm = 160
	f.physique.reach_cm = 163
	f.physique.walk_weight_kg = 57.5
	f.physique.biotype_id = &"f_light"
	f.physique.stance = Physique.Stance.ORTHODOX
	return f


func test_round_trip_preserves_data() -> void:
	var f: FighterState = _fighter()
	var copy: FighterState = FighterState.from_dict(JSON.parse_string(JSON.stringify(f.to_dict())))
	assert_eq(copy.to_dict(), f.to_dict(), "round-trip via JSON")
	assert_eq(copy.id, &"F-000001")
	assert_eq(copy.division, FighterState.Division.FEMALE)


func test_enums_serialize_by_name() -> void:
	var d: Dictionary = _fighter().to_dict()
	assert_eq(d["division"], "FEMALE")
	assert_eq(d["physique"]["stance"], "ORTHODOX")


func test_new_fighter_has_all_attributes_at_default() -> void:
	var f: FighterState = FighterState.create_blank(&"F-1", 30.0)
	assert_eq(f.attributes.size(), AttributeIds.ALL.size())
	assert_almost(f.attributes[&"queixo"], 30.0)

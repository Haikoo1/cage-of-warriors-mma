extends TestCase


func test_id_generator_increments_per_prefix() -> void:
	var c: CareerState = CareerState.new()
	assert_eq(c.next_id("F"), &"F-000001")
	assert_eq(c.next_id("F"), &"F-000002")
	assert_eq(c.next_id("B"), &"B-000001")


func test_round_trip_preserves_fighters_and_counters() -> void:
	var c: CareerState = CareerState.new()
	c.career_seed = 1234
	c.week_index = 57
	var f: FighterState = FighterState.create_blank(c.next_id("F"), 40.0)
	c.add_fighter(f)
	c.player_fighter_id = f.id
	var copy: CareerState = CareerState.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())))
	assert_eq(copy.to_dict(), c.to_dict(), "round-trip")
	assert_eq(copy.next_id("F"), &"F-000002", "contador persistido")
	assert_true(copy.get_fighter(&"F-000001") != null, "lutador recuperado")

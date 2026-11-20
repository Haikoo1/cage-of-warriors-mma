extends TestCase
## Grafo de posições sem becos (COMBAT_ARCHITECTURE §3.3): todo estado é alcançável a partir de EP
## e todo papel de todo estado tem pelo menos uma saída.


func _techniques() -> Array:
	return DataLoader.load_from("res://data").grapple_techniques.values()


func test_all_techniques_valid() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	var errors: Array[String] = defs.validate_all()
	assert_eq(errors.size(), 0, str(errors))


func test_every_position_reachable_from_standing() -> void:
	var reached: Dictionary = {&"EP": true}
	var changed: bool = true
	while changed:
		changed = false
		for t: GrappleTechniqueDef in _techniques():
			if not reached.has(t.from_state):
				continue
			for target: StringName in [t.to_state, t.counter_state, t.escape_state]:
				if target != &"" and not reached.has(target):
					reached[target] = true
					changed = true
	for p: StringName in CombatGrappling.POSITIONS:
		assert_true(reached.has(p), "%s alcançável" % p)


func test_every_role_has_an_exit() -> void:
	for p: StringName in CombatGrappling.POSITIONS:
		var roles: Array = [&"any"] if CombatGrappling.NEUTRAL.has(p) else [&"top", &"bottom"]
		for role: StringName in roles:
			var found: bool = false
			for t: GrappleTechniqueDef in _techniques():
				if t.from_state == p and t.role == role and (t.to_state != p or t.kind == &"submission" or t.result_top == &"attacker"):
					found = true
			assert_true(found, "saída para %s/%s" % [p, role])


func test_invalid_technique_is_rejected() -> void:
	var t: GrappleTechniqueDef = GrappleTechniqueDef.new()
	t.id = &"bad"
	t.from_state = &"XX"
	t.to_state = &"SG"
	t.pressure_attr = &"forca"
	t.resistance_attr = &"forca"
	t.startup_frames = 10
	var errors: Array[String] = t.validate()
	assert_has_error(errors, "from_state")

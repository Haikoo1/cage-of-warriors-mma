extends TestCase


func _move(x: int, z: int) -> FighterCommand:
	var c: FighterCommand = FighterCommand.new()
	c.move_x = x
	c.move_z = z
	return c


func test_forward_is_relative_to_opponent() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 3.0)
	var a0: float = s.fighters[0].x
	var b0: float = s.fighters[1].x
	s.step(_move(1, 0), _move(1, 0))
	assert_true(s.fighters[0].x > a0, "A (à esquerda) avança para a direita")
	assert_true(s.fighters[1].x < b0, "B (à direita) avança para a esquerda")


func test_retreat_is_slower_than_advance() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 3.0)
	var a0: float = s.fighters[0].x
	var b0: float = s.fighters[1].x
	s.step(_move(1, 0), _move(-1, 0))
	var advanced: float = absf(s.fighters[0].x - a0)
	var retreated: float = absf(s.fighters[1].x - b0)
	assert_true(retreated < advanced, "recuo %f < avanço %f" % [retreated, advanced])


func test_cage_limits_x() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 3.0)
	for i: int in 600:
		s.step(_move(-1, 0), CombatFixture.idle())
	assert_almost(s.fighters[0].x, -s.balance.cage_half_width_m, 0.001, "parou na grade")
	assert_true(s.fighters[0].is_cornered(s.balance), "encurralado")


func test_fighters_cannot_pass_through_each_other() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 1.0)
	for i: int in 300:
		s.step(_move(1, 0), CombatFixture.idle())
	assert_true(s.fighters[0].x < s.fighters[1].x, "A continua à esquerda de B")
	assert_true(s.fighters[1].x - s.fighters[0].x >= s.balance.body_min_distance_m - 0.001, "distância mínima")


func test_depth_is_limited() -> void:
	var s: CombatSim = CombatFixture.sim()
	for i: int in 600:
		s.step(_move(0, 1), CombatFixture.idle())
	assert_almost(s.fighters[0].z, s.balance.depth_half_m, 0.001)


func test_lateral_step_not_followed_gives_angle() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 2.0)
	s.step(_move(0, 1), CombatFixture.idle())
	assert_true(s.fighters[0].angle_frames > 0, "A ganhou Vantagem de Ângulo")


func test_moving_costs_stamina() -> void:
	var s: CombatSim = CombatFixture.sim()
	CombatFixture.place(s, 3.0)
	s.fighters[0].stamina = 80.0
	s.step(_move(0, 1), CombatFixture.idle())
	assert_true(s.fighters[0].stamina < 80.0, "lateral gasta Fôlego")

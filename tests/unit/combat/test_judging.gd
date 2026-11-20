extends TestCase


func _stats(damage: float, kd: int = 0, grapple: int = 0, control_s: float = 0.0) -> Judging.FighterRoundStats:
	var st: Judging.FighterRoundStats = Judging.FighterRoundStats.new()
	st.damage_dealt = damage
	st.knockdowns = kd
	st.grapple_successes = grapple
	st.control_frames = roundi(control_s * 60)
	return st


func test_clear_striking_winner_takes_10_9_from_all_judges() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var scores: Array = Judging.score_round(_stats(60.0), _stats(15.0), rng)
	for card: Array in scores:
		assert_eq(card, [10, 9])


func test_two_knockdowns_make_10_8() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var scores: Array = Judging.score_round(_stats(60.0, 2), _stats(10.0), rng)
	assert_eq(scores[0], [10, 8])


func test_empty_round_is_10_10() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	assert_eq(Judging.score_round(_stats(0.0), _stats(0.0), rng)[0], [10, 10])


func test_grappling_judge_can_disagree_on_close_round() -> void:
	# Striker com mais dano × wrestler com controle: juízes com pesos diferentes podem divergir.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var winners: Dictionary = {}
	for seed: int in 30:
		rng.seed = seed
		for card: Array in Judging.score_round(_stats(30.0), _stats(5.0, 0, 3, 90.0), rng):
			winners[0 if card[0] > card[1] else 1] = true
	assert_eq(winners.size(), 2, "existe divergência entre juízes em round equilibrado")


func test_decision_types() -> void:
	assert_eq(Judging.decide([[30, 27], [29, 28], [29, 28]]), [FightResult.Method.DECISION_UNANIMOUS, FightResult.FighterSlot.A])
	assert_eq(Judging.decide([[29, 28], [28, 29], [29, 28]]), [FightResult.Method.DECISION_SPLIT, FightResult.FighterSlot.A])
	assert_eq(Judging.decide([[28, 29], [28, 28], [28, 29]]), [FightResult.Method.DECISION_MAJORITY, FightResult.FighterSlot.B])
	assert_eq(Judging.decide([[29, 28], [28, 29], [28, 28]]), [FightResult.Method.DRAW, FightResult.FighterSlot.NONE])

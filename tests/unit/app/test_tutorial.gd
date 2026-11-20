extends TestCase
## Tutorial interativo: lições avançam por eventos reais do combate.


func _hit(att: int, strike: StringName, outcome: CombatEvent.Outcome, zone: StringName = &"head") -> CombatEvent:
	var e: CombatEvent = CombatEvent.make(CombatEvent.Type.STRIKE_RESOLVED, att, 1 - att)
	e.strike_id = strike
	e.outcome = outcome
	e.zone = zone
	return e


func test_first_lesson_needs_three_clean_jabs() -> void:
	var t: TutorialRunner = TutorialRunner.new()
	var s: CombatSim = CombatFixture.sim()
	assert_eq(t.index, 0)
	t.feed([_hit(0, &"jab", CombatEvent.Outcome.CLEAN), _hit(0, &"jab", CombatEvent.Outcome.BLOCKED)], s)
	assert_eq(t.progress, 1, "bloqueado não conta")
	t.feed([_hit(0, &"jab", CombatEvent.Outcome.CLEAN), _hit(0, &"jab", CombatEvent.Outcome.COUNTER)], s)
	assert_eq(t.index, 1, "avançou para a próxima lição")
	assert_eq(t.progress, 0)


func test_block_lesson_counts_opponent_blocked_strikes() -> void:
	var t: TutorialRunner = TutorialRunner.new()
	var ids: Array = TutorialRunner.LESSONS.map(func(l: Dictionary) -> String: return l["id"])
	t.index = ids.find("block")
	var start: int = t.index
	var s: CombatSim = CombatFixture.sim()
	for k: int in 3:
		t.feed([_hit(1, &"jab", CombatEvent.Outcome.BLOCKED)], s)
	assert_eq(t.index, start + 1, "concluiu o bloqueio")


func test_all_lessons_have_text_and_dummy_mode() -> void:
	assert_true(TutorialRunner.LESSONS.size() >= 10, "pelo menos 10 lições")
	for l: Dictionary in TutorialRunner.LESSONS:
		assert_true(String(l["text"]) != "" and l.has("dummy") and int(l["target"]) > 0, "lição %s completa" % l["id"])

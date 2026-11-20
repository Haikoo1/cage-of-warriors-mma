extends TestCase
## Mapa evento de combate → som (COMBAT_DESIGN §8.1). O áudio só reage a eventos; não decide nada.


func _event(t: CombatEvent.Type, outcome: CombatEvent.Outcome = CombatEvent.Outcome.NONE, damage: float = 0.0) -> CombatEvent:
	var e: CombatEvent = CombatEvent.make(t, 0, 1)
	e.outcome = outcome
	e.damage = damage
	return e


func test_mapping() -> void:
	assert_eq(CombatSounds.sound_for(_event(CombatEvent.Type.STRIKE_RESOLVED, CombatEvent.Outcome.CLEAN, 3.0)), &"hit_light")
	assert_eq(CombatSounds.sound_for(_event(CombatEvent.Type.STRIKE_RESOLVED, CombatEvent.Outcome.CLEAN, 9.0)), &"hit_heavy")
	assert_eq(CombatSounds.sound_for(_event(CombatEvent.Type.STRIKE_RESOLVED, CombatEvent.Outcome.COUNTER, 2.0)), &"hit_heavy")
	assert_eq(CombatSounds.sound_for(_event(CombatEvent.Type.STRIKE_RESOLVED, CombatEvent.Outcome.BLOCKED)), &"block")
	assert_eq(CombatSounds.sound_for(_event(CombatEvent.Type.STRIKE_RESOLVED, CombatEvent.Outcome.MISS_ANGLE)), &"whoosh")
	assert_eq(CombatSounds.sound_for(_event(CombatEvent.Type.FIGHT_OVER)), &"bell")
	var kd: CombatEvent = _event(CombatEvent.Type.SHOCK)
	kd.shock_state = FighterCombatState.Action.DOWN
	assert_eq(CombatSounds.sound_for(kd), &"body_fall")


func test_all_sound_files_load() -> void:
	for name: StringName in CombatSounds.ALL:
		var stream: AudioStream = load("res://assets/audio/sfx/%s.wav" % name) as AudioStream
		assert_true(stream != null, "som %s" % name)

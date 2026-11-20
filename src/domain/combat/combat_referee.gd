class_name CombatReferee
extends RefCounted
## Árbitro como sistema de regras (COMBAT_DESIGN §7.2–7.3, R-030): separa clinch parado, levanta luta parada
## no chão e interrompe por TKO quando falta "defesa inteligente".

const TKO_STRIKES: int = 5  # [PROV]
const TKO_WINDOW_FRAMES: int = 240  # 4 s [PROV]
const CLINCH: Array[StringName] = [&"CL", &"CG"]
const GROUND: Array[StringName] = [&"SG", &"SM", &"SL", &"SO", &"SC", &"SR"]

var last_activity_frame: int = 0
var _last_position: StringName = &"EP"
var _unanswered: Array = [[], []]


func observe(sim: CombatSim, events: Array[CombatEvent]) -> void:
	var g: CombatGrappling = sim.grappling
	if g.position != _last_position:
		_last_position = g.position
		last_activity_frame = sim.frame
	for e: CombatEvent in events:
		match e.type:
			CombatEvent.Type.STRIKE_STARTED, CombatEvent.Type.GRAPPLE_STARTED:
				last_activity_frame = sim.frame
				(_unanswered[e.attacker] as Array).clear()  # quem ataca está se defendendo
			CombatEvent.Type.SQUEEZE_TICK:
				last_activity_frame = sim.frame
			CombatEvent.Type.STRIKE_RESOLVED:
				last_activity_frame = sim.frame
				if (e.outcome == CombatEvent.Outcome.CLEAN or e.outcome == CombatEvent.Outcome.COUNTER) \
						and _defenseless(sim, e.defender):
					(_unanswered[e.defender] as Array).append(sim.frame)
	for i: int in 2:
		var hits: Array = _unanswered[i]
		while not hits.is_empty() and sim.frame - int(hits[0]) > TKO_WINDOW_FRAMES:
			hits.pop_front()
		if hits.size() >= TKO_STRIKES:
			sim.finish(1 - i, &"tko")
			return
	var idle_frames: int = sim.frame - last_activity_frame
	if CLINCH.has(g.position) and idle_frames >= roundi(sim.rules.clinch_inactivity_seconds * 60):
		_restart_standing(sim)
	elif GROUND.has(g.position) and g.submission == null and idle_frames >= roundi(sim.rules.ground_inactivity_seconds * 60):
		_restart_standing(sim)


func reset_round(sim: CombatSim) -> void:
	last_activity_frame = sim.frame
	_last_position = sim.grappling.position
	_unanswered = [[], []]


func _defenseless(sim: CombatSim, i: int) -> bool:
	var d: FighterCombatState = sim.fighters[i]
	if d.action == FighterCombatState.Action.STUNNED or d.action == FighterCombatState.Action.DOWN:
		return true
	var g: CombatGrappling = sim.grappling
	return CombatGrappling.GROUND.has(g.position) and g.top != i and not d.guard_high


func _restart_standing(sim: CombatSim) -> void:
	sim.grappling.transition(sim, &"EP", -1)
	last_activity_frame = sim.frame
	_last_position = &"EP"

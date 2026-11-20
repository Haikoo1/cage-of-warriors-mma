class_name CombatSounds
extends RefCounted
## Mapa evento de combate → efeito sonoro (COMBAT_DESIGN §8.1). Apresentação pura: o áudio só reage.

const ALL: Array[StringName] = [&"hit_light", &"hit_heavy", &"block", &"whoosh", &"body_fall", &"bell",
	&"crowd_loop", &"crowd_roar", &"ui_click"]
const HEAVY_DAMAGE: float = 6.0


static func sound_for(e: CombatEvent) -> StringName:
	match e.type:
		CombatEvent.Type.STRIKE_RESOLVED:
			match e.outcome:
				CombatEvent.Outcome.CLEAN:
					return &"hit_heavy" if e.damage >= HEAVY_DAMAGE else &"hit_light"
				CombatEvent.Outcome.COUNTER:
					return &"hit_heavy"
				CombatEvent.Outcome.BLOCKED:
					return &"block"
				_:
					return &"whoosh"
		CombatEvent.Type.SHOCK:
			if e.shock_state == FighterCombatState.Action.DOWN or e.shock_state == FighterCombatState.Action.OUT:
				return &"body_fall"
		CombatEvent.Type.GRAPPLE_RESOLVED:
			if e.grapple_outcome == CombatEvent.GrappleOutcome.SUCCESS and e.technique_id in [&"double_leg", &"single_leg", &"clinch_trip", &"cage_takedown"]:
				return &"body_fall"
		CombatEvent.Type.FIGHT_OVER:
			return &"bell"
	return &""


## Momentos que levantam o público.
static func crowd_reacts(e: CombatEvent) -> bool:
	return (e.type == CombatEvent.Type.SHOCK and e.shock_state in [FighterCombatState.Action.DOWN, FighterCombatState.Action.OUT]) \
		or e.type == CombatEvent.Type.FIGHT_OVER \
		or (e.type == CombatEvent.Type.SQUEEZE_TICK and e.grapple_outcome == CombatEvent.GrappleOutcome.TAPPED)

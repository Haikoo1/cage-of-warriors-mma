class_name FighterCombatState
extends RefCounted
## Estado individual de um lutador durante a luta (COMBAT_ARCHITECTURE §3.1). Transitório: nunca é salvo.

enum Action { IDLE, STRIKE_STARTUP, STRIKE_ACTIVE, STRIKE_RECOVERY, EVADING, ROCKED, STUNNED, DOWN, OUT, GRAPPLING }
enum Evade { NONE, SLIP, DUCK, PULL }

const ZONES: Array[StringName] = [&"head", &"body", &"legs"]

var snapshot: FighterSnapshot
## Plano de chão em metros (T-004): x = distância, z = profundidade.
var x: float = 0.0
var z: float = 0.0
## +1 se o adversário está à direita (x maior), -1 se à esquerda.
var facing: int = 1

var action: Action = Action.IDLE
var action_frames_left: int = 0
var strike: StrikeDef
var strike_zone: StringName = &""
var evade: Evade = Evade.NONE
var guard_high: bool = false
var guard_low: bool = false
var angle_frames: int = 0
var moved_this_step: bool = false
var gnp_cooldown: int = 0
var cut: int = 0  # gravidade do corte 0..3 (COMBAT §6.4)

var stamina: float = 100.0
var reserve: float = 100.0
var acute: Dictionary = {&"head": 0.0, &"body": 0.0, &"legs": 0.0}
var residual: Dictionary = {&"head": 0.0, &"body": 0.0, &"legs": 0.0}

## Métricas do protótipo (critério da E-03): tentativas e resultados por rótulo.
var stats: Dictionary = {"attempts": 0, "landed": 0, "blocked": 0, "missed": 0, "evaded": 0, "counters": 0}


func attr(id: StringName) -> float:
	return float(snapshot.attributes.get(id, 50.0))


func zone_damage(zone: StringName) -> float:
	return float(acute[zone]) + float(residual[zone])


func stamina_ratio() -> float:
	return stamina / 100.0


func is_striking() -> bool:
	return action == Action.STRIKE_STARTUP or action == Action.STRIKE_ACTIVE or action == Action.STRIKE_RECOVERY


func is_cornered(bal: CombatBalanceDef) -> bool:
	return absf(x) >= bal.cage_half_width_m - bal.cornered_distance_m


func set_action(new_action: Action, frames: int) -> void:
	action = new_action
	action_frames_left = frames
	if new_action != Action.EVADING:
		evade = Evade.NONE
	if not is_striking():
		strike = null
		strike_zone = &""


func to_hash_dict() -> Dictionary:
	return {
		"x": snappedf(x, 0.0001), "z": snappedf(z, 0.0001), "facing": facing,
		"action": action, "frames": action_frames_left,
		"stamina": snappedf(stamina, 0.0001), "reserve": snappedf(reserve, 0.0001),
		"acute": acute, "residual": residual, "stats": stats,
	}

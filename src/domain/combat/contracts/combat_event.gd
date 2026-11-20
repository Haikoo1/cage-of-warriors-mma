class_name CombatEvent
extends RefCounted
## Algo que aconteceu em um passo da luta; consumido por HUD, efeitos, estatísticas e juízes.
## Os rótulos de Outcome são os mesmos do feedback "por que falhou" (COMBAT_DESIGN §8.2).

enum Type { STRIKE_STARTED, STRIKE_RESOLVED, SHOCK, FIGHT_OVER, GRAPPLE_STARTED, GRAPPLE_RESOLVED, SQUEEZE_TICK }
## Resultado da Disputa (COMBAT §4.2): READ = "Defendido (leitura)", PARTIAL/FAIL = "Resistiu", SUCCESS = "Passou".
enum GrappleOutcome { NONE, READ, PERFECT_READ, SUCCESS, PARTIAL, FAIL, TAPPED, ESCAPED }
enum Outcome { NONE, MISS_RANGE, MISS_ANGLE, EVADED, BLOCKED, CLEAN, COUNTER }

var type: Type = Type.STRIKE_RESOLVED
var attacker: int = -1
var defender: int = -1
var strike_id: StringName = &""
var zone: StringName = &""
var outcome: Outcome = Outcome.NONE
var damage: float = 0.0
var impact_ratio: float = 0.0
var shock_state: int = -1  # FighterCombatState.Action resultante, -1 se nenhum
var technique_id: StringName = &""
var grapple_outcome: GrappleOutcome = GrappleOutcome.NONE
var squeeze_meter: float = 0.0


static func make(t: Type, att: int, def_idx: int) -> CombatEvent:
	var e: CombatEvent = CombatEvent.new()
	e.type = t
	e.attacker = att
	e.defender = def_idx
	return e

class_name CareerState
extends RefCounted
## Raiz do estado de uma carreira (CAREER_ARCHITECTURE §1). Versão mínima da E-02B.

var career_seed: int = 0
var week_index: int = 0
var player_fighter_id: StringName = &""
var fighters: Dictionary = {}  # StringName -> FighterState
var _id_counters: Dictionary = {}  # prefixo (String) -> último número usado


## IDs estáveis por carreira: "F-000001", "B-000001"... (DATA_ARCHITECTURE §5).
func next_id(prefix: String) -> StringName:
	var n: int = int(_id_counters.get(prefix, 0)) + 1
	_id_counters[prefix] = n
	return StringName("%s-%06d" % [prefix, n])


func add_fighter(f: FighterState) -> void:
	assert(not fighters.has(f.id), "lutador duplicado %s" % f.id)
	fighters[f.id] = f


func get_fighter(fighter_id: StringName) -> FighterState:
	return fighters.get(fighter_id) as FighterState


func to_dict() -> Dictionary:
	var list: Array = []
	var ids: Array = fighters.keys()
	ids.sort()
	for fid: StringName in ids:
		list.append((fighters[fid] as FighterState).to_dict())
	return {
		"career_seed": career_seed,
		"week_index": week_index,
		"player_fighter_id": String(player_fighter_id),
		"id_counters": _id_counters.duplicate(),
		"fighters": list,
	}


static func from_dict(d: Dictionary) -> CareerState:
	var c: CareerState = CareerState.new()
	c.career_seed = int(d.get("career_seed", 0))
	c.week_index = int(d.get("week_index", 0))
	c.player_fighter_id = StringName(d.get("player_fighter_id", ""))
	var counters: Dictionary = d.get("id_counters", {})
	for prefix: String in counters:
		c._id_counters[prefix] = int(counters[prefix])
	for fd: Dictionary in d.get("fighters", []):
		c.add_fighter(FighterState.from_dict(fd))
	return c

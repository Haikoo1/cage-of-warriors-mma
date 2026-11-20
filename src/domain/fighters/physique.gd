class_name Physique
extends RefCounted
## Dados físicos do lutador (CHARACTER_DESIGN §6.1).

enum Stance { ORTHODOX, SOUTHPAW }

var height_cm: int = 175
var reach_cm: int = 178
var walk_weight_kg: float = 75.0
var biotype_id: StringName = &""
var stance: Stance = Stance.ORTHODOX


func to_dict() -> Dictionary:
	return {
		"height_cm": height_cm,
		"reach_cm": reach_cm,
		"walk_weight_kg": walk_weight_kg,
		"biotype_id": String(biotype_id),
		"stance": Stance.keys()[stance],
	}


static func from_dict(d: Dictionary) -> Physique:
	var p: Physique = Physique.new()
	p.height_cm = int(d.get("height_cm", p.height_cm))
	p.reach_cm = int(d.get("reach_cm", p.reach_cm))
	p.walk_weight_kg = float(d.get("walk_weight_kg", p.walk_weight_kg))
	p.biotype_id = StringName(d.get("biotype_id", ""))
	p.stance = Stance.keys().find(d.get("stance", "ORTHODOX")) as Stance
	return p

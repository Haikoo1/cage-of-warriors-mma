class_name FighterState
extends RefCounted
## Estado dinâmico de um lutador (DATA_ARCHITECTURE §3). Guarda só IDs de definições, nunca Resources.
## Versão mínima da E-02B: saúde, cartel, reputação e contrato entram nas etapas de carreira.

enum Division { MALE, FEMALE }

var id: StringName = &""
var display_name: String = ""
var division: Division = Division.MALE
var weight_class_id: StringName = &""
var birth_week: int = 0
## StringName (AttributeIds) -> float 1..100; arredondado só na UI.
var attributes: Dictionary = {}
var physique: Physique = Physique.new()


static func create_blank(fighter_id: StringName, default_value: float) -> FighterState:
	var f: FighterState = FighterState.new()
	f.id = fighter_id
	for attr: StringName in AttributeIds.ALL:
		f.attributes[attr] = default_value
	return f


func to_dict() -> Dictionary:
	var attrs: Dictionary = {}
	for key: StringName in attributes:
		attrs[String(key)] = float(attributes[key])
	return {
		"id": String(id),
		"display_name": display_name,
		"division": Division.keys()[division],
		"weight_class_id": String(weight_class_id),
		"birth_week": birth_week,
		"attributes": attrs,
		"physique": physique.to_dict(),
	}


static func from_dict(d: Dictionary) -> FighterState:
	var f: FighterState = FighterState.new()
	f.id = StringName(d.get("id", ""))
	f.display_name = d.get("display_name", "")
	f.division = Division.keys().find(d.get("division", "MALE")) as Division
	f.weight_class_id = StringName(d.get("weight_class_id", ""))
	f.birth_week = int(d.get("birth_week", 0))
	var attrs: Dictionary = d.get("attributes", {})
	for key: String in attrs:
		f.attributes[StringName(key)] = float(attrs[key])
	f.physique = Physique.from_dict(d.get("physique", {}))
	return f

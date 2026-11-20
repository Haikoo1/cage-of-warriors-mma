class_name WeightClassDef
extends Resource
## Categoria de peso (CHARACTER_DESIGN §6). Somente leitura em tempo de jogo (DATA_ARCHITECTURE §4).

enum Division { MALE, FEMALE }

const KG_PER_LB: float = 0.45359237

@export var id: StringName
@export var division: Division = Division.MALE
@export var display_key: String = ""
@export var limit_lb: float = 0.0
@export var tolerance_lb: float = 1.0
@export var allowed_biotypes: PackedStringArray = PackedStringArray()
## Multiplicadores de massa [PROV] (CHARACTER_DESIGN §6.3).
@export var damage_mult: float = 1.0
@export var move_cost_mult: float = 1.0
@export var move_speed_mult: float = 1.0


func limit_kg() -> float:
	return limit_lb * KG_PER_LB


func validate() -> Array[String]:
	var errors: Array[String] = []
	var p: String = "WeightClassDef '%s': " % id
	if id == &"":
		errors.append(p + "id vazio")
	if limit_lb <= 0.0:
		errors.append(p + "limit_lb deve ser > 0")
	if tolerance_lb < 0.0:
		errors.append(p + "tolerance_lb deve ser >= 0")
	if allowed_biotypes.is_empty():
		errors.append(p + "allowed_biotypes vazio")
	if damage_mult <= 0.0 or move_cost_mult <= 0.0 or move_speed_mult <= 0.0:
		errors.append(p + "multiplicadores devem ser > 0")
	return errors

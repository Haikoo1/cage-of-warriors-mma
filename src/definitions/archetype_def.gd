class_name ArchetypeDef
extends Resource
## Pesos de ação da IA por estilo (COMBAT_DESIGN §9.3). Não altera atributos: só preferências.

@export var id: StringName
@export var display_key: String = ""
@export var preferred_distance_m: float = 0.9
@export var punch_weight: float = 1.0
@export var kick_weight: float = 1.0
@export var takedown_weight: float = 0.0
@export var clinch_weight: float = 0.0
@export var ground_top_weight: float = 1.0
@export var ground_bottom_escape_weight: float = 1.0
## Probabilidade de manter a guarda alta quando está no alcance do adversário e parado.
@export var guard_tendency: float = 0.4


func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("ArchetypeDef: id vazio")
	if preferred_distance_m <= 0.0:
		errors.append("ArchetypeDef '%s': preferred_distance_m deve ser > 0" % id)
	if guard_tendency < 0.0 or guard_tendency > 1.0:
		errors.append("ArchetypeDef '%s': guard_tendency fora de [0, 1]" % id)
	return errors

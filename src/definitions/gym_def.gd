class_name GymDef
extends Resource
## Academia (CAREER_DESIGN §4.4): especialidades multiplicam ganhos; estrutura reduz risco de lesão.

@export var id: StringName
@export var display_name: String = ""
## área -> multiplicador (1.0 = neutro).
@export var specialties: Dictionary = {}
## 1..5: reduz risco de lesão e acelera a recuperação da fadiga.
@export var structure: int = 2
@export var monthly_cost: float = 200.0
@export var min_popularity: float = 0.0


func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"" or structure < 1 or structure > 5:
		errors.append("GymDef '%s': id vazio ou estrutura fora de 1..5" % id)
	return errors

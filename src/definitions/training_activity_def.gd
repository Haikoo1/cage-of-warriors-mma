class_name TrainingActivityDef
extends Resource
## Atividade de um bloco de treino (CAREER_DESIGN §4.1). Valores [PROV].

@export var id: StringName
@export var display_name: String = ""
## Área da academia que multiplica os ganhos: boxing, kickboxing, wrestling, jiujitsu, physical, none.
@export var area: StringName = &"none"
## Ganho base por bloco: atributo -> pontos.
@export var gains: Dictionary = {}
## Fadiga gerada (negativa = recupera).
@export var load: float = 0.0
@export var injury_risk: float = 0.0
@export var money_per_block: float = 0.0
@export var requires_fight: bool = false


func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("TrainingActivityDef: id vazio")
	for attr: Variant in gains:
		if not AttributeIds.is_valid(StringName(attr)):
			errors.append("TrainingActivityDef '%s': atributo desconhecido '%s'" % [id, attr])
	return errors

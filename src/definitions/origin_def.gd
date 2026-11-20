class_name OriginDef
extends Resource
## Origem do lutador na criação (CAREER_DESIGN §2.3).

@export var id: StringName
@export var display_name: String = ""
@export var description: String = ""
## Atributos-base (os demais começam em `default_attribute`).
@export var base_attributes: Dictionary = {}
@export var default_attribute: float = 35.0
@export var archetype: StringName = &"arch_striker"
@export var starting_money: float = 1500.0
@export var starting_gym: StringName


func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("OriginDef: id vazio")
	for attr: Variant in base_attributes:
		if not AttributeIds.is_valid(StringName(attr)):
			errors.append("OriginDef '%s': atributo desconhecido '%s'" % [id, attr])
	return errors

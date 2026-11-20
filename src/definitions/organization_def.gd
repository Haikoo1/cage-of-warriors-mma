class_name OrganizationDef
extends Resource
## Organização fictícia (CAREER_DESIGN §7, D-010). Nível 1 local → 4 elite.

@export var id: StringName
@export var display_name: String = ""
@export var tier: int = 1
@export var ruleset_id: StringName = &"rs_standard"
## Semanas entre eventos e lutas por categoria em cada evento.
@export var event_interval_weeks: int = 4
@export var bouts_per_class: int = 2
## Bolsa base (participação / vitória) [PROV].
@export var show_purse: float = 1000.0
@export var win_purse: float = 1000.0
## Lutadores gerados por categoria no mundo inicial.
@export var roster_per_class: int = 10
## Média de atributos dos lutadores gerados.
@export var attribute_mean: float = 45.0
@export var contract_fights: int = 4
## Rating mínimo para receber convite.
@export var min_rating: float = 0.0


func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"" or tier < 1 or tier > 4:
		errors.append("OrganizationDef '%s': id vazio ou nível fora de 1..4" % id)
	if event_interval_weeks < 1 or roster_per_class < 4:
		errors.append("OrganizationDef '%s': intervalo de eventos ou elenco inválido" % id)
	return errors

class_name RuleSetDef
extends Resource
## Regras configuráveis por organização (COMBAT_DESIGN §7.1). Referência: Regras Unificadas, a validar (R-020).

@export var id: StringName
@export var rounds_normal: int = 3
@export var rounds_title: int = 5
@export var round_seconds: int = 300
@export var break_seconds: int = 60
@export var scoring_system: StringName = &"ten_point_must"
@export var prohibited_strikes: PackedStringArray = PackedStringArray()
## Inatividade antes de o árbitro separar/levantar [PROV] (COMBAT_DESIGN §7.3).
@export var clinch_inactivity_seconds: float = 10.0
@export var ground_inactivity_seconds: float = 15.0
@export var weight_tolerance_lb: float = 1.0


func validate(defs: Definitions) -> Array[String]:
	var errors: Array[String] = []
	var p: String = "RuleSetDef '%s': " % id
	if id == &"":
		errors.append(p + "id vazio")
	if rounds_normal <= 0:
		errors.append(p + "rounds_normal deve ser > 0")
	if rounds_title < rounds_normal:
		errors.append(p + "rounds_title menor que rounds_normal")
	if round_seconds <= 0 or break_seconds < 0:
		errors.append(p + "duração de round/intervalo inválida")
	for strike_id: String in prohibited_strikes:
		if defs.strike(StringName(strike_id)) == null:
			errors.append(p + "golpe proibido inexistente '%s'" % strike_id)
	return errors

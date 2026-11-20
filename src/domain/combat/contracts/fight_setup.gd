class_name FightSetup
extends RefCounted
## Entrada de uma luta (GAME_SYSTEMS §3.1, R-018). Mesmo contrato para luta jogada, simulada e Luta Rápida.

enum ControlMode { PLAYER, AI }

var bout_id: StringName = &""
var fighter_a: FighterSnapshot
var fighter_b: FighterSnapshot
var control_a: ControlMode = ControlMode.PLAYER
var control_b: ControlMode = ControlMode.AI
var ruleset_id: StringName = &""
var weight_class_id: StringName = &""
var is_title: bool = false
var seed: int = 0


func validate(defs: Definitions) -> Array[String]:
	var errors: Array[String] = []
	if fighter_a == null or fighter_b == null:
		errors.append("FightSetup: faltam lutadores")
	if defs.rule_set(ruleset_id) == null:
		errors.append("FightSetup: ruleset inexistente '%s'" % ruleset_id)
	if defs.weight_class(weight_class_id) == null:
		errors.append("FightSetup: categoria inexistente '%s'" % weight_class_id)
	return errors

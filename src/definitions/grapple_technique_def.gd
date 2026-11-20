class_name GrappleTechniqueDef
extends Resource
## Técnica de grappling resolvida pela Disputa (COMBAT_DESIGN §4.2, T-005). Transições do grafo são só dados.

const ROLES: Array[StringName] = [&"any", &"top", &"bottom"]
const TOPS: Array[StringName] = [&"attacker", &"defender", &"keep", &"none"]
const KINDS: Array[StringName] = [&"transition", &"submission"]

@export var id: StringName
@export var kind: StringName = &"transition"
@export var from_state: StringName
## Papel exigido do atacante: any (posições neutras), top ou bottom.
@export var role: StringName = &"any"
@export var direction: FighterCommand.Direction = FighterCommand.Direction.NONE
@export var to_state: StringName
## Quem fica "por cima" depois: attacker, defender, keep (mantém) ou none (posição neutra).
@export var result_top: StringName = &"keep"
@export var startup_frames: int = 0
@export var pressure_attr: StringName
@export var resistance_attr: StringName
## Direção que o defensor precisa ler durante a preparação.
@export var defense_direction: FighterCommand.Direction = FighterCommand.Direction.NONE
## Leitura perfeita (início da janela) leva a este estado, se definido.
@export var counter_state: StringName = &""
@export var counter_top: StringName = &"none"
@export var max_range_m: float = 0.0
@export var requires_advantage: bool = false
@export var grants_advantage: bool = false
@export var stamina_cost: float = 0.0
@export_group("Finalização")
@export var squeeze_rate: float = 0.0
@export var escapes_needed: int = 3
@export var escape_state: StringName = &""
@export var escape_top: StringName = &"defender"


func validate() -> Array[String]:
	var errors: Array[String] = []
	var p: String = "GrappleTechniqueDef '%s': " % id
	if id == &"":
		errors.append(p + "id vazio")
	if not CombatGrappling.POSITIONS.has(from_state):
		errors.append(p + "from_state inválido '%s'" % from_state)
	if not KINDS.has(kind):
		errors.append(p + "kind inválido")
	if kind == &"transition" and not CombatGrappling.POSITIONS.has(to_state):
		errors.append(p + "to_state inválido '%s'" % to_state)
	if kind == &"submission" and not CombatGrappling.POSITIONS.has(escape_state):
		errors.append(p + "escape_state inválido '%s'" % escape_state)
	if counter_state != &"" and not CombatGrappling.POSITIONS.has(counter_state):
		errors.append(p + "counter_state inválido '%s'" % counter_state)
	if not ROLES.has(role):
		errors.append(p + "role inválido '%s'" % role)
	for t: StringName in [result_top, counter_top, escape_top]:
		if not TOPS.has(t):
			errors.append(p + "valor de topo inválido '%s'" % t)
	if not AttributeIds.is_valid(pressure_attr) or not AttributeIds.is_valid(resistance_attr):
		errors.append(p + "atributo de pressão/resistência desconhecido")
	if startup_frames <= 0:
		errors.append(p + "startup_frames deve ser > 0")
	return errors

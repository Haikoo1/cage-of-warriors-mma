class_name StrikeDef
extends Resource
## Golpe em pé (COMBAT_DESIGN §3.2–3.5). Quadros = passos de simulação a 60 Hz (T-004).

enum Limb { LEAD_HAND, REAR_HAND, LEAD_LEG, REAR_LEG }
enum Variant { STRAIGHT, CURVED, BODY }

const VALID_TARGETS: PackedStringArray = ["head", "body", "legs"]

@export var id: StringName
@export var limb: Limb = Limb.LEAD_HAND
@export var variant: Variant = Variant.STRAIGHT
@export var targets: PackedStringArray = PackedStringArray()
@export var base_reach_m: float = 0.0
@export var depth_tolerance_m: float = 0.0
@export var startup_frames: int = 0
@export var active_frames: int = 0
@export var recovery_frames: int = 0
@export var chain_window_frames: int = 0
## Fração da preparação até a qual a finta é possível.
@export var feint_cutoff: float = 0.6
@export var power: float = 0.0
@export var stamina_cost: float = 0.0
@export var technique_attribute: StringName


func total_frames() -> int:
	return startup_frames + active_frames + recovery_frames


func validate() -> Array[String]:
	var errors: Array[String] = []
	var p: String = "StrikeDef '%s': " % id
	if id == &"":
		errors.append(p + "id vazio")
	if targets.is_empty():
		errors.append(p + "targets vazio")
	for t: String in targets:
		if not VALID_TARGETS.has(t):
			errors.append(p + "targets contém alvo inválido '%s'" % t)
	if base_reach_m <= 0.0:
		errors.append(p + "base_reach_m deve ser > 0")
	if depth_tolerance_m <= 0.0:
		errors.append(p + "depth_tolerance_m deve ser > 0")
	if startup_frames <= 0:
		errors.append(p + "startup_frames deve ser > 0")
	if active_frames <= 0:
		errors.append(p + "active_frames deve ser > 0")
	if recovery_frames <= 0:
		errors.append(p + "recovery_frames deve ser > 0")
	if chain_window_frames < 0:
		errors.append(p + "chain_window_frames deve ser >= 0")
	if feint_cutoff < 0.0 or feint_cutoff > 1.0:
		errors.append(p + "feint_cutoff fora de [0, 1]")
	if not AttributeIds.is_valid(technique_attribute):
		errors.append(p + "technique_attribute desconhecido '%s'" % technique_attribute)
	return errors

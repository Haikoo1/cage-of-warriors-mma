class_name CognitiveProfileDef
extends Resource
## Limitações humanas da IA (COMBAT_DESIGN §9.5). A dificuldade muda ISTO, nunca atributos (REQ-07).

@export var id: StringName
@export var display_key: String = ""
## Atraso entre algo ficar visível e a IA perceber. Mínimo de 150 ms (COMBAT §9.6).
@export var perception_delay_ms: int = 250
@export var read_error: float = 0.25
@export var decision_interval_ms: int = 200
## Aleatoriedade na escolha entre ações (0 = sempre a melhor). Nunca zero.
@export var temperature: float = 0.5
## Amostras mínimas antes de explorar um hábito do adversário.
@export var habit_min_samples: int = 4
## Abaixo desta fração de Fôlego a IA prioriza recuperar.
@export var stamina_discipline: float = 0.3

const MIN_PERCEPTION_MS: int = 150


func perception_delay_frames() -> int:
	return roundi(perception_delay_ms * 60.0 / 1000.0)


func decision_interval_frames() -> int:
	return maxi(1, roundi(decision_interval_ms * 60.0 / 1000.0))


func validate() -> Array[String]:
	var errors: Array[String] = []
	var p: String = "CognitiveProfileDef '%s': " % id
	if id == &"":
		errors.append(p + "id vazio")
	if perception_delay_ms < MIN_PERCEPTION_MS:
		errors.append(p + "perception_delay_ms abaixo do mínimo de %d" % MIN_PERCEPTION_MS)
	if read_error < 0.0 or read_error > 1.0:
		errors.append(p + "read_error fora de [0, 1]")
	if temperature <= 0.0:
		errors.append(p + "temperature deve ser > 0")
	return errors

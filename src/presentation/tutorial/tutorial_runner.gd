class_name TutorialRunner
extends RefCounted
## Tutorial interativo (E-12): lições verificadas pelos eventos reais do combate (nada é encenado).

const LESSONS: Array[Dictionary] = [
	{"id": "jab", "text": "Aproxime-se (D) e acerte 3 jabs: U.", "dummy": TrainingDummy.Mode.STILL, "target": 3, "reset": false},
	{"id": "body", "text": "Golpe ao corpo: segure Q e aperte I (direto no corpo) 2 vezes.", "dummy": TrainingDummy.Mode.STILL, "target": 2, "reset": false},
	{"id": "kick", "text": "Chute baixo: K. Acerte 2 chutes baixos ou ao corpo (Q+K).", "dummy": TrainingDummy.Mode.STILL, "target": 2, "reset": false},
	{"id": "block", "text": "O boneco agora dá jabs. Segure Shift (guarda) e bloqueie 3.", "dummy": TrainingDummy.Mode.JAB, "target": 3, "reset": true},
	{"id": "slip", "text": "Esquiva: aperte Espaço+W quando o jab vier. Esquive 2 vezes.", "dummy": TrainingDummy.Mode.JAB, "target": 2, "reset": false},
	{"id": "counter", "text": "Contra-golpe: acerte o boneco ENQUANTO ele prepara o jab (1 vez).", "dummy": TrainingDummy.Mode.JAB, "target": 1, "reset": false},
	{"id": "sprawl", "text": "O boneco é wrestler. Defenda a queda com Espaço+S logo no início dela.", "dummy": TrainingDummy.Mode.WRESTLER, "target": 1, "reset": true},
	{"id": "takedown", "text": "Sua vez: chegue perto e derrube com L+S (double leg).", "dummy": TrainingDummy.Mode.STILL, "target": 1, "reset": true},
	{"id": "pass", "text": "Por cima na guarda: passe 2 vezes com L+D (guarda, meia, lateral).", "dummy": TrainingDummy.Mode.STILL, "target": 2, "reset": false},
	{"id": "gnp", "text": "Ground and pound: acerte 3 socos no chão (U/I).", "dummy": TrainingDummy.Mode.STILL, "target": 3, "reset": false},
	{"id": "finish", "text": "Finalize! Use uma finalização do overlay (ex.: nas costas, L+S).", "dummy": TrainingDummy.Mode.STILL, "target": 1, "reset": false},
]

var index: int = 0
var progress: int = 0


func current() -> Dictionary:
	return LESSONS[mini(index, LESSONS.size() - 1)]


func is_done() -> bool:
	return index >= LESSONS.size()


## Processa os eventos do passo; devolve true quando uma lição termina.
func feed(events: Array, sim: CombatSim) -> bool:
	if is_done():
		return false
	for e: CombatEvent in events:
		if _counts(String(current()["id"]), e, sim):
			progress += 1
	if progress >= int(current()["target"]):
		index += 1
		progress = 0
		return true
	return false


func _counts(id: String, e: CombatEvent, sim: CombatSim) -> bool:
	var landed: bool = e.type == CombatEvent.Type.STRIKE_RESOLVED and e.outcome in [CombatEvent.Outcome.CLEAN, CombatEvent.Outcome.COUNTER]
	var grapple_ok: bool = e.type == CombatEvent.Type.GRAPPLE_RESOLVED and e.attacker == 0 and e.grapple_outcome == CombatEvent.GrappleOutcome.SUCCESS
	match id:
		"jab":
			return landed and e.attacker == 0 and e.strike_id == &"jab"
		"body":
			return landed and e.attacker == 0 and e.zone == &"body" and e.strike_id in [&"cross", &"jab"]
		"kick":
			return landed and e.attacker == 0 and e.strike_id in [&"low_kick", &"body_kick", &"calf_kick"]
		"block":
			return e.type == CombatEvent.Type.STRIKE_RESOLVED and e.attacker == 1 and e.outcome == CombatEvent.Outcome.BLOCKED
		"slip":
			return e.type == CombatEvent.Type.STRIKE_RESOLVED and e.attacker == 1 and e.outcome == CombatEvent.Outcome.EVADED
		"counter":
			return e.type == CombatEvent.Type.STRIKE_RESOLVED and e.attacker == 0 and e.outcome == CombatEvent.Outcome.COUNTER
		"sprawl":
			return e.type == CombatEvent.Type.GRAPPLE_RESOLVED and e.attacker == 1 \
				and e.grapple_outcome in [CombatEvent.GrappleOutcome.READ, CombatEvent.GrappleOutcome.PERFECT_READ]
		"takedown":
			return grapple_ok and e.technique_id in [&"double_leg", &"single_leg"]
		"pass":
			return grapple_ok and e.technique_id in [&"guard_pass", &"half_pass"]
		"gnp":
			return landed and e.attacker == 0 and e.strike_id == &"ground_and_pound"
		"finish":
			return e.type == CombatEvent.Type.FIGHT_OVER and e.attacker == 0 and sim.finish_method == &"submission"
	return false

class_name FightResult
extends RefCounted
## Saída de uma luta (GAME_SYSTEMS §3.2). Produzido pelo combate jogado e pelo resolvedor estatístico.

enum FighterSlot { A, B, NONE }
enum Method {
	KO, TKO, SUBMISSION, DECISION_UNANIMOUS, DECISION_SPLIT, DECISION_MAJORITY,
	DRAW, DISQUALIFICATION, NO_CONTEST, TECHNICAL_DECISION,
}

var bout_id: StringName = &""
var winner: FighterSlot = FighterSlot.NONE
var method: Method = Method.DECISION_UNANIMOUS
var method_detail: StringName = &""
var round: int = 0
var time_seconds: int = 0
var scorecards: Array = []  # por juiz: [pontos A, pontos B] (detalhe por round em etapas futuras)
var stats: Dictionary = {}
var medical: Dictionary = {}  # "a"/"b" -> dano por zona, knockdowns, cortes


func to_dict() -> Dictionary:
	return {
		"bout_id": String(bout_id),
		"winner": FighterSlot.keys()[winner],
		"method": Method.keys()[method],
		"method_detail": String(method_detail),
		"round": round,
		"time_seconds": time_seconds,
		"scorecards": scorecards.duplicate(true),
		"stats": stats.duplicate(true),
		"medical": medical.duplicate(true),
	}


static func from_dict(d: Dictionary) -> FightResult:
	var r: FightResult = FightResult.new()
	r.bout_id = StringName(d.get("bout_id", ""))
	r.winner = FighterSlot.keys().find(d.get("winner", "NONE")) as FighterSlot
	r.method = Method.keys().find(d.get("method", "DECISION_UNANIMOUS")) as Method
	r.method_detail = StringName(d.get("method_detail", ""))
	r.round = int(d.get("round", 0))
	r.time_seconds = int(d.get("time_seconds", 0))
	# JSON devolve números como float; pontuações são inteiras.
	for card: Array in d.get("scorecards", []):
		r.scorecards.append(card.map(func(v: Variant) -> int: return int(v)))
	r.stats = d.get("stats", {})
	r.medical = d.get("medical", {})
	return r

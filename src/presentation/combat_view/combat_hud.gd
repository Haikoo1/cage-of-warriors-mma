class_name CombatHud
extends Control
## HUD greybox (nível Completo, R-027): Fôlego/Reserva, dano por zona, feedback "por que falhou" e métricas.

const OUTCOME_TEXT: Dictionary = {
	CombatEvent.Outcome.MISS_RANGE: "Fora de alcance",
	CombatEvent.Outcome.MISS_ANGLE: "Errou o ângulo",
	CombatEvent.Outcome.EVADED: "Esquivou",
	CombatEvent.Outcome.BLOCKED: "Bloqueado",
	CombatEvent.Outcome.CLEAN: "Acertou",
	CombatEvent.Outcome.COUNTER: "Contra-golpe!",
}

var sim: CombatSim
var dummy_mode: String = ""
var feedback: Array[String] = ["", ""]
var _feedback_timer: Array[int] = [0, 0]


func present(events: Array[CombatEvent]) -> void:
	for e: CombatEvent in events:
		if e.type == CombatEvent.Type.STRIKE_RESOLVED:
			feedback[e.attacker] = "%s: %s" % [e.strike_id, OUTCOME_TEXT.get(e.outcome, "")]
			_feedback_timer[e.attacker] = 90
	for i: int in 2:
		_feedback_timer[i] = maxi(0, _feedback_timer[i] - 1)
		if _feedback_timer[i] == 0:
			feedback[i] = ""
	queue_redraw()


func _draw() -> void:
	if sim == null:
		return
	for i: int in 2:
		_draw_panel(i)
	var help: String = "WASD mover | U/I mãos  J/K pernas | E curvo  Q corpo | Shift guarda | Espaço+W/S/trás esquiva\nF1 depuração | F2 boneco: %s | F3 métricas no log | R reiniciar | Esc menu" % dummy_mode
	draw_multiline_string(ThemeDB.fallback_font, Vector2(8, 322), help, HORIZONTAL_ALIGNMENT_LEFT, 624, 9, -1, Color(1, 1, 1, 0.75))


func _draw_panel(i: int) -> void:
	var f: FighterCombatState = sim.fighters[i]
	var x0: float = 8.0 if i == 0 else 392.0
	var title: String = "JOGADOR" if i == 0 else "BONECO"
	_text(Vector2(x0, 14), title, GreyboxView.COLORS[i])
	draw_rect(Rect2(x0, 18, 240, 6), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(x0, 18, 240 * f.reserve / 100.0, 6), Color(0.3, 0.3, 0.3))
	var st: Color = Color.GREEN if f.stamina > 50 else (Color.YELLOW if f.stamina >= 25 else Color.RED)
	draw_rect(Rect2(x0, 18, 240 * f.stamina / 100.0, 6), st)
	_text(Vector2(x0, 36), "Fôlego %d / Reserva %d   Cabeça %d  Corpo %d  Pernas %d" % [
		f.stamina, f.reserve, f.zone_damage(&"head"), f.zone_damage(&"body"), f.zone_damage(&"legs")], Color.WHITE)
	var s: Dictionary = f.stats
	_text(Vector2(x0, 48), "Golpes %d  acertos %d  bloq %d  erros %d  esquivados %d  contra %d" % [
		s["attempts"], s["landed"], s["blocked"], s["missed"], s["evaded"], s["counters"]], Color(1, 1, 1, 0.7))
	_text(Vector2(x0, 62), feedback[i], Color.YELLOW)


func _text(pos: Vector2, t: String, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c)

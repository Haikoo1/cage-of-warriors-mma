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

const GRAPPLE_TEXT: Dictionary = {
	CombatEvent.GrappleOutcome.READ: "Defendido (leitura)",
	CombatEvent.GrappleOutcome.PERFECT_READ: "Leitura perfeita! Contra",
	CombatEvent.GrappleOutcome.SUCCESS: "Passou",
	CombatEvent.GrappleOutcome.PARTIAL: "Resistiu (progresso parcial)",
	CombatEvent.GrappleOutcome.FAIL: "Resistiu",
	CombatEvent.GrappleOutcome.TAPPED: "FINALIZOU!",
	CombatEvent.GrappleOutcome.ESCAPED: "Escapou da finalização",
}
const DIR_KEYS: Dictionary = {0: "L", 1: "L+D", 2: "L+A", 3: "L+W", 4: "L+S"}

var sim: CombatSim
var dummy_mode: String = ""
var feedback: Array[String] = ["", ""]
var _feedback_timer: Array[int] = [0, 0]


func present(events: Array[CombatEvent]) -> void:
	for e: CombatEvent in events:
		if e.type == CombatEvent.Type.STRIKE_RESOLVED:
			feedback[e.attacker] = "%s: %s" % [e.strike_id, OUTCOME_TEXT.get(e.outcome, "")]
			_feedback_timer[e.attacker] = 90
		elif e.type == CombatEvent.Type.GRAPPLE_RESOLVED or (e.type == CombatEvent.Type.SQUEEZE_TICK and e.grapple_outcome != CombatEvent.GrappleOutcome.NONE):
			feedback[e.attacker] = "%s: %s" % [e.technique_id, GRAPPLE_TEXT.get(e.grapple_outcome, "")]
			_feedback_timer[e.attacker] = 120
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
	_draw_grappling()
	var help: String = "WASD mover | U/I mãos  J/K pernas | E curvo  Q corpo | Shift guarda | Espaço+W/S/trás esquiva | L clinch, L+S/W quedas\nF1 depuração | F2 boneco: %s | F3 métricas no log | R reiniciar | Esc menu" % dummy_mode
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


## Overlay de opções da posição atual (COMBAT §4.2) e Medidor de Aperto.
func _draw_grappling() -> void:
	var g: CombatGrappling = sim.grappling
	if g.submission != null:
		var sub: CombatGrappling.Submission = g.submission
		draw_rect(Rect2(220, 80, 200, 8), Color(0.2, 0.2, 0.2))
		draw_rect(Rect2(220, 80, 2.0 * clampf(sub.meter, 0.0, 100.0), 8), Color.RED)
		var who: String = "VOCÊ APERTA (WASD muda o ajuste)" if sub.attacker == 0 else "ESCAPE: toque a direção do ajuste (WASD)"
		_text(Vector2(220, 100), "%s  — escapes %d/%d" % [who, sub.escapes, sub.technique.escapes_needed], Color.ORANGE)
		return
	var role: StringName = g.role_of(0)
	var lines: PackedStringArray = []
	for t: GrappleTechniqueDef in sim.defs.grapple_techniques.values():
		if t.from_state == g.position and t.role == role:
			var lock: String = " (precisa de pegada)" if t.requires_advantage and g.clinch_owner != 0 else ""
			lines.append("%s %s%s" % [DIR_KEYS.get(int(t.direction), "?"), t.id, lock])
	if g.position != &"EP" and g.top == 0:
		lines.append("U/I socos no chão")
	if g.position != &"EP" and g.top == 1:
		lines.append("Shift cobrir-se")
	if g.pending != null and g.pending.attacker == 1:
		lines.append(">> DEFENDA: toque a direção da técnica (%s)" % g.pending.technique.id)
	lines.sort()
	for k: int in lines.size():
		_text(Vector2(8, 82 + k * 11), lines[k], Color(0.8, 1.0, 0.8))

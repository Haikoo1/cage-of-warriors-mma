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
var names: Array[String] = ["JOGADOR", "BONECO"]
var training: bool = true
var paused: bool = false
var career_lock: bool = false  # luta de carreira não pode ser abandonada
var max_tips: int = 2
var tutorial: TutorialRunner
var title_fight: bool = false  # carreira: depende da estrutura da academia (CAREER §4.5)
var player_focus: CombatSim.Focus = CombatSim.Focus.NORMAL
var feedback: Array[String] = ["", ""]
var _feedback_timer: Array[int] = [0, 0]


func present(events: Array[CombatEvent]) -> void:
	for e: CombatEvent in events:
		if e.type == CombatEvent.Type.CUT:
			feedback[e.attacker] = "Abriu um corte! (%d/3)" % e.shock_state
			_feedback_timer[e.attacker] = 120
		elif e.type == CombatEvent.Type.STRIKE_RESOLVED:
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
	var level: StringName = Settings.store.hud_level
	if level != &"immersive":
		for i: int in 2:
			_draw_panel(i)
	if level == &"full" or sim.grappling.submission != null:
		_draw_grappling()
	_draw_clock()
	if tutorial != null:
		UiDraw.panel(self, Rect2(150, 96, 340, 44), true)
		if tutorial.is_done():
			_text(Vector2(162, 114), "TUTORIAL CONCLUÍDO! Esc volta ao menu.", UiDraw.C_GOOD)
		else:
			_text(Vector2(162, 112), "Lição %d/%d  ·  %d/%d" % [tutorial.index + 1, TutorialRunner.LESSONS.size(), tutorial.progress, int(tutorial.current()["target"])], UiDraw.C_SEL)
			draw_string(ThemeDB.fallback_font, Vector2(162, 128), String(tutorial.current()["text"]), HORIZONTAL_ALIGNMENT_LEFT, 320, 9, UiDraw.C_TEXT)
	if sim.phase == CombatSim.Phase.ROUND_BREAK:
		_draw_break()
		return
	if sim.is_finished():
		_draw_end()
	if paused:
		draw_rect(Rect2(220, 140, 200, 60), Color(0, 0, 0, 0.85))
		_text(Vector2(236, 162), "PAUSA", Color.YELLOW)
		_text(Vector2(236, 180), "P continuar · Esc %s" % ("continuar" if career_lock else "sair"), Color.WHITE)
	var help: String = "WASD mover | U/I mãos  J/K pernas | E curvo  Q corpo | Shift guarda | Espaço+W/S/trás esquiva | L clinch, L+S/W quedas\nF1 depuração | F2 boneco: %s | F3 métricas | R reiniciar | Esc menu" % dummy_mode if training else "F1 depuração | F4 sprites (teste de arte) | Esc sair"
	UiDraw.footer(self, help.replace("
", "  ·  "))


func _draw_panel(i: int) -> void:
	var f: FighterCombatState = sim.fighters[i]
	var x0: float = 8.0 if i == 0 else 390.0
	UiDraw.panel(self, Rect2(x0, 6, 242, 62))
	UiDraw.icon(self, "mask", Vector2(x0 + 6, 9), 12, GreyboxView.COLORS[i].lightened(0.5))
	_text(Vector2(x0 + 22, 19), names[i], GreyboxView.COLORS[i].lightened(0.25))
	UiDraw.icon(self, "heart", Vector2(x0 + 236 - 10, 9), 10)
	UiDraw.bar(self, Rect2(x0 + 8, 23, 226, 7), f.reserve / 100.0, Color(0.3, 0.32, 0.38))
	var st: Color = UiDraw.C_GOOD if f.stamina > 50 else (UiDraw.C_SEL if f.stamina >= 25 else UiDraw.C_BAD)
	UiDraw.bar(self, Rect2(x0 + 8, 23, 226, 7), f.stamina / 100.0, st)
	_text(Vector2(x0 + 8, 42), "Fôlego %d / %d   Cabeça %d · Corpo %d · Pernas %d" % [
		f.stamina, f.reserve, f.zone_damage(&"head"), f.zone_damage(&"body"), f.zone_damage(&"legs")], UiDraw.C_TEXT)
	var s: Dictionary = f.stats
	_text(Vector2(x0 + 8, 54), "Golpes %d · acertos %d · bloq. %d · contra %d" % [s["attempts"], s["landed"], s["blocked"], s["counters"]], UiDraw.C_DIM)
	if f.cut > 0:
		_text(Vector2(x0 + 190, 19), "CORTE %d/3" % f.cut, UiDraw.C_BAD)
	if feedback[i] != "":
		_text(Vector2(x0 + 8, 82), feedback[i], UiDraw.C_SEL)


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
		_text(Vector2(10, 102 + k * 11), lines[k], Color(0.8, 1.0, 0.8))


func _draw_clock() -> void:
	if training:
		return
	var left: int = maxi(0, sim.round_seconds - sim.round_seconds_elapsed())
	if title_fight:
		UiDraw.icon(self, "belt", Vector2(296, 32), 48)
		draw_string(ThemeDB.fallback_font, Vector2(270, 88), "DISPUTA DE CINTURÃO", HORIZONTAL_ALIGNMENT_CENTER, 100, 8, UiDraw.C_SEL)
	UiDraw.panel(self, Rect2(276, 6, 88, 26))
	draw_string(ThemeDB.fallback_font, Vector2(276, 24), "R%d/%d  %d:%02d" % [sim.round, sim.total_rounds, left / 60, left % 60], HORIZONTAL_ALIGNMENT_CENTER, 88, 12, UiDraw.C_TEXT)


## Intervalo (COMBAT §5.1, §5.3): estatísticas do round, dicas do córner e foco tático.
func _draw_break() -> void:
	draw_rect(Rect2(110, 90, 420, 190), Color(0, 0, 0, 0.85))
	_text(Vector2(124, 108), "INTERVALO — fim do round %d" % (sim.round), Color.YELLOW)
	var last: Array = sim.round_stat_history[-1]
	for k: int in 2:
		var st: Dictionary = last[k]
		_text(Vector2(124, 126 + k * 12), "%s: dano %.0f · transições %d · controle %.0fs" % [names[k], float(st["damage"]), int(st["grapple"]), float(st["control_s"])], Color.WHITE)
	var cards: Array = sim.round_scores[-1]
	_text(Vector2(124, 156), "Juízes no round: %s" % ", ".join(cards.map(func(c: Array) -> String: return "%d-%d" % [c[0], c[1]])), Color(1, 1, 1, 0.8))
	var y: float = 176
	for tip: String in corner_tips():
		_text(Vector2(124, y), "Córner: " + tip, Color(0.7, 1, 0.7))
		y += 12
	var focus: String = "Manter o plano (normal)" if player_focus == CombatSim.Focus.NORMAL else "Recuperar o fôlego (+Fôlego, menos recuperação de dano)"
	_text(Vector2(124, 236), "Foco: 1 = normal · 2 = recuperar fôlego   →  %s" % focus, Color.ORANGE)
	_text(Vector2(124, 256), "Enter: próximo round", Color(1, 1, 1, 0.7))


## Até 2 observações sobre o round (COMBAT §5.1). Sem bônus: só informação.
func corner_tips() -> Array[String]:
	var tips: Array[String] = []
	var last: Array = sim.round_stat_history[-1]
	var me: Dictionary = last[0]
	var opp: Dictionary = last[1]
	var f: FighterCombatState = sim.fighters[0]
	if float(opp["control_s"]) > float(me["control_s"]) + 20.0:
		tips.append("ele te controlou no chão/grade. Defenda as quedas com Espaço+S.")
	if float(opp["damage"]) > float(me["damage"]) * 1.5 + 5.0:
		tips.append("você está apanhando na trocação. Use o passo lateral (W/S) e a guarda.")
	if f.stamina_ratio() < 0.4:
		tips.append("seu fôlego está baixo. Considere o foco 'recuperar'.")
	if sim.fighters[1].zone_damage(&"head") > 40.0 and tips.size() < 2:
		tips.append("ele está sentindo a cabeça. Pressione com cuidado.")
	if tips.is_empty():
		tips.append("round equilibrado. Mantenha o plano.")
	return tips.slice(0, max_tips)


func _draw_end() -> void:
	draw_rect(Rect2(170, 130, 300, 50), Color(0, 0, 0, 0.85))
	var method: String = {&"ko": "NOCAUTE", &"tko": "NOCAUTE TÉCNICO", &"submission": "FINALIZAÇÃO", &"decision": "DECISÃO DOS JUÍZES"}.get(sim.finish_method, "FIM")
	_text(Vector2(186, 152), method, Color.YELLOW)
	var w: int = sim.winner()
	_text(Vector2(186, 168), ("Vencedor: %s" % names[w]) if w >= 0 else "Empate", Color.WHITE)

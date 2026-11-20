class_name CombatHud
extends Control
## HUD de transmissão (D-023): painéis de canto com dano por região (opcional), fôlego e nome; régua de domínio no
## topo; placar centralizado embaixo com organização, cronômetro e round. Desenhada na resolução da janela (HD);
## coordenadas lógicas 640x360. Nenhuma marca real: a organização é a fictícia da luta.

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
const W: float = 640.0
const CORNER: Array[Color] = [Color(0.78, 0.09, 0.12), Color(0.12, 0.36, 0.78)]  # córner vermelho / azul
const C_FRAME: Color = Color(0.04, 0.05, 0.08, 0.88)
const C_EDGE: Color = Color(0.55, 0.58, 0.64)
const C_GOLD: Color = Color(0.86, 0.68, 0.22)
const ZONES: Array[StringName] = [&"head", &"body", &"legs"]

var sim: CombatSim
var dummy_mode: String = ""
var names: Array[String] = ["JOGADOR", "BONECO"]
var event_name: String = "JAULA"  # organização fictícia da luta (carreira: a do evento)
var weight_name: String = ""
var training: bool = true
var paused: bool = false
var career_lock: bool = false  # luta de carreira não pode ser abandonada
var max_tips: int = 2
var tutorial: TutorialRunner
var title_fight: bool = false  # carreira: depende da estrutura da academia (CAREER §4.5)
var player_focus: CombatSim.Focus = CombatSim.Focus.NORMAL
var feedback: Array[String] = ["", ""]
var _feedback_timer: Array[int] = [0, 0]
var _bold: SystemFont
var _bold_italic: SystemFont


func _init() -> void:
	_bold = SystemFont.new()
	_bold.font_names = PackedStringArray(["Segoe UI", "Arial", "Noto Sans"])
	_bold.font_weight = 700
	_bold_italic = _bold.duplicate() as SystemFont
	_bold_italic.font_italic = true
	_bold_italic.font_weight = 800


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
			_draw_corner(i, level == &"full")
		if not training:
			_draw_momentum()
	if level == &"full" or sim.grappling.submission != null:
		_draw_grappling()
	_draw_scoreboard()
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
		UiDraw.panel(self, Rect2(220, 136, 200, 56), true)
		_txt(_bold, Vector2(220, 158), "PAUSA", 14, C_GOLD, 200, HORIZONTAL_ALIGNMENT_CENTER)
		_txt(ThemeDB.fallback_font, Vector2(220, 176), "P continuar · Esc %s" % ("continuar" if career_lock else "sair"), 9, UiDraw.C_TEXT, 200, HORIZONTAL_ALIGNMENT_CENTER)
	if training:
		UiDraw.footer(self, "WASD mover | U/I mãos  J/K pernas | E curvo  Q corpo | Shift guarda | Espaço+W/S/trás esquiva | L clinch, L+S/W quedas  ·  F1 depuração | F2 boneco: %s | F3 métricas | R reiniciar | Esc menu" % dummy_mode)


# ------------------------------------------------------------------ primitivas espelháveis (lado B = espelho do A)
func _mx(i: int, x: float) -> float:
	return x if i == 0 else W - x


func _poly(i: int, pts: Array, color: Color) -> void:
	var out: PackedVector2Array = []
	for p: Vector2 in pts:
		out.append(Vector2(_mx(i, p.x), p.y))
	draw_colored_polygon(out, color)


func _rect(i: int, r: Rect2, color: Color) -> void:
	var x0: float = _mx(i, r.position.x)
	var x1: float = _mx(i, r.position.x + r.size.x)
	draw_rect(Rect2(minf(x0, x1), r.position.y, absf(x1 - x0), r.size.y), color)


func _line(i: int, a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
	draw_line(Vector2(_mx(i, a.x), a.y), Vector2(_mx(i, b.x), b.y), color, width, true)


func _txt(font: Font, pos: Vector2, s: String, size: int, color: Color, width: float = -1, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos, s, align, width, size, color)


func _text(pos: Vector2, t: String, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c)


## Barra com fundo, preenchimento ancorado no lado de dentro (espelhada no B) e brilho superior.
func _bar(i: int, r: Rect2, value: float, color: Color, ghost: float = -1.0) -> void:
	_rect(i, r, Color(0.02, 0.02, 0.03, 0.9))
	if ghost > value:
		_rect(i, Rect2(r.position, Vector2(r.size.x * clampf(ghost, 0, 1), r.size.y)), Color(0.32, 0.33, 0.36))
	var fill: Rect2 = Rect2(r.position, Vector2(r.size.x * clampf(value, 0, 1), r.size.y))
	_rect(i, fill, color)
	_rect(i, Rect2(fill.position, Vector2(fill.size.x, maxf(1.0, r.size.y * 0.3))), color.lightened(0.35))


# ------------------------------------------------------------------ painel de canto
func _draw_corner(i: int, full: bool) -> void:
	var f: FighterCombatState = sim.fighters[i]
	var damage_hud: bool = Settings.store.show_damage_hud
	var bottom: float = 40.0 if damage_hud else 30.0
	# Moldura escura angulada e emblema em losango.
	_poly(i, [Vector2(30, 5), Vector2(236, 5), Vector2(236, bottom), Vector2(44, bottom)], C_FRAME)
	_line(i, Vector2(30, 5), Vector2(236, 5), C_EDGE)
	_line(i, Vector2(236, 5), Vector2(236, bottom), Color(C_EDGE, 0.5))
	var c: Vector2 = Vector2(30, 27)
	_poly(i, [c + Vector2(0, -24), c + Vector2(24, 0), c + Vector2(0, 24), c + Vector2(-24, 0)], C_EDGE)
	_poly(i, [c + Vector2(0, -21), c + Vector2(21, 0), c + Vector2(0, 21), c + Vector2(-21, 0)], Color(0.07, 0.08, 0.11))
	_poly(i, [c + Vector2(0, -21), c + Vector2(21, 0), c + Vector2(0, 0), c + Vector2(-21, 0)], Color(0.13, 0.14, 0.18))
	_txt(_bold, Vector2(_mx(i, c.x) - 20, c.y + 5), _initials(names[i]), 13, CORNER[i].lightened(0.45), 40, HORIZONTAL_ALIGNMENT_CENTER)
	# Reserva (fôlego máximo da luta): barra branca fina.
	_bar(i, Rect2(60, 9, 170, 3), f.reserve / 100.0, Color(0.92, 0.93, 0.95))
	var y: float = 16.0
	if damage_hud:
		for k: int in 3:
			var x: float = 60.0 + k * 57.0
			_rect(i, Rect2(x, y, 12, 12), Color(0.16, 0.17, 0.21))
			_zone_icon(i, ZONES[k], Vector2(x + 6, y + 6))
			var health: float = 1.0 - clampf(f.zone_damage(ZONES[k]) / 100.0, 0.0, 1.0)
			_bar(i, Rect2(x + 14, y + 1, 41, 10), health, _health_color(health))
		y += 16.0
	# Fôlego: barra amarelo-laranja com raio; o que passa da Reserva fica escuro.
	_lightning(i, Vector2(64, y + 3))
	var st: float = f.stamina / 100.0
	var col: Color = C_GOLD if st > 0.25 else UiDraw.C_BAD
	_bar(i, Rect2(72, y, 158, 6), st, col, f.reserve / 100.0)
	# Faixa do nome com a cor do córner.
	var ny: float = bottom + 2.0
	_poly(i, [Vector2(44, ny), Vector2(236, ny), Vector2(230, ny + 14), Vector2(50, ny + 14)], Color(CORNER[i], 0.25))
	_poly(i, [Vector2(44, ny), Vector2(150, ny), Vector2(144, ny + 14), Vector2(50, ny + 14)], Color(CORNER[i], 0.85))
	var name_x: float = 56.0 if i == 0 else W - 56.0 - 170.0
	_txt(_bold, Vector2(name_x, ny + 11), names[i].to_upper(), 10, Color.WHITE, 170,
		HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT)
	var info_y: float = ny + 26.0
	if f.cut > 0:
		_txt(_bold, Vector2(_mx(i, 50) - (0 if i == 0 else 120), info_y), "CORTE %d/3" % f.cut, 8, UiDraw.C_BAD, 120,
			HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT)
		info_y += 11.0
	if full and feedback[i] != "":
		_txt(ThemeDB.fallback_font, Vector2(_mx(i, 50) - (0 if i == 0 else 190), info_y), feedback[i], 9, C_GOLD, 190,
			HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT)
		info_y += 11.0
	if full and training:
		var s: Dictionary = f.stats
		_txt(ThemeDB.fallback_font, Vector2(_mx(i, 50) - (0 if i == 0 else 190), info_y), "Golpes %d · acertos %d · bloq. %d · contra %d" % [s["attempts"], s["landed"], s["blocked"], s["counters"]],
			8, UiDraw.C_DIM, 190, HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT)


func _initials(n: String) -> String:
	var parts: PackedStringArray = n.strip_edges().split(" ", false)
	if parts.is_empty():
		return "?"
	if parts.size() == 1:
		return parts[0].left(2).to_upper()
	return (parts[0].left(1) + parts[parts.size() - 1].left(1)).to_upper()


func _health_color(h: float) -> Color:
	if h > 0.6:
		return Color(0.13, 0.72, 0.45)
	if h > 0.3:
		return Color(0.93, 0.74, 0.2)
	return Color(0.9, 0.24, 0.2)


## Ícones vetoriais (nítidos em qualquer resolução): cabeça, tronco, pernas.
func _zone_icon(i: int, zone: StringName, c: Vector2) -> void:
	var col: Color = Color(0.93, 0.94, 0.96)
	var cx: float = _mx(i, c.x)
	match zone:
		&"head":
			draw_circle(Vector2(cx, c.y - 0.5), 3.6, col, true, -1.0, true)
			draw_rect(Rect2(cx - 1.5, c.y + 2.5, 3, 2.5), col)
		&"body":
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 4.5, c.y - 4), Vector2(cx + 4.5, c.y - 4), Vector2(cx + 3, c.y + 4.5), Vector2(cx - 3, c.y + 4.5)]), col)
		&"legs":
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 3.5, c.y - 4.5), Vector2(cx - 0.5, c.y - 4.5), Vector2(cx - 1.2, c.y + 4.5), Vector2(cx - 3.8, c.y + 4.5)]), col)
			draw_colored_polygon(PackedVector2Array([Vector2(cx + 0.5, c.y - 4.5), Vector2(cx + 3.5, c.y - 4.5), Vector2(cx + 3.8, c.y + 4.5), Vector2(cx + 1.2, c.y + 4.5)]), col)


func _lightning(i: int, c: Vector2) -> void:
	_poly(i, [c + Vector2(1.5, -3.5), c + Vector2(-2.5, 0.8), c + Vector2(-0.2, 0.8), c + Vector2(-1.5, 3.8), c + Vector2(2.5, -0.8), c + Vector2(0.2, -0.8)], C_GOLD)


## Régua de domínio no topo: o marcador pende para quem causou mais dano (só informação, sem efeito em regra).
func _draw_momentum() -> void:
	var dealt: Array[float] = [0.0, 0.0]
	for i: int in 2:
		for z: StringName in ZONES:
			dealt[1 - i] += sim.fighters[i].zone_damage(z)
	var m: float = clampf((dealt[0] - dealt[1]) / 80.0, -1.0, 1.0)
	for k: int in range(-9, 10):
		var x: float = 320.0 + k * 6.0
		draw_line(Vector2(x, 14), Vector2(x, 20 if k % 3 == 0 else 18), Color(0.85, 0.87, 0.92, 0.55), 1.0, true)
	var mx: float = 320.0 - m * 54.0
	draw_rect(Rect2(mx - 4, 13, 8, 8), CORNER[0] if m > 0.05 else (CORNER[1] if m < -0.05 else Color(0.85, 0.87, 0.92)))


# ------------------------------------------------------------------ placar de transmissão (embaixo, centralizado)
func _draw_scoreboard() -> void:
	if training:
		return
	var left: int = maxi(0, sim.round_seconds - sim.round_seconds_elapsed())
	var top: float = 316.0
	var h: float = 18.0
	var cx0: float = 274.0  # bloco central: 274..366
	var cw: float = 92.0
	# Blocos laterais com os nomes e a cor do córner na borda externa.
	for i: int in 2:
		_rect(i, Rect2(166, top, cx0 - 166, h), Color(0.2, 0.21, 0.24, 0.94))
		_rect(i, Rect2(166, top, 3, h), CORNER[i])
		var nx: float = 172.0 if i == 0 else W - 172.0 - 100.0
		_txt(ThemeDB.fallback_font, Vector2(nx, top + 13), names[i].to_upper(), 10, Color.WHITE, 100, HORIZONTAL_ALIGNMENT_CENTER)
	# Bloco central: organização (fictícia) | cronômetro.
	draw_rect(Rect2(cx0, top - 2, cw, h + 2), Color(0.05, 0.05, 0.07, 0.97))
	draw_rect(Rect2(cx0, top - 2, cw, 1), Color(1, 1, 1, 0.15))
	_txt(_bold_italic, Vector2(cx0 + 3, top + 13), event_name.to_upper().left(6), 10, Color.WHITE, 46, HORIZONTAL_ALIGNMENT_CENTER)
	draw_rect(Rect2(cx0 + 50, top + 2, 1, h - 4), Color(1, 1, 1, 0.22))
	_txt(_bold, Vector2(cx0 + 52, top + 14), "%d:%02d" % [left / 60, left % 60], 15, Color.WHITE, 38, HORIZONTAL_ALIGNMENT_CENTER)
	# Barra dourada do tempo do round, logo abaixo.
	var frac: float = float(left) / float(maxi(1, sim.round_seconds))
	draw_rect(Rect2(cx0, top + h + 1, cw, 6), Color(0.15, 0.12, 0.04, 0.9))
	draw_rect(Rect2(cx0, top + h + 1, cw * frac, 6), C_GOLD)
	draw_rect(Rect2(cx0, top + h + 1, cw * frac, 2), C_GOLD.lightened(0.3))
	# Acima do placar, em pilha: cinturão (luta de título) · texto da disputa · round.
	var ribbon_top: float = top - (24.0 if title_fight else 13.0)
	draw_rect(Rect2(cx0 - 76, ribbon_top, cw + 152, top - ribbon_top - 2), Color(0.02, 0.02, 0.04, 0.82))
	draw_rect(Rect2(cx0 - 76, ribbon_top, cw + 152, 1), Color(C_GOLD, 0.6))
	_txt(_bold, Vector2(cx0 - 40, top - 5), "ROUND %d DE %d" % [sim.round, sim.total_rounds], 8, C_GOLD, cw + 80, HORIZONTAL_ALIGNMENT_CENTER)
	if title_fight:
		_txt(_bold, Vector2(200, top - 16), "DISPUTA DE CINTURÃO" + ((" · " + weight_name.to_upper()) if weight_name != "" else ""), 8, Color.WHITE, 240, HORIZONTAL_ALIGNMENT_CENTER)
		UiDraw.icon(self, "belt", Vector2(306, top - 48), 28)


# ------------------------------------------------------------------ grappling, intervalo, fim
## Overlay de opções da posição atual (COMBAT §4.2) e Medidor de Aperto.
func _draw_grappling() -> void:
	var g: CombatGrappling = sim.grappling
	if g.submission != null:
		var sub: CombatGrappling.Submission = g.submission
		UiDraw.panel(self, Rect2(210, 74, 220, 32))
		_txt(_bold, Vector2(218, 86), "FINALIZAÇÃO: %s" % sub.technique.id, 8, Color.WHITE)
		_bar(0, Rect2(218, 90, 204, 6), clampf(sub.meter, 0.0, 100.0) / 100.0, Color(0.9, 0.2, 0.18))
		var who: String = "VOCÊ APERTA (WASD muda o ajuste)" if sub.attacker == 0 else "ESCAPE: toque a direção do ajuste (WASD)"
		_text(Vector2(210, 118), "%s  — escapes %d/%d" % [who, sub.escapes, sub.technique.escapes_needed], Color.ORANGE)
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
		_text(Vector2(10, 110 + k * 11), lines[k], Color(0.8, 1.0, 0.8))


## Intervalo (COMBAT §5.1, §5.3): estatísticas do round, dicas do córner e foco tático.
func _draw_break() -> void:
	UiDraw.panel(self, Rect2(110, 86, 420, 200), true)
	_txt(_bold, Vector2(124, 106), "INTERVALO — FIM DO ROUND %d" % sim.round, 12, C_GOLD)
	var last: Array = sim.round_stat_history[-1]
	for k: int in 2:
		var st: Dictionary = last[k]
		draw_rect(Rect2(124, 116 + k * 14, 3, 10), CORNER[k])
		_text(Vector2(132, 125 + k * 14), "%s: dano %.0f · transições %d · controle %.0fs" % [names[k], float(st["damage"]), int(st["grapple"]), float(st["control_s"])], Color.WHITE)
	var cards: Array = sim.round_scores[-1]
	_text(Vector2(124, 160), "Juízes no round: %s" % ", ".join(cards.map(func(c: Array) -> String: return "%d-%d" % [c[0], c[1]])), Color(1, 1, 1, 0.8))
	var y: float = 180
	for tip: String in corner_tips():
		_text(Vector2(124, y), "Córner: " + tip, Color(0.7, 1, 0.7))
		y += 12
	var focus: String = "Manter o plano (normal)" if player_focus == CombatSim.Focus.NORMAL else "Recuperar o fôlego (+Fôlego, menos recuperação de dano)"
	_text(Vector2(124, 240), "Foco: 1 = normal · 2 = recuperar fôlego   →  %s" % focus, Color.ORANGE)
	_text(Vector2(124, 262), "Enter: próximo round", Color(1, 1, 1, 0.7))


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
	var method: String = {&"ko": "NOCAUTE", &"tko": "NOCAUTE TÉCNICO", &"submission": "FINALIZAÇÃO", &"decision": "DECISÃO DOS JUÍZES"}.get(sim.finish_method, "FIM")
	draw_rect(Rect2(0, 138, W, 50), Color(0, 0, 0, 0.78))
	draw_rect(Rect2(0, 138, W, 2), C_GOLD)
	draw_rect(Rect2(0, 186, W, 2), C_GOLD)
	_txt(_bold_italic, Vector2(0, 162), method, 18, C_GOLD, W, HORIZONTAL_ALIGNMENT_CENTER)
	var w: int = sim.winner()
	_txt(_bold, Vector2(0, 180), ("VENCEDOR: %s" % names[w].to_upper()) if w >= 0 else "EMPATE", 10, Color.WHITE, W, HORIZONTAL_ALIGNMENT_CENTER)

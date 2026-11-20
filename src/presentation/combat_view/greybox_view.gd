class_name GreyboxView
extends Node2D
## Desenho greybox da luta (E-03): jaula, sombras, lutadores em formas simples e overlay de depuração.
## Só lê o estado da simulação (COMBAT_ARCHITECTURE §10); nenhuma regra aqui.

const PPM: float = 70.0  # pixels por metro [PROV, depende de R-003]
const DEPTH_PPM: float = 20.0
const FLOOR_Y: float = 290.0
const CENTER_X: float = 320.0
const COLORS: Array[Color] = [Color(0.35, 0.6, 1.0), Color(1.0, 0.45, 0.35)]

var sim: CombatSim
var debug_overlay: bool = true


func _process(_delta: float) -> void:
	queue_redraw()


func to_screen(x: float, z: float) -> Vector2:
	return Vector2(roundf(CENTER_X + x * PPM), roundf(FLOOR_Y - z * DEPTH_PPM))


func _draw() -> void:
	if sim == null:
		return
	var bal: CombatBalanceDef = sim.balance
	# Lona (faixa de profundidade) e grades nas extremidades X.
	var tl: Vector2 = to_screen(-bal.cage_half_width_m, bal.depth_half_m)
	var br: Vector2 = to_screen(bal.cage_half_width_m, -bal.depth_half_m)
	draw_rect(Rect2(tl, br - tl), Color(0.22, 0.22, 0.25))
	for side: float in [-1.0, 1.0]:
		var top: Vector2 = to_screen(side * bal.cage_half_width_m, bal.depth_half_m)
		draw_line(top + Vector2(0, -150), to_screen(side * bal.cage_half_width_m, -bal.depth_half_m), Color(0.6, 0.6, 0.6), 2.0)
	if sim.grappling.position != &"EP":
		_draw_grapple_pair()
		return
	# Desenha primeiro quem está mais ao fundo (maior z).
	var order: Array[int] = [0, 1]
	if sim.fighters[1].z > sim.fighters[0].z:
		order = [1, 0]
	for i: int in order:
		_draw_fighter(i)


func _draw_fighter(i: int) -> void:
	var f: FighterCombatState = sim.fighters[i]
	var base: Vector2 = to_screen(f.x, f.z)
	var color: Color = COLORS[i]
	draw_set_transform(base)
	draw_circle(Vector2.ZERO, 3.0, Color(0, 0, 0, 0.0))
	_draw_ellipse(Vector2.ZERO, 18.0, 5.0, Color(0, 0, 0, 0.45))  # sombra de contato
	var height: float = 120.0
	var crouch: float = 0.0
	match f.action:
		FighterCombatState.Action.DOWN, FighterCombatState.Action.OUT:
			draw_rect(Rect2(-55, -16, 110, 16), color.darkened(0.3))
			draw_set_transform(Vector2.ZERO)
			_label(base + Vector2(-30, -40), "KO" if f.action == FighterCombatState.Action.OUT else "CAÍDO", Color.RED)
			return
		FighterCombatState.Action.EVADING:
			if f.evade == FighterCombatState.Evade.DUCK:
				crouch = 25.0
	var lean: float = 0.0
	if f.evade == FighterCombatState.Evade.PULL:
		lean = -8.0 * f.facing
	elif f.evade == FighterCombatState.Evade.SLIP:
		lean = 4.0 * f.facing
	draw_rect(Rect2(-12, -height + 24 + crouch, 24, height - 24 - crouch), color)
	var head: Vector2 = Vector2(lean, -height + 12 + crouch)
	draw_circle(head, 12.0, color.lightened(0.2))
	if f.guard_high:
		draw_rect(Rect2(head.x + f.facing * 8 - 3, head.y - 12, 6, 24), Color.WHITE)
	if f.guard_low:
		draw_rect(Rect2(f.facing * 12 - 3, -height + 40, 6, 30), Color.WHITE)
	if f.is_striking() and f.strike != null:
		var y: float = {&"head": -height + 12, &"body": -height * 0.55, &"legs": -height * 0.2}[f.strike_zone]
		var reach_px: float = f.strike.base_reach_m * f.snapshot.reach_cm / sim.balance.reference_reach_cm * PPM
		var progress: float = 0.35 if f.action == FighterCombatState.Action.STRIKE_STARTUP else (1.0 if f.action == FighterCombatState.Action.STRIKE_ACTIVE else 0.5)
		var col: Color = Color.YELLOW if f.action == FighterCombatState.Action.STRIKE_ACTIVE else Color(1, 1, 1, 0.5)
		draw_line(Vector2(0, y), Vector2(f.facing * reach_px * progress, y), col, 4.0)
	draw_set_transform(Vector2.ZERO)
	var state_text: String = {
		FighterCombatState.Action.ROCKED: "ABALADO", FighterCombatState.Action.STUNNED: "ATORDOADO",
	}.get(f.action, "")
	if state_text != "":
		_label(base + Vector2(-34, -height - 22), state_text, Color.ORANGE)
	if debug_overlay:
		_draw_debug(f, base)


func _draw_debug(f: FighterCombatState, base: Vector2) -> void:
	# Faixa de alcance do jab e da perna (tolerância de profundidade não aparece em escala na vista lateral).
	for id: StringName in [&"jab", &"low_kick"]:
		var s: StrikeDef = sim.defs.strike(id)
		if s == null:
			continue
		var reach: float = s.base_reach_m * f.snapshot.reach_cm / sim.balance.reference_reach_cm * PPM
		draw_line(base + Vector2(0, 6), base + Vector2(f.facing * reach, 6), Color(1, 1, 0, 0.35) if id == &"jab" else Color(0, 1, 1, 0.35), 2.0)
	_label(base + Vector2(-20, 10), "z %.2f" % f.z, Color(1, 1, 1, 0.6))
	if f.angle_frames > 0:
		_label(base + Vector2(-20, 20), "ÂNGULO", Color.GREEN)


const POSITION_NAMES: Dictionary = {
	&"CL": "CLINCH", &"CG": "CLINCH NA GRADE", &"SG": "GUARDA", &"SL": "CONTROLE LATERAL",
	&"SO": "MONTADA", &"SC": "COSTAS", &"SR": "LEVANTANDO",
}


## Posições de clinch e solo em formas simples: quem está por cima é desenhado por último e mais alto.
func _draw_grapple_pair() -> void:
	var g: CombatGrappling = sim.grappling
	var a: FighterCombatState = sim.fighters[0]
	var b: FighterCombatState = sim.fighters[1]
	var mid: Vector2 = (to_screen(a.x, a.z) + to_screen(b.x, b.z)) / 2.0
	_draw_ellipse(mid, 40.0, 6.0, Color(0, 0, 0, 0.45))
	var top_i: int = g.top if g.top >= 0 else 0
	var bottom_i: int = 1 - top_i
	var ct: Color = COLORS[top_i]
	var cb: Color = COLORS[bottom_i]
	match g.position:
		&"CL", &"CG":
			for i: int in 2:
				var p: Vector2 = to_screen(sim.fighters[i].x, sim.fighters[i].z)
				draw_rect(Rect2(p.x - 12, p.y - 96, 24, 96), COLORS[i])
				draw_circle(Vector2(p.x + sim.fighters[i].facing * 6, p.y - 104), 12.0, COLORS[i].lightened(0.2))
			if g.clinch_owner >= 0:
				var o: Vector2 = to_screen(sim.fighters[g.clinch_owner].x, 0)
				_label(Vector2(o.x - 16, mid.y - 132), "PEGADA", Color.GREEN)
		&"SR":
			draw_rect(Rect2(mid.x - 30, mid.y - 50, 26, 50), cb)
			draw_rect(Rect2(mid.x - 4, mid.y - 70, 24, 70), ct)
		_:
			draw_rect(Rect2(mid.x - 55, mid.y - 16, 110, 16), cb)  # quem está por baixo, deitado
			draw_circle(Vector2(mid.x - 58 * sim.fighters[bottom_i].facing, mid.y - 8), 10.0, cb.lightened(0.2))
			var h: float = {&"SG": 40.0, &"SL": 30.0, &"SO": 50.0, &"SC": 36.0}.get(g.position, 36.0)
			draw_rect(Rect2(mid.x - 14, mid.y - 16 - h, 28, h), ct)
			draw_circle(Vector2(mid.x, mid.y - 26 - h), 11.0, ct.lightened(0.2))
	_label(Vector2(mid.x - 40, mid.y - 150), POSITION_NAMES.get(g.position, ""), Color.WHITE)
	if g.top >= 0:
		_label(Vector2(mid.x - 40, mid.y - 138), "por cima: %s" % ("JOGADOR" if g.top == 0 else "BONECO"), COLORS[g.top])


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts: PackedVector2Array = []
	for k: int in 16:
		var a: float = TAU * k / 16.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func _label(pos: Vector2, text: String, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)

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
var _fighter_nodes: Array[FighterSpriteNode] = []
var _configured_for: CombatSim
var debug_overlay: bool = false
var show_blood: bool = true
## E-06: F4 alterna entre formas greybox e os sprites do pipeline 3D → pixel (só em pé; solo segue greybox).
var use_sprites: bool = true
var sprites: SpriteSet = SpriteSet.load_biotype("res://assets/sprites/fighters/m_medium", "m_medium")


func _process(_delta: float) -> void:
	queue_redraw()


func to_screen(x: float, z: float) -> Vector2:
	return Vector2(roundf(CENTER_X + x * PPM), roundf(FLOOR_Y - z * DEPTH_PPM))


func _draw() -> void:
	if sim == null:
		return
	_draw_arena(sim.balance)
	_ensure_fighter_nodes()
	if sim.grappling.position != &"EP":
		for n: FighterSpriteNode in _fighter_nodes:
			n.visible = false
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
	if not use_sprites and i < _fighter_nodes.size():
		_fighter_nodes[i].visible = false
	if use_sprites and sprites != null:
		_draw_sprite(i, f, base)
		return
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
	&"CL": "CLINCH", &"CG": "CLINCH NA GRADE", &"SG": "GUARDA", &"SM": "MEIA-GUARDA", &"SL": "CONTROLE LATERAL",
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
			var h: float = {&"SG": 40.0, &"SM": 36.0, &"SL": 30.0, &"SO": 50.0, &"SC": 36.0}.get(g.position, 36.0)
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


## Cria (uma vez por luta) um nó por lutador com o material de cores da aparência dele.
func _ensure_fighter_nodes() -> void:
	if sprites == null or _configured_for == sim:
		return
	for n: FighterSpriteNode in _fighter_nodes:
		n.queue_free()
	_fighter_nodes.clear()
	for k: int in 2:
		var node: FighterSpriteNode = FighterSpriteNode.new()
		node.configure(sprites, sim.fighters[k].snapshot.appearance)
		add_child(node)
		_fighter_nodes.append(node)
	_configured_for = sim


func _draw_sprite(i: int, f: FighterCombatState, base: Vector2) -> void:
	_draw_ellipse(base, 18.0, 5.0, Color(0, 0, 0, 0.45))
	if _fighter_nodes.size() == 2:
		var g0: CombatGrappling = sim.grappling
		var tech: GrappleTechniqueDef = g0.pending.technique if (g0.pending != null and g0.pending.attacker == i) else null
		var node: FighterSpriteNode = _fighter_nodes[i]
		node.visible = true
		node.z_index = 10 - roundi(f.z * 4.0)
		node.show_blood = show_blood
		node.present(base, sprites.pick(f, sim.frame, tech), float(f.facing), PPM / sprites.px_per_m, f.cut)
		if debug_overlay:
			_draw_debug(f, base)
		return
	var g: CombatGrappling = sim.grappling
	var technique: GrappleTechniqueDef = g.pending.technique if (g.pending != null and g.pending.attacker == i) else null
	var pick: Array = sprites.pick(f, sim.frame, technique)
	var tex: Texture2D = sprites.textures[pick[0]]
	var size: Vector2 = Vector2(sprites.frame_size)
	var src: Rect2 = Rect2(Vector2(size.x * int(pick[1]), 0), size)
	# A âncora (pés) cai no ponto do chão; espelha quando o lutador olha para a esquerda.
	var scale_px: float = PPM / sprites.px_per_m
	var flip: float = float(f.facing)
	draw_set_transform(base, 0.0, Vector2(flip * scale_px, scale_px))
	var tint: Color = Color.WHITE if i == 0 else Color(1.0, 0.8, 0.75)
	draw_texture_rect_region(tex, Rect2(-sprites.anchor, size), src, tint)
	draw_set_transform(Vector2.ZERO)
	if f.cut > 0 and show_blood:
		var head: Vector2 = base + Vector2(f.facing * 6, -sprites.anchor.y * scale_px + 22 * scale_px)
		for k: int in f.cut * 2:
			draw_rect(Rect2(roundf(head.x + k % 3 - 1), roundf(head.y + k * 2), 1, 2), Color(0.6, 0.02, 0.03))
	if debug_overlay:
		_draw_debug(f, base)


const CROWD_SEED: int = 1337


## Arena (ART §7): fundo escuro, público em silhueta em camadas, holofotes, lona com logo e grade com tela.
## Tudo desenhado em pixels inteiros na SubViewport 640x360 (pixel art fiel).
func _draw_arena(bal: CombatBalanceDef) -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.035, 0.035, 0.05))
	var floor_top: float = FLOOR_Y - bal.depth_half_m * DEPTH_PPM
	var floor_bottom: float = FLOOR_Y + bal.depth_half_m * DEPTH_PPM
	# Público: 4 fileiras de cabeças/ombros com leve balanço (reage em momentos fortes no futuro).
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = CROWD_SEED
	var bob: float = sin(Time.get_ticks_msec() / 400.0)
	for row: int in 4:
		var y: float = 150.0 + row * 22.0
		var shade: float = 0.06 + row * 0.025
		var x: float = -10.0 + row * 7.0
		while x < 650.0:
			var w: float = rng.randf_range(9.0, 14.0)
			var hy: float = y - rng.randf_range(0.0, 5.0) + (bob if rng.randf() < 0.3 else 0.0)
			var col: Color = Color(shade, shade, shade + 0.02)
			draw_rect(Rect2(roundf(x), roundf(hy + 7), roundf(w), 30), col)
			draw_circle(Vector2(roundf(x + w / 2), roundf(hy + 3)), roundf(w * 0.32), col)
			if rng.randf() < 0.04:
				draw_rect(Rect2(roundf(x + w / 2), roundf(hy - 2), 2, 2), Color(0.9, 0.9, 1.0, 0.8))  # celular
			x += w + rng.randf_range(1.0, 4.0)
	# Holofotes.
	for k: int in 3:
		var cx: float = 160.0 + k * 160.0
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 6, 0), Vector2(cx + 6, 0), Vector2(cx + 70, floor_bottom), Vector2(cx - 70, floor_bottom)]),
			Color(1.0, 0.95, 0.8, 0.035))
	# Grade do fundo (tela em losangos) acima da lona.
	var left: float = CENTER_X - bal.cage_half_width_m * PPM
	var right: float = CENTER_X + bal.cage_half_width_m * PPM
	var fence_top: float = floor_top - 78.0
	draw_rect(Rect2(left, fence_top, right - left, floor_top - fence_top), Color(0.02, 0.02, 0.03, 0.55))
	var step: float = 8.0
	var xx: float = left
	while xx < right:
		draw_line(Vector2(roundf(xx), fence_top), Vector2(roundf(xx + 39), floor_top), Color(0.35, 0.37, 0.42, 0.35))
		draw_line(Vector2(roundf(xx + 39), fence_top), Vector2(roundf(xx), floor_top), Color(0.35, 0.37, 0.42, 0.35))
		xx += step * 2.0
	draw_rect(Rect2(left, fence_top - 3, right - left, 3), Color(0.12, 0.12, 0.15))
	# Lona com borda, logo central e sombra de vinheta.
	draw_rect(Rect2(left, floor_top, right - left, floor_bottom - floor_top), Color(0.82, 0.82, 0.8))
	draw_rect(Rect2(left, floor_top, right - left, 3), Color(0.6, 0.6, 0.6))
	draw_rect(Rect2(left, floor_bottom - 4, right - left, 4), Color(0.12, 0.12, 0.14))
	var logo: PackedVector2Array = []
	for k2: int in 8:
		var a: float = TAU * k2 / 8.0 + TAU / 16.0
		logo.append(Vector2(roundf(CENTER_X + cos(a) * 46), roundf((floor_top + floor_bottom) / 2 + sin(a) * 18)))
	draw_colored_polygon(logo, Color(0.72, 0.12, 0.14, 0.35))
	draw_string(ThemeDB.fallback_font, Vector2(CENTER_X - 22, (floor_top + floor_bottom) / 2 + 4), "JAULA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.35))
	# Postes da grade nas extremidades X (interativos, COMBAT §2.5).
	for side: float in [-1.0, 1.0]:
		var px: float = CENTER_X + side * bal.cage_half_width_m * PPM
		draw_rect(Rect2(px - 3, fence_top - 10, 6, floor_bottom - fence_top + 10), Color(0.18, 0.18, 0.21))
		draw_rect(Rect2(px - 2, fence_top - 10, 2, floor_bottom - fence_top + 10), Color(0.4, 0.4, 0.45))
		draw_rect(Rect2(px - 5, fence_top - 14, 10, 6), Color(0.05, 0.05, 0.06))

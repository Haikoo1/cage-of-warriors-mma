class_name UiDraw
extends RefCounted
## Estilo visual das telas (UI em HD, D-018): fundo em degradê, painéis arredondados, cartões de menu.
## Coordenadas lógicas 640x360; o texto é rasterizado na resolução real da janela (modo canvas_items).

const TITLE: int = 18
const TEXT: int = 10
const SMALL: int = 9
const C_TEXT: Color = Color(0.93, 0.94, 0.96)
const C_DIM: Color = Color(0.62, 0.65, 0.72)
const C_SEL: Color = Color(1.0, 0.78, 0.25)
const C_GOOD: Color = Color(0.45, 0.92, 0.6)
const C_BAD: Color = Color(1.0, 0.45, 0.42)
const C_ACCENT: Color = Color(0.86, 0.16, 0.2)
const C_BG_TOP: Color = Color(0.07, 0.08, 0.12)
const C_BG_BOTTOM: Color = Color(0.02, 0.02, 0.04)


static func text(ci: CanvasItem, pos: Vector2, s: String, color: Color = C_TEXT, size: int = TEXT, width: float = -1) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, width, size, color)


static func text_center(ci: CanvasItem, y: float, s: String, color: Color = C_TEXT, size: int = TEXT) -> void:
	ci.draw_string(ThemeDB.fallback_font, Vector2(0, y), s, HORIZONTAL_ALIGNMENT_CENTER, 640, size, color)


## Fundo padrão de todas as telas: degradê escuro, holofote suave e faixa de título com acento vermelho.
static func background(ci: CanvasItem, title: String = "", subtitle: String = "") -> void:
	var colors: PackedColorArray = [C_BG_TOP, C_BG_TOP, C_BG_BOTTOM, C_BG_BOTTOM]
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(640, 0), Vector2(640, 360), Vector2(0, 360)]), colors)
	for k: int in 6:
		ci.draw_circle(Vector2(470, 40), 260.0 - k * 38.0, Color(0.9, 0.9, 1.0, 0.012))
	if title != "":
		ci.draw_rect(Rect2(0, 0, 640, 40), Color(0, 0, 0, 0.35))
		ci.draw_rect(Rect2(0, 40, 640, 1.5), C_ACCENT)
		text(ci, Vector2(22, 27), title, C_TEXT, 16)
		if subtitle != "":
			ci.draw_string(ThemeDB.fallback_font, Vector2(0, 26), subtitle, HORIZONTAL_ALIGNMENT_RIGHT, 618, SMALL, C_DIM)


static func panel(ci: CanvasItem, rect: Rect2, highlight: bool = false) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.13, 0.18, 0.88) if not highlight else Color(0.2, 0.17, 0.12, 0.95)
	sb.set_corner_radius_all(5)
	sb.border_color = C_SEL if highlight else Color(1, 1, 1, 0.08)
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 3
	ci.draw_style_box(sb, rect)


## Cartão de menu com marcador de seleção.
static func menu_item(ci: CanvasItem, rect: Rect2, label: String, selected: bool, size: int = 11) -> void:
	panel(ci, rect, selected)
	if selected:
		ci.draw_rect(Rect2(rect.position.x, rect.position.y + 3, 2.5, rect.size.y - 6), C_SEL)
	text(ci, rect.position + Vector2(12, rect.size.y * 0.5 + size * 0.36), label, C_SEL if selected else C_TEXT, size, rect.size.x - 20)


static func bar(ci: CanvasItem, rect: Rect2, value: float, color: Color) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.17, 0.21)
	sb.set_corner_radius_all(2)
	ci.draw_style_box(sb, rect)
	if value > 0.0:
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = color
		fill.set_corner_radius_all(2)
		ci.draw_style_box(fill, Rect2(rect.position, Vector2(maxf(3.0, rect.size.x * clampf(value, 0.0, 1.0)), rect.size.y)))


static func footer(ci: CanvasItem, s: String) -> void:
	ci.draw_rect(Rect2(0, 344, 640, 16), Color(0, 0, 0, 0.45))
	text(ci, Vector2(12, 355), s, C_DIM, 8, 616)


## Ícone em pixel art (assets/ui/icons, gerados por tools/gen_icons.js). Filtro nearest: nítido em HD.
static func icon(ci: CanvasItem, name: String, pos: Vector2, size: float = 12.0, tint: Color = Color.WHITE) -> void:
	var tex: Texture2D = _icon_tex(name)
	if tex != null:
		ci.draw_texture_rect(tex, Rect2(pos, Vector2(size, size)), false, tint)


## Ícone + texto alinhados (estilo RPG).
static func icon_text(ci: CanvasItem, name: String, pos: Vector2, s: String, color: Color = C_TEXT, size: int = TEXT) -> void:
	icon(ci, name, pos + Vector2(0, -size - 1), size + 3)
	text(ci, pos + Vector2(size + 6, 0), s, color, size)


## Selo de nível (overall) em círculo dourado.
static func level_badge(ci: CanvasItem, center: Vector2, level: int, radius: float = 14.0) -> void:
	ci.draw_circle(center, radius + 2, Color(0.25, 0.16, 0.04))
	ci.draw_circle(center, radius, Color(0.86, 0.64, 0.18))
	ci.draw_circle(center, radius - 3, Color(0.98, 0.82, 0.36))
	ci.draw_string(ThemeDB.fallback_font, center + Vector2(-radius, -radius * 0.32), "NV", HORIZONTAL_ALIGNMENT_CENTER, radius * 2, 6, Color(0.3, 0.18, 0.02))
	ci.draw_string(ThemeDB.fallback_font, center + Vector2(-radius, radius * 0.55), str(level), HORIZONTAL_ALIGNMENT_CENTER, radius * 2, 12, Color(0.2, 0.1, 0.0))


## Fileira de cinturões conquistados.
static func belts(ci: CanvasItem, pos: Vector2, count: int, size: float = 14.0, max_shown: int = 6) -> void:
	for k: int in mini(count, max_shown):
		icon(ci, "belt", pos + Vector2(k * (size + 2), 0), size)
	if count > max_shown:
		text(ci, pos + Vector2(max_shown * (size + 2) + 2, size * 0.8), "+%d" % (count - max_shown), C_SEL, SMALL)


static var _icons: Dictionary = {}


static func _icon_tex(name: String) -> Texture2D:
	if not _icons.has(name):
		_icons[name] = load("res://assets/ui/icons/%s.png" % name) as Texture2D
	return _icons[name]


static func money(v: float) -> String:
	var sign: String = "-" if v < 0 else ""
	var digits: String = String.num_int64(absi(roundi(v)))
	var out: String = ""
	for i: int in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += "."
		out += digits[i]
	return "%s$ %s" % [sign, out]

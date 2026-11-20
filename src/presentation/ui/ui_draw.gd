class_name UiDraw
extends RefCounted
## Utilitários de desenho das telas provisórias (UI final é a E-10). Fonte padrão em tamanho pequeno.

const TITLE: int = 18
const TEXT: int = 10
const SMALL: int = 9
const C_TEXT: Color = Color(1, 1, 1, 0.9)
const C_DIM: Color = Color(1, 1, 1, 0.55)
const C_SEL: Color = Color(1.0, 0.85, 0.3)
const C_GOOD: Color = Color(0.55, 1.0, 0.6)
const C_BAD: Color = Color(1.0, 0.5, 0.45)


static func text(ci: CanvasItem, pos: Vector2, s: String, color: Color = C_TEXT, size: int = TEXT, width: float = -1) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, width, size, color)


static func bar(ci: CanvasItem, rect: Rect2, value: float, color: Color) -> void:
	ci.draw_rect(rect, Color(0.15, 0.15, 0.17))
	ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(value, 0.0, 1.0), rect.size.y)), color)


static func panel(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_rect(rect, Color(0.08, 0.08, 0.1, 0.92))
	ci.draw_rect(rect, Color(1, 1, 1, 0.12), false, 1.0)


static func money(v: float) -> String:
	var sign: String = "-" if v < 0 else ""
	return "%s$ %s" % [sign, String.num_int64(absi(roundi(v)))]

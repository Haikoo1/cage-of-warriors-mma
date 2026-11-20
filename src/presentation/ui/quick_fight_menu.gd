extends Control
## Menu da Luta Rápida: W/S escolhe a linha, A/D muda o valor, Enter começa, Esc volta.

const ROWS: Array[String] = ["Seu estilo", "Estilo do adversário", "Nível da IA", "Rounds", "Duração do round", "Modo"]

var values: Array[int] = [0, 1, 1, 0, 0, 0]
var row: int = 0


func _options(i: int) -> Array:
	match i:
		0, 1:
			return QuickFight.STYLES
		2:
			return QuickFight.PROFILE_NAMES
		3:
			return ["3 rounds", "5 rounds (título)"]
		4:
			return QuickFight.ROUND_LENGTHS.map(func(s: int) -> String: return "%d min" % (s / 60))
	return ["Você x IA", "IA x IA (assistir)"]


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(40, 50), "LUTA RÁPIDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	for i: int in ROWS.size():
		var y: float = 90 + i * 26
		var col: Color = Color.YELLOW if i == row else Color(1, 1, 1, 0.75)
		draw_string(font, Vector2(40, y), ROWS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		draw_string(font, Vector2(260, y), "< %s >" % _options(i)[values[i]], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
	draw_string(font, Vector2(40, 270), "W/S escolher  ·  A/D mudar  ·  Enter lutar  ·  Esc voltar", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.6))
	draw_string(font, Vector2(40, 290), "Lutadores de exemplo do peso-leve com atributos provisórios. Regras: 3x5 min oficial; duração ajustável aqui.", HORIZONTAL_ALIGNMENT_LEFT, 560, 9, Color(1, 1, 1, 0.5))


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_W, KEY_UP:
			row = (row + ROWS.size() - 1) % ROWS.size()
		KEY_S, KEY_DOWN:
			row = (row + 1) % ROWS.size()
		KEY_A, KEY_LEFT:
			values[row] = (values[row] + _options(row).size() - 1) % _options(row).size()
		KEY_D, KEY_RIGHT:
			values[row] = (values[row] + 1) % _options(row).size()
		KEY_ENTER, KEY_KP_ENTER:
			var cfg: QuickFight.Config = QuickFight.build(DataRegistry.definitions, values[0], values[1], values[2],
				values[3] == 1, values[4], values[5] == 1, Time.get_ticks_usec())
			SceneRouter.go_to(&"combat_test", {"quick_fight": cfg})
		KEY_ESCAPE:
			SceneRouter.go_to(&"boot")

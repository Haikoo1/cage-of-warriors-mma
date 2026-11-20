extends Control
## Menu da Luta Rápida: W/S escolhe a linha, A/D muda o valor, Enter começa, Esc volta.

const ROWS: Array[String] = ["Seu estilo", "Estilo do adversário", "Nível da IA", "Rounds", "Duração do round", "Modo", "Seu visual"]

var values: Array[int] = [0, 1, 1, 0, 0, 0, 0]
var random_look: Appearance = Appearance.new()
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
		5:
			return ["Você x IA", "IA x IA (assistir)"]
	var looks: Array = ["Padrão", "Aleatório (R sorteia de novo)"]
	if GameSession.career != null:
		looks.append("Do lutador da carreira")
	return looks


func _look() -> Appearance:
	match values[6]:
		1: return random_look
		2: return GameSession.career.state.player().appearance if GameSession.career != null else null
	return null


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	UiDraw.background(self, "LUTA RÁPIDA", "lutadores de exemplo · peso-leve")
	for i: int in ROWS.size():
		var rect: Rect2 = Rect2(40, 62 + i * 30, 560, 24)
		UiDraw.panel(self, rect, i == row)
		UiDraw.text(self, rect.position + Vector2(14, 16), ROWS[i], UiDraw.C_SEL if i == row else UiDraw.C_DIM, 10)
		UiDraw.text(self, rect.position + Vector2(220, 16), "‹  %s  ›" % _options(i)[values[i]], UiDraw.C_TEXT, 11)
	UiDraw.text(self, Vector2(40, 260), "Regras oficiais: 3 x 5 min. A duração aqui é ajustável para lutas rápidas.", UiDraw.C_DIM, UiDraw.SMALL)
	UiDraw.footer(self, "W/S escolher · A/D mudar · R visual aleatório · Enter lutar · Esc voltar")


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
		KEY_R:
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.randomize()
			random_look = Appearance.random(rng, true)
			values[6] = 1
		KEY_ENTER, KEY_KP_ENTER:
			var cfg: QuickFight.Config = QuickFight.build(DataRegistry.definitions, values[0], values[1], values[2],
				values[3] == 1, values[4], values[5] == 1, Time.get_ticks_usec(), _look())
			SceneRouter.go_to(&"combat_test", {"quick_fight": cfg})
		KEY_ESCAPE:
			SceneRouter.go_to(&"boot")

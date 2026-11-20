extends Control
## Opções (GAME_SYSTEMS §7): HUD, direção, volumes e remapeamento de teclas (D-016).
## W/S linha · A/D valor · Enter numa ação = trocar tecla (aperte a nova) · Backspace = padrões · Esc salva e volta.

const HUD_LEVELS: Array[StringName] = [&"full", &"minimal", &"immersive"]
const HUD_NAMES: Array[String] = ["Completo", "Mínimo", "Imersivo"]
const ACTION_NAMES: Dictionary = {
	&"move_forward": "Avançar / direita", &"move_back": "Recuar / esquerda", &"move_up": "Passo lateral (fundo)",
	&"move_down": "Passo lateral (frente)", &"lead_hand": "Mão da frente", &"rear_hand": "Mão de trás",
	&"lead_leg": "Perna da frente", &"rear_leg": "Perna de trás", &"mod_curved": "Modificador curvo",
	&"mod_body": "Modificador corpo", &"guard": "Guarda", &"technique": "Técnica (esquivas)", &"grapple": "Agarrar",
	&"pause": "Pausa",
}
const FIXED_ROWS: int = 5

var row: int = 0
var waiting_key: bool = false
var actions: Array[StringName] = []
var store: SettingsStore


func _ready() -> void:
	store = Settings.store
	for a: StringName in InputBindings.DEFAULT_KEYS:
		actions.append(a)


func _rows() -> int:
	return FIXED_ROWS + actions.size()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.06, 0.06, 0.08))
	UiDraw.text(self, Vector2(30, 30), "OPÇÕES", UiDraw.C_SEL, UiDraw.TITLE)
	var fixed: Array[String] = [
		"Nível de HUD: %s" % HUD_NAMES[HUD_LEVELS.find(store.hud_level)],
		"Frente/trás: %s" % ("relativo ao adversário" if store.directions_relative_to_opponent else "relativo à tela"),
		"Volume geral: %d%%" % roundi(store.master_volume * 100),
		"Volume da música: %d%%" % roundi(store.music_volume * 100),
		"Volume dos efeitos: %d%%" % roundi(store.sfx_volume * 100),
	]
	var start: int = maxi(0, row - 16)
	for i: int in range(start, mini(_rows(), start + 22)):
		var y: float = 54 + (i - start) * 13
		var col: Color = UiDraw.C_SEL if i == row else UiDraw.C_TEXT
		var label: String
		if i < FIXED_ROWS:
			label = fixed[i]
		else:
			var action: StringName = actions[i - FIXED_ROWS]
			var key_name: String = "aperte uma tecla..." if (waiting_key and i == row) else OS.get_keycode_string(InputBindings.key_for(action))
			label = "Tecla — %s: %s" % [ACTION_NAMES.get(action, action), key_name]
		UiDraw.text(self, Vector2(30, y), ("> " if i == row else "  ") + label, col, UiDraw.TEXT)
	UiDraw.text(self, Vector2(30, 348), "W/S linha · A/D mudar · Enter trocar tecla · Backspace teclas padrão · Esc salvar e voltar", UiDraw.C_DIM, UiDraw.SMALL)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = (event as InputEventKey).physical_keycode
	if waiting_key:
		if key != KEY_ESCAPE:
			var action: StringName = actions[row - FIXED_ROWS]
			store.key_overrides[action] = int(key)
			InputBindings.apply_overrides({action: key})
		waiting_key = false
		return
	match key:
		KEY_W, KEY_UP:
			row = (row + _rows() - 1) % _rows()
		KEY_S, KEY_DOWN:
			row = (row + 1) % _rows()
		KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT:
			_change(1 if key in [KEY_D, KEY_RIGHT] else -1)
		KEY_ENTER, KEY_KP_ENTER:
			if row >= FIXED_ROWS:
				waiting_key = true
		KEY_BACKSPACE:
			store.key_overrides.clear()
			InputBindings.reset_to_defaults()
		KEY_ESCAPE:
			Settings.save()
			SceneRouter.go_to(&"boot")


func _change(step: int) -> void:
	match row:
		0:
			store.hud_level = HUD_LEVELS[(HUD_LEVELS.find(store.hud_level) + step + 3) % 3]
		1:
			store.directions_relative_to_opponent = not store.directions_relative_to_opponent
		2:
			store.master_volume = clampf(store.master_volume + step * 0.1, 0.0, 1.0)
		3:
			store.music_volume = clampf(store.music_volume + step * 0.1, 0.0, 1.0)
		4:
			store.sfx_volume = clampf(store.sfx_volume + step * 0.1, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, store.master_volume)))

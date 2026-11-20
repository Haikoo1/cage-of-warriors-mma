extends Control
## Menu principal (GAME_SYSTEMS §8): carreira, Luta Rápida, treino. W/S escolhe, Enter confirma.

const SLOTS: int = 3

var options: Array[String] = []
var actions: Array[Callable] = []
var row: int = 0
var summaries: Array[String] = []


func _ready() -> void:
	var defs: Definitions = DataRegistry.definitions
	summaries.clear()
	for s: int in range(1, SLOTS + 1):
		summaries.append(CareerController.slot_summary(defs, s))
	options.clear()
	actions.clear()
	_add("Nova carreira", func() -> void: SceneRouter.go_to(&"career_create"))
	for s: int in range(1, SLOTS + 1):
		if summaries[s - 1] != "":
			var slot: int = s
			_add("Continuar — slot %d: %s" % [s, summaries[s - 1]], func() -> void: _continue(slot))
	_add("Luta Rápida", func() -> void: SceneRouter.go_to(&"quick_fight"))
	_add("Tutorial interativo", func() -> void: SceneRouter.go_to(&"combat_test", {"tutorial": true}))
	_add("Treino livre (boneco)", func() -> void: SceneRouter.go_to(&"combat_test"))
	_add("Como jogar", func() -> void: SceneRouter.go_to(&"how_to_play"))
	_add("Opções (teclas, HUD, volume)", func() -> void: SceneRouter.go_to(&"settings"))
	_add("Sair", func() -> void: get_tree().quit())
	%Info.text = ""


func _add(label: String, action: Callable) -> void:
	options.append(label)
	actions.append(action)


func _continue(slot: int) -> void:
	var cc: CareerController = CareerController.load_slot(DataRegistry.definitions, slot)
	if cc != null:
		GameSession.career = cc
		SceneRouter.go_to(&"career_dashboard")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	UiDraw.background(self)
	UiDraw.text(self, Vector2(30, 62), "PROJETO", UiDraw.C_DIM, 14)
	UiDraw.text(self, Vector2(28, 98), "JAULA", UiDraw.C_TEXT, 40)
	draw_rect(Rect2(30, 106, 120, 2), UiDraw.C_ACCENT)
	UiDraw.text(self, Vector2(30, 122), "MMA 2.5D · modo carreira", UiDraw.C_DIM, UiDraw.TEXT)
	for i: int in options.size():
		UiDraw.menu_item(self, Rect2(30, 136 + i * 24, 300, 20), options[i], i == row, 10)
	UiDraw.panel(self, Rect2(370, 136, 240, 150))
	UiDraw.text(self, Vector2(384, 156), "Status do protótipo", UiDraw.C_SEL, 11)
	var defs: Definitions = DataRegistry.definitions
	var status: String = "dados OK" if DataRegistry.errors.is_empty() else "%d erro(s) nos dados" % DataRegistry.errors.size()
	var lines: Array[String] = [
		"Versão %s" % ProjectSettings.get_setting("application/config/version"),
		"%d categorias · %d organizações" % [defs.weight_classes.size(), defs.organizations.size()],
		"%d golpes · %d técnicas de grappling" % [defs.strikes.size(), defs.grapple_techniques.size()],
		status,
		"",
		"Novo por aqui? Abra \"Como jogar\".",
	]
	for k: int in lines.size():
		UiDraw.text(self, Vector2(384, 176 + k * 16), lines[k], UiDraw.C_TEXT if k < 4 else UiDraw.C_DIM, UiDraw.TEXT)
	UiDraw.footer(self, "W/S escolher · Enter confirmar")


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_W, KEY_UP:
			row = (row + options.size() - 1) % options.size()
		KEY_S, KEY_DOWN:
			row = (row + 1) % options.size()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			actions[row].call()

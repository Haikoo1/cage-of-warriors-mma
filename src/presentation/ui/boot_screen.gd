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
	_add("Treino livre (boneco)", func() -> void: SceneRouter.go_to(&"combat_test"))
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
	UiDraw.text(self, Vector2(40, 60), "PROJETO JAULA", UiDraw.C_SEL, 26)
	UiDraw.text(self, Vector2(42, 80), "MMA 2.5D · protótipo jogável (arte provisória)", UiDraw.C_DIM, UiDraw.SMALL)
	for i: int in options.size():
		var col: Color = UiDraw.C_SEL if i == row else UiDraw.C_TEXT
		UiDraw.text(self, Vector2(40, 120 + i * 22), ("> " if i == row else "  ") + options[i], col, 12)
	var defs: Definitions = DataRegistry.definitions
	var status: String = "dados OK" if DataRegistry.errors.is_empty() else "%d erro(s) nos dados" % DataRegistry.errors.size()
	UiDraw.text(self, Vector2(40, 340), "v%s · %d categorias · %d organizações · %s · W/S escolher · Enter confirmar" % [
		ProjectSettings.get_setting("application/config/version"), defs.weight_classes.size(), defs.organizations.size(), status],
		UiDraw.C_DIM, UiDraw.SMALL)


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

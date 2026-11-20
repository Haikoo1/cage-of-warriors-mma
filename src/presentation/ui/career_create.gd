extends Control
## Criação da carreira (CAREER_DESIGN §2). W/S linha · A/D valor · digite o nome · Enter cria · Esc volta.

const ROWS: Array[String] = ["Nome", "Categoria", "Origem", "Idade", "Duração do round", "Slot de save"]
const ROUND_LENGTHS: Array[int] = [60, 120, 180, 300]

var row: int = 0
var name_text: String = "Novo Lutador"
var wc_ids: Array[StringName] = []
var origin_ids: Array[StringName] = []
var values: Array[int] = [0, 3, 3, 4, 1, 0]  # índices: nome(ignorado), categoria, origem, idade-18, round, slot-1


func _ready() -> void:
	var defs: Definitions = DataRegistry.definitions
	for wc: StringName in defs.weight_classes:
		wc_ids.append(wc)
	wc_ids.sort_custom(func(x: StringName, y: StringName) -> bool:
		var a: WeightClassDef = defs.weight_class(x)
		var b: WeightClassDef = defs.weight_class(y)
		return a.division < b.division or (a.division == b.division and a.limit_lb < b.limit_lb))
	for o: StringName in defs.origins:
		origin_ids.append(o)
	origin_ids.sort()
	values[1] = wc_ids.find(&"m_lightweight")


func _count(i: int) -> int:
	return [1, wc_ids.size(), origin_ids.size(), 13, ROUND_LENGTHS.size(), 3][i]


func _value_text(i: int) -> String:
	var defs: Definitions = DataRegistry.definitions
	match i:
		0:
			return name_text + ("_" if row == 0 else "")
		1:
			var wc: WeightClassDef = defs.weight_class(wc_ids[values[1]])
			return "%s %s (%.0f lb / %.1f kg)" % ["Masc." if wc.division == WeightClassDef.Division.MALE else "Fem.", wc.display_key, wc.limit_lb, wc.limit_kg()]
		2:
			return defs.origin(origin_ids[values[2]]).display_name
		3:
			return "%d anos" % (18 + values[3])
		4:
			return "%d min (lutas jogadas; regras oficiais 5 min)" % (ROUND_LENGTHS[values[4]] / 60)
	var s: int = values[5] + 1
	var used: String = CareerController.slot_summary(defs, s)
	return "%d%s" % [s, ("  (SOBRESCREVE: %s)" % used) if used != "" else ""]


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	UiDraw.text(self, Vector2(40, 46), "NOVA CARREIRA", UiDraw.C_SEL, UiDraw.TITLE)
	for i: int in ROWS.size():
		var y: float = 82 + i * 24
		var col: Color = UiDraw.C_SEL if i == row else UiDraw.C_TEXT
		UiDraw.text(self, Vector2(40, y), ROWS[i], col, 11)
		UiDraw.text(self, Vector2(190, y), ("< %s >" if i > 0 else "%s") % _value_text(i), col, 11)
	var origin: OriginDef = DataRegistry.definitions.origin(origin_ids[values[2]])
	UiDraw.text(self, Vector2(40, 240), origin.description, UiDraw.C_DIM, UiDraw.TEXT)
	UiDraw.text(self, Vector2(40, 256), "Mais novo = atributos baixos e carreira longa; mais velho = começa melhor, com menos tempo até o pico.", UiDraw.C_DIM, UiDraw.SMALL)
	UiDraw.text(self, Vector2(40, 300), "W/S linha · A/D mudar · digite o nome na 1ª linha · Enter criar · Esc voltar", UiDraw.C_DIM, UiDraw.SMALL)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var key: InputEventKey = event as InputEventKey
	if row == 0 and key.unicode >= 32 and key.unicode != 127 and name_text.length() < 22 \
			and key.physical_keycode not in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
		name_text += char(key.unicode)
		return
	match key.physical_keycode:
		KEY_BACKSPACE:
			if row == 0:
				name_text = name_text.left(-1)
		KEY_UP:
			row = (row + ROWS.size() - 1) % ROWS.size()
		KEY_DOWN, KEY_TAB:
			row = (row + 1) % ROWS.size()
		KEY_W:
			row = (row + ROWS.size() - 1) % ROWS.size()
		KEY_S:
			row = (row + 1) % ROWS.size()
		KEY_A, KEY_LEFT:
			if row > 0:
				values[row] = (values[row] + _count(row) - 1) % _count(row)
		KEY_D, KEY_RIGHT:
			if row > 0:
				values[row] = (values[row] + 1) % _count(row)
		KEY_ENTER, KEY_KP_ENTER:
			_create()
		KEY_ESCAPE:
			SceneRouter.go_to(&"boot")


func _create() -> void:
	var setup: CareerSetup = CareerSetup.new()
	setup.name = name_text.strip_edges() if name_text.strip_edges() != "" else "Novo Lutador"
	setup.weight_class_id = wc_ids[values[1]]
	setup.origin_id = origin_ids[values[2]]
	setup.age = 18 + values[3]
	setup.round_seconds = ROUND_LENGTHS[values[4]]
	setup.seed = Time.get_ticks_usec()
	var slot: int = values[5] + 1
	CareerController.delete_slot(slot)
	var cc: CareerController = CareerController.create(DataRegistry.definitions, setup, slot)
	cc.save()
	GameSession.career = cc
	SceneRouter.go_to(&"career_dashboard")

extends Control
## Criação da carreira (CAREER_DESIGN §2) com criador de visual (estilo Stardew/Terraria): prévia animada
## com troca de paleta em tempo real. ↑/↓ linha · A/D (←/→) valor · digite o nome · R aleatório · Enter cria · Esc volta.

const ROWS: Array[String] = ["Nome", "Categoria", "Origem", "Idade", "Duração do round", "Slot de save",
	"Tom de pele", "Físico", "Cabelo", "Cor do cabelo", "Barba", "Calção", "Luvas"]
const ROUND_LENGTHS: Array[int] = [60, 120, 180, 300]
const FIRST_LOOK_ROW: int = 6
const ROW_H: float = 20.0
## Sprites de 189 px (D-022) a 2/3 = 126 px lógicos: em 1080p cada pixel do sprite vira exatamente 2x2.
const PREVIEW_SCALE: float = 2.0 / 3.0

var row: int = 0
var name_text: String = "Novo Lutador"
var wc_ids: Array[StringName] = []
var origin_ids: Array[StringName] = []
var values: Array[int] = [0, 3, 3, 4, 1, 0]
var look: Appearance = Appearance.new()
var preview: FighterSpriteNode
var sprites: SpriteSet
var _anim_time: float = 0.0


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
	sprites = SpriteSet.for_biotype(&"m_medium")
	if sprites != null:
		preview = FighterSpriteNode.new()
		add_child(preview)
		_refresh_preview()


func _is_female() -> bool:
	return DataRegistry.definitions.weight_class(wc_ids[values[1]]).division == WeightClassDef.Division.FEMALE


## Linhas do visual: 6 pele · 7 físico · 8 cabelo · 9 cor do cabelo · 10 barba · 11 calção · 12 luvas.
func _count(i: int) -> int:
	match i:
		0: return 1
		1: return wc_ids.size()
		2: return origin_ids.size()
		3: return 13
		4: return ROUND_LENGTHS.size()
		5: return 3
		6: return Appearance.SKIN_TONES.size()
		7: return Appearance.BUILD_NAMES.size()
		8: return Appearance.HAIR_STYLE_NAMES.size()
		9: return Appearance.HAIR_COLORS.size()
		10: return 1 if _is_female() else Appearance.BEARD_NAMES.size()
		11: return Appearance.SHORTS_COLORS.size()
	return Appearance.GLOVE_COLORS.size()


func _get_value(i: int) -> int:
	match i:
		6: return look.skin
		7: return look.build
		8: return look.hair_style
		9: return look.hair_color
		10: return look.beard
		11: return look.shorts
		12: return look.gloves
	return values[i]


func _set_value(i: int, v: int) -> void:
	match i:
		6: look.skin = v
		7: look.build = v
		8: look.hair_style = v
		9: look.hair_color = v
		10: look.beard = 0 if _is_female() else v
		11: look.shorts = v
		12: look.gloves = v
		_: values[i] = v
	if i == 1 and _is_female():
		look.beard = 0
	_refresh_preview()


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
			return "%d min (lutas jogadas)" % (ROUND_LENGTHS[values[4]] / 60)
		5:
			var s: int = values[5] + 1
			var used: String = CareerController.slot_summary(defs, s)
			return "%d%s" % [s, ("  (sobrescreve: %s)" % used) if used != "" else ""]
		6: return Appearance.SKIN_NAMES[look.skin]
		7: return Appearance.BUILD_NAMES[look.build]
		8: return Appearance.HAIR_STYLE_NAMES[look.hair_style]
		9: return Appearance.HAIR_COLOR_NAMES[look.hair_color]
		10: return Appearance.BEARD_NAMES[look.beard] + (" (indisponível)" if _is_female() else "")
		11: return Appearance.SHORTS_NAMES[look.shorts]
	return Appearance.GLOVE_NAMES[look.gloves]


func _refresh_preview() -> void:
	var fam: SpriteSet = SpriteSet.for_biotype(&"f_medium" if _is_female() else &"m_medium")
	if fam != null:
		sprites = fam
	if preview != null:
		preview.configure(sprites, look)


func _process(delta: float) -> void:
	_anim_time += delta
	if preview != null:
		var frames: int = int(sprites.frames.get("guard", 1))
		var idx: int = int(_anim_time * 20.0 / 1.5) % frames
		preview.present(Vector2(500, 298), ["guard", idx], 1.0, PREVIEW_SCALE, 0)
	queue_redraw()


func _draw() -> void:
	UiDraw.background(self, "NOVA CARREIRA", "do circuito local ao cinturão")
	for i: int in ROWS.size():
		var y: float = 48 + i * ROW_H + (8 if i >= FIRST_LOOK_ROW else 0)
		var rect: Rect2 = Rect2(20, y, 400, ROW_H - 2)
		UiDraw.panel(self, rect, i == row)
		UiDraw.text(self, rect.position + Vector2(10, 12), ROWS[i], UiDraw.C_SEL if i == row else UiDraw.C_DIM, 9)
		UiDraw.text(self, rect.position + Vector2(120, 12), ("‹ %s ›" if i > 0 else "%s") % _value_text(i), UiDraw.C_TEXT, 9, 275)
	UiDraw.text(self, Vector2(22, 48 + FIRST_LOOK_ROW * ROW_H + 4), "VISUAL", UiDraw.C_ACCENT, 7)
	UiDraw.panel(self, Rect2(440, 50, 180, 270))
	UiDraw.text(self, Vector2(452, 66), "Prévia", UiDraw.C_SEL, 10)
	draw_rect(Rect2(452, 300, 156, 3), Color(0.8, 0.8, 0.78))
	var origin: OriginDef = DataRegistry.definitions.origin(origin_ids[values[2]])
	UiDraw.text(self, Vector2(452, 82), origin.display_name, UiDraw.C_TEXT, 8, 160)
	UiDraw.text(self, Vector2(452, 314), origin.description, UiDraw.C_DIM, 7, 160)
	UiDraw.footer(self, "↑/↓ linha · A/D mudar · digite o nome na 1ª linha · R visual aleatório · Enter criar · Esc voltar")


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
		KEY_UP, KEY_W:
			row = (row + ROWS.size() - 1) % ROWS.size()
		KEY_DOWN, KEY_S, KEY_TAB:
			row = (row + 1) % ROWS.size()
		KEY_A, KEY_LEFT:
			if row > 0:
				_set_value(row, (_get_value(row) + _count(row) - 1) % _count(row))
		KEY_D, KEY_RIGHT:
			if row > 0:
				_set_value(row, (_get_value(row) + 1) % _count(row))
		KEY_R:
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.randomize()
			look = Appearance.random(rng, not _is_female())
			_refresh_preview()
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
	setup.appearance = look.duplicate_appearance()
	var slot: int = values[5] + 1
	CareerController.delete_slot(slot)
	var cc: CareerController = CareerController.create(DataRegistry.definitions, setup, slot)
	cc.save()
	GameSession.career = cc
	SceneRouter.go_to(&"career_dashboard")

extends TestCase
## Aba Visual da carreira (D-019): troca de visual pelo controlador, sem efeito em regra, persistida no save.

const SLOT: int = 8


func _new(wc: StringName) -> CareerController:
	var setup: CareerSetup = CareerSetup.new()
	setup.name = "Visual"
	setup.weight_class_id = wc
	setup.seed = 5
	setup.appearance.skin = 4
	return CareerController.create(DataLoader.load_from("res://data"), setup, SLOT)


func test_change_appearance_keeps_skin_and_persists() -> void:
	var cc: CareerController = _new(&"m_lightweight")
	var look: Appearance = Appearance.new()
	look.skin = 0
	look.hair_style = 3
	look.shorts = 6
	look.beard = 2
	cc.change_appearance(look)
	var a: Appearance = cc.state.player().appearance
	assert_eq(a.skin, 4, "pele não muda na loja")
	assert_eq(a.hair_style, 3)
	assert_eq(a.shorts, 6)
	assert_eq(a.beard, 2)
	look.shorts = 2
	assert_eq(cc.state.player().appearance.shorts, 6, "o controlador copia o visual (sem alias)")
	assert_eq(cc.save(), OK)
	var loaded: CareerController = CareerController.load_slot(DataLoader.load_from("res://data"), SLOT)
	assert_eq(loaded.state.player().appearance.hair_style, 3)
	CareerController.delete_slot(SLOT)


func test_female_fighters_cannot_get_beard() -> void:
	var cc: CareerController = _new(&"f_strawweight")
	var look: Appearance = Appearance.new()
	look.beard = 3
	cc.change_appearance(look)
	assert_eq(cc.state.player().appearance.beard, 0)

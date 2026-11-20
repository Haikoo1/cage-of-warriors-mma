extends SceneTree
## Smoke das telas da carreira: menu, criação, dashboard (todas as abas), avanço, oferta, luta simulada, entrevista.
## Uso: godot --headless --path . --script res://tests/runner/smoke_career.gd  (falha se houver SCRIPT ERROR no log)


func _key(screen: Node, code: Key) -> void:
	var ev: InputEventKey = InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	screen.call("_unhandled_input", ev)


func _screen(holder: Node) -> Node:
	return holder.get_child(holder.get_child_count() - 1)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _initialize() -> void:
	await process_frame
	var router: Node = root.get_node("SceneRouter")
	var session: Node = root.get_node("GameSession")
	var defs: Definitions = root.get_node("DataRegistry").get("definitions")
	var holder: Node = Node.new()
	root.add_child(holder)
	router.call("set_screen_root", holder)
	router.call("go_to", &"boot")
	await _frames(3)
	router.call("go_to", &"career_create")
	await _frames(3)
	for k: Key in [KEY_DOWN, KEY_D, KEY_DOWN, KEY_D, KEY_UP]:
		_key(_screen(holder), k)
	await _frames(2)
	var setup: CareerSetup = CareerSetup.new()
	setup.name = "Smoke"
	setup.seed = 3
	var cc: CareerController = CareerController.create(defs, setup, 8)
	session.set("career", cc)
	router.call("go_to", &"career_dashboard")
	await _frames(3)
	for k: Key in [KEY_1, KEY_2, KEY_S, KEY_E, KEY_Q, KEY_G, KEY_3, KEY_4, KEY_E, KEY_C, KEY_5, KEY_1]:
		_key(_screen(holder), k)
		await _frames(2)
	var weeks: int = 0
	while cc.state.offers.is_empty() and weeks < 20:
		_key(_screen(holder), KEY_SPACE)
		weeks += 1
		await _frames(1)
	_key(_screen(holder), KEY_3)
	_key(_screen(holder), KEY_ENTER)
	await _frames(2)
	_key(_screen(holder), KEY_1)
	var guard: int = 0
	while not cc.is_fight_week() and guard < 30 and not cc.state.booked.is_empty():
		_key(_screen(holder), KEY_A)
		guard += 1
		await _frames(1)
	if cc.is_fight_week():
		_key(_screen(holder), KEY_F)
		await _frames(2)
		_key(_screen(holder), KEY_2)
	await _frames(3)
	print("SMOKE_OK semana=%d cartel=%s notícias=%d" % [cc.state.week_index + 1, cc.state.player().record_text(), cc.state.news.size()])
	CareerController.delete_slot(8)
	quit(0)

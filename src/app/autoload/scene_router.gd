extends Node
## Autoload SceneRouter (T-008): troca a tela ativa em Main/ScreenRoot. Rotas são IDs enumerados.

const ROUTES: Dictionary = {
	&"boot": "res://scenes/ui/boot_screen.tscn",
	&"combat_test": "res://scenes/combat/combat_test.tscn",
	&"quick_fight": "res://scenes/ui/quick_fight_menu.tscn",
	&"fight_result": "res://scenes/ui/fight_result.tscn",
}

var _screen_root: Node
var _current: Node


func set_screen_root(root: Node) -> void:
	_screen_root = root


func go_to(route: StringName, params: Dictionary = {}) -> void:
	assert(ROUTES.has(route), "rota desconhecida: %s" % route)
	assert(_screen_root != null, "ScreenRoot não registrado")
	if _current != null:
		_current.queue_free()
	var scene: PackedScene = load(ROUTES[route]) as PackedScene
	_current = scene.instantiate()
	if _current.has_method("setup"):
		_current.call("setup", params)
	_screen_root.add_child(_current)

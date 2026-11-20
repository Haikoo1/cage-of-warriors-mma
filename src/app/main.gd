extends Node
## Cena raiz (GODOT_ARCHITECTURE §1.2).


func _ready() -> void:
	SceneRouter.set_screen_root(%ScreenRoot)
	SceneRouter.go_to(&"boot")

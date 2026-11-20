extends Control
## Tela provisória: versão, estado dos dados e acesso aos modos do protótipo. Substituída pelo menu principal.


func _ready() -> void:
	var defs: Definitions = DataRegistry.definitions
	var status: String = "dados OK" if DataRegistry.errors.is_empty() else "%d erros nos dados" % DataRegistry.errors.size()
	%Info.text = "Projeto Jaula %s — protótipo de combate (greybox)\n%d categoria(s), %d golpe(s), %d técnicas de grappling: %s" % [
		ProjectSettings.get_setting("application/config/version"),
		defs.weight_classes.size(), defs.strikes.size(), defs.grapple_techniques.size(), status,
	]
	%Info.text += "\n\nEnter: Luta Rápida   ·   T: treino contra o boneco"


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_ENTER, KEY_KP_ENTER:
			SceneRouter.go_to(&"quick_fight")
		KEY_T:
			SceneRouter.go_to(&"combat_test")

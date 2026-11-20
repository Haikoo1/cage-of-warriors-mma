extends Node
## Autoload Settings (T-008): preferências globais e mapa de entrada.

const PATH: String = "user://settings.cfg"

var store: SettingsStore = SettingsStore.new()


func _ready() -> void:
	InputBindings.register_defaults()
	store.load_from(PATH)  # ausência do arquivo mantém os padrões


func save() -> Error:
	return store.save_to(PATH)

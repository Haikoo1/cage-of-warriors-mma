extends Node
## Autoload Settings (T-008): preferências globais e mapa de entrada.

const PATH: String = "user://settings.cfg"

var store: SettingsStore = SettingsStore.new()


func _ready() -> void:
	InputBindings.register_defaults()
	store.load_from(PATH)  # ausência do arquivo mantém os padrões
	InputBindings.apply_overrides(store.key_overrides)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, store.master_volume)))


func save() -> Error:
	return store.save_to(PATH)

extends Node
## Autoload Settings (T-008): preferências globais e mapa de entrada.

const PATH: String = "user://settings.cfg"

var store: SettingsStore = SettingsStore.new()


func _ready() -> void:
	# Interface em HD (D-018): fonte do sistema renderizada na resolução da janela.
	var font: SystemFont = SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "Arial", "Helvetica"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.hinting = TextServer.HINTING_LIGHT
	ThemeDB.fallback_font = font
	InputBindings.register_defaults()
	store.load_from(PATH)  # ausência do arquivo mantém os padrões
	InputBindings.apply_overrides(store.key_overrides)



func save() -> Error:
	return store.save_to(PATH)

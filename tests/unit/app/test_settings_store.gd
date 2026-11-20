extends TestCase

const PATH: String = "user://test_settings.cfg"


func test_save_and_load_round_trip() -> void:
	var s: SettingsStore = SettingsStore.new()
	s.music_volume = 0.3
	s.hud_level = &"minimal"
	assert_eq(s.save_to(PATH), OK)
	var loaded: SettingsStore = SettingsStore.new()
	assert_eq(loaded.load_from(PATH), OK)
	assert_almost(loaded.music_volume, 0.3)
	assert_eq(loaded.hud_level, &"minimal")
	DirAccess.remove_absolute(PATH)


func test_missing_file_keeps_defaults() -> void:
	var s: SettingsStore = SettingsStore.new()
	assert_true(s.load_from("user://nao_existe.cfg") != OK, "retorna erro")
	assert_eq(s.hud_level, &"full")


func test_input_bindings_register_all_actions() -> void:
	InputBindings.register_defaults()
	for action: StringName in InputBindings.DEFAULT_KEYS.keys():
		assert_true(InputMap.has_action(action), "ação %s" % action)
	assert_true(InputMap.has_action(&"technique"), "Técnica (Espaço)")


func test_damage_hud_is_optional_and_persists() -> void:
	var s: SettingsStore = SettingsStore.new()
	assert_true(s.show_damage_hud, "ligado por padrão")
	s.show_damage_hud = false
	assert_eq(s.save_to(PATH), OK)
	var loaded: SettingsStore = SettingsStore.new()
	assert_eq(loaded.load_from(PATH), OK)
	assert_false(loaded.show_damage_hud, "desligado volta desligado")
	DirAccess.remove_absolute(PATH)

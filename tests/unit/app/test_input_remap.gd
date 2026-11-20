extends TestCase
## Controles remapeáveis pelo jogador (pedido do usuário na E-03; GAME_SYSTEMS §7).

const PATH: String = "user://test_remap.cfg"


func test_override_replaces_default_key() -> void:
	InputBindings.register_defaults()
	InputBindings.apply_overrides({&"lead_hand": KEY_Z})
	assert_eq(InputBindings.key_for(&"lead_hand"), KEY_Z)
	InputBindings.reset_to_defaults()
	assert_eq(InputBindings.key_for(&"lead_hand"), InputBindings.DEFAULT_KEYS[&"lead_hand"])


func test_overrides_persist_in_settings() -> void:
	var s: SettingsStore = SettingsStore.new()
	s.key_overrides = {&"rear_leg": KEY_M}
	s.save_to(PATH)
	var loaded: SettingsStore = SettingsStore.new()
	loaded.load_from(PATH)
	assert_eq(loaded.key_overrides.get(&"rear_leg"), KEY_M)
	DirAccess.remove_absolute(PATH)


func test_unknown_action_is_ignored() -> void:
	InputBindings.register_defaults()
	InputBindings.apply_overrides({&"acao_inexistente": KEY_P})
	assert_false(InputMap.has_action(&"acao_inexistente"), "não cria ações novas")

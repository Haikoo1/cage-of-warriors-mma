class_name InputBindings
extends RefCounted
## Teclas padrão do combate, teclado primeiro (D-015, COMBAT_DESIGN §3.1). Remapeamento: etapa de opções.
## Padrões de gamepad entram com a tela de opções. O jogador pode trocar qualquer tecla (key_overrides em Settings).

const DEFAULT_KEYS: Dictionary = {
	&"move_forward": KEY_D,
	&"move_back": KEY_A,
	&"move_up": KEY_W,
	&"move_down": KEY_S,
	&"lead_hand": KEY_U,
	&"rear_hand": KEY_I,
	&"lead_leg": KEY_J,
	&"rear_leg": KEY_K,
	&"mod_curved": KEY_E,
	&"mod_body": KEY_Q,
	&"guard": KEY_SHIFT,
	&"technique": KEY_SPACE,
	&"grapple": KEY_L,
	&"pause": KEY_ESCAPE,
}


static func register_defaults() -> void:
	for action: StringName in DEFAULT_KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var ev: InputEventKey = InputEventKey.new()
		ev.physical_keycode = DEFAULT_KEYS[action]
		InputMap.action_add_event(action, ev)


## Aplica teclas escolhidas pelo jogador (ação -> keycode). Ações desconhecidas são ignoradas.
static func apply_overrides(overrides: Dictionary) -> void:
	for action: StringName in overrides:
		if not DEFAULT_KEYS.has(action):
			continue
		_set_key(action, int(overrides[action]))


static func reset_to_defaults() -> void:
	for action: StringName in DEFAULT_KEYS:
		_set_key(action, DEFAULT_KEYS[action])


static func key_for(action: StringName) -> int:
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return (ev as InputEventKey).physical_keycode
	return KEY_NONE


static func _set_key(action: StringName, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = keycode as Key
	InputMap.action_add_event(action, key)

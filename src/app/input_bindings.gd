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


## Gamepad (D-015: alternativa completa). Botão -> ação; eixos em JOY_AXES.
const DEFAULT_JOY_BUTTONS: Dictionary = {
	&"lead_hand": JOY_BUTTON_X, &"rear_hand": JOY_BUTTON_Y, &"lead_leg": JOY_BUTTON_A, &"rear_leg": JOY_BUTTON_B,
	&"mod_body": JOY_BUTTON_RIGHT_SHOULDER, &"guard": JOY_BUTTON_LEFT_SHOULDER, &"technique": JOY_BUTTON_RIGHT_STICK,
	&"pause": JOY_BUTTON_START, &"move_forward": JOY_BUTTON_DPAD_RIGHT, &"move_back": JOY_BUTTON_DPAD_LEFT,
	&"move_up": JOY_BUTTON_DPAD_UP, &"move_down": JOY_BUTTON_DPAD_DOWN,
}
## ação -> [eixo, sinal]
const DEFAULT_JOY_AXES: Dictionary = {
	&"move_forward": [JOY_AXIS_LEFT_X, 1.0], &"move_back": [JOY_AXIS_LEFT_X, -1.0],
	&"move_up": [JOY_AXIS_LEFT_Y, -1.0], &"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	&"mod_curved": [JOY_AXIS_TRIGGER_RIGHT, 1.0], &"grapple": [JOY_AXIS_TRIGGER_LEFT, 1.0],
}
const MENU_BUTTONS: Dictionary = {
	JOY_BUTTON_DPAD_UP: KEY_UP, JOY_BUTTON_DPAD_DOWN: KEY_DOWN, JOY_BUTTON_DPAD_LEFT: KEY_LEFT,
	JOY_BUTTON_DPAD_RIGHT: KEY_RIGHT, JOY_BUTTON_A: KEY_ENTER, JOY_BUTTON_B: KEY_ESCAPE, JOY_BUTTON_START: KEY_ESCAPE,
	JOY_BUTTON_X: KEY_SPACE, JOY_BUTTON_LEFT_SHOULDER: KEY_Q, JOY_BUTTON_RIGHT_SHOULDER: KEY_E,
}


## Tecla equivalente para navegar menus com o gamepad (KEY_NONE se não houver).
static func menu_key_for(ev: InputEventJoypadButton) -> Key:
	return MENU_BUTTONS.get(ev.button_index, KEY_NONE)


static func register_defaults() -> void:
	_register_joypad()
	for action: StringName in DEFAULT_KEYS:
		if key_for(action) != KEY_NONE:
			continue
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


static func _register_joypad() -> void:
	for action: StringName in DEFAULT_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.4)
	for action: StringName in DEFAULT_JOY_BUTTONS:
		var b: InputEventJoypadButton = InputEventJoypadButton.new()
		b.button_index = DEFAULT_JOY_BUTTONS[action]
		if not InputMap.action_has_event(action, b):
			InputMap.action_add_event(action, b)
	for action: StringName in DEFAULT_JOY_AXES:
		var m: InputEventJoypadMotion = InputEventJoypadMotion.new()
		m.axis = DEFAULT_JOY_AXES[action][0]
		m.axis_value = DEFAULT_JOY_AXES[action][1]
		if not InputMap.action_has_event(action, m):
			InputMap.action_add_event(action, m)

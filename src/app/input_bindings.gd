class_name InputBindings
extends RefCounted
## Teclas padrão do combate, teclado primeiro (D-015, COMBAT_DESIGN §3.1). Remapeamento: etapa de opções.
## Padrões de gamepad entram em E-03.

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

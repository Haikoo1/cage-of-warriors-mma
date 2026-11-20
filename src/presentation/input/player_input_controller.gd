class_name PlayerInputController
extends RefCounted
## Converte o estado das ações do InputMap em FighterCommand (T-018). Teclado primeiro (D-015).
## Em pé: WASD move; Espaço + W/S/trás = esquivas (e defesas de queda); L (+W/S) = clinch/quedas.
## Clinch e solo: sem locomoção — WASD é a direção de técnica direto; L + direção inicia a técnica (COMBAT §3.1).

var relative_to_opponent: bool = true


func get_command(facing: int, position: StringName) -> FighterCommand:
	var c: FighterCommand = FighterCommand.new()
	var right: int = int(Input.is_action_pressed(&"move_forward")) - int(Input.is_action_pressed(&"move_back"))
	var depth: int = int(Input.is_action_pressed(&"move_up")) - int(Input.is_action_pressed(&"move_down"))
	# D/A: "avançar/recuar" (relativo ao adversário) ou "direita/esquerda" da tela (V-007).
	var forward: int = right if relative_to_opponent else right * facing
	c.guard = Input.is_action_pressed(&"guard")
	c.mod_curved = Input.is_action_pressed(&"mod_curved")
	c.mod_body = Input.is_action_pressed(&"mod_body")
	c.grapple = Input.is_action_just_pressed(&"grapple")
	var limbs: Array[StringName] = [&"lead_hand", &"rear_hand", &"lead_leg", &"rear_leg"]
	for i: int in limbs.size():
		if Input.is_action_just_pressed(limbs[i]):
			c.strike_limb = i
	if position != &"EP":
		c.technique_direction = _pressed_direction(forward, depth, c.grapple)
		return c
	if c.grapple:
		c.technique_direction = _dir(0, depth)  # L = clinch, L+S = double leg, L+W = single leg
	elif Input.is_action_pressed(&"technique"):
		c.technique_direction = _dir(mini(forward, 0), depth)
	else:
		c.move_x = forward
		c.move_z = depth
	return c


## No chão: ao apertar L usa a direção segurada; sem L, só o toque novo conta (leitura/escape).
func _pressed_direction(forward: int, depth: int, grapple_now: bool) -> FighterCommand.Direction:
	if grapple_now:
		return _dir(forward, depth)
	var just_f: int = int(Input.is_action_just_pressed(&"move_forward")) - int(Input.is_action_just_pressed(&"move_back"))
	var just_z: int = int(Input.is_action_just_pressed(&"move_up")) - int(Input.is_action_just_pressed(&"move_down"))
	if just_f == 0 and just_z == 0:
		return FighterCommand.Direction.NONE
	return _dir(just_f if relative_to_opponent else forward, just_z)


static func _dir(forward: int, depth: int) -> FighterCommand.Direction:
	if depth > 0:
		return FighterCommand.Direction.UP
	if depth < 0:
		return FighterCommand.Direction.DOWN
	if forward > 0:
		return FighterCommand.Direction.FORWARD
	if forward < 0:
		return FighterCommand.Direction.BACK
	return FighterCommand.Direction.NONE

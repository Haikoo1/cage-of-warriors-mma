class_name PlayerInputController
extends RefCounted
## Converte o estado das ações do InputMap em FighterCommand (T-018). Teclado primeiro (D-015).
## Espaço (Técnica) + W/S/trás = esquivas (COMBAT_DESIGN §3.1, corrigido na E-03).

var relative_to_opponent: bool = true


func get_command(facing: int) -> FighterCommand:
	var c: FighterCommand = FighterCommand.new()
	var right: int = int(Input.is_action_pressed(&"move_forward")) - int(Input.is_action_pressed(&"move_back"))
	var depth: int = int(Input.is_action_pressed(&"move_up")) - int(Input.is_action_pressed(&"move_down"))
	# D/A: "avançar/recuar" (relativo ao adversário) ou "direita/esquerda" da tela (V-007).
	var forward: int = right if relative_to_opponent else right * facing
	if Input.is_action_pressed(&"technique"):
		if depth > 0:
			c.technique_direction = FighterCommand.Direction.UP
		elif depth < 0:
			c.technique_direction = FighterCommand.Direction.DOWN
		elif forward < 0:
			c.technique_direction = FighterCommand.Direction.BACK
	else:
		c.move_x = forward
		c.move_z = depth
	c.guard = Input.is_action_pressed(&"guard")
	c.mod_curved = Input.is_action_pressed(&"mod_curved")
	c.mod_body = Input.is_action_pressed(&"mod_body")
	c.grapple = Input.is_action_just_pressed(&"grapple")
	var limbs: Array[StringName] = [&"lead_hand", &"rear_hand", &"lead_leg", &"rear_leg"]
	for i: int in limbs.size():
		if Input.is_action_just_pressed(limbs[i]):
			c.strike_limb = i
	return c

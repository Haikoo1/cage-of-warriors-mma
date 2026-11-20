class_name FighterCommand
extends RefCounted
## Intenção de um lutador em um passo (T-018). Igual para jogador e IA. Entradas digitais em 4 direções (R-038).

enum Direction { NONE, FORWARD, BACK, UP, DOWN }

var move_x: int = 0  # -1 recuar, 0, +1 avançar (relativo ao adversário)
var move_z: int = 0  # -1 frente da tela, 0, +1 fundo
var strike_limb: int = -1  # StrikeDef.Limb ou -1
var mod_curved: bool = false
var mod_body: bool = false
var guard: bool = false
var grapple: bool = false
var technique_direction: Direction = Direction.NONE


func is_neutral() -> bool:
	return move_x == 0 and move_z == 0 and strike_limb == -1 and not guard and not grapple \
		and technique_direction == Direction.NONE

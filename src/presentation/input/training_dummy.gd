class_name TrainingDummy
extends RefCounted
## Boneco de treino da E-03 (a IA de verdade é a E-05). Usa a mesma interface de comando do jogador.

enum Mode { STILL, GUARD, JAB, MOVE, KICKS }

const NAMES: Dictionary = {
	Mode.STILL: "parado", Mode.GUARD: "guarda alta", Mode.JAB: "jab a cada 1 s",
	Mode.MOVE: "anda para frente e para trás", Mode.KICKS: "chute baixo a cada 1,5 s",
}

var mode: Mode = Mode.STILL
var _t: int = 0


func cycle() -> void:
	mode = ((mode + 1) % Mode.size()) as Mode


func get_command() -> FighterCommand:
	_t += 1
	var c: FighterCommand = FighterCommand.new()
	match mode:
		Mode.GUARD:
			c.guard = true
		Mode.JAB:
			if _t % 60 == 0:
				c.strike_limb = StrikeDef.Limb.LEAD_HAND
		Mode.MOVE:
			c.move_x = 1 if (_t / 90) % 2 == 0 else -1
		Mode.KICKS:
			if _t % 90 == 0:
				c.strike_limb = StrikeDef.Limb.REAR_LEG
	return c

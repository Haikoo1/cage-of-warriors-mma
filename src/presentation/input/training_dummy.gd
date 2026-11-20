class_name TrainingDummy
extends RefCounted
## Boneco de treino (a IA de verdade é a E-05). Usa a mesma interface de comando do jogador.
## Ferramenta de desenvolvimento: os modos de grappling olham o estado da luta direto (a IA real usará FighterPerception).

enum Mode { STILL, GUARD, JAB, MOVE, KICKS, WRESTLER, DEFENDER }

const NAMES: Dictionary = {
	Mode.STILL: "parado", Mode.GUARD: "guarda alta", Mode.JAB: "jab a cada 1 s",
	Mode.MOVE: "anda para frente e para trás", Mode.KICKS: "chute baixo a cada 1,5 s",
	Mode.WRESTLER: "wrestler (derruba, passa, finaliza)", Mode.DEFENDER: "defensor (lê 50% das técnicas)",
}
const ME: int = 1

var mode: Mode = Mode.STILL
var _t: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func cycle() -> void:
	mode = ((mode + 1) % Mode.size()) as Mode


func get_command(sim: CombatSim) -> FighterCommand:
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
		Mode.WRESTLER:
			_wrestler(sim, c)
		Mode.DEFENDER:
			_defender(sim, c)
	return c


func _wrestler(sim: CombatSim, c: FighterCommand) -> void:
	var g: CombatGrappling = sim.grappling
	if g.submission != null:
		if g.submission.attacker == ME and _t % 50 == 0:
			c.technique_direction = _random_dir()
		return
	if _t % 45 != 0:
		if g.position == &"EP" and absf(sim.fighters[0].x - sim.fighters[1].x) > 1.1:
			c.move_x = 1
		return
	c.grapple = true
	match [g.position, g.role_of(ME)]:
		[&"EP", _]:
			c.technique_direction = FighterCommand.Direction.DOWN
		[&"CL", _]:
			c.technique_direction = FighterCommand.Direction.UP if g.clinch_owner != ME else FighterCommand.Direction.DOWN
		[&"CG", &"top"], [&"SC", &"top"], [&"SR", &"top"]:
			c.technique_direction = FighterCommand.Direction.DOWN
		[&"SG", &"top"]:
			c.technique_direction = FighterCommand.Direction.FORWARD
		[&"SL", &"top"]:
			c.technique_direction = FighterCommand.Direction.UP
		[&"SO", &"top"]:
			c.technique_direction = FighterCommand.Direction.BACK
		_:
			c.technique_direction = _random_dir()


func _defender(sim: CombatSim, c: FighterCommand) -> void:
	var g: CombatGrappling = sim.grappling
	if g.pending != null and g.pending.attacker != ME and g.pending.read_frame < 0 and g.pending.elapsed == 3:
		c.technique_direction = g.pending.technique.defense_direction if _rng.randf() < 0.5 else _random_dir()
	elif g.submission != null and g.submission.attacker != ME and _t % 20 == 0:
		c.technique_direction = g.submission.attacker_dir if _rng.randf() < 0.5 else _random_dir()


func _random_dir() -> FighterCommand.Direction:
	return (_rng.randi_range(1, 4)) as FighterCommand.Direction

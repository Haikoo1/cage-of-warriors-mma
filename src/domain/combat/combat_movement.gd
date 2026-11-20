class_name CombatMovement
extends RefCounted
## Movimento no plano X/Z, limites da jaula, colisão e Vantagem de Ângulo (COMBAT_DESIGN §2).

const DT: float = 1.0 / 60.0


static func update(sim: CombatSim, i: int, cmd: FighterCommand, other_cmd: FighterCommand) -> void:
	var f: FighterCombatState = sim.fighters[i]
	var o: FighterCombatState = sim.fighters[1 - i]
	var bal: CombatBalanceDef = sim.balance
	f.moved_this_step = false
	var mobility: float = _mobility_factor(f, sim)
	if mobility <= 0.0 or (cmd.move_x == 0 and cmd.move_z == 0):
		return
	var speed_x: float = bal.walk_speed_mps * (1.0 if cmd.move_x > 0 else bal.back_speed_factor)
	var new_x: float = f.x + cmd.move_x * f.facing * speed_x * mobility * DT
	var new_z: float = clampf(f.z + cmd.move_z * bal.lateral_speed_mps * mobility * DT, -bal.depth_half_m, bal.depth_half_m)
	new_x = clampf(new_x, -bal.cage_half_width_m, bal.cage_half_width_m)
	# Colisão: perto em Z, não pode chegar mais perto que a distância mínima nem atravessar (COMBAT §2.6).
	if absf(new_z - o.z) < bal.collision_depth_m and f.facing * (o.x - new_x) < bal.body_min_distance_m:
		new_x = o.x - f.facing * bal.body_min_distance_m
	f.x = new_x
	f.z = new_z
	f.moved_this_step = true
	var cost: float = (absf(cmd.move_x) * bal.move_stamina_per_s + absf(cmd.move_z) * bal.lateral_stamina_per_s) * DT
	CombatPhysiology.spend(f, cost, bal)
	# Passo lateral não acompanhado pelo adversário gera Vantagem de Ângulo (COMBAT §2.4).
	if cmd.move_z != 0 and other_cmd.move_z == 0:
		f.angle_frames = bal.angle_frames


static func update_facing(sim: CombatSim) -> void:
	var a: FighterCombatState = sim.fighters[0]
	var b: FighterCombatState = sim.fighters[1]
	if not is_equal_approx(a.x, b.x):
		a.facing = 1 if b.x > a.x else -1
		b.facing = -a.facing


static func _mobility_factor(f: FighterCombatState, sim: CombatSim) -> float:
	var base: float
	match f.action:
		FighterCombatState.Action.IDLE:
			base = 1.0
		FighterCombatState.Action.STUNNED:
			base = 0.4
		_:
			return 0.0
	var guard: float = sim.balance.guard_move_factor if (f.guard_high or f.guard_low) else 1.0
	var weight: float = sim.weight_class.move_speed_mult if sim.weight_class != null else 1.0
	return base * (0.75 + f.attr(&"mobilidade") / 200.0) * guard * weight / CombatPhysiology.frame_multiplier(f)

class_name CombatSim
extends RefCounted
## Orquestra a luta em passo fixo de 60 Hz (T-004, COMBAT_ARCHITECTURE §2). Sem Nodes: testável headless.
## E-03: movimento, trocação, defesa e fisiologia. E-04: grappling (Disputa, posições, finalização).
## Rounds, árbitro, juízes e IA entram na E-05.

var defs: Definitions
var balance: CombatBalanceDef
var weight_class: WeightClassDef
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var fighters: Array[FighterCombatState] = []
var grappling: CombatGrappling = CombatGrappling.new()
var frame: int = 0
var finish_method: StringName = &""
var _finished: bool = false
var _winner: int = -1


func _init(setup: FightSetup, definitions: Definitions) -> void:
	defs = definitions
	balance = definitions.combat_balance if definitions.combat_balance != null else CombatBalanceDef.new()
	weight_class = definitions.weight_class(setup.weight_class_id)
	rng.seed = setup.seed
	for snap: FighterSnapshot in [setup.fighter_a, setup.fighter_b]:
		var f: FighterCombatState = FighterCombatState.new()
		f.snapshot = snap
		f.reserve = 100.0 * snap.reserve_start
		f.stamina = f.reserve
		fighters.append(f)
	fighters[0].x = -1.5
	fighters[1].x = 1.5
	CombatMovement.update_facing(self)


## Ordem fixa do passo (COMBAT_ARCHITECTURE §2): técnicas → leituras → golpes → movimento → fases → fisiologia.
func step(cmd_a: FighterCommand, cmd_b: FighterCommand) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	if _finished:
		return events
	var cmds: Array[FighterCommand] = [cmd_a, cmd_b]
	for i: int in 2:
		grappling.apply_command(self, i, cmds[i], events)
	var consumed: Array[bool] = [grappling.register_read(0, cmd_a), grappling.register_read(1, cmd_b)]
	var standing: bool = grappling.position == &"EP"
	for i: int in 2:
		if standing and not consumed[i]:
			CombatStriking.apply_command(self, i, cmds[i], events)
		elif not standing:
			grappling.apply_ground_guard(self, i, cmds[i])
	if standing:
		for i: int in 2:
			CombatMovement.update(self, i, cmds[i], cmds[1 - i])
	else:
		for f: FighterCombatState in fighters:
			f.moved_this_step = false
	for i: int in 2:
		if fighters[i].action != FighterCombatState.Action.GRAPPLING:
			CombatStriking.advance(self, i, events)
	grappling.advance(self, events)
	for f: FighterCombatState in fighters:
		CombatPhysiology.regenerate(f, balance)
		f.angle_frames = maxi(0, f.angle_frames - 1)
	CombatMovement.update_facing(self)
	frame += 1
	for i: int in 2:
		if not _finished and fighters[i].action == FighterCombatState.Action.OUT:
			finish(1 - i, &"ko")
	if _finished:
		events.append(CombatEvent.make(CombatEvent.Type.FIGHT_OVER, _winner, 1 - _winner))
	return events


func finish(winner_index: int, method: StringName) -> void:
	if _finished:
		return
	_finished = true
	_winner = winner_index
	finish_method = method


func is_finished() -> bool:
	return _finished


func winner() -> int:
	return _winner


func state_hash() -> String:
	return var_to_str([frame, grappling.position, grappling.top, fighters[0].to_hash_dict(), fighters[1].to_hash_dict()]).sha256_text()

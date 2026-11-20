class_name CombatSim
extends RefCounted
## Orquestra a luta em passo fixo de 60 Hz (T-004, COMBAT_ARCHITECTURE §2). Sem Nodes: testável headless.
## E-03: movimento, trocação, defesa e fisiologia. Rounds, árbitro, juízes e grappling entram em E-04/E-05.

var defs: Definitions
var balance: CombatBalanceDef
var weight_class: WeightClassDef
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var fighters: Array[FighterCombatState] = []
var frame: int = 0
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


func step(cmd_a: FighterCommand, cmd_b: FighterCommand) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	if _finished:
		return events
	var cmds: Array[FighterCommand] = [cmd_a, cmd_b]
	for i: int in 2:
		CombatStriking.apply_command(self, i, cmds[i], events)
	for i: int in 2:
		CombatMovement.update(self, i, cmds[i], cmds[1 - i])
	for i: int in 2:
		CombatStriking.advance(self, i, events)
	for f: FighterCombatState in fighters:
		CombatPhysiology.regenerate(f, balance)
		f.angle_frames = maxi(0, f.angle_frames - 1)
	CombatMovement.update_facing(self)
	frame += 1
	for i: int in 2:
		if fighters[i].action == FighterCombatState.Action.OUT:
			_finished = true
			_winner = 1 - i
			events.append(CombatEvent.make(CombatEvent.Type.FIGHT_OVER, 1 - i, i))
	return events


func is_finished() -> bool:
	return _finished


func winner() -> int:
	return _winner


func state_hash() -> String:
	return var_to_str([frame, fighters[0].to_hash_dict(), fighters[1].to_hash_dict()]).sha256_text()

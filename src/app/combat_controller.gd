extends Node2D
## Liga CombatSim ↔ entrada ↔ apresentação no passo fixo de 60 Hz (COMBAT_ARCHITECTURE §10.1).
## E-03/E-04: luta de treino contra o boneco (trocação e grappling), sem rounds.

@onready var view: GreyboxView = %GreyboxView
@onready var hud: CombatHud = %CombatHud

var sim: CombatSim
var player: PlayerInputController = PlayerInputController.new()
var dummy: TrainingDummy = TrainingDummy.new()


func _ready() -> void:
	player.relative_to_opponent = Settings.store.directions_relative_to_opponent
	_start()


func _start() -> void:
	var defs: Definitions = DataRegistry.definitions
	var setup: FightSetup = FightSetup.new()
	setup.fighter_a = FighterSnapshot.from_fighter(FighterState.create_blank(&"F-PLAYER", 50.0))
	setup.fighter_b = FighterSnapshot.from_fighter(FighterState.create_blank(&"F-DUMMY", 50.0))
	setup.ruleset_id = &"rs_standard"
	setup.weight_class_id = &"m_lightweight"
	setup.seed = Time.get_ticks_usec()
	sim = CombatSim.new(setup, defs)
	view.sim = sim
	hud.sim = sim


func _physics_process(_delta: float) -> void:
	var cmd_player: FighterCommand = player.get_command(sim.fighters[0].facing, sim.grappling.position)
	var events: Array[CombatEvent] = sim.step(cmd_player, dummy.get_command(sim))
	hud.dummy_mode = TrainingDummy.NAMES[dummy.mode]
	hud.present(events)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_F1:
			view.debug_overlay = not view.debug_overlay
		KEY_F2:
			dummy.cycle()
		KEY_F3:
			for i: int in 2:
				print("métricas lutador %d: %s" % [i, sim.fighters[i].stats])
		KEY_R:
			_start()
		KEY_ESCAPE:
			SceneRouter.go_to(&"boot")

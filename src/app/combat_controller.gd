extends Node2D
## Liga CombatSim ↔ entrada/IA ↔ apresentação no passo fixo de 60 Hz (COMBAT_ARCHITECTURE §10.1).
## Dois modos: Luta Rápida (params "quick_fight": regras completas, IA) ou treino com boneco (sem params).

const END_DELAY_FRAMES: int = 150

@onready var view: GreyboxView = %GreyboxView
@onready var hud: CombatHud = %CombatHud

var sim: CombatSim
var player: PlayerInputController = PlayerInputController.new()
var dummy: TrainingDummy = TrainingDummy.new()
var quick: QuickFight.Config
var player_focus: CombatSim.Focus = CombatSim.Focus.NORMAL
var _end_timer: int = 0
var _break_timer: int = 0


func setup(params: Dictionary) -> void:
	quick = params.get("quick_fight")


func _ready() -> void:
	player.relative_to_opponent = Settings.store.directions_relative_to_opponent
	_start()


func _start() -> void:
	var defs: Definitions = DataRegistry.definitions
	var setup_data: FightSetup
	if quick != null:
		setup_data = quick.setup
		hud.names = ["VOCÊ", "IA"]
		if quick.watch_only:
			hud.names = ["IA A", "IA B"]
		hud.training = false
	else:
		setup_data = FightSetup.new()
		setup_data.fighter_a = FighterSnapshot.from_fighter(FighterState.create_blank(&"F-PLAYER", 50.0))
		setup_data.fighter_b = FighterSnapshot.from_fighter(FighterState.create_blank(&"F-DUMMY", 50.0))
		setup_data.ruleset_id = &"rs_standard"
		setup_data.weight_class_id = &"m_lightweight"
		setup_data.round_seconds_override = 3600  # treino: round longo
		setup_data.seed = Time.get_ticks_usec()
		hud.training = true
	sim = CombatSim.new(setup_data, defs)
	view.sim = sim
	hud.sim = sim
	_end_timer = 0


func _physics_process(_delta: float) -> void:
	if sim.is_finished():
		_end_timer += 1
		if quick != null and _end_timer == END_DELAY_FRAMES:
			SceneRouter.go_to(&"fight_result", {"result": sim.build_result(&"QUICK"), "names": hud.names})
		return
	if sim.phase == CombatSim.Phase.ROUND_BREAK:
		_break_timer += 1
		hud.player_focus = player_focus
		if quick != null and quick.watch_only and _break_timer > 120:
			_next_round()
		hud.present([])
		return
	var cmd_a: FighterCommand
	if quick != null and quick.ai_a != null:
		quick.ai_a.observe(sim)
		cmd_a = quick.ai_a.get_command(sim)
	else:
		cmd_a = player.get_command(sim.fighters[0].facing, sim.grappling.position)
	var cmd_b: FighterCommand
	if quick != null:
		quick.ai_b.observe(sim)
		cmd_b = quick.ai_b.get_command(sim)
	else:
		cmd_b = dummy.get_command(sim)
	var events: Array[CombatEvent] = sim.step(cmd_a, cmd_b)
	hud.dummy_mode = TrainingDummy.NAMES[dummy.mode]
	hud.present(events)


func _next_round() -> void:
	var focus_a: CombatSim.Focus = player_focus
	if quick != null and quick.ai_a != null:
		focus_a = quick.ai_a.choose_focus(sim)
	var focus_b: CombatSim.Focus = quick.ai_b.choose_focus(sim) if quick != null else CombatSim.Focus.NORMAL
	sim.begin_next_round(focus_a, focus_b)
	player_focus = CombatSim.Focus.NORMAL
	_break_timer = 0


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = (event as InputEventKey).physical_keycode
	if sim.phase == CombatSim.Phase.ROUND_BREAK:
		match key:
			KEY_1:
				player_focus = CombatSim.Focus.NORMAL
			KEY_2:
				player_focus = CombatSim.Focus.RECOVER
			KEY_ENTER, KEY_KP_ENTER:
				_next_round()
	match key:
		KEY_F1:
			view.debug_overlay = not view.debug_overlay
		KEY_F4:
			view.use_sprites = not view.use_sprites
		KEY_F2:
			if quick == null:
				dummy.cycle()
		KEY_F3:
			for i: int in 2:
				print("métricas lutador %d: %s" % [i, sim.fighters[i].stats])
		KEY_R:
			if quick == null:
				_start()
		KEY_ESCAPE:
			SceneRouter.go_to(&"quick_fight" if quick != null else &"boot")

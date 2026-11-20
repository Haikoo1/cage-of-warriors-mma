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
var career_mode: bool = false
var weigh_in: Dictionary = {}
var fighter_names: Array = []
var tutorial: TutorialRunner
var player_focus: CombatSim.Focus = CombatSim.Focus.NORMAL
var paused: bool = false
var _end_timer: int = 0
var _break_timer: int = 0


func setup(params: Dictionary) -> void:
	quick = params.get("quick_fight")
	career_mode = bool(params.get("career", false))
	weigh_in = params.get("weigh_in", {})
	fighter_names = params.get("names", [])
	if bool(params.get("tutorial", false)):
		tutorial = TutorialRunner.new()


func _ready() -> void:
	player.relative_to_opponent = Settings.store.directions_relative_to_opponent
	view.show_blood = Settings.store.show_blood
	_start()
	AudioDirector.start_ambience(&"crowd_loop")
	AudioDirector.play(&"bell", -6.0, 0.0)


func _exit_tree() -> void:
	AudioDirector.stop_ambience()


func _play_sounds(events: Array[CombatEvent]) -> void:
	for e: CombatEvent in events:
		AudioDirector.play(CombatSounds.sound_for(e), -2.0)
		if CombatSounds.crowd_reacts(e):
			AudioDirector.play(&"crowd_roar", -4.0, 0.03)


func _start() -> void:
	var defs: Definitions = DataRegistry.definitions
	var setup_data: FightSetup
	if quick != null:
		setup_data = quick.setup
		hud.names = ["VOCÊ", "IA"]
		if quick.watch_only:
			hud.names = ["IA A", "IA B"]
		if career_mode and GameSession.career != null and not GameSession.career.state.booked.is_empty():
			var org: OrganizationDef = GameSession.career.defs.organization(StringName(GameSession.career.state.booked.get("org", "")))
			if org != null:
				hud.event_name = String(org.id).trim_prefix("org_").to_upper()
		if career_mode and GameSession.career != null:
			var gym: GymDef = GameSession.career.defs.gym(GameSession.career.state.gym_id)
			hud.max_tips = 2 if gym != null and gym.structure >= 3 else 1
		if fighter_names.size() == 2:
			hud.names = [String(fighter_names[0]), String(fighter_names[1])]
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
	hud.tutorial = tutorial
	hud.title_fight = setup_data.is_title
	var wc: WeightClassDef = defs.weight_class(setup_data.weight_class_id)
	hud.weight_name = wc.display_key if wc != null else ""
	if tutorial != null and not tutorial.is_done():
		dummy.mode = tutorial.current()["dummy"]
	_end_timer = 0


func _physics_process(_delta: float) -> void:
	hud.paused = paused
	hud.career_lock = career_mode
	if paused:
		hud.present([])
		return
	if sim.is_finished() and tutorial != null and not tutorial.is_done():
		_start()
		return
	if sim.is_finished():
		_end_timer += 1
		if quick != null and _end_timer == END_DELAY_FRAMES:
			var result: FightResult = sim.build_result(&"QUICK")
			if career_mode and GameSession.career != null:
				GameSession.career.finish_player_fight(result, weigh_in)
			SceneRouter.go_to(&"fight_result", {"result": result, "names": hud.names, "career": career_mode, "title": sim.total_rounds == sim.rules.rounds_title and quick.setup.is_title})
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
	var round_before: int = sim.round
	var events: Array[CombatEvent] = sim.step(cmd_a, cmd_b)
	_play_sounds(events)
	if tutorial != null and tutorial.feed(events, sim):
		AudioDirector.play(&"bell", -8.0, 0.0)
		if not tutorial.is_done():
			if bool(tutorial.current()["reset"]) or sim.is_finished():
				_start()
			dummy.mode = tutorial.current()["dummy"]
	if sim.phase == CombatSim.Phase.ROUND_BREAK:
		AudioDirector.play(&"bell", -6.0, 0.0)
	hud.dummy_mode = TrainingDummy.NAMES[dummy.mode]
	hud.present(events)


func _next_round() -> void:
	var focus_a: CombatSim.Focus = player_focus
	if quick != null and quick.ai_a != null:
		focus_a = quick.ai_a.choose_focus(sim)
	var focus_b: CombatSim.Focus = quick.ai_b.choose_focus(sim) if quick != null else CombatSim.Focus.NORMAL
	sim.begin_next_round(focus_a, focus_b)
	AudioDirector.play(&"bell", -6.0, 0.0)
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
		KEY_P:
			paused = not paused
		KEY_ESCAPE:
			if not paused:
				paused = true
			elif not career_mode:  # luta de carreira não pode ser abandonada (sem save no meio da luta, R-028)
				SceneRouter.go_to(&"quick_fight" if quick != null else &"boot")
			else:
				paused = false

class_name CombatFixture
extends RefCounted
## Monta definições e lutas mínimas em memória para testes de combate (sem ler data/).


static func strike(id: StringName, limb: StrikeDef.Limb, variant: StrikeDef.Variant, targets: PackedStringArray,
		reach: float, tolerance: float, startup: int, attr: StringName = &"boxe") -> StrikeDef:
	var s: StrikeDef = StrikeDef.new()
	s.id = id
	s.limb = limb
	s.variant = variant
	s.targets = targets
	s.base_reach_m = reach
	s.depth_tolerance_m = tolerance
	s.startup_frames = startup
	s.active_frames = 3
	s.recovery_frames = 10
	s.chain_window_frames = 6
	s.power = 10.0
	s.stamina_cost = 2.0
	s.technique_attribute = attr
	return s


static func defs() -> Definitions:
	var d: Definitions = Definitions.new()
	var wc: WeightClassDef = WeightClassDef.new()
	wc.id = &"wc_test"
	wc.limit_lb = 155.0
	wc.allowed_biotypes = PackedStringArray(["m_medium"])
	d.add(wc)
	var rs: RuleSetDef = RuleSetDef.new()
	rs.id = &"rs_test"
	d.add(rs)
	d.add(strike(&"jab", StrikeDef.Limb.LEAD_HAND, StrikeDef.Variant.STRAIGHT, PackedStringArray(["head", "body"]), 0.9, 0.3, 6))
	d.add(strike(&"hook", StrikeDef.Limb.LEAD_HAND, StrikeDef.Variant.CURVED, PackedStringArray(["head", "body"]), 0.6, 0.6, 10))
	d.add(strike(&"low_kick", StrikeDef.Limb.REAR_LEG, StrikeDef.Variant.STRAIGHT, PackedStringArray(["legs"]), 1.1, 0.6, 12, &"kickboxing"))
	d.add(CombatBalanceDef.new())
	# Técnicas de grappling vêm dos dados reais (também valida data/grappling).
	for t: GrappleTechniqueDef in DataLoader.load_from("res://data").grapple_techniques.values():
		d.add(t)
	return d


static func grapple(dir: FighterCommand.Direction = FighterCommand.Direction.NONE) -> FighterCommand:
	var c: FighterCommand = FighterCommand.new()
	c.grapple = true
	c.technique_direction = dir
	return c


static func direction(dir: FighterCommand.Direction) -> FighterCommand:
	var c: FighterCommand = FighterCommand.new()
	c.technique_direction = dir
	return c


## Coloca a luta direto em uma posição (atalho de teste).
static func set_position(s: CombatSim, position: StringName, top: int) -> void:
	s.grappling.transition(s, position, top)


## Roda até a disputa pendente terminar; devolve o evento de resolução.
static func run_until_grapple(s: CombatSim, cmd_a: FighterCommand, cmd_b: FighterCommand = null, max_steps: int = 60) -> CombatEvent:
	var events: Array[CombatEvent] = s.step(cmd_a, cmd_b if cmd_b != null else idle())
	for i: int in max_steps:
		for e: CombatEvent in events:
			if e.type == CombatEvent.Type.GRAPPLE_RESOLVED:
				return e
		events = s.step(idle(), idle())
	return null


static func sim(attr_a: float = 50.0, attr_b: float = 50.0, seed: int = 1) -> CombatSim:
	var setup: FightSetup = FightSetup.new()
	var fa: FighterState = FighterState.create_blank(&"F-A", attr_a)
	var fb: FighterState = FighterState.create_blank(&"F-B", attr_b)
	fa.physique.reach_cm = 180
	fb.physique.reach_cm = 180
	setup.fighter_a = FighterSnapshot.from_fighter(fa)
	setup.fighter_b = FighterSnapshot.from_fighter(fb)
	setup.ruleset_id = &"rs_test"
	setup.weight_class_id = &"wc_test"
	setup.seed = seed
	return CombatSim.new(setup, defs())


## Coloca os lutadores a uma distância em X e diferença em Z.
static func place(s: CombatSim, distance: float, dz: float = 0.0) -> void:
	s.fighters[0].x = -distance / 2.0
	s.fighters[1].x = distance / 2.0
	s.fighters[0].z = 0.0
	s.fighters[1].z = dz


static func idle() -> FighterCommand:
	return FighterCommand.new()


static func hit(limb: int, body: bool = false, curved: bool = false) -> FighterCommand:
	var c: FighterCommand = FighterCommand.new()
	c.strike_limb = limb
	c.mod_body = body
	c.mod_curved = curved
	return c


## Roda passos até o golpe do atacante A resolver; devolve o primeiro evento de golpe.
static func run_until_resolved(s: CombatSim, cmd_a: FighterCommand, cmd_b: FighterCommand = null, max_steps: int = 60) -> CombatEvent:
	var first_b: FighterCommand = cmd_b if cmd_b != null else idle()
	var events: Array[CombatEvent] = s.step(cmd_a, first_b)
	for i: int in max_steps:
		for e: CombatEvent in events:
			if e.type == CombatEvent.Type.STRIKE_RESOLVED and e.attacker == 0:
				return e
		events = s.step(idle(), first_b if cmd_b != null and cmd_b.guard else idle())
	return null

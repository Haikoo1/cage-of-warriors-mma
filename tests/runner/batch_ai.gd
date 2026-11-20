extends SceneTree
## Lote de lutas IA x IA headless para enxergar o balanceamento (insumo do marco M1 e da calibração M3).
## Uso: godot --headless --path . --script res://tests/runner/batch_ai.gd

const FIGHTS_PER_MATCHUP: int = 40
const ROUND_SECONDS: int = 300


func _initialize() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	var matchups: Array = [[0, 0], [0, 1], [1, 1], [2, 2]]
	for m: Array in matchups:
		var methods: Dictionary = {}
		var total_time: float = 0.0
		var wins_a: int = 0
		for k: int in FIGHTS_PER_MATCHUP:
			var cfg: QuickFight.Config = QuickFight.build(defs, m[0], m[1], 1, false, 3, true, 1000 + k)
			cfg.setup.round_seconds_override = ROUND_SECONDS
			var s: CombatSim = CombatSim.new(cfg.setup, defs)
			var guard: int = 0
			while not s.is_finished() and guard < 200000:
				guard += 1
				if s.phase == CombatSim.Phase.ROUND_BREAK:
					s.begin_next_round(cfg.ai_a.choose_focus(s), cfg.ai_b.choose_focus(s))
					continue
				cfg.ai_a.observe(s)
				cfg.ai_b.observe(s)
				s.step(cfg.ai_a.get_command(s), cfg.ai_b.get_command(s))
			var r: FightResult = s.build_result(&"B")
			var name: String = FightResult.Method.keys()[r.method]
			methods[name] = int(methods.get(name, 0)) + 1
			total_time += (r.round - 1) * ROUND_SECONDS + r.time_seconds
			if r.winner == FightResult.FighterSlot.A:
				wins_a += 1
		print("%s x %s: métodos=%s  tempo médio=%.0fs  vitórias A=%d/%d" % [QuickFight.STYLES[m[0]], QuickFight.STYLES[m[1]],
			str(methods), total_time / FIGHTS_PER_MATCHUP, wins_a, FIGHTS_PER_MATCHUP])
	quit(0)

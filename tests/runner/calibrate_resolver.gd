extends SceneTree
## Calibração M3: distribuição de métodos do resolvedor estatístico x lutas IA x IA no motor (docs/playtest/M1_COMBATE.md §1.3).
## Uso: godot --headless --path . --script res://tests/runner/calibrate_resolver.gd
const N: int = 400
const ENGINE: Dictionary = {  # finalizações (KO/TKO/SUB) em 40 lutas, medidas na E-05
	"Trocador x Trocador": 22, "Trocador x Wrestler": 11, "Wrestler x Wrestler": 14, "Equilibrado x Equilibrado": 4,
}
func _initialize() -> void:
	var matchups: Array = [[0, 0], [0, 1], [1, 1], [2, 2]]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var worst: float = 0.0
	for m: Array in matchups:
		var a: FighterState = QuickFight.fighter_for_style(&"A", "A", m[0])
		var b: FighterState = QuickFight.fighter_for_style(&"B", "B", m[1])
		var fin: int = 0
		var wins_a: int = 0
		for k: int in N:
			rng.seed = k
			var r: FightResult = FightResolver.resolve(a, b, 3, rng)
			if r.method in [FightResult.Method.KO, FightResult.Method.TKO, FightResult.Method.SUBMISSION]:
				fin += 1
			if r.winner == FightResult.FighterSlot.A:
				wins_a += 1
		var name: String = "%s x %s" % [QuickFight.STYLES[m[0]], QuickFight.STYLES[m[1]]]
		var res_pct: float = 100.0 * fin / N
		var eng_pct: float = 100.0 * ENGINE[name] / 40.0
		worst = maxf(worst, absf(res_pct - eng_pct))
		print("%s: finalizações resolvedor %.0f%% x motor %.0f%%  (vitórias A resolvedor %.0f%%)" % [name, res_pct, eng_pct, 100.0 * wins_a / N])
	print("CALIB %s maior diferença %.0f p.p. (meta ±10)" % ["OK" if worst <= 10.0 else "FORA", worst])
	quit(0)

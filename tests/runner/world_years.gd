extends SceneTree
## Marco M3 (ROADMAP §3): simula N anos de mundo e mede estabilidade e desempenho.
## Uso: godot --headless --path . --script res://tests/runner/world_years.gd

const YEARS: int = 10


func _initialize() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	var setup: CareerSetup = CareerSetup.new()
	setup.seed = 2026
	var c: CareerState = CareerFactory.new_career(defs, setup)
	c.player().retired = true  # mundo sozinho
	var start_pop: int = _active(c)
	var t0: int = Time.get_ticks_msec()
	var champ_changes: int = 0
	var last_champs: Dictionary = c.champions.duplicate()
	for year: int in YEARS:
		var ty: int = Time.get_ticks_msec()
		for w: int in 52:
			c.booked = {}
			c.offers.clear()
			WeekSimulator.simulate_week(c, defs)
		for k: String in c.champions:
			if c.champions[k] != last_champs.get(k, ""):
				champ_changes += 1
		last_champs = c.champions.duplicate()
		var methods: Dictionary = {}
		print("ano %d: ativos=%d  total=%d  tempo=%d ms" % [year + 1, _active(c), c.fighters.size(), Time.get_ticks_msec() - ty])
	var orphans: int = 0
	for k: String in c.champions:
		var f: FighterState = c.get_fighter(StringName(c.champions[k]))
		if f == null or f.retired:
			orphans += 1
	var ok: bool = absf(_active(c) - start_pop) / float(start_pop) < 0.25 and orphans == 0 and champ_changes > 20
	print("M3_%s ativos %d→%d · trocas de cinturão %d · campeões órfãos %d · %d anos em %.1f s" % [
		"OK" if ok else "FAIL", start_pop, _active(c), champ_changes, orphans, YEARS, (Time.get_ticks_msec() - t0) / 1000.0])
	quit(0 if ok else 1)


func _active(c: CareerState) -> int:
	var n: int = 0
	for f: FighterState in c.fighters.values():
		if not f.retired:
			n += 1
	return n

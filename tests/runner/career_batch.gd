extends SceneTree
## Lote de balanceamento da carreira (marco M4): carreiras com política automática simples.
## Uso: godot --headless --path . --script res://tests/runner/career_batch.gd
## A política aceita a primeira oferta, aceita convites, simula as próprias lutas e larga o trabalho paralelo
## quando tem mais de $ 15.000 — mede o que o sistema produz, não o melhor jogo possível.

const CAREERS: int = 10
const YEARS: int = 8


func _initialize() -> void:
	var defs: Definitions = DataLoader.load_from("res://data")
	var origins: Array[StringName] = [&"origin_wrestler", &"origin_bjj", &"origin_kickboxer", &"origin_mma"]
	var tier_reached: Array[int] = [0, 0, 0, 0, 0]
	var totals: Dictionary = {"fights": 0, "wins": 0, "titles": 0, "injury_weeks": 0, "negative_weeks": 0, "final_money": 0.0}
	var t0: int = Time.get_ticks_msec()
	for k: int in CAREERS:
		var setup: CareerSetup = CareerSetup.new()
		setup.seed = 900 + k
		setup.origin_id = origins[k % origins.size()]
		setup.age = 20 + k % 6
		var cc: CareerController = CareerController.create(defs, setup, 99)
		var s: CareerState = cc.state
		var best_tier: int = 1
		for w: int in YEARS * 52:
			if s.pending_interview:
				cc.answer_interview(w % 3)
			if cc.is_fight_week():
				cc.simulate_player_fight()
				continue
			for i: int in s.offers.size():
				if s.offers[i]["kind"] == "contract":
					cc.accept_offer(i)
					break
			if s.booked.is_empty():
				for i: int in s.offers.size():
					if s.offers[i]["kind"] == "fight":
						cc.accept_offer(i)
						break
			if s.money > 15000.0 and s.training_plan.has(&"side_job"):
				for b: int in s.training_plan.size():
					if s.training_plan[b] == &"side_job":
						cc.set_plan_block(b, &"sparring" if b % 2 == 0 else &"conditioning")
			WeekSimulator.simulate_week(s, defs)
			var p: FighterState = s.player()
			if not p.injury.is_empty():
				totals["injury_weeks"] += 1
			if s.money < 0.0:
				totals["negative_weeks"] += 1
			best_tier = maxi(best_tier, defs.organization(p.org_id).tier)
		var p2: FighterState = s.player()
		tier_reached[best_tier] += 1
		totals["fights"] += p2.wins + p2.losses + p2.draws
		totals["wins"] += p2.wins
		totals["titles"] += p2.titles
		totals["final_money"] += s.money
		print("carreira %d (%s, %d anos): %s · nível máx %d · títulos %d · $ %.0f · overall %.0f" % [k + 1, setup.origin_id,
			setup.age, p2.record_text(), best_tier, p2.titles, s.money, p2.overall()])
	var n: float = float(CAREERS)
	print("M4 lutas/ano %.1f · vitórias %.0f%% · títulos/carreira %.1f · semanas lesionado/ano %.1f · semanas no vermelho/ano %.1f · dinheiro final médio $ %.0f" % [
		totals["fights"] / n / YEARS, 100.0 * totals["wins"] / maxf(1.0, totals["fights"]), totals["titles"] / n,
		totals["injury_weeks"] / n / YEARS, totals["negative_weeks"] / n / YEARS, totals["final_money"] / n])
	print("M4 nível máximo alcançado: local %d · regional %d · continental %d · elite %d   (%.0f s)" % [
		tier_reached[1], tier_reached[2], tier_reached[3], tier_reached[4], (Time.get_ticks_msec() - t0) / 1000.0])
	CareerController.delete_slot(99)
	quit(0)

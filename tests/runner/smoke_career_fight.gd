extends SceneTree
## Smoke da luta JOGADA na carreira: IA no lugar do jogador, rounds de 1 min, até o resultado ser aplicado à carreira.
func _initialize() -> void:
	await process_frame
	var router: Node = root.get_node("SceneRouter")
	var defs: Definitions = root.get_node("DataRegistry").get("definitions")
	var holder: Node = Node.new()
	root.add_child(holder)
	router.call("set_screen_root", holder)
	var setup: CareerSetup = CareerSetup.new()
	setup.seed = 11
	setup.round_seconds = 60
	var cc: CareerController = CareerController.create(defs, setup, 7)
	root.get_node("GameSession").set("career", cc)
	var p: FighterState = cc.state.player()
	var opp: FighterState = null
	for f: FighterState in Rankings.roster(cc.state, p.org_id, p.weight_class_id):
		if f != p:
			opp = f
			break
	cc.state.booked = {"kind": "fight", "opponent": String(opp.id), "org": String(p.org_id), "week": cc.state.week_index,
		"title": false, "short": false, "show": 600.0, "win": 600.0, "expires": 0, "fights": 0}
	var prep: Dictionary = cc.prepare_fight()
	var cfg: QuickFight.Config = prep["config"]
	cfg.ai_a = CombatAI.new(defs.archetype(&"arch_striker"), defs.cognitive_profile(&"cog_intermediate"), 0, 5)
	var record_before: int = p.wins + p.losses + p.draws
	router.call("go_to", &"combat_test", {"quick_fight": cfg, "career": true, "weigh_in": prep["weigh_in"], "names": prep["names"]})
	for i: int in 60 * 60 * 5:
		await physics_frame
		var screen: Node = holder.get_child(holder.get_child_count() - 1)
		if screen.has_method("_next_round") and screen.get("sim") != null and (screen.get("sim") as CombatSim).phase == CombatSim.Phase.ROUND_BREAK:
			screen.call("_next_round")
		if screen.get("result") != null:
			var applied: bool = p.wins + p.losses + p.draws == record_before + 1 and cc.state.booked.is_empty()
			print("SMOKE_%s cartel=%s booked_vazio=%s" % ["OK" if applied else "FAIL", p.record_text(), cc.state.booked.is_empty()])
			CareerController.delete_slot(7)
			quit(0 if applied else 1)
			return
	print("SMOKE_FAIL luta não terminou")
	quit(1)

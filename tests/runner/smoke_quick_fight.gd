extends SceneTree
## Smoke da Luta Rápida IA x IA na cena real: rounds curtos, intervalos automáticos, até a tela de resultado.
## Uso: godot --headless --path . --script res://tests/runner/smoke_quick_fight.gd

const MAX_FRAMES: int = 60 * 60 * 6


func _initialize() -> void:
	# Autoloads são nós da árvore; espera um quadro para estarem prontos.
	await process_frame
	var router: Node = root.get_node("SceneRouter")
	var registry: Node = root.get_node("DataRegistry")
	var holder: Node = Node.new()
	root.add_child(holder)
	router.call("set_screen_root", holder)
	var cfg: QuickFight.Config = QuickFight.build(registry.get("definitions"), 0, 1, 1, false, 0, true, 42)
	router.call("go_to", &"combat_test", {"quick_fight": cfg})
	for i: int in MAX_FRAMES:
		await physics_frame
		var screen: Node = holder.get_child(holder.get_child_count() - 1) if holder.get_child_count() > 0 else null
		if screen != null and screen.get("result") != null:
			var r: FightResult = screen.get("result")
			print("SMOKE_OK método=%s round=%d tempo=%d cartelas=%s" % [FightResult.Method.keys()[r.method], r.round, r.time_seconds, str(r.scorecards)])
			quit(0)
			return
	print("SMOKE_FAIL luta não chegou à tela de resultado")
	quit(1)

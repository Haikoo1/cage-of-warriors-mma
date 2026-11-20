extends SceneTree
## Captura as poses de grappling (clinch e chão) numa luta IA x IA. Precisa de janela.
## Uso: godot --path . --resolution 1920x1080 --script res://tests/runner/shot_grapple.gd -- <pasta_saida>
func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://shots"
	await process_frame
	var router: Node = root.get_node("SceneRouter")
	var defs: Definitions = root.get_node("DataRegistry").get("definitions")
	var holder: Node = Node.new()
	root.add_child(holder)
	router.call("set_screen_root", holder)
	var cfg: QuickFight.Config = QuickFight.build(defs, 0, 1, 1, false, 0, true, 11)
	router.call("go_to", &"combat_test", {"quick_fight": cfg})
	for i: int in 20:
		await process_frame
	var screen: Node = holder.get_child(holder.get_child_count() - 1)
	var sim: CombatSim = screen.get("sim")
	for pos: StringName in [&"CL", &"SG", &"SM"]:
		sim.grappling.transition(sim, pos, 0)
		for i: int in 2:
			await process_frame
		var img: Image = root.get_viewport().get_texture().get_image()
		img.save_png(out.path_join("grapple_%s.png" % pos))
		print("SHOT ", pos, " ", sim.grappling.position)
	quit(0)

extends SceneTree
## Captura telas renderizadas (precisa de janela/GPU, não headless).
## Uso: godot --path . --resolution 1920x1080 --script res://tests/runner/screenshots.gd -- <pasta_saida>
func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://shots"
	await process_frame
	var router: Node = root.get_node("SceneRouter")
	var defs: Definitions = root.get_node("DataRegistry").get("definitions")
	var holder: Node = Node.new()
	root.add_child(holder)
	router.call("set_screen_root", holder)
	var setup: CareerSetup = CareerSetup.new()
	setup.name = "Lia Moreira"
	setup.weight_class_id = &"f_strawweight"
	setup.origin_id = &"origin_bjj"
	setup.seed = 5
	var cc: CareerController = CareerController.create(defs, setup, 6)
	for w: int in 6:
		cc.simulate_week()
	root.get_node("GameSession").set("career", cc)
	var cfg: QuickFight.Config = QuickFight.build(defs, 0, 1, 1, false, 0, true, 7)
	var shots: Array = [["boot", {}], ["quick_fight", {}], ["career_create", {}], ["career_dashboard", {}],
		["settings", {}], ["how_to_play", {}], ["combat_test", {"quick_fight": cfg}]]
	for s: Array in shots:
		router.call("go_to", StringName(s[0]), s[1])
		var frames: int = 200 if s[0] == "combat_test" else 6
		for i: int in frames:
			await process_frame
		var img: Image = root.get_viewport().get_texture().get_image()
		img.save_png(out.path_join("%s.png" % s[0]))
		print("SHOT ", s[0], " ", img.get_size())
	CareerController.delete_slot(6)
	quit(0)

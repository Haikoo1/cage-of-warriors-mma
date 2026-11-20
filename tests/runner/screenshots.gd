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
	cc.state.player().titles = 3
	root.get_node("GameSession").set("career", cc)
	var cfg: QuickFight.Config = QuickFight.build(defs, 0, 1, 1, true, 0, true, 7)
	var shots: Array = [["boot", {}], ["quick_fight", {}], ["career_create", {}], ["career_dashboard", {}], ["career_dashboard", {"tab": "5"}], ["career_dashboard", {"tab": "6"}],
		["settings", {}], ["how_to_play", {}], ["combat_test", {"quick_fight": cfg}]]
	for s: Array in shots:
		router.call("go_to", StringName(s[0]), s[1])
		var frames: int = 200 if s[0] == "combat_test" else 6
		for i: int in frames:
			await process_frame
		if s[0] == "career_dashboard" and String(s[1].get("tab", "")) != "":
			var ev: InputEventKey = InputEventKey.new()
			ev.physical_keycode = KEY_5 if String(s[1]["tab"]) == "5" else KEY_6
			ev.pressed = true
			holder.get_child(holder.get_child_count() - 1).call("_unhandled_input", ev)
			for i: int in 3:
				await process_frame
		var img: Image = root.get_viewport().get_texture().get_image()
		img.save_png(out.path_join("%s%s.png" % [s[0], String(s[1].get("tab", ""))]))
		print("SHOT ", s[0], " ", img.get_size())
	CareerController.delete_slot(6)
	quit(0)

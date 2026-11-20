extends SceneTree
## Smoke do tutorial interativo: abre a cena em modo tutorial, força a lição de sprawl e roda alguns segundos.
func _initialize() -> void:
	await process_frame
	var router: Node = root.get_node("SceneRouter")
	var holder: Node = Node.new()
	root.add_child(holder)
	router.call("set_screen_root", holder)
	router.call("go_to", &"combat_test", {"tutorial": true})
	await process_frame
	var screen: Node = holder.get_child(holder.get_child_count() - 1)
	var t: TutorialRunner = screen.get("tutorial")
	if t == null:
		print("SMOKE_FAIL tutorial não iniciou")
		quit(1)
		return
	t.index = 6  # sprawl: boneco wrestler ataca
	(screen.get("dummy") as TrainingDummy).mode = TrainingDummy.Mode.WRESTLER
	for i: int in 600:
		await physics_frame
	print("SMOKE_OK lição=%d posição=%s" % [t.index + 1, (screen.get("sim") as CombatSim).grappling.position])
	quit(0)

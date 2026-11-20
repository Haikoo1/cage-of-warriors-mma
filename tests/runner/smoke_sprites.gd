extends SceneTree
## Smoke dos sprites da E-06: carrega a folha, roda a cena de treino com sprites ligados e golpes do boneco.
func _initialize() -> void:
	await process_frame  # autoloads prontos antes de compilar as cenas
	var set: SpriteSet = SpriteSet.load_biotype("res://assets/sprites/fighters/m_medium", "m_medium")
	if set == null or set.textures.size() < 7:
		print("SMOKE_FAIL sprites não carregaram")
		quit(1)
		return
	var scene: Node = (load("res://scenes/combat/combat_test.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	(scene.get("view") as GreyboxView).use_sprites = true
	(scene.get("dummy") as TrainingDummy).mode = TrainingDummy.Mode.JAB
	var used: Dictionary = {}
	for i: int in 300:
		await physics_frame
		var sim: CombatSim = scene.get("sim")
		used[set.pick(sim.fighters[1], sim.frame)[0]] = true
	print("SMOKE_OK animações=%d usadas=%s" % [set.textures.size(), str(used.keys())])
	quit(0)

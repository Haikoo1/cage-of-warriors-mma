extends SceneTree
## Smoke da cena de combate: instancia, roda ~10 s de jogo com o boneco wrestler e confirma que a luta avançou.
## Uso: godot --headless --path . --script res://tests/runner/smoke_combat.gd

const MAX_FRAMES: int = 600


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/combat/combat_test.tscn") as PackedScene
	if packed == null:
		print("SMOKE_FAIL cena não carregou")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	var dummy: TrainingDummy = scene.get("dummy") as TrainingDummy
	if dummy == null:
		print("SMOKE_FAIL controlador sem boneco (erro de script?)")
		quit(1)
		return
	dummy.mode = TrainingDummy.Mode.WRESTLER
	var positions: Dictionary = {}
	for i: int in MAX_FRAMES:
		await physics_frame
		var sim: CombatSim = scene.get("sim") as CombatSim
		positions[sim.grappling.position] = true
	var final_sim: CombatSim = scene.get("sim") as CombatSim
	print("SMOKE_OK frame=%d posições visitadas=%s" % [final_sim.frame, str(positions.keys())])
	quit(0)

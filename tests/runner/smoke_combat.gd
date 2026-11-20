extends SceneTree
func _initialize() -> void:
	var scene: Node = (load("res://scenes/combat/combat_test.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	for i: int in 120:
		await physics_frame
	print("SMOKE_OK frame=", scene.get("sim").frame)
	quit()

extends TestCase
## Confirma na versão fixada (T-001) as configurações de T-011 (revisada: UI em HD + mundo pixel-perfect em SubViewport, D-018).


func test_pixel_perfect_settings() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 640)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 360)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items", "UI renderizada em HD")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep")
	assert_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0)
	assert_eq(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"), true)


func test_physics_runs_at_60_hz() -> void:
	assert_eq(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 60)


func test_five_autoloads() -> void:
	for autoload_name: String in ["DataRegistry", "Settings", "SceneRouter", "AudioDirector", "GameSession"]:
		assert_true(ProjectSettings.has_setting("autoload/" + autoload_name), autoload_name)


func test_combat_world_renders_in_pixel_perfect_subviewport() -> void:
	var scene: Node = (load("res://scenes/combat/combat_test.tscn") as PackedScene).instantiate()
	var vp: SubViewport = scene.get_node("PixelWorld/SubViewport") as SubViewport
	assert_eq(vp.size, Vector2i(960, 540), "mundo em 960x540 (D-022): 2x exato em 1080p")
	var view: Node2D = vp.get_node("GreyboxView") as Node2D
	assert_eq(view.scale, Vector2(1.5, 1.5), "lógica da vista em unidades de 640x360")
	assert_almost(GreyboxView.PPM * view.scale.x, 105.0, 0.001, "sprites (105 px/m) desenhados em 1:1")
	assert_eq(vp.canvas_item_default_texture_filter, Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
	assert_true(vp.get_node_or_null("GreyboxView") != null, "lutadores dentro da SubViewport")
	scene.free()

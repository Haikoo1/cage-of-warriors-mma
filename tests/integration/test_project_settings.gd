extends TestCase
## Confirma na versão fixada (T-001) os nomes e valores das configurações de T-011.


func test_pixel_perfect_settings() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 640)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 360)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer")
	assert_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0)
	assert_eq(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"), true)


func test_physics_runs_at_60_hz() -> void:
	assert_eq(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 60)


func test_five_autoloads() -> void:
	for autoload_name: String in ["DataRegistry", "Settings", "SceneRouter", "AudioDirector", "GameSession"]:
		assert_true(ProjectSettings.has_setting("autoload/" + autoload_name), autoload_name)

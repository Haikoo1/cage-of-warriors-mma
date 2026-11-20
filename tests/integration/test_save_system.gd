extends TestCase

const DIR: String = "user://test_saves/slot_test"


func _career() -> CareerState:
	var c: CareerState = CareerState.new()
	c.career_seed = 99
	c.week_index = 10
	var f: FighterState = FighterState.create_blank(c.next_id("F"), 45.0)
	c.add_fighter(f)
	c.player_fighter_id = f.id
	return c


func _clean() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		for file: String in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR.path_join(file))


func test_save_and_load_round_trip() -> void:
	_clean()
	var c: CareerState = _career()
	assert_eq(SaveSystem.save_career(c, DIR, "career", "manual"), OK)
	var res: SaveSystem.LoadResult = SaveSystem.load_career(DIR.path_join("career.json.gz"))
	assert_eq(res.error_message, "")
	assert_eq(res.career.to_dict(), c.to_dict())
	assert_false(FileAccess.file_exists(DIR.path_join("career.json.gz.tmp")), "sem .tmp")


func test_newer_schema_is_refused() -> void:
	_clean()
	DirAccess.make_dir_recursive_absolute(DIR)
	var path: String = DIR.path_join("future.json.gz")
	var file: FileAccess = FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	file.store_string(JSON.stringify({"schema_version": SaveSystem.CURRENT_SCHEMA + 1, "career": {}}))
	file.close()
	var errors: Array[String] = [SaveSystem.load_career(path).error_message]
	assert_has_error(errors, "versão mais nova")


func test_autosaves_rotate_and_fallback_skips_corrupted() -> void:
	_clean()
	var c: CareerState = _career()
	for week: int in [1, 2, 3, 4]:
		c.week_index = week
		assert_eq(SaveSystem.save_autosave(c, DIR), OK)
	assert_true(FileAccess.file_exists(DIR.path_join("auto_2.json.gz")), "3 rotativos")
	assert_false(FileAccess.file_exists(DIR.path_join("auto_3.json.gz")), "no máximo 3")
	var corrupt: FileAccess = FileAccess.open(DIR.path_join("auto_0.json.gz"), FileAccess.WRITE)
	corrupt.store_string("lixo")
	corrupt.close()
	var res: SaveSystem.LoadResult = SaveSystem.load_latest_valid(DIR)
	assert_eq(res.error_message, "")
	assert_eq(res.career.week_index, 3, "caiu para auto_1")


func test_envelope_contains_version_metadata() -> void:
	var env: Dictionary = SaveSystem.build_envelope(_career(), "week_start")
	assert_eq(env["schema_version"], SaveSystem.CURRENT_SCHEMA)
	assert_true(env.has("game_version") and env.has("saved_at") and env.has("career"), "campos")


func test_v1_save_migrates_to_current() -> void:
	_clean()
	DirAccess.make_dir_recursive_absolute(DIR)
	var path: String = DIR.path_join("v1.json.gz")
	var file: FileAccess = FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	file.store_string(JSON.stringify({"schema_version": 1, "career": _career().to_dict()}))
	file.close()
	var res: SaveSystem.LoadResult = SaveSystem.load_career(path)
	assert_eq(res.error_message, "", "migrou")
	assert_eq(res.career.week_index, 10)

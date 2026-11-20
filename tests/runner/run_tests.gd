extends SceneTree
## Runner próprio de testes (T-009). Uso:
##   godot --headless --path . --script res://tests/runner/run_tests.gd
## Sai com código 1 se algum teste falhar ou não fizer asserções.
## Erros de script não interrompem a Godot: use tests/run_tests.ps1, que também falha com "SCRIPT ERROR".

const TEST_DIRS: Array[String] = ["res://tests/unit", "res://tests/integration"]


func _initialize() -> void:
	var files: Array[String] = []
	for dir: String in TEST_DIRS:
		_collect(dir, files)
	files.sort()
	var total: int = 0
	var failed: int = 0
	for path: String in files:
		var script: GDScript = load(path) as GDScript
		if script == null or not script.can_instantiate():
			print("  FALHA ao carregar (erro de script) ", path)
			failed += 1
			continue
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			var test: TestCase = script.new() as TestCase
			test.call(method_name)
			if test.assertions == 0:
				test.failures.append("teste sem asserções (pode ter abortado por erro de script)")
			if test.failures.is_empty():
				print("  ok   ", path.get_file(), " :: ", method_name)
			else:
				failed += 1
				print("  FALHA ", path.get_file(), " :: ", method_name)
				for f: String in test.failures:
					print("        - ", f)
	print("\n%d testes, %d falhas" % [total, failed])
	quit(1 if failed > 0 else 0)


func _collect(dir: String, out: Array[String]) -> void:
	for file: String in DirAccess.get_files_at(dir):
		if file.begins_with("test_") and file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(sub), out)

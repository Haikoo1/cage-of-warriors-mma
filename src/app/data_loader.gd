class_name DataLoader
extends RefCounted
## Carrega as definições de data/ (camada de aplicação: usa ResourceLoader e DirAccess).

const FOLDERS: Array[String] = ["weight_classes", "strikes", "rulesets", "balance", "grappling", "ai"]


static func load_from(root: String) -> Definitions:
	var defs: Definitions = Definitions.new()
	for folder: String in FOLDERS:
		var dir: String = root.path_join(folder)
		if not DirAccess.dir_exists_absolute(dir):
			continue
		for file: String in DirAccess.get_files_at(dir):
			# Em builds exportadas os .tres aparecem como .tres.remap.
			var name: String = file.trim_suffix(".remap")
			if not name.ends_with(".tres"):
				continue
			var res: Resource = ResourceLoader.load(dir.path_join(name))
			if res == null:
				defs.load_errors.append("falha ao carregar %s" % dir.path_join(name))
				continue
			defs.add(res)
	return defs

class_name SaveSystem
extends RefCounted
## Persistência da carreira (SAVE_AND_TESTING §1, T-007): JSON + gzip, escrita atômica, autosaves rotativos.

const CURRENT_SCHEMA: int = 3
const AUTOSAVE_COUNT: int = 3
const EXT: String = ".json.gz"


class LoadResult:
	var career: CareerState
	var error_message: String = ""


static func build_envelope(career: CareerState, trigger: String) -> Dictionary:
	return {
		"schema_version": CURRENT_SCHEMA,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"saved_at": Time.get_datetime_string_from_system(true),
		"trigger": trigger,
		"career": career.to_dict(),
	}


static func save_career(career: CareerState, dir: String, base_name: String, trigger: String) -> Error:
	var err: Error = DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		return err
	var path: String = dir.path_join(base_name + EXT)
	var tmp: String = path + ".tmp"
	var text: String = JSON.stringify(build_envelope(career, trigger))
	var file: FileAccess = FileAccess.open_compressed(tmp, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.close()
	# Verificação de leitura antes de substituir o arquivo anterior.
	if _read_text(tmp) != text:
		DirAccess.remove_absolute(tmp)
		push_error("SaveSystem: verificação de leitura falhou em %s" % tmp)
		return ERR_FILE_CORRUPT
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path)


static func save_autosave(career: CareerState, dir: String) -> Error:
	DirAccess.make_dir_recursive_absolute(dir)
	for i: int in range(AUTOSAVE_COUNT - 1, 0, -1):
		var older: String = dir.path_join("auto_%d%s" % [i - 1, EXT])
		var newer: String = dir.path_join("auto_%d%s" % [i, EXT])
		if FileAccess.file_exists(older):
			if FileAccess.file_exists(newer):
				DirAccess.remove_absolute(newer)
			DirAccess.rename_absolute(older, newer)
	return save_career(career, dir, "auto_0", "autosave")


static func load_career(path: String) -> LoadResult:
	var res: LoadResult = LoadResult.new()
	var text: String = _read_text(path)
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	if not parsed is Dictionary:
		res.error_message = "arquivo ilegível ou corrompido: %s" % path
		return res
	var doc: Dictionary = parsed
	var version: int = int(doc.get("schema_version", 0))
	if version > CURRENT_SCHEMA:
		res.error_message = "save de versão mais nova (%d) que o jogo (%d)" % [version, CURRENT_SCHEMA]
		return res
	while version < CURRENT_SCHEMA:
		var migrated: Variant = migrate(version, doc)
		if migrated == null:
			res.error_message = "sem migração a partir da versão %d" % version
			return res
		doc = migrated
		version += 1
	if not doc.get("career") is Dictionary:
		res.error_message = "save sem dados de carreira"
		return res
	res.career = CareerState.from_dict(doc["career"])
	return res


## Tenta o save manual e depois os autosaves, do mais novo para o mais antigo (SAVE_AND_TESTING §1.7).
static func load_latest_valid(dir: String) -> LoadResult:
	var candidates: Array[String] = []
	for i: int in AUTOSAVE_COUNT:
		candidates.append(dir.path_join("auto_%d%s" % [i, EXT]))
	candidates.append(dir.path_join("career" + EXT))
	var last: LoadResult = LoadResult.new()
	last.error_message = "nenhum save encontrado em %s" % dir
	for path: String in candidates:
		if not FileAccess.file_exists(path):
			continue
		last = load_career(path)
		if last.error_message == "":
			return last
		push_warning("SaveSystem: %s" % last.error_message)
	return last


static func _read_text(path: String) -> String:
	var file: FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


## Migrações em cadeia v_n → v_n+1 (SAVE_AND_TESTING §1.6). Devolve null se não houver migração.
static func migrate(from_version: int, doc: Dictionary) -> Variant:
	match from_version:
		1:
			# v2 (E-07): carreira completa. Campos novos têm padrão em from_dict; nada a converter.
			var d: Dictionary = doc.duplicate(true)
			d["schema_version"] = 2
			return d
		2:
			# v3 (D-022): criador de personagem ampliado. Barba booleana vira estilo (true -> rente), físico padrão
			# atlético, e os cabelos 1..3 antigos (curto, moicano, coque) passam a 2..4.
			var d3: Dictionary = doc.duplicate(true)
			d3["schema_version"] = 3
			var career: Variant = d3.get("career")
			if career is Dictionary:
				for fd: Variant in (career as Dictionary).get("fighters", []):
					if fd is Dictionary and (fd as Dictionary).get("appearance") is Dictionary:
						var ap: Dictionary = fd["appearance"]
						ap["beard"] = 1 if bool(ap.get("beard", false)) else 0
						ap["build"] = int(ap.get("build", 1))
						var hs: int = int(ap.get("hair_style", 1))
						ap["hair_style"] = hs + 1 if hs > 0 else 0
			return d3
	return null

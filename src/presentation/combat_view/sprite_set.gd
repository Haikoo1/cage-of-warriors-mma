class_name SpriteSet
extends RefCounted
## Spritesheets de um biotipo geradas pelo pipeline 3D → pixel (E-06, tools/art_pipeline/pipeline.py).
## Escolhe animação e quadro a partir do ESTADO da simulação (ART §6.1): a arte acompanha os dados.

var frame_size: Vector2i
var anchor: Vector2
var px_per_m: float
var sim_frames_per_sprite: int = 4
var textures: Dictionary = {}  # nome -> Texture2D
var frames: Dictionary = {}  # nome -> quantidade de quadros


static func load_biotype(dir: String, biotype: String) -> SpriteSet:
	var meta_path: String = dir.path_join(biotype + ".json")
	if not FileAccess.file_exists(meta_path):
		return null
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	var s: SpriteSet = SpriteSet.new()
	s.frame_size = Vector2i(int(meta["frame_size"][0]), int(meta["frame_size"][1]))
	s.anchor = Vector2(float(meta["anchor"][0]), float(meta["anchor"][1]))
	s.px_per_m = float(meta["px_per_m"])
	s.sim_frames_per_sprite = int(meta["sim_frames_per_sprite"])
	for anim: String in meta["animations"]:
		var tex: Texture2D = load(dir.path_join(anim + ".png")) as Texture2D
		if tex != null:
			s.textures[anim] = tex
			s.frames[anim] = int(meta["animations"][anim]["frames"])
	return s


## Animação e quadro para um lutador. `elapsed` = quadros de simulação desde o início da ação.
func pick(f: FighterCombatState, sim_frame: int) -> Array:
	var anim: String = "guard"
	var index: int = (sim_frame / sim_frames_per_sprite) % int(frames.get("guard", 1))
	if f.is_striking() and f.strike != null and textures.has(String(f.strike.id)):
		anim = String(f.strike.id)
		index = _phase_frame(f, anim)
	elif f.action == FighterCombatState.Action.GRAPPLING and textures.has("double_leg"):
		anim = "double_leg"
		index = mini(int(frames[anim]) - 1, (int(frames[anim]) - 1) * (1.0 - float(f.action_frames_left) / 20.0))
	elif f.action == FighterCombatState.Action.ROCKED or f.action == FighterCombatState.Action.STUNNED:
		anim = "hit_head"
		index = 1
	elif f.moved_this_step and textures.has("walk"):
		anim = "walk"
		index = (sim_frame / sim_frames_per_sprite) % int(frames["walk"])
	return [anim, clampi(index, 0, int(frames.get(anim, 1)) - 1)]


## Progresso dentro do golpe: preparação → execução → recuperação mapeados nos quadros da folha.
func _phase_frame(f: FighterCombatState, anim: String) -> int:
	var s: StrikeDef = f.strike
	var total: int = s.total_frames()
	var done: int
	match f.action:
		FighterCombatState.Action.STRIKE_STARTUP:
			done = s.startup_frames - f.action_frames_left
		FighterCombatState.Action.STRIKE_ACTIVE:
			done = s.startup_frames + s.active_frames - f.action_frames_left
		_:
			done = total - f.action_frames_left
	return int(float(clampi(done, 0, total)) / float(total) * (int(frames[anim]) - 1) + 0.5)

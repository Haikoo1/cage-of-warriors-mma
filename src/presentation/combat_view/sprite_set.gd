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
var hair: Dictionary = {}  # estilo (int) -> {anim -> Texture2D}
var beard: Dictionary = {}  # anim -> Texture2D
var palette: Dictionary = {}
var far_darken: float = 0.72


static var _cache: Dictionary = {}


## Família de sprites disponível para um biótipo de dados (por enquanto 1 masculina e 1 feminina).
static func family_for(biotype_id: StringName) -> String:
	return "f_medium" if String(biotype_id).begins_with("f_") else "m_medium"


static func for_biotype(biotype_id: StringName) -> SpriteSet:
	var fam: String = family_for(biotype_id)
	if not _cache.has(fam):
		_cache[fam] = load_biotype("res://assets/sprites/fighters/" + fam, fam)
	return _cache[fam]


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
		for style: Variant in meta.get("hair_styles", []):
			var ht: Texture2D = load(dir.path_join("%s__hair%d.png" % [anim, int(style)])) as Texture2D
			if ht != null:
				if not s.hair.has(int(style)):
					s.hair[int(style)] = {}
				s.hair[int(style)][anim] = ht
		if bool(meta.get("beard", false)):
			s.beard[anim] = load(dir.path_join("%s__beard.png" % anim)) as Texture2D
	s.palette = meta.get("palette", {})
	s.far_darken = float(meta.get("far_darken", 0.72))
	return s


func hair_layer(style: int, anim: String) -> Texture2D:
	return (hair.get(style, {}) as Dictionary).get(anim) as Texture2D


func beard_layer(anim: String) -> Texture2D:
	return beard.get(anim) as Texture2D


const EVADE_ANIMS: Dictionary = {
	FighterCombatState.Evade.SLIP: "slip", FighterCombatState.Evade.DUCK: "duck", FighterCombatState.Evade.PULL: "pull",
}
## Técnicas em pé que usam a animação de queda (as demais ficam em guarda até o solo/clinch).
const TAKEDOWN_TECHNIQUES: Array[StringName] = [&"double_leg", &"single_leg"]
const EVADE_FRAMES: int = 14


## Animação e quadro para um lutador. `technique` = técnica de grappling em preparação por ele, se houver.
func pick(f: FighterCombatState, sim_frame: int, technique: GrappleTechniqueDef = null) -> Array:
	var anim: String = "guard"
	var index: int = (sim_frame / sim_frames_per_sprite) % int(frames.get("guard", 1))
	if f.is_striking() and f.strike != null and textures.has(String(f.strike.id)):
		anim = String(f.strike.id)
		index = _phase_frame(f, anim)
	elif f.action == FighterCombatState.Action.EVADING and EVADE_ANIMS.has(f.evade):
		anim = EVADE_ANIMS[f.evade]
		index = _progress_frame(anim, EVADE_FRAMES - f.action_frames_left, EVADE_FRAMES)
	elif f.action == FighterCombatState.Action.DOWN or f.action == FighterCombatState.Action.OUT:
		anim = "down"
		index = 0
	elif f.action == FighterCombatState.Action.GRAPPLING and technique != null and TAKEDOWN_TECHNIQUES.has(technique.id):
		anim = "double_leg"
		index = _progress_frame(anim, technique.startup_frames - f.action_frames_left, technique.startup_frames)
	elif f.action == FighterCombatState.Action.ROCKED or f.action == FighterCombatState.Action.STUNNED:
		anim = "hit_head"
		index = 1
	elif f.moved_this_step and textures.has("walk"):
		anim = "walk"
		index = (sim_frame / sim_frames_per_sprite) % int(frames["walk"])
	if not textures.has(anim):
		anim = "guard"
		index = 0
	return [anim, clampi(index, 0, int(frames.get(anim, 1)) - 1)]


func _progress_frame(anim: String, done: int, total: int) -> int:
	return int(float(clampi(done, 0, total)) / float(maxi(1, total)) * (int(frames.get(anim, 1)) - 1) + 0.5)


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

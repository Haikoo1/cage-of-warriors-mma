class_name Appearance
extends RefCounted
## Aparência do lutador (CHARACTER §8, criador de personagem D-019/D-022): só apresentação, nenhum efeito em regra.
## Cada cor é dada pelos extremos [escuro, claro]; a rampa de 6 tons é interpolada e aplicada por troca de paleta
## sobre as camadas renderizadas pelo pipeline (corpo por físico, cabelo, barba).

const TONES: int = 6

## 8 tons de pele com a mesma qualidade de detalhe (ART §4).
const SKIN_TONES: Array = [
	[[0.40, 0.24, 0.18], [1.00, 0.88, 0.78]], [[0.34, 0.19, 0.13], [0.97, 0.80, 0.66]],
	[[0.24, 0.12, 0.08], [0.94, 0.76, 0.60]], [[0.20, 0.10, 0.06], [0.86, 0.64, 0.46]],
	[[0.15, 0.08, 0.05], [0.74, 0.52, 0.36]], [[0.10, 0.05, 0.03], [0.60, 0.40, 0.28]],
	[[0.07, 0.04, 0.03], [0.46, 0.31, 0.22]], [[0.22, 0.14, 0.07], [0.90, 0.76, 0.54]],
]
const HAIR_COLORS: Array = [
	[[0.04, 0.03, 0.03], [0.30, 0.24, 0.22]], [[0.08, 0.05, 0.03], [0.50, 0.34, 0.22]],
	[[0.30, 0.20, 0.08], [0.98, 0.88, 0.58]], [[0.24, 0.06, 0.03], [0.92, 0.50, 0.26]],
	[[0.26, 0.26, 0.28], [0.92, 0.92, 0.94]], [[0.04, 0.08, 0.24], [0.46, 0.64, 0.98]],
]
const SHORTS_COLORS: Array = [
	[[0.04, 0.06, 0.24], [0.36, 0.52, 0.98]], [[0.26, 0.03, 0.04], [0.98, 0.38, 0.32]],
	[[0.04, 0.04, 0.05], [0.34, 0.34, 0.37]], [[0.50, 0.50, 0.48], [1.00, 1.00, 0.97]],
	[[0.03, 0.18, 0.07], [0.40, 0.84, 0.44]], [[0.32, 0.20, 0.02], [1.00, 0.90, 0.44]],
	[[0.18, 0.04, 0.26], [0.80, 0.46, 0.98]], [[0.36, 0.10, 0.02], [1.00, 0.64, 0.34]],
]
const GLOVE_COLORS: Array = [
	[[0.30, 0.03, 0.04], [0.97, 0.38, 0.34]], [[0.03, 0.06, 0.24], [0.34, 0.48, 0.96]],
	[[0.04, 0.04, 0.05], [0.32, 0.32, 0.35]], [[0.50, 0.50, 0.48], [1.00, 1.00, 0.97]],
	[[0.32, 0.20, 0.02], [1.00, 0.90, 0.44]], [[0.03, 0.18, 0.07], [0.40, 0.84, 0.44]],
]
const ACCENT_RED: Array = [[0.30, 0.03, 0.04], [0.97, 0.38, 0.34]]
const ACCENT_WHITE: Array = [[0.50, 0.50, 0.48], [1.00, 1.00, 0.97]]
const SKIN_NAMES: Array[String] = ["Clara", "Média clara", "Média", "Morena", "Morena escura", "Escura", "Muito escura", "Oliva"]
const HAIR_STYLE_NAMES: Array[String] = ["Careca", "Raspado", "Curto", "Moicano", "Coque", "Black power", "Rabo de cavalo", "Dreads", "Topete"]
const HAIR_COLOR_NAMES: Array[String] = ["Preto", "Castanho", "Loiro", "Ruivo", "Grisalho", "Azul"]
const BEARD_NAMES: Array[String] = ["Nenhuma", "Rente", "Cheia", "Cavanhaque", "Bigode"]
const BUILD_NAMES: Array[String] = ["Magro", "Atlético", "Musculoso", "Pesado"]
const SHORTS_NAMES: Array[String] = ["Azul", "Vermelho", "Preto", "Branco", "Verde", "Dourado", "Roxo", "Laranja"]
const GLOVE_NAMES: Array[String] = ["Vermelha", "Azul", "Preta", "Branca", "Dourada", "Verde"]

var skin: int = 2
var build: int = 1  # 0 magro, 1 atlético, 2 musculoso, 3 pesado (só visual, dentro do biótipo da categoria)
var hair_style: int = 2  # índice em HAIR_STYLE_NAMES; 0 = careca
var hair_color: int = 1
var beard: int = 0  # índice em BEARD_NAMES; 0 = sem barba
var shorts: int = 2
var gloves: int = 2


static func random(rng: RandomNumberGenerator, male: bool) -> Appearance:
	var a: Appearance = Appearance.new()
	a.skin = rng.randi_range(0, SKIN_TONES.size() - 1)
	a.build = [0, 1, 1, 1, 2, 2, 3][rng.randi_range(0, 6)]
	a.hair_style = rng.randi_range(0, HAIR_STYLE_NAMES.size() - 1) if male else rng.randi_range(1, HAIR_STYLE_NAMES.size() - 1)
	a.hair_color = rng.randi_range(0, 4)
	a.beard = rng.randi_range(1, BEARD_NAMES.size() - 1) if male and rng.randf() < 0.4 else 0
	a.shorts = rng.randi_range(0, SHORTS_COLORS.size() - 1)
	a.gloves = rng.randi_range(0, GLOVE_COLORS.size() - 1)
	return a


## Rampa de 6 tons (escuro -> claro) a partir dos extremos.
static func tones(ends: Array) -> Array:
	var out: Array = []
	for k: int in TONES:
		var t: float = float(k) / float(TONES - 1)
		out.append([lerpf(ends[0][0], ends[1][0], t), lerpf(ends[0][1], ends[1][1], t), lerpf(ends[0][2], ends[1][2], t)])
	return out


## Pares (origem -> destino) para o shader. `palette` vem do JSON do pipeline. Com far_darken < 1 inclui também
## os tons escurecidos do lado longe (sprites antigos); o pipeline v3 usa 1,0 (sem lado longe).
func palette_pairs(palette: Dictionary, far_darken: float) -> Array:
	var src: PackedColorArray = []
	var dst: PackedColorArray = []
	var targets: Dictionary = {
		"skin": SKIN_TONES[skin], "hair": HAIR_COLORS[hair_color], "shorts": SHORTS_COLORS[shorts],
		"glove": GLOVE_COLORS[gloves], "accent": ACCENT_WHITE if shorts == 1 else ACCENT_RED,
	}
	var variants: Array[float] = [1.0]
	if far_darken < 0.999:
		variants.append(far_darken)
	for mat: String in ["skin", "hair", "shorts", "glove", "accent"]:
		var from: Array = palette.get(mat, [])
		var to: Array = tones(targets[mat])
		for k: int in mini(from.size(), to.size()):
			for darken: float in variants:
				src.append(Color(float(from[k][0]) * darken, float(from[k][1]) * darken, float(from[k][2]) * darken))
				dst.append(Color(float(to[k][0]) * darken, float(to[k][1]) * darken, float(to[k][2]) * darken))
	return [src, dst]


func to_dict() -> Dictionary:
	return {"skin": skin, "build": build, "hair_style": hair_style, "hair_color": hair_color, "beard": beard,
		"shorts": shorts, "gloves": gloves}


static func from_dict(d: Dictionary) -> Appearance:
	var a: Appearance = Appearance.new()
	a.skin = clampi(int(d.get("skin", a.skin)), 0, SKIN_TONES.size() - 1)
	a.build = clampi(int(d.get("build", a.build)), 0, BUILD_NAMES.size() - 1)
	a.hair_style = clampi(int(d.get("hair_style", a.hair_style)), 0, HAIR_STYLE_NAMES.size() - 1)
	a.hair_color = clampi(int(d.get("hair_color", a.hair_color)), 0, HAIR_COLORS.size() - 1)
	a.beard = clampi(int(d.get("beard", a.beard)), 0, BEARD_NAMES.size() - 1)
	a.shorts = clampi(int(d.get("shorts", a.shorts)), 0, SHORTS_COLORS.size() - 1)
	a.gloves = clampi(int(d.get("gloves", a.gloves)), 0, GLOVE_COLORS.size() - 1)
	return a


func duplicate_appearance() -> Appearance:
	return Appearance.from_dict(to_dict())

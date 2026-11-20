class_name Appearance
extends RefCounted
## Aparência do lutador (CHARACTER §8, criador de visual): só apresentação, nenhum efeito em regra.
## As cores são rampas de 4 tons aplicadas por troca de paleta sobre as camadas renderizadas pelo pipeline.

## 8 tons de pele com a mesma qualidade de detalhe (ART §4).
const SKIN_TONES: Array = [
	[[0.42, 0.25, 0.17], [0.66, 0.44, 0.31], [0.85, 0.64, 0.49], [0.98, 0.84, 0.70]],
	[[0.40, 0.22, 0.14], [0.62, 0.38, 0.25], [0.80, 0.55, 0.39], [0.94, 0.74, 0.58]],
	[[0.36, 0.19, 0.11], [0.56, 0.33, 0.20], [0.72, 0.47, 0.31], [0.86, 0.63, 0.46]],
	[[0.30, 0.16, 0.09], [0.48, 0.28, 0.16], [0.64, 0.40, 0.25], [0.78, 0.54, 0.37]],
	[[0.24, 0.13, 0.08], [0.40, 0.23, 0.13], [0.55, 0.34, 0.21], [0.68, 0.46, 0.31]],
	[[0.18, 0.10, 0.06], [0.31, 0.18, 0.11], [0.44, 0.27, 0.17], [0.57, 0.38, 0.26]],
	[[0.13, 0.07, 0.05], [0.23, 0.13, 0.08], [0.34, 0.21, 0.14], [0.46, 0.31, 0.22]],
	[[0.38, 0.24, 0.15], [0.60, 0.42, 0.27], [0.78, 0.60, 0.40], [0.92, 0.78, 0.58]],
]
const HAIR_COLORS: Array = [
	[[0.05, 0.04, 0.04], [0.10, 0.08, 0.08], [0.17, 0.14, 0.13], [0.26, 0.22, 0.20]],  # preto
	[[0.10, 0.06, 0.03], [0.22, 0.13, 0.07], [0.36, 0.22, 0.12], [0.52, 0.34, 0.20]],  # castanho
	[[0.36, 0.24, 0.08], [0.62, 0.44, 0.16], [0.84, 0.66, 0.30], [0.98, 0.86, 0.52]],  # loiro
	[[0.30, 0.08, 0.03], [0.52, 0.16, 0.06], [0.74, 0.30, 0.12], [0.92, 0.48, 0.24]],  # ruivo
	[[0.30, 0.30, 0.32], [0.50, 0.50, 0.52], [0.70, 0.70, 0.72], [0.88, 0.88, 0.90]],  # grisalho
	[[0.06, 0.12, 0.30], [0.12, 0.24, 0.56], [0.22, 0.40, 0.82], [0.46, 0.64, 0.98]],  # azul
]
const SHORTS_COLORS: Array = [
	[[0.05, 0.07, 0.30], [0.10, 0.16, 0.55], [0.16, 0.28, 0.80], [0.32, 0.48, 0.98]],  # azul
	[[0.30, 0.04, 0.05], [0.55, 0.08, 0.09], [0.78, 0.14, 0.14], [0.96, 0.34, 0.30]],  # vermelho
	[[0.04, 0.04, 0.05], [0.09, 0.09, 0.11], [0.16, 0.16, 0.19], [0.28, 0.28, 0.32]],  # preto
	[[0.55, 0.55, 0.52], [0.76, 0.76, 0.72], [0.90, 0.90, 0.87], [1.00, 1.00, 0.97]],  # branco
	[[0.04, 0.22, 0.08], [0.08, 0.40, 0.14], [0.14, 0.60, 0.22], [0.36, 0.82, 0.40]],  # verde
	[[0.36, 0.24, 0.02], [0.66, 0.46, 0.04], [0.92, 0.70, 0.10], [1.00, 0.88, 0.40]],  # dourado
	[[0.22, 0.05, 0.30], [0.40, 0.10, 0.55], [0.58, 0.20, 0.78], [0.78, 0.42, 0.96]],  # roxo
	[[0.40, 0.12, 0.02], [0.70, 0.24, 0.04], [0.94, 0.42, 0.10], [1.00, 0.64, 0.34]],  # laranja
]
const GLOVE_COLORS: Array = [
	[[0.32, 0.03, 0.04], [0.58, 0.06, 0.07], [0.82, 0.13, 0.12], [1.00, 0.38, 0.30]],  # vermelho
	[[0.03, 0.06, 0.26], [0.06, 0.12, 0.48], [0.12, 0.24, 0.74], [0.32, 0.46, 0.94]],  # azul
	[[0.04, 0.04, 0.05], [0.09, 0.09, 0.11], [0.17, 0.17, 0.20], [0.30, 0.30, 0.34]],  # preto
	[[0.55, 0.55, 0.52], [0.76, 0.76, 0.72], [0.90, 0.90, 0.87], [1.00, 1.00, 0.97]],  # branco
	[[0.36, 0.24, 0.02], [0.66, 0.46, 0.04], [0.92, 0.70, 0.10], [1.00, 0.88, 0.40]],  # dourado
	[[0.04, 0.22, 0.08], [0.08, 0.40, 0.14], [0.14, 0.60, 0.22], [0.36, 0.82, 0.40]],  # verde
]
const SKIN_NAMES: Array[String] = ["Clara", "Média clara", "Média", "Morena", "Morena escura", "Escura", "Muito escura", "Oliva"]
const HAIR_STYLE_NAMES: Array[String] = ["Careca", "Curto", "Moicano", "Coque"]
const HAIR_COLOR_NAMES: Array[String] = ["Preto", "Castanho", "Loiro", "Ruivo", "Grisalho", "Azul"]
const SHORTS_NAMES: Array[String] = ["Azul", "Vermelho", "Preto", "Branco", "Verde", "Dourado", "Roxo", "Laranja"]
const GLOVE_NAMES: Array[String] = ["Vermelha", "Azul", "Preta", "Branca", "Dourada", "Verde"]

var skin: int = 1
var hair_style: int = 1  # 0 careca, 1 curto, 2 moicano, 3 coque
var hair_color: int = 1
var beard: bool = false
var shorts: int = 0
var gloves: int = 0


static func random(rng: RandomNumberGenerator, male: bool) -> Appearance:
	var a: Appearance = Appearance.new()
	a.skin = rng.randi_range(0, SKIN_TONES.size() - 1)
	a.hair_style = rng.randi_range(0, 3) if male else rng.randi_range(1, 3)
	a.hair_color = rng.randi_range(0, 4)
	a.beard = male and rng.randf() < 0.35
	a.shorts = rng.randi_range(0, SHORTS_COLORS.size() - 1)
	a.gloves = rng.randi_range(0, GLOVE_COLORS.size() - 1)
	return a


## Pares (origem -> destino) para o shader. `palette` vem do JSON do pipeline; inclui os tons do lado longe.
func palette_pairs(palette: Dictionary, far_darken: float) -> Array:
	var src: PackedColorArray = []
	var dst: PackedColorArray = []
	var targets: Dictionary = {
		"skin": SKIN_TONES[skin], "hair": HAIR_COLORS[hair_color], "shorts": SHORTS_COLORS[shorts],
		"stripe": SHORTS_COLORS[3] if shorts != 3 else SHORTS_COLORS[2], "glove": GLOVE_COLORS[gloves],
	}
	for mat: String in ["skin", "hair", "shorts", "stripe", "glove"]:
		var from: Array = palette.get(mat, [])
		var to: Array = targets[mat]
		for k: int in mini(from.size(), 4):
			for darken: float in [1.0, far_darken]:
				src.append(Color(float(from[k][0]) * darken, float(from[k][1]) * darken, float(from[k][2]) * darken))
				dst.append(Color(float(to[k][0]) * darken, float(to[k][1]) * darken, float(to[k][2]) * darken))
	return [src, dst]


func to_dict() -> Dictionary:
	return {"skin": skin, "hair_style": hair_style, "hair_color": hair_color, "beard": beard, "shorts": shorts, "gloves": gloves}


static func from_dict(d: Dictionary) -> Appearance:
	var a: Appearance = Appearance.new()
	a.skin = clampi(int(d.get("skin", a.skin)), 0, SKIN_TONES.size() - 1)
	a.hair_style = clampi(int(d.get("hair_style", a.hair_style)), 0, 3)
	a.hair_color = clampi(int(d.get("hair_color", a.hair_color)), 0, HAIR_COLORS.size() - 1)
	a.beard = bool(d.get("beard", a.beard))
	a.shorts = clampi(int(d.get("shorts", a.shorts)), 0, SHORTS_COLORS.size() - 1)
	a.gloves = clampi(int(d.get("gloves", a.gloves)), 0, GLOVE_COLORS.size() - 1)
	return a


func duplicate_appearance() -> Appearance:
	return Appearance.from_dict(to_dict())

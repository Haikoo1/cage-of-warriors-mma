class_name AttributeIds
extends RefCounted
## IDs dos 17 atributos visíveis (CHARACTER_DESIGN §2, CODING_STANDARDS §6).
## Fica em código até existir AttributeDef em data/ (prevista em DATA_ARCHITECTURE §2).

const ALL: Array[StringName] = [
	&"forca", &"velocidade", &"condicionamento", &"recuperacao", &"mobilidade",
	&"queixo", &"robustez",
	&"boxe", &"kickboxing", &"defesa_em_pe",
	&"wrestling_ofensivo", &"wrestling_defensivo", &"controle_solo", &"jiu_jitsu", &"defesa_finalizacao",
	&"qi_luta", &"compostura",
]


static func is_valid(id: StringName) -> bool:
	return ALL.has(id)

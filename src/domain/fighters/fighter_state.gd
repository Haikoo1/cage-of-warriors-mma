class_name FighterState
extends RefCounted
## Estado dinâmico de um lutador (DATA_ARCHITECTURE §3). Guarda só IDs de definições, nunca Resources.

enum Division { MALE, FEMALE }

var id: StringName = &""
var display_name: String = ""
var nationality: String = ""
var division: Division = Division.MALE
var weight_class_id: StringName = &""
var birth_week: int = 0
## StringName (AttributeIds) -> float 1..100; arredondado só na UI.
var attributes: Dictionary = {}
var physique: Physique = Physique.new()

# Estilo e características ocultas (CHARACTER §3, §5)
var archetype_id: StringName = &"arch_striker"
var potential: float = 75.0  # teto dos atributos treináveis (oculto)
var peak_age: int = 30

# Carreira (CAREER §5, §8–10)
var org_id: StringName = &""
var contract_fights_left: int = 0
var rating: float = 1000.0
var popularity: float = 10.0
var titles: int = 0
var wins: int = 0
var losses: int = 0
var draws: int = 0
var streak: int = 0  # >0 vitórias seguidas, <0 derrotas seguidas
var history: Array = []  # {week, opponent, opponent_name, result, method, round, org, title}
var retired: bool = false
var retired_week: int = 0

# Saúde (CAREER §5)
var fatigue: float = 0.0
var career_wear: float = 0.0
var injury: Dictionary = {}  # {"name": String, "weeks": int} — vazio = saudável
var unavailable_until: int = 0


static func create_blank(fighter_id: StringName, default_value: float) -> FighterState:
	var f: FighterState = FighterState.new()
	f.id = fighter_id
	for attr: StringName in AttributeIds.ALL:
		f.attributes[attr] = default_value
	return f


func age_years(week_index: int) -> float:
	return (week_index - birth_week) / 52.0


func is_available(week_index: int) -> bool:
	return not retired and injury.is_empty() and week_index >= unavailable_until


func record_text() -> String:
	return "%d-%d-%d" % [wins, losses, draws]


## Nota geral só para exibição (CHARACTER §1.1): não é usada por regra nenhuma.
func overall() -> float:
	var total: float = 0.0
	for a: StringName in AttributeIds.ALL:
		total += float(attributes.get(a, 0.0))
	return total / AttributeIds.ALL.size()


func to_dict() -> Dictionary:
	var attrs: Dictionary = {}
	for key: StringName in attributes:
		attrs[String(key)] = snappedf(float(attributes[key]), 0.001)
	return {
		"id": String(id), "display_name": display_name, "nationality": nationality,
		"division": Division.keys()[division], "weight_class_id": String(weight_class_id), "birth_week": birth_week,
		"attributes": attrs, "physique": physique.to_dict(),
		"archetype_id": String(archetype_id), "potential": potential, "peak_age": peak_age,
		"org_id": String(org_id), "contract_fights_left": contract_fights_left, "rating": snappedf(rating, 0.01),
		"popularity": snappedf(popularity, 0.01), "titles": titles, "wins": wins, "losses": losses, "draws": draws,
		"streak": streak, "history": history.duplicate(true), "retired": retired, "retired_week": retired_week,
		"fatigue": snappedf(fatigue, 0.01), "career_wear": snappedf(career_wear, 0.01), "injury": injury.duplicate(),
		"unavailable_until": unavailable_until,
	}


static func from_dict(d: Dictionary) -> FighterState:
	var f: FighterState = FighterState.new()
	f.id = StringName(d.get("id", ""))
	f.display_name = d.get("display_name", "")
	f.nationality = d.get("nationality", "")
	f.division = Division.keys().find(d.get("division", "MALE")) as Division
	f.weight_class_id = StringName(d.get("weight_class_id", ""))
	f.birth_week = int(d.get("birth_week", 0))
	var attrs: Dictionary = d.get("attributes", {})
	for key: String in attrs:
		f.attributes[StringName(key)] = float(attrs[key])
	f.physique = Physique.from_dict(d.get("physique", {}))
	f.archetype_id = StringName(d.get("archetype_id", "arch_striker"))
	f.potential = float(d.get("potential", 75.0))
	f.peak_age = int(d.get("peak_age", 30))
	f.org_id = StringName(d.get("org_id", ""))
	f.contract_fights_left = int(d.get("contract_fights_left", 0))
	f.rating = float(d.get("rating", 1000.0))
	f.popularity = float(d.get("popularity", 10.0))
	f.titles = int(d.get("titles", 0))
	f.wins = int(d.get("wins", 0))
	f.losses = int(d.get("losses", 0))
	f.draws = int(d.get("draws", 0))
	f.streak = int(d.get("streak", 0))
	for h: Dictionary in d.get("history", []):
		var entry: Dictionary = h.duplicate()
		for k: String in ["week", "round"]:
			if entry.has(k):
				entry[k] = int(entry[k])
		f.history.append(entry)
	f.retired = bool(d.get("retired", false))
	f.retired_week = int(d.get("retired_week", 0))
	f.fatigue = float(d.get("fatigue", 0.0))
	f.career_wear = float(d.get("career_wear", 0.0))
	var inj: Dictionary = d.get("injury", {})
	if not inj.is_empty():
		f.injury = {"name": String(inj.get("name", "")), "weeks": int(inj.get("weeks", 0))}
	f.unavailable_until = int(d.get("unavailable_until", 0))
	return f

class_name CareerState
extends RefCounted
## Raiz do estado de uma carreira (CAREER_ARCHITECTURE §1): o mundo inteiro + dados do jogador.
## Datas = semanas desde o início (week_index). Aleatoriedade derivada de (semente, semana, fluxo): ver CareerRng.

var career_seed: int = 0
var week_index: int = 0
var player_fighter_id: StringName = &""
var fighters: Dictionary = {}  # StringName -> FighterState
var _id_counters: Dictionary = {}  # prefixo -> último número

# Jogador
var money: float = 0.0
var gym_id: StringName = &""
var training_plan: Array[StringName] = []
var round_seconds: int = 120  # duração do round nas lutas jogadas (opção de acessibilidade da carreira)
var offers: Array = []  # [{kind, opponent, org, week, title, show, win, expires, fights}]
var booked: Dictionary = {}  # luta marcada do jogador (mesmo formato de oferta) ou vazio
var pending_interview: bool = false
var news: Array = []  # [{week, text}] mais recentes primeiro
var champions: Dictionary = {}  # "org|wc" -> id do campeão
var legacy: Dictionary = {}  # preenchido na aposentadoria


func next_id(prefix: String) -> StringName:
	var n: int = int(_id_counters.get(prefix, 0)) + 1
	_id_counters[prefix] = n
	return StringName("%s-%06d" % [prefix, n])


func add_fighter(f: FighterState) -> void:
	assert(not fighters.has(f.id), "lutador duplicado %s" % f.id)
	fighters[f.id] = f


func get_fighter(fighter_id: StringName) -> FighterState:
	return fighters.get(fighter_id) as FighterState


func player() -> FighterState:
	return get_fighter(player_fighter_id)


func champion(org: StringName, wc: StringName) -> StringName:
	return StringName(champions.get("%s|%s" % [org, wc], ""))


func set_champion(org: StringName, wc: StringName, fighter_id: StringName) -> void:
	champions["%s|%s" % [org, wc]] = String(fighter_id)


func add_news(text: String) -> void:
	news.push_front({"week": week_index, "text": text})
	if news.size() > 40:
		news.resize(40)


func to_dict() -> Dictionary:
	var list: Array = []
	var ids: Array = fighters.keys()
	ids.sort()
	for fid: StringName in ids:
		list.append((fighters[fid] as FighterState).to_dict())
	var plan: Array = []
	for a: StringName in training_plan:
		plan.append(String(a))
	return {
		"career_seed": career_seed, "week_index": week_index, "player_fighter_id": String(player_fighter_id),
		"id_counters": _id_counters.duplicate(), "fighters": list,
		"money": snappedf(money, 0.01), "gym_id": String(gym_id), "training_plan": plan, "round_seconds": round_seconds,
		"offers": offers.duplicate(true), "booked": booked.duplicate(true), "pending_interview": pending_interview,
		"news": news.duplicate(true), "champions": champions.duplicate(), "legacy": legacy.duplicate(true),
	}


static func from_dict(d: Dictionary) -> CareerState:
	var c: CareerState = CareerState.new()
	c.career_seed = int(d.get("career_seed", 0))
	c.week_index = int(d.get("week_index", 0))
	c.player_fighter_id = StringName(d.get("player_fighter_id", ""))
	var counters: Dictionary = d.get("id_counters", {})
	for prefix: String in counters:
		c._id_counters[prefix] = int(counters[prefix])
	for fd: Dictionary in d.get("fighters", []):
		c.add_fighter(FighterState.from_dict(fd))
	c.money = float(d.get("money", 0.0))
	c.gym_id = StringName(d.get("gym_id", ""))
	for a: String in d.get("training_plan", []):
		c.training_plan.append(StringName(a))
	c.round_seconds = int(d.get("round_seconds", 120))
	for o: Dictionary in d.get("offers", []):
		c.offers.append(_normalize_offer(o))
	var b: Dictionary = d.get("booked", {})
	c.booked = _normalize_offer(b) if not b.is_empty() else {}
	c.pending_interview = bool(d.get("pending_interview", false))
	for n: Dictionary in d.get("news", []):
		c.news.append({"week": int(n.get("week", 0)), "text": String(n.get("text", ""))})
	c.champions = (d.get("champions", {}) as Dictionary).duplicate()
	c.legacy = (d.get("legacy", {}) as Dictionary).duplicate(true)
	return c


## JSON devolve inteiros como float; ofertas usam semanas e lutas inteiras.
static func _normalize_offer(o: Dictionary) -> Dictionary:
	var n: Dictionary = o.duplicate(true)
	for k: String in ["week", "expires", "fights"]:
		if n.has(k):
			n[k] = int(n[k])
	return n

class_name CareerController
extends RefCounted
## Fachada da carreira para as telas (CAREER_ARCHITECTURE §1): valida ações do jogador e delega aos sistemas.
## Telas nunca alteram CareerState diretamente (GODOT_ARCHITECTURE §1.5).

const SAVE_ROOT: String = "user://saves"
const MAX_ADVANCE_WEEKS: int = 26

var state: CareerState
var defs: Definitions
var slot: int = 1


static func create(definitions: Definitions, setup: CareerSetup, save_slot: int) -> CareerController:
	var cc: CareerController = CareerController.new()
	cc.defs = definitions
	cc.slot = save_slot
	cc.state = CareerFactory.new_career(definitions, setup)
	return cc


static func slot_dir(save_slot: int) -> String:
	return SAVE_ROOT.path_join("slot_%d" % save_slot)


static func load_slot(definitions: Definitions, save_slot: int) -> CareerController:
	var res: SaveSystem.LoadResult = SaveSystem.load_latest_valid(slot_dir(save_slot))
	if res.error_message != "" or res.career == null:
		return null
	var cc: CareerController = CareerController.new()
	cc.defs = definitions
	cc.slot = save_slot
	cc.state = res.career
	return cc


## Resumo para o menu sem manter a carreira carregada: "" se o slot está vazio.
static func slot_summary(definitions: Definitions, save_slot: int) -> String:
	var cc: CareerController = load_slot(definitions, save_slot)
	if cc == null:
		return ""
	var p: FighterState = cc.state.player()
	return "%s · %s · semana %d%s" % [p.display_name, p.record_text(), cc.state.week_index + 1, " · aposentado" if p.retired else ""]


static func delete_slot(save_slot: int) -> void:
	var dir: String = slot_dir(save_slot)
	if DirAccess.dir_exists_absolute(dir):
		for f: String in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir.path_join(f))


func save() -> Error:
	return SaveSystem.save_career(state, slot_dir(slot), "career", "manual")


func autosave() -> void:
	SaveSystem.save_autosave(state, slot_dir(slot))


# ------------------------------------------------------------------ tempo
func simulate_week() -> Dictionary:
	var report: Dictionary = WeekSimulator.simulate_week(state, defs)
	if not report["blocked"]:
		autosave()
	return report


## Avanço rápido: para em oferta, lesão, semana da luta ou entrevista (CAREER §3.2).
func advance_until_event(max_weeks: int = MAX_ADVANCE_WEEKS) -> Dictionary:
	var report: Dictionary = {"blocked": false, "notes": [], "stop": false}
	for k: int in max_weeks:
		report = WeekSimulator.simulate_week(state, defs)
		if report["blocked"] or report["stop"]:
			break
	autosave()
	return report


func is_fight_week() -> bool:
	return not state.booked.is_empty() and int(state.booked["week"]) <= state.week_index


# ------------------------------------------------------------------ ações do jogador
func set_plan_block(index: int, activity: StringName) -> void:
	if index >= 0 and index < state.training_plan.size() and defs.training_activity(activity) != null:
		state.training_plan[index] = activity


func change_gym(gym_id: StringName) -> bool:
	var g: GymDef = defs.gym(gym_id)
	if g == null or state.player().popularity < g.min_popularity:
		return false
	state.gym_id = gym_id
	state.add_news("Mudou-se para %s." % g.display_name)
	return true


## Aba Visual (D-019): só aparência, sem efeito em regra. A pele é fixa; lutadoras não têm barba.
func change_appearance(look: Appearance) -> void:
	var p: FighterState = state.player()
	var a: Appearance = look.duplicate_appearance()
	a.skin = p.appearance.skin
	if defs.weight_class(p.weight_class_id).division == WeightClassDef.Division.FEMALE:
		a.beard = false
	p.appearance = a


func accept_offer(index: int) -> bool:
	return Matchmaking.accept_offer(state, index)


func decline_offer(index: int) -> void:
	Matchmaking.decline_offer(state, index)


func counter_offer(index: int) -> bool:
	return Matchmaking.counter_offer(state, index, CareerRng.make(state, &"counter", index + state.offers.size() * 7))


## Relatório de scouting do próximo adversário (COMBAT §5.1): a precisão cresce com blocos de estudo.
func scouting_report() -> Dictionary:
	var rep: Dictionary = {"precision": 0, "style": "?", "attributes": [], "weakness": "?", "tendency": "?"}
	if state.booked.is_empty():
		return rep
	var opp: FighterState = state.get_fighter(StringName(state.booked["opponent"]))
	var b: int = state.scouting_blocks
	var precision: int = 0 if b == 0 else (1 if b <= 2 else (2 if b <= 5 else 3))
	rep["precision"] = precision
	if precision == 0:
		return rep
	var arch: ArchetypeDef = defs.archetype(opp.archetype_id)
	rep["style"] = arch.display_key if arch else "?"
	rep["tendency"] = "procura quedas e controle por cima" if opp.archetype_id == &"arch_wrestler" else "prefere trocar em pé, na distância"
	var band: float = [0.0, 10.0, 5.0, 0.0][precision]
	var attrs: Array = AttributeIds.ALL.duplicate()
	attrs.sort_custom(func(x: StringName, y: StringName) -> bool: return float(opp.attributes[x]) > float(opp.attributes[y]))
	for k: int in 4:
		var v: float = float(opp.attributes[attrs[k]])
		rep["attributes"].append([String(attrs[k]), roundi(v - band), roundi(v + band)])
	if precision >= 2:
		rep["weakness"] = String(attrs[attrs.size() - 1])
	return rep


# ------------------------------------------------------------------ luta do jogador
## Pesagem + FightSetup (jogador = A, adversário = B controlado pela IA).
func prepare_fight() -> Dictionary:
	var p: FighterState = state.player()
	var opp: FighterState = state.get_fighter(StringName(state.booked["opponent"]))
	var bal: CareerBalanceDef = defs.career_balance if defs.career_balance != null else CareerBalanceDef.new()
	var wc: WeightClassDef = defs.weight_class(p.weight_class_id)
	var rng: RandomNumberGenerator = CareerRng.make(state, &"weigh_in")
	var weigh: Dictionary = WeightSystem.weigh_in(p, wc, bal, bool(state.booked.get("short", false)), rng)
	var org: OrganizationDef = defs.organization(StringName(state.booked["org"]))
	var setup: FightSetup = FightSetup.new()
	setup.bout_id = &"CAREER"
	setup.fighter_a = _snapshot(p, float(weigh["reserve"]) * (1.0 - maxf(0.0, p.fatigue - bal.fatigue_penalty_start) / 200.0), float(weigh["chin"]))
	setup.fighter_b = _snapshot(opp, 1.0, 0.0)
	setup.ruleset_id = org.ruleset_id if org != null else &"rs_standard"
	setup.weight_class_id = p.weight_class_id
	setup.is_title = bool(state.booked.get("title", false))
	setup.round_seconds_override = state.round_seconds
	setup.seed = hash([state.career_seed, state.week_index, "fight"])
	setup.control_a = FightSetup.ControlMode.PLAYER
	setup.control_b = FightSetup.ControlMode.AI
	var cfg: QuickFight.Config = QuickFight.Config.new()
	cfg.setup = setup
	cfg.ai_b = CombatAI.new(defs.archetype(opp.archetype_id), defs.cognitive_profile(profile_for(opp)), 1, setup.seed + 1)
	return {"config": cfg, "weigh_in": weigh, "opponent": opp, "names": [p.display_name, opp.display_name]}


## Perfil cognitivo do NPC pelo QI de Luta (CHARACTER §2.5): nunca bônus de atributo.
static func profile_for(f: FighterState) -> StringName:
	var qi: float = float(f.attributes.get(&"qi_luta", 50.0))
	if qi < 50.0:
		return &"cog_beginner"
	if qi < 68.0:
		return &"cog_intermediate"
	return &"cog_elite"


func finish_player_fight(result: FightResult, weigh_in: Dictionary = {}) -> void:
	var bout: Dictionary = {"a": String(state.player_fighter_id), "b": state.booked["opponent"], "org": state.booked["org"],
		"title": state.booked.get("title", false), "show": state.booked.get("show", 0.0), "win": state.booked.get("win", 0.0)}
	if not weigh_in.is_empty() and not bool(weigh_in.get("made_weight", true)):
		var bal: CareerBalanceDef = defs.career_balance if defs.career_balance != null else CareerBalanceDef.new()
		state.money -= float(bout["show"]) * bal.weight_miss_fine
		state.player().popularity = maxf(0.0, state.player().popularity - 3.0)
		state.change_relationship(StringName(bout["org"]), -8.0)
		bout["title"] = false  # quem falha no peso não pode ganhar o cinturão (CAREER §6.2)
		state.add_news("%s não bateu o peso: multa e luta sem título." % state.player().display_name)
	var rival_key: String = String(bout["b"])
	ResultApplier.apply(state, defs, bout, result)
	if state.rivals.has(rival_key):
		state.player().popularity = minf(100.0, state.player().popularity + 3.0)  # luta de rivalidade vende mais
		state.rivals.erase(rival_key)
		state.add_news("Rivalidade resolvida na jaula.")
	state.booked = {}
	autosave()


## Acessibilidade (P-012): resolve a luta do jogador pelo resolvedor estatístico.
func simulate_player_fight() -> FightResult:
	var prep: Dictionary = prepare_fight()
	var rules: RuleSetDef = defs.rule_set((prep["config"] as QuickFight.Config).setup.ruleset_id)
	var rounds: int = (rules.rounds_title if bool(state.booked.get("title", false)) else rules.rounds_normal) if rules else 3
	var result: FightResult = FightResolver.resolve(state.player(), prep["opponent"], rounds, CareerRng.make(state, &"player_sim"))
	finish_player_fight(result, prep["weigh_in"])
	return result


## Entrevista pós-luta (CAREER §10.5): 0 respeitoso, 1 confiante, 2 provocador. Sem efeito em atributos (R-034).
func answer_interview(tone: int) -> void:
	if not state.pending_interview:
		return
	var p: FighterState = state.player()
	if tone == 2:
		_provoke()
	var deltas: Array[float] = [1.0, 2.0, 4.0]
	var texts: Array[String] = ["agradece ao adversário e à equipe", "diz que está pronto para o topo", "provoca o próximo da fila"]
	p.popularity = clampf(p.popularity + deltas[clampi(tone, 0, 2)], 0.0, 100.0)
	state.add_news("Entrevista: %s %s." % [p.display_name, texts[clampi(tone, 0, 2)]])
	state.pending_interview = false


## Provocar cria rivalidade: com o último adversário se perdeu, senão com quem está logo acima no ranking.
func _provoke() -> void:
	var p: FighterState = state.player()
	var target: FighterState = null
	if not p.history.is_empty() and p.history[-1]["result"] == "L":
		target = state.get_fighter(StringName(p.history[-1]["opponent"]))
	else:
		var roster: Array[FighterState] = Rankings.roster(state, p.org_id, p.weight_class_id)
		var idx: int = roster.find(p)
		if idx > 0:
			target = roster[idx - 1]
		elif roster.size() > 1:
			target = roster[1]
	if target != null and target != p:
		state.rivals[String(target.id)] = minf(100.0, float(state.rivals.get(String(target.id), 0.0)) + 40.0)
		state.add_news("Rivalidade: %s responde às provocações de %s." % [target.display_name, p.display_name])


# ------------------------------------------------------------------ fim de carreira
func retire() -> Dictionary:
	var p: FighterState = state.player()
	p.retired = true
	var finishes: int = 0
	for h: Dictionary in p.history:
		if h["result"] == "W" and String(h["method"]) in ["nocaute", "nocaute técnico", "finalização"]:
			finishes += 1
	var score: int = p.wins * 3 + p.titles * 20 + finishes * 2 + roundi(p.popularity / 4.0) - p.losses
	var hall: bool = score >= 120
	state.legacy = {"score": score, "record": p.record_text(), "titles": p.titles, "finishes": finishes,
		"age": snappedf(p.age_years(state.week_index), 0.1), "hall_of_fame": hall}
	state.add_news("%s se aposenta aos %d anos (%s).%s" % [p.display_name, int(p.age_years(state.week_index)), p.record_text(),
		" Entra para o Hall da Fama!" if hall else ""])
	state.offers.clear()
	state.booked = {}
	save()
	return state.legacy


func _snapshot(f: FighterState, reserve: float, chin_mod: float) -> FighterSnapshot:
	var s: FighterSnapshot = FighterSnapshot.from_fighter(f)
	s.reserve_start = clampf(reserve, 0.5, 1.0)
	s.attributes[&"queixo"] = maxf(1.0, float(s.attributes[&"queixo"]) + chin_mod)
	# Lesão em retorno precoce: atributos físicos reduzidos no dia (CAREER §5.3).
	if not f.injury.is_empty():
		for attr: StringName in [&"velocidade", &"forca", &"mobilidade"]:
			s.attributes[attr] = float(s.attributes[attr]) * 0.85
	return s

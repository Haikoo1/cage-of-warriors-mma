extends Control
## Dashboard da carreira (GAME_SYSTEMS §8). Abas: 1 Visão geral · 2 Treino · 3 Ofertas · 4 Rankings · 5 Perfil.
## Só lê o estado e chama o CareerController (nunca altera CareerState direto).

const TABS: Array[String] = ["1 Visão geral", "2 Treino", "3 Ofertas", "4 Rankings", "5 Perfil"]
const ATTR_NAMES: Dictionary = {
	&"forca": "Força", &"velocidade": "Velocidade", &"condicionamento": "Condicionamento", &"recuperacao": "Recuperação",
	&"mobilidade": "Mobilidade", &"queixo": "Queixo", &"robustez": "Robustez", &"boxe": "Boxe", &"kickboxing": "Kickboxing",
	&"defesa_em_pe": "Defesa em Pé", &"wrestling_ofensivo": "Wrestling Of.", &"wrestling_defensivo": "Wrestling Def.",
	&"controle_solo": "Controle de Solo", &"jiu_jitsu": "Jiu-jitsu", &"defesa_finalizacao": "Def. Finalização",
	&"qi_luta": "QI de Luta", &"compostura": "Compostura",
}

var cc: CareerController
var tab: int = 0
var cursor: int = 0
var rank_org: int = 0
var rank_wc: int = 0
var message: String = ""
var retire_confirm: bool = false
var activity_ids: Array[StringName] = []
var gym_ids: Array[StringName] = []
var wc_ids: Array[StringName] = []
var _before_attrs: Dictionary = {}


func _ready() -> void:
	cc = GameSession.career
	if cc == null:
		SceneRouter.go_to(&"boot")
		return
	for a: StringName in cc.defs.training_activities:
		activity_ids.append(a)
	activity_ids.sort()
	for g: StringName in cc.defs.gyms:
		gym_ids.append(g)
	gym_ids.sort()
	for w: StringName in cc.defs.weight_classes:
		wc_ids.append(w)
	wc_ids.sort()
	var p: FighterState = cc.state.player()
	rank_wc = wc_ids.find(p.weight_class_id)
	rank_org = maxi(0, cc.defs.organizations_by_tier().map(func(o: OrganizationDef) -> StringName: return o.id).find(p.org_id))
	_before_attrs = p.attributes.duplicate()


func _process(_delta: float) -> void:
	queue_redraw()


# ------------------------------------------------------------------ desenho
func _draw() -> void:
	if cc == null:
		return
	var s: CareerState = cc.state
	var p: FighterState = s.player()
	UiDraw.background(self)
	var org: OrganizationDef = cc.defs.organization(p.org_id)
	var wc: WeightClassDef = cc.defs.weight_class(p.weight_class_id)
	var rank: int = Rankings.rank_of(s, p)
	var rank_text: String = "campeão" if rank == 0 else ("#%d" % rank if rank > 0 else "-")
	UiDraw.text(self, Vector2(10, 14), "%s  ·  %s  ·  %s %s  ·  %s" % [p.display_name, p.record_text(), wc.display_key,
		"(M)" if wc.division == WeightClassDef.Division.MALE else "(F)", org.display_name if org else "-"], UiDraw.C_SEL, 11)
	UiDraw.text(self, Vector2(10, 27), "Semana %d  ·  %.1f anos  ·  ranking %s  ·  %s  ·  popularidade %.0f" % [
		s.week_index + 1, p.age_years(s.week_index), rank_text, UiDraw.money(s.money), p.popularity], UiDraw.C_TEXT, UiDraw.SMALL)
	for i: int in TABS.size():
		UiDraw.text(self, Vector2(10 + i * 110, 44), TABS[i], UiDraw.C_SEL if i == tab else UiDraw.C_DIM, UiDraw.TEXT)
	draw_line(Vector2(8, 48), Vector2(632, 48), Color(1, 1, 1, 0.15))
	if not s.legacy.is_empty():
		_draw_legacy()
	else:
		match tab:
			0: _draw_overview()
			1: _draw_training()
			2: _draw_offers()
			3: _draw_rankings()
			4: _draw_profile()
	if message != "":
		UiDraw.text(self, Vector2(10, 336), message, UiDraw.C_GOOD, UiDraw.SMALL, 620)
	UiDraw.footer(self, _help())


func _help() -> String:
	if not cc.state.legacy.is_empty():
		return "Esc menu"
	var common: String = "1-5 abas · Espaço simular semana · A avançar até evento · F5 salvar · Esc salvar e sair"
	match tab:
		1: return "W/S bloco · Q/E atividade · G trocar academia · " + common
		2: return "W/S oferta · Enter aceitar · C contrapropor · X recusar · " + common
		3: return "Q/E categoria · Z/C organização · " + common
	return "R aposentar (2x) · " + common


func _draw_overview() -> void:
	var s: CareerState = cc.state
	var p: FighterState = s.player()
	var y: float = 64
	UiDraw.text(self, Vector2(10, y), "Fadiga acumulada", UiDraw.C_TEXT)
	UiDraw.bar(self, Rect2(120, y - 8, 160, 8), p.fatigue / 100.0, UiDraw.C_GOOD if p.fatigue < 40 else (UiDraw.C_SEL if p.fatigue < 70 else UiDraw.C_BAD))
	UiDraw.text(self, Vector2(290, y), "%.0f / 100" % p.fatigue, UiDraw.C_DIM, UiDraw.SMALL)
	y += 14
	var health: String = "Saudável" if p.injury.is_empty() else "LESIONADO: %s (%d sem.)" % [p.injury["name"], p.injury["weeks"]]
	if p.unavailable_until > s.week_index and p.injury.is_empty():
		health = "Suspensão médica até a semana %d" % (p.unavailable_until + 1)
	UiDraw.text(self, Vector2(10, y), health, UiDraw.C_TEXT if p.injury.is_empty() else UiDraw.C_BAD)
	UiDraw.text(self, Vector2(300, y), "Desgaste de carreira: %.0f" % p.career_wear, UiDraw.C_DIM, UiDraw.SMALL)
	y += 22
	UiDraw.panel(self, Rect2(8, y - 12, 624, 60))
	if s.pending_interview:
		UiDraw.text(self, Vector2(16, y + 2), "ENTREVISTA PÓS-LUTA — como você responde?", UiDraw.C_SEL, 11)
		UiDraw.text(self, Vector2(16, y + 18), "1 Respeitoso (+pouca popularidade)   2 Confiante   3 Provocador (+muita popularidade, cria rivalidade)", UiDraw.C_TEXT)
	elif cc.is_fight_week():
		var opp: FighterState = s.get_fighter(StringName(s.booked["opponent"]))
		UiDraw.text(self, Vector2(16, y + 2), "SEMANA DA LUTA%s: %s (%s)" % [" — DISPUTA DE CINTURÃO" if s.booked["title"] else "", opp.display_name, opp.record_text()], UiDraw.C_SEL, 11)
		UiDraw.text(self, Vector2(16, y + 18), "Enter: pesagem e LUTAR (você joga)     F: simular a luta", UiDraw.C_TEXT)
		var cut: float = WeightSystem.cut_fraction(p, cc.defs.weight_class(p.weight_class_id), bool(s.booked.get("short", false)))
		UiDraw.text(self, Vector2(16, y + 34), "Corte de peso previsto: %.1f%%" % (cut * 100.0), UiDraw.C_DIM, UiDraw.SMALL)
		_draw_scouting(Vector2(240, y + 34))
	elif not s.booked.is_empty():
		var opp2: FighterState = s.get_fighter(StringName(s.booked["opponent"]))
		UiDraw.text(self, Vector2(16, y + 2), "Próxima luta: %s (%s) na semana %d — faltam %d semanas de camp" % [opp2.display_name,
			opp2.record_text(), int(s.booked["week"]) + 1, int(s.booked["week"]) - s.week_index], UiDraw.C_TEXT, 11)
		_draw_scouting(Vector2(16, y + 18))
	elif not s.offers.is_empty():
		UiDraw.text(self, Vector2(16, y + 2), "Você tem %d oferta(s) — aba 3." % s.offers.size(), UiDraw.C_SEL, 11)
	elif not p.is_available(s.week_index):
		UiDraw.text(self, Vector2(16, y + 2), "Indisponível para lutar no momento.", UiDraw.C_TEXT, 11)
	else:
		UiDraw.text(self, Vector2(16, y + 2), "Sem luta marcada. Treine e espere ofertas (Espaço / A).", UiDraw.C_TEXT, 11)
	y += 66
	UiDraw.text(self, Vector2(10, y), "Notícias", UiDraw.C_SEL)
	for k: int in mini(10, s.news.size()):
		var n: Dictionary = s.news[k]
		UiDraw.text(self, Vector2(10, y + 14 + k * 12), "S%d  %s" % [int(n["week"]) + 1, n["text"]], UiDraw.C_TEXT, UiDraw.SMALL, 620)


## Relatório de scouting (COMBAT §5.1): mais blocos de "Estudo do adversário" = faixas mais estreitas.
func _draw_scouting(pos: Vector2) -> void:
	var rep: Dictionary = cc.scouting_report()
	if int(rep["precision"]) == 0:
		UiDraw.text(self, pos, "Scouting: nenhum estudo do adversário ainda (bloco 'Estudo do adversário' no treino).", UiDraw.C_DIM, UiDraw.SMALL)
		return
	var parts: PackedStringArray = []
	for a: Array in rep["attributes"]:
		var name: String = ATTR_NAMES.get(StringName(a[0]), a[0])
		parts.append("%s %d" % [name, a[1]] if a[1] == a[2] else "%s %d–%d" % [name, a[1], a[2]])
	var weak: String = ("  ·  ponto fraco: %s" % ATTR_NAMES.get(StringName(rep["weakness"]), rep["weakness"])) if rep["weakness"] != "?" else ""
	UiDraw.text(self, pos, "Scouting (%s): %s — %s. Fortes: %s%s" % [["", "básico", "bom", "completo"][int(rep["precision"])],
		rep["style"], rep["tendency"], ", ".join(parts), weak], UiDraw.C_TEXT, UiDraw.SMALL, 600 - pos.x)


func _draw_training() -> void:
	var s: CareerState = cc.state
	var gym: GymDef = cc.defs.gym(s.gym_id)
	UiDraw.text(self, Vector2(10, 64), "Academia: %s (estrutura %d, %s/mês)" % [gym.display_name, gym.structure, UiDraw.money(gym.monthly_cost)], UiDraw.C_TEXT)
	var days: Array[String] = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
	for i: int in s.training_plan.size():
		var act: TrainingActivityDef = cc.defs.training_activity(s.training_plan[i])
		var y: float = 84 + i * 14
		var col: Color = UiDraw.C_SEL if i == cursor else UiDraw.C_TEXT
		UiDraw.text(self, Vector2(10, y), "%s %s" % [days[i / 2], "manhã" if i % 2 == 0 else "tarde"], UiDraw.C_DIM, UiDraw.SMALL)
		UiDraw.text(self, Vector2(90, y), ("< %s >" if i == cursor else "%s") % act.display_name, col, UiDraw.TEXT)
		UiDraw.text(self, Vector2(290, y), "carga %+.0f" % act.load, UiDraw.C_DIM, UiDraw.SMALL)
	var load: float = TrainingSystem.forecast_load(s, cc.defs)
	var p: FighterState = s.player()
	UiDraw.text(self, Vector2(360, 84), "Carga da semana: %+.0f" % load, UiDraw.C_TEXT)
	UiDraw.text(self, Vector2(360, 98), "Fadiga atual: %.0f" % p.fatigue, UiDraw.C_TEXT)
	UiDraw.text(self, Vector2(360, 116), "Acima de 40 de fadiga os ganhos caem;", UiDraw.C_DIM, UiDraw.SMALL)
	UiDraw.text(self, Vector2(360, 128), "acima de 90 o treinador vetará treino pesado.", UiDraw.C_DIM, UiDraw.SMALL)
	UiDraw.text(self, Vector2(360, 140), "Trabalho paralelo paga, mas tira treino.", UiDraw.C_DIM, UiDraw.SMALL)
	var act_sel: TrainingActivityDef = cc.defs.training_activity(s.training_plan[cursor])
	var gains: PackedStringArray = []
	for attr: Variant in act_sel.gains:
		gains.append("%s +%.2f" % [ATTR_NAMES.get(StringName(attr), attr), float(act_sel.gains[attr])])
	UiDraw.text(self, Vector2(360, 166), act_sel.display_name, UiDraw.C_SEL)
	UiDraw.text(self, Vector2(360, 180), ", ".join(gains) if not gains.is_empty() else ("recupera fadiga" if act_sel.load < 0 else ("renda $%.0f" % act_sel.money_per_block if act_sel.money_per_block > 0 else "melhora o scouting")), UiDraw.C_TEXT, UiDraw.SMALL, 270)


func _draw_offers() -> void:
	var s: CareerState = cc.state
	var p0: FighterState = s.player()
	UiDraw.text(self, Vector2(10, 62), "Relação com %s: %.0f/100 (recusar e contrapropor sem sucesso baixa; salvar cards com pouco prazo sobe)" % [
		cc.defs.organization(p0.org_id).display_name, s.relationship(p0.org_id)], UiDraw.C_DIM, UiDraw.SMALL)
	if s.offers.is_empty():
		UiDraw.text(self, Vector2(10, 80), "Nenhuma oferta no momento. Ofertas chegam quando você está disponível e sem luta marcada.", UiDraw.C_DIM)
		return
	for i: int in s.offers.size():
		var o: Dictionary = s.offers[i]
		var y: float = 84 + i * 30
		var col: Color = UiDraw.C_SEL if i == cursor else UiDraw.C_TEXT
		if o["kind"] == "contract":
			var org: OrganizationDef = cc.defs.organization(StringName(o["org"]))
			UiDraw.text(self, Vector2(10, y), "CONTRATO: %s — %d lutas, %s + %s por vitória" % [org.display_name, int(o["fights"]),
				UiDraw.money(float(o["show"])), UiDraw.money(float(o["win"]))], col, 11)
		else:
			var opp: FighterState = s.get_fighter(StringName(o["opponent"]))
			var opp_rank: int = Rankings.rank_of(s, opp)
			UiDraw.text(self, Vector2(10, y), "%s%s%s (%s, %s, ranking %s) — semana %d%s" % ["TÍTULO: " if o["title"] else "", "RIVAL: " if o.get("rivalry", false) else "", opp.display_name,
				opp.record_text(), cc.defs.archetype(opp.archetype_id).display_key, "C" if opp_rank == 0 else str(opp_rank),
				int(o["week"]) + 1, "  [POUCO PRAZO]" if o["short"] else ""], col, 11)
			UiDraw.text(self, Vector2(22, y + 12), "Bolsa %s + %s por vitória · expira na semana %d · rating dele %.0f (seu %.0f)%s" % [
				UiDraw.money(float(o["show"])), UiDraw.money(float(o["win"])), int(o["expires"]) + 1, opp.rating, s.player().rating,
				"  · já contraproposta" if o.get("countered", false) else ""], UiDraw.C_DIM, UiDraw.SMALL)


func _draw_rankings() -> void:
	var s: CareerState = cc.state
	var orgs: Array[OrganizationDef] = cc.defs.organizations_by_tier()
	var org: OrganizationDef = orgs[rank_org]
	var wc: WeightClassDef = cc.defs.weight_class(wc_ids[rank_wc])
	UiDraw.text(self, Vector2(10, 66), "%s  ·  %s %s" % [org.display_name, wc.display_key, "(M)" if wc.division == WeightClassDef.Division.MALE else "(F)"], UiDraw.C_SEL, 11)
	var roster: Array[FighterState] = Rankings.roster(s, org.id, wc.id)
	for k: int in mini(16, roster.size()):
		var f: FighterState = roster[k]
		var col: Color = UiDraw.C_GOOD if f.id == s.player_fighter_id else (UiDraw.C_BAD if s.rivals.has(String(f.id)) else UiDraw.C_TEXT)
		UiDraw.text(self, Vector2(10, 84 + k * 14), "%s  %s%s" % ["C " if k == 0 else "%2d" % k, f.display_name, "  (rival)" if s.rivals.has(String(f.id)) else ""], col, UiDraw.TEXT)
		UiDraw.text(self, Vector2(220, 84 + k * 14), "%s   rating %.0f   %s   %d anos%s" % [f.record_text(), f.rating,
			cc.defs.archetype(f.archetype_id).display_key, int(f.age_years(s.week_index)), "  (lesionado)" if not f.injury.is_empty() else ""], col, UiDraw.SMALL)


func _draw_profile() -> void:
	var p: FighterState = cc.state.player()
	var k: int = 0
	for attr: StringName in AttributeIds.ALL:
		var x: float = 10 + (k / 9) * 210
		var y: float = 66 + (k % 9) * 16
		var v: float = float(p.attributes[attr])
		var delta: float = v - float(_before_attrs.get(attr, v))
		UiDraw.text(self, Vector2(x, y), ATTR_NAMES[attr], UiDraw.C_TEXT, UiDraw.SMALL)
		UiDraw.bar(self, Rect2(x + 96, y - 7, 70, 6), v / 100.0, UiDraw.C_GOOD)
		UiDraw.text(self, Vector2(x + 170, y), "%d%s" % [roundi(v), (" %+.1f" % delta) if absf(delta) >= 0.1 else ""], UiDraw.C_TEXT, UiDraw.SMALL)
		k += 1
	var ph: Physique = p.physique
	UiDraw.text(self, Vector2(430, 66), "Altura %d cm · envergadura %d cm" % [ph.height_cm, ph.reach_cm], UiDraw.C_DIM, UiDraw.SMALL)
	UiDraw.text(self, Vector2(430, 80), "Peso de caminhada %.1f kg" % ph.walk_weight_kg, UiDraw.C_DIM, UiDraw.SMALL)
	UiDraw.text(self, Vector2(430, 94), "Títulos: %d · sequência %+d" % [p.titles, p.streak], UiDraw.C_DIM, UiDraw.SMALL)
	var ry: float = 112
	for rid: String in cc.state.rivals:
		var rf: FighterState = cc.state.get_fighter(StringName(rid))
		if rf != null:
			UiDraw.text(self, Vector2(430, ry), "Rival: %s (%.0f)" % [rf.display_name, float(cc.state.rivals[rid])], UiDraw.C_BAD, UiDraw.SMALL)
			ry += 12
	UiDraw.text(self, Vector2(10, 220), "Últimas lutas", UiDraw.C_SEL)
	var hist: Array = p.history.duplicate()
	hist.reverse()
	for i: int in mini(7, hist.size()):
		var h: Dictionary = hist[i]
		var col: Color = UiDraw.C_GOOD if h["result"] == "W" else (UiDraw.C_BAD if h["result"] == "L" else UiDraw.C_TEXT)
		UiDraw.text(self, Vector2(10, 234 + i * 12), "S%d  %s  %s — %s (R%d)%s" % [int(h["week"]) + 1, h["result"], h["opponent_name"],
			h["method"], int(h["round"]), "  [título]" if h["title"] else ""], col, UiDraw.SMALL)


func _draw_legacy() -> void:
	var l: Dictionary = cc.state.legacy
	UiDraw.text(self, Vector2(10, 80), "CARREIRA ENCERRADA", UiDraw.C_SEL, UiDraw.TITLE)
	UiDraw.text(self, Vector2(10, 110), "Cartel final %s · %d título(s) · %d finalizações · aposentou aos %.1f anos" % [l["record"], int(l["titles"]), int(l["finishes"]), float(l["age"])], UiDraw.C_TEXT, 11)
	UiDraw.text(self, Vector2(10, 130), "Pontuação de legado: %d" % int(l["score"]), UiDraw.C_TEXT, 11)
	UiDraw.text(self, Vector2(10, 150), "HALL DA FAMA!" if l["hall_of_fame"] else "Não entrou no Hall da Fama (120 pontos).", UiDraw.C_GOOD if l["hall_of_fame"] else UiDraw.C_DIM, 11)


# ------------------------------------------------------------------ entrada
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = (event as InputEventKey).physical_keycode
	var s: CareerState = cc.state
	if key == KEY_ESCAPE:
		cc.save()
		GameSession.close_career()
		SceneRouter.go_to(&"boot")
		return
	if not s.legacy.is_empty():
		return
	if key != KEY_R:
		retire_confirm = false
	match key:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			if s.pending_interview and tab == 0 and key <= KEY_3:
				cc.answer_interview(key - KEY_1)
				message = "Entrevista registrada."
			else:
				tab = key - KEY_1
				cursor = 0
		KEY_SPACE:
			_advance(false)
		KEY_A:
			if tab != 1:
				_advance(true)
		KEY_F5:
			message = "Jogo salvo." if cc.save() == OK else "Falha ao salvar."
		KEY_R:
			if tab == 0:
				if retire_confirm:
					cc.retire()
				else:
					retire_confirm = true
					message = "Aperte R de novo para APOSENTAR (encerra a carreira)."
		KEY_ENTER, KEY_KP_ENTER:
			if tab == 0 and cc.is_fight_week() and not s.pending_interview:
				_fight()
			elif tab == 2 and not s.offers.is_empty():
				message = "Oferta aceita." if cc.accept_offer(cursor) else "Não foi possível aceitar (já tem luta marcada?)."
				cursor = 0
		KEY_F:
			if tab == 0 and cc.is_fight_week() and not s.pending_interview:
				var r: FightResult = cc.simulate_player_fight()
				message = "Luta simulada: %s por %s." % ["VITÓRIA" if r.winner == FightResult.FighterSlot.A else ("EMPATE" if r.winner == FightResult.FighterSlot.NONE else "DERROTA"), ResultApplier.method_name(r.method)]
		KEY_X:
			if tab == 2:
				cc.decline_offer(cursor)
				cursor = 0
		KEY_W, KEY_UP:
			cursor = maxi(0, cursor - 1)
		KEY_S, KEY_DOWN:
			cursor = mini(_cursor_max(), cursor + 1)
		KEY_Q, KEY_E:
			var step: int = -1 if key == KEY_Q else 1
			if tab == 1:
				var idx: int = activity_ids.find(s.training_plan[cursor])
				cc.set_plan_block(cursor, activity_ids[(idx + step + activity_ids.size()) % activity_ids.size()])
			elif tab == 3:
				rank_wc = (rank_wc + step + wc_ids.size()) % wc_ids.size()
		KEY_C when tab == 2:
			if not s.offers.is_empty():
				message = "Contraproposta aceita!" if cc.counter_offer(cursor) else "Contraproposta recusada ou indisponível."
				cursor = 0
		KEY_Z, KEY_C:
			if tab == 3:
				rank_org = (rank_org + (1 if key == KEY_C else -1) + 4) % 4
		KEY_G:
			if tab == 1:
				var gi: int = gym_ids.find(s.gym_id)
				for k: int in gym_ids.size():
					var cand: StringName = gym_ids[(gi + 1 + k) % gym_ids.size()]
					if cc.change_gym(cand):
						message = "Academia: %s" % cc.defs.gym(cand).display_name
						break


func _cursor_max() -> int:
	match tab:
		1: return cc.state.training_plan.size() - 1
		2: return maxi(0, cc.state.offers.size() - 1)
	return 0


func _advance(until_event: bool) -> void:
	var s: CareerState = cc.state
	if s.pending_interview:
		message = "Responda a entrevista primeiro (1/2/3 na aba Visão geral)."
		tab = 0
		return
	if cc.is_fight_week():
		message = "É semana de luta: Enter para lutar ou F para simular."
		tab = 0
		return
	_before_attrs = s.player().attributes.duplicate()
	var report: Dictionary = cc.advance_until_event() if until_event else cc.simulate_week()
	var notes: Array = report["notes"]
	message = ("Semana %d. " % (s.week_index + 1)) + (" ".join(notes) if not notes.is_empty() else "")


func _fight() -> void:
	var prep: Dictionary = cc.prepare_fight()
	SceneRouter.go_to(&"combat_test", {"quick_fight": prep["config"], "career": true, "weigh_in": prep["weigh_in"], "names": prep["names"]})

extends Control
## Resultado e estatísticas (GAME_SYSTEMS §8): método, cartelas por juiz e por round, estatísticas.

const METHOD_TEXT: Dictionary = {
	FightResult.Method.KO: "Nocaute", FightResult.Method.TKO: "Nocaute técnico",
	FightResult.Method.SUBMISSION: "Finalização", FightResult.Method.DECISION_UNANIMOUS: "Decisão unânime",
	FightResult.Method.DECISION_SPLIT: "Decisão dividida", FightResult.Method.DECISION_MAJORITY: "Decisão majoritária",
	FightResult.Method.DRAW: "Empate",
}

var result: FightResult
var names: Array = ["A", "B"]
var career: bool = false
var title: bool = false


func setup(params: Dictionary) -> void:
	result = params.get("result")
	names = params.get("names", names)
	career = bool(params.get("career", false))
	title = bool(params.get("title", false))


func _draw() -> void:
	if result == null:
		return
	UiDraw.background(self, "RESULTADO DA LUTA")
	if title and result.winner != FightResult.FighterSlot.NONE:
		UiDraw.icon(self, "belt", Vector2(470, 44), 120)
		draw_string(ThemeDB.fallback_font, Vector2(430, 176), "NOVO CAMPEÃO!" if result.winner == FightResult.FighterSlot.A else "O CINTURÃO FICA", HORIZONTAL_ALIGNMENT_CENTER, 200, 14, UiDraw.C_SEL)
	var font: Font = ThemeDB.fallback_font
	var winner: String = "Empate" if result.winner == FightResult.FighterSlot.NONE else ("Vencedor: %s" % names[int(result.winner)])
	draw_string(font, Vector2(30, 66), winner, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UiDraw.C_SEL)
	var mins: int = result.time_seconds / 60
	draw_string(font, Vector2(30, 84), "%s — round %d, %d:%02d" % [METHOD_TEXT.get(result.method, "?"), result.round, mins, result.time_seconds % 60],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	var y: float = 108
	draw_string(font, Vector2(30, y), "Juízes (total %s x %s):" % names, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.85))
	var judge_names: Array[String] = ["Juiz 1 (equilibrado)", "Juiz 2 (trocação)", "Juiz 3 (grappling)"]
	for j: int in result.scorecards.size():
		var card: Array = result.scorecards[j]
		y += 14
		var per_round: PackedStringArray = []
		for r: Dictionary in result.stats.get("rounds", []):
			per_round.append("%d-%d" % [int(r["cards"][j][0]), int(r["cards"][j][1])])
		draw_string(font, Vector2(40, y), "%s: %d-%d   (%s)" % [judge_names[j], int(card[0]), int(card[1]), ", ".join(per_round)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	y += 24
	draw_string(font, Vector2(30, y), "Por round (dano causado · quedas/transições · controle):", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.85))
	var rounds: Array = result.stats.get("rounds", [])
	for k: int in rounds.size():
		var st: Array = rounds[k]["stats"]
		y += 14
		draw_string(font, Vector2(40, y), "R%d  %s: %.0f · %d · %.0fs   |   %s: %.0f · %d · %.0fs" % [k + 1,
			names[0], float(st[0]["damage"]), int(st[0]["grapple"]), float(st[0]["control_s"]),
			names[1], float(st[1]["damage"]), int(st[1]["grapple"]), float(st[1]["control_s"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	y += 24
	for k: int in 2:
		var s: Dictionary = result.stats.get("a" if k == 0 else "b", {})
		var med: Dictionary = result.medical.get("a" if k == 0 else "b", {})
		draw_string(font, Vector2(30, y + k * 14), "%s: golpes %d, acertos %d, bloqueados %d · dano recebido cabeça %.0f corpo %.0f pernas %.0f" % [
			names[k], int(s.get("attempts", 0)), int(s.get("landed", 0)), int(s.get("blocked", 0)),
			float(med.get("head", 0)), float(med.get("body", 0)), float(med.get("legs", 0))], HORIZONTAL_ALIGNMENT_LEFT, 590, 10, Color(1, 1, 1, 0.8))
	UiDraw.footer(self, "Enter: voltar à carreira" if career else "Enter: nova Luta Rápida  ·  Esc: menu")


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_ENTER, KEY_KP_ENTER:
			SceneRouter.go_to(&"career_dashboard" if career else &"quick_fight")
		KEY_ESCAPE:
			SceneRouter.go_to(&"career_dashboard" if career else &"boot")

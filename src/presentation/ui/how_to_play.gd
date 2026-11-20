extends Control
## Ajuda rápida (substitui o tutorial até a E-12): controles e o essencial da carreira. Esc volta.

const PAGES: Array = [
	["LUTA — EM PÉ", [
		"WASD: mover (D avança, A recua, W/S passo lateral).",
		"U / I: mão da frente / mão de trás.   J / K: perna da frente / perna de trás.",
		"Segure E: golpe curvo (gancho).   Segure Q: mirar o corpo.",
		"Shift: guarda alta (com Q: guarda baixa).",
		"Espaço + W: esquiva lateral · Espaço + S: abaixar · Espaço + trás: recuar o tronco.",
		"Golpe reto erra se você estiver deslocado em profundidade: use o passo lateral!",
		"Acertar durante a preparação do golpe do adversário = CONTRA-GOLPE (dano x1,5).",
	]],
	["LUTA — AGARRADA", [
		"L: entrar no clinch (perto) · L+S: double leg · L+W: single leg.",
		"Defender queda: Espaço+S durante a preparação (sprawl). No início da janela = contra-ataque.",
		"No clinch e no chão não há caminhada: L + direção inicia técnica; tocar a direção certa DEFENDE.",
		"O canto esquerdo da tela lista as técnicas da sua posição e a tecla de cada uma.",
		"Por cima no chão: U/I socam. Por baixo: Shift cobre (evita TKO).",
		"Finalização: no Medidor de Aperto, toque a mesma direção do ajuste do adversário para escapar.",
	]],
	["LUTA — REGRAS", [
		"Rounds com relógio; no intervalo escolha o foco (1 normal, 2 recuperar fôlego) e Enter.",
		"Fôlego (barra colorida) regenera parado; a Reserva (cinza) só cai. Cansado = golpes lentos e fracos.",
		"Árbitro separa clinch parado e levanta luta parada no chão; 5 golpes sem defesa = TKO.",
		"3 juízes (10 pontos): dano, quedas e controle. Esc/P pausa. F1 depuração · F4 sprites de teste.",
	]],
	["CARREIRA", [
		"Gamepad: analógico/direcional move · X/Y mãos · A/B pernas · RT curvo · RB corpo · LB guarda · LT agarrar · R3 técnica.",
		"Comece no circuito local. Espaço simula 1 semana; A avança até algo acontecer.",
		"Aba 2 (Treino): 12 blocos por semana. Mais carga = mais ganho e mais fadiga; acima de 40 rende menos.",
		"Aba 3 (Ofertas): aceite lutas (Enter). Vencendo e subindo no ranking chegam convites de ligas maiores.",
		"Semana da luta: Enter para LUTAR ou F para simular. Depois responda a entrevista (1/2/3).",
		"Dinheiro: bolsas pagam a equipe (15%); custo de vida e academia são semanais; trabalho paralelo ajuda.",
		"Lesões e suspensões impedem lutar. Idade e nocautes desgastam. R (2x) aposenta.",
		"O jogo salva sozinho a cada semana (F5 salva também). Esc salva e volta ao menu.",
	]],
]

var page: int = 0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	UiDraw.background(self, "COMO JOGAR — %s" % PAGES[page][0], "página %d de %d" % [page + 1, PAGES.size()])
	var lines: Array = PAGES[page][1]
	for i: int in lines.size():
		UiDraw.text(self, Vector2(30, 70 + i * 22), "• " + String(lines[i]), UiDraw.C_TEXT, UiDraw.TEXT, 590)
	UiDraw.footer(self, "A/D página · Esc voltar · as teclas podem ser trocadas em Opções")


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_A, KEY_LEFT:
			page = (page + PAGES.size() - 1) % PAGES.size()
		KEY_D, KEY_RIGHT, KEY_ENTER, KEY_SPACE:
			page = (page + 1) % PAGES.size()
		KEY_ESCAPE:
			SceneRouter.go_to(&"boot")

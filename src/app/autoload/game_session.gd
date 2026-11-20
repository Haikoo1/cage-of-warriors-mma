extends Node
## Autoload GameSession (T-008): segura a carreira ativa entre trocas de tela. Sem lógica de jogo.

var career: CareerController


func has_career() -> bool:
	return career != null


func close_career() -> void:
	career = null

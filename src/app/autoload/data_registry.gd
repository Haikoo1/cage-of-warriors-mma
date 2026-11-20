extends Node
## Autoload DataRegistry (T-008): carrega e valida data/ uma vez; serve as definições somente leitura.
## Regra: o domínio nunca acessa este autoload; recebe `definitions` por parâmetro.

const DATA_ROOT: String = "res://data"

var definitions: Definitions
var errors: Array[String] = []


func _ready() -> void:
	definitions = DataLoader.load_from(DATA_ROOT)
	errors = definitions.validate_all()
	for e: String in errors:
		push_error("DataRegistry: " + e)

extends Control
## Tela provisória da fundação: mostra versão e estado dos dados. Substituída pelo menu principal.


func _ready() -> void:
	var defs: Definitions = DataRegistry.definitions
	var status: String = "dados OK" if DataRegistry.errors.is_empty() else "%d erros nos dados" % DataRegistry.errors.size()
	%Info.text = "Projeto Jaula %s — fundação técnica (E-02B)\n%d categoria(s), %d golpe(s), %d ruleset(s): %s" % [
		ProjectSettings.get_setting("application/config/version"),
		defs.weight_classes.size(), defs.strikes.size(), defs.rule_sets.size(), status,
	]

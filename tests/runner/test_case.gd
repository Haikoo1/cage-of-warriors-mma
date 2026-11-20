class_name TestCase
extends RefCounted
## Base mínima dos testes do runner próprio (T-009). Cada método test_* é executado em uma instância nova.

var failures: Array[String] = []
var assertions: int = 0


func assert_true(condition: bool, message: String = "esperado verdadeiro") -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func assert_false(condition: bool, message: String = "esperado falso") -> void:
	assert_true(not condition, message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	assertions += 1
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s esperado <%s>, obtido <%s>" % [message, str(expected), str(actual)])


func assert_almost(actual: float, expected: float, epsilon: float = 0.0001, message: String = "") -> void:
	assertions += 1
	if absf(actual - expected) > epsilon:
		failures.append("%s esperado %f, obtido %f" % [message, expected, actual])


## Verifica que alguma mensagem da lista contém o trecho (usado para erros de validação).
func assert_has_error(errors: Array[String], fragment: String) -> void:
	assertions += 1
	for e: String in errors:
		if e.contains(fragment):
			return
	failures.append("nenhum erro contém '%s' em %s" % [fragment, str(errors)])

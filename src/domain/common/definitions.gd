class_name Definitions
extends RefCounted
## Conjunto somente leitura das definições estáticas (DATA_ARCHITECTURE §2).
## O domínio recebe esta instância por parâmetro; só a camada de aplicação usa o autoload DataRegistry.

var weight_classes: Dictionary = {}  # StringName -> WeightClassDef
var strikes: Dictionary = {}  # StringName -> StrikeDef
var rule_sets: Dictionary = {}  # StringName -> RuleSetDef
var load_errors: Array[String] = []


func add(def: Resource) -> void:
	var table: Dictionary = _table_for(def)
	if table == null:
		load_errors.append("tipo de definição não suportado: %s" % def)
		return
	var id: StringName = def.get("id")
	if table.has(id):
		load_errors.append("id duplicado '%s' (%s)" % [id, def.get_script().get_global_name()])
		return
	table[id] = def


func weight_class(id: StringName) -> WeightClassDef:
	return weight_classes.get(id) as WeightClassDef


func strike(id: StringName) -> StrikeDef:
	return strikes.get(id) as StrikeDef


func rule_set(id: StringName) -> RuleSetDef:
	return rule_sets.get(id) as RuleSetDef


func validate_all() -> Array[String]:
	var errors: Array[String] = load_errors.duplicate()
	for d: WeightClassDef in weight_classes.values():
		errors.append_array(d.validate())
	for d: StrikeDef in strikes.values():
		errors.append_array(d.validate())
	for d: RuleSetDef in rule_sets.values():
		errors.append_array(d.validate(self))
	return errors


## Hash de todo o conteúdo; usado para detectar alteração acidental de definições (DATA_ARCHITECTURE §4).
func content_hash() -> String:
	var parts: PackedStringArray = []
	for table: Dictionary in [weight_classes, strikes, rule_sets]:
		var ids: Array = table.keys()
		ids.sort()
		for id: StringName in ids:
			parts.append(_serialize(table[id]))
	return "\n".join(parts).sha256_text()


func _table_for(def: Resource) -> Variant:
	if def is WeightClassDef:
		return weight_classes
	if def is StrikeDef:
		return strikes
	if def is RuleSetDef:
		return rule_sets
	return null


func _serialize(def: Resource) -> String:
	var values: Dictionary = {}
	for prop: Dictionary in def.get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			values[prop["name"]] = def.get(prop["name"])
	return var_to_str(values)

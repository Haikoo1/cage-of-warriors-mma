class_name Definitions
extends RefCounted
## Conjunto somente leitura das definições estáticas (DATA_ARCHITECTURE §2).
## O domínio recebe esta instância por parâmetro; só a camada de aplicação usa o autoload DataRegistry.

var weight_classes: Dictionary = {}  # StringName -> WeightClassDef
var strikes: Dictionary = {}  # StringName -> StrikeDef
var rule_sets: Dictionary = {}  # StringName -> RuleSetDef
var grapple_techniques: Dictionary = {}  # StringName -> GrappleTechniqueDef
var archetypes: Dictionary = {}  # StringName -> ArchetypeDef
var cognitive_profiles: Dictionary = {}  # StringName -> CognitiveProfileDef
var combat_balance: CombatBalanceDef
var load_errors: Array[String] = []


func add(def: Resource) -> void:
	if def is CombatBalanceDef:
		if combat_balance != null:
			load_errors.append("CombatBalanceDef duplicado")
		combat_balance = def
		return
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


func archetype(id: StringName) -> ArchetypeDef:
	return archetypes.get(id) as ArchetypeDef


func cognitive_profile(id: StringName) -> CognitiveProfileDef:
	return cognitive_profiles.get(id) as CognitiveProfileDef


func grapple_technique(id: StringName) -> GrappleTechniqueDef:
	return grapple_techniques.get(id) as GrappleTechniqueDef


## Técnica disponível para um papel em uma posição e direção (COMBAT_ARCHITECTURE §3.3).
func find_grapple(from_state: StringName, role: StringName, dir: FighterCommand.Direction) -> GrappleTechniqueDef:
	for t: GrappleTechniqueDef in grapple_techniques.values():
		if t.from_state == from_state and t.role == role and t.direction == dir:
			return t
	return null


func validate_all() -> Array[String]:
	var errors: Array[String] = load_errors.duplicate()
	for d: WeightClassDef in weight_classes.values():
		errors.append_array(d.validate())
	for d: StrikeDef in strikes.values():
		errors.append_array(d.validate())
	for d: RuleSetDef in rule_sets.values():
		errors.append_array(d.validate(self))
	for d: GrappleTechniqueDef in grapple_techniques.values():
		errors.append_array(d.validate())
	for d: ArchetypeDef in archetypes.values():
		errors.append_array(d.validate())
	for d: CognitiveProfileDef in cognitive_profiles.values():
		errors.append_array(d.validate())
	if combat_balance == null:
		errors.append("CombatBalanceDef ausente")
	else:
		errors.append_array(combat_balance.validate())
	return errors


## Hash de todo o conteúdo; usado para detectar alteração acidental de definições (DATA_ARCHITECTURE §4).
func content_hash() -> String:
	var parts: PackedStringArray = []
	for table: Dictionary in [weight_classes, strikes, rule_sets, grapple_techniques, archetypes, cognitive_profiles]:
		var ids: Array = table.keys()
		ids.sort()
		for id: StringName in ids:
			parts.append(_serialize(table[id]))
	if combat_balance != null:
		parts.append(_serialize(combat_balance))
	return "\n".join(parts).sha256_text()


func _table_for(def: Resource) -> Variant:
	if def is WeightClassDef:
		return weight_classes
	if def is StrikeDef:
		return strikes
	if def is RuleSetDef:
		return rule_sets
	if def is GrappleTechniqueDef:
		return grapple_techniques
	if def is ArchetypeDef:
		return archetypes
	if def is CognitiveProfileDef:
		return cognitive_profiles
	return null


func _serialize(def: Resource) -> String:
	var values: Dictionary = {}
	for prop: Dictionary in def.get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			values[prop["name"]] = def.get(prop["name"])
	return var_to_str(values)

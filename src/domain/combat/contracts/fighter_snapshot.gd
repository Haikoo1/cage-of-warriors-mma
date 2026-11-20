class_name FighterSnapshot
extends RefCounted
## Cópia de valores de um lutador para uma luta. O combate nunca aponta para o FighterState (DATA_ARCHITECTURE §8).

var fighter_id: StringName = &""
var attributes: Dictionary = {}
var height_cm: int = 0
var reach_cm: int = 0
var fight_weight_kg: float = 0.0
var biotype_id: StringName = &""
var stance: Physique.Stance = Physique.Stance.ORTHODOX
var appearance: Appearance = Appearance.new()
## Modificadores do dia (corte de peso, Fadiga, lesão) — preenchidos pela carreira em etapas futuras.
var reserve_start: float = 1.0
var chin_modifier: float = 0.0


static func from_fighter(f: FighterState) -> FighterSnapshot:
	var s: FighterSnapshot = FighterSnapshot.new()
	s.fighter_id = f.id
	s.attributes = f.attributes.duplicate()
	s.height_cm = f.physique.height_cm
	s.reach_cm = f.physique.reach_cm
	s.fight_weight_kg = f.physique.walk_weight_kg
	s.biotype_id = f.physique.biotype_id
	s.stance = f.physique.stance
	s.appearance = f.appearance.duplicate_appearance()
	return s

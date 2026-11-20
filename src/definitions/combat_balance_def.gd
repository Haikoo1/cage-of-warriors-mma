class_name CombatBalanceDef
extends Resource
## Constantes globais de balanceamento do combate (BalanceConstants, DATA_ARCHITECTURE §2).
## TODOS os valores são [PROV] (COMBAT_DESIGN): precisam de playtest no marco M1.

@export_group("Movimento (COMBAT §2)")
@export var walk_speed_mps: float = 2.2
@export var back_speed_factor: float = 0.85
@export var lateral_speed_mps: float = 1.4
@export var guard_move_factor: float = 0.6
@export var cage_half_width_m: float = 4.5
@export var depth_half_m: float = 1.4
@export var cornered_distance_m: float = 1.0
@export var body_min_distance_m: float = 0.55
@export var collision_depth_m: float = 0.45
@export var angle_frames: int = 36
@export var angle_tolerance_factor: float = 0.7
@export var reference_reach_cm: float = 180.0

@export_group("Fôlego e Reserva (COMBAT §6.1)")
@export var move_stamina_per_s: float = 1.0
@export var lateral_stamina_per_s: float = 2.0
@export var regen_per_s: float = 8.0
@export var reserve_loss_ratio: float = 0.15
@export var reserve_floor: float = 20.0
@export var body_damage_reserve_ratio: float = 0.3

@export_group("Defesa (COMBAT §3.6)")
@export var block_damage_ratio: float = 0.2
@export var block_stamina_ratio: float = 0.4
@export var evade_frames: int = 14
@export var evade_stamina: float = 2.5
@export var slip_offset_m: float = 0.35
@export var pull_range_m: float = 0.25

@export_group("Golpes e choque (COMBAT §3.5, §6.3)")
@export var counter_mult: float = 1.5
@export var power_variance: float = 0.05
@export var shock_base: float = 28.0
## Fração do impacto que vira dano por zona (calibrado na E-05 com lotes IA x IA).
@export var damage_scale: float = 0.5
@export var rocked_ratio: float = 0.6
@export var stunned_ratio: float = 1.0
@export var knockdown_ratio: float = 1.5
@export var knockout_ratio: float = 2.2
@export var rocked_frames: int = 20
@export var stunned_frames: int = 150
@export var knockdown_frames: int = 120


@export_group("Grappling (COMBAT §4)")
## Bônus de pressão por progresso parcial acumulado na mesma técnica.
@export var partial_bonus: float = 0.2
@export var partial_ratio: float = 0.8
## Leitura no primeiro terço da janela é "perfeita" e abre o contra.
@export var perfect_read_fraction: float = 0.34
@export var fail_stamina_mult: float = 2.0
@export var gnp_power: float = 9.0
@export var gnp_cooldown_frames: int = 24
@export var gnp_mult_guard: float = 0.6
@export var gnp_mult_half: float = 0.8
@export var gnp_mult_side: float = 1.0
@export var gnp_mult_mount: float = 1.2
@export var gnp_mult_back: float = 0.5
@export var clinch_knee_power: float = 12.0
@export var clinch_elbow_power: float = 10.0
@export var clinch_strike_cooldown_frames: int = 30
@export_group("Cortes (COMBAT §6.4)")
@export var cut_chance_elbow: float = 0.18
@export var cut_chance_power: float = 0.05
@export var cut_chance_other: float = 0.02
@export var cut_min_head_damage: float = 8.0
@export var doctor_stop_chance: float = 0.5
@export_group("Grappling (cont.)")
@export var squeeze_cycle_frames: int = 60
@export var squeeze_start: float = 20.0
@export var squeeze_escape_drop: float = 25.0


func validate() -> Array[String]:
	var errors: Array[String] = []
	if walk_speed_mps <= 0.0 or lateral_speed_mps <= 0.0:
		errors.append("CombatBalanceDef: velocidades devem ser > 0")
	if not (rocked_ratio < stunned_ratio and stunned_ratio < knockdown_ratio and knockdown_ratio < knockout_ratio):
		errors.append("CombatBalanceDef: limiares de choque devem ser crescentes")
	if cage_half_width_m <= body_min_distance_m:
		errors.append("CombatBalanceDef: jaula menor que a distância mínima entre corpos")
	return errors

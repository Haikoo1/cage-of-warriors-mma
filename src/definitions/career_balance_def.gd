class_name CareerBalanceDef
extends Resource
## Constantes da carreira (CAREER_DESIGN). Todos [PROV]: precisam de playtest (M4).

@export_group("Treino e fadiga (§4)")
@export var blocks_per_week: int = 12
@export var weekly_fatigue_recovery: float = 30.0
## Recuperação extra proporcional à fadiga atual (quanto mais cansado, mais o descanso rende).
@export var fatigue_recovery_ratio: float = 0.25
@export var fatigue_penalty_start: float = 40.0
@export var fatigue_block_heavy: float = 90.0
@export var potential_softness: float = 15.0
@export var untrained_decay: float = 0.05
@export var conditioning_decay: float = 0.35

@export_group("Idade (CHARACTER §7.3)")
@export var physical_decline_per_month: float = 0.35
@export var development_age: int = 25

@export_group("Saúde (§5)")
@export var training_injury_scale: float = 1.0
@export var ko_suspension_weeks: int = 8
@export var tko_suspension_weeks: int = 6
@export var decision_suspension_weeks: int = 2
@export var wear_per_ko: float = 8.0
@export var wear_per_tko: float = 4.0
@export var retirement_wear: float = 85.0

@export_group("Peso (§6)")
@export var cut_soft: float = 0.05
@export var cut_hard: float = 0.08
@export var cut_extreme: float = 0.12
@export var weight_miss_fine: float = 0.2

@export_group("Economia (§10)")
@export var cost_of_living_week: float = 150.0
@export var team_cut: float = 0.15
@export var short_notice_bonus: float = 0.25

@export_group("Reputação e ranking (§9–10)")
@export var elo_k: float = 32.0
@export var finish_k_bonus: float = 1.25
@export var popularity_win: float = 3.0
@export var popularity_finish: float = 3.0
@export var popularity_loss: float = -2.0
@export var popularity_decay_week: float = 0.05

@export_group("Mundo (§11)")
@export var npc_retire_age: int = 36
@export var prospects_per_month: int = 1
@export var offer_chance: float = 0.6
@export var camp_weeks_min: int = 6
@export var camp_weeks_max: int = 9


func validate() -> Array[String]:
	var errors: Array[String] = []
	if blocks_per_week < 1 or not (cut_soft < cut_hard and cut_hard < cut_extreme):
		errors.append("CareerBalanceDef: blocos ou faixas de corte inválidos")
	return errors

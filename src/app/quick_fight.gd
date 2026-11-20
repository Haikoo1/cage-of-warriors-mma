class_name QuickFight
extends RefCounted
## Monta a Luta Rápida (GDD §3): lutadores de exemplo por estilo + configuração de controle.
## Mesmo contrato FightSetup da carreira (CAREER_ARCHITECTURE §7).

const STYLES: Array[String] = ["Trocador", "Wrestler", "Equilibrado"]
const STYLE_ARCHETYPE: Array[StringName] = [&"arch_striker", &"arch_wrestler", &"arch_striker"]
const PROFILES: Array[StringName] = [&"cog_beginner", &"cog_intermediate", &"cog_elite"]
const PROFILE_NAMES: Array[String] = ["Iniciante", "Intermediário", "Elite"]
const ROUND_LENGTHS: Array[int] = [60, 120, 180, 300]

## Atributos de exemplo [PROV]: ilustram estilos, não estão balanceados.
const STYLE_ATTRIBUTES: Array[Dictionary] = [
	{&"boxe": 72, &"kickboxing": 70, &"defesa_em_pe": 66, &"velocidade": 66, &"mobilidade": 64,
	 &"wrestling_ofensivo": 40, &"wrestling_defensivo": 64, &"controle_solo": 40, &"jiu_jitsu": 35, &"defesa_finalizacao": 45},
	{&"wrestling_ofensivo": 76, &"wrestling_defensivo": 72, &"controle_solo": 72, &"forca": 68, &"condicionamento": 66,
	 &"boxe": 45, &"kickboxing": 35, &"defesa_em_pe": 45, &"jiu_jitsu": 52, &"defesa_finalizacao": 56},
	{},
]


class Config:
	var setup: FightSetup
	var ai_a: CombatAI  # null = jogador controla o lutador A
	var ai_b: CombatAI
	var watch_only: bool = false


static func fighter_for_style(id: StringName, name: String, style: int) -> FighterState:
	var f: FighterState = FighterState.create_blank(id, 58.0)
	f.display_name = name
	f.weight_class_id = &"m_lightweight"
	for attr: StringName in STYLE_ATTRIBUTES[style]:
		f.attributes[attr] = float(STYLE_ATTRIBUTES[style][attr])
	return f


static func build(defs: Definitions, player_style: int, opp_style: int, profile: int, title: bool,
		round_length: int, watch_only: bool, seed: int) -> Config:
	var cfg: Config = Config.new()
	var setup: FightSetup = FightSetup.new()
	setup.bout_id = &"QUICK"
	setup.fighter_a = FighterSnapshot.from_fighter(fighter_for_style(&"F-A", "Você" if not watch_only else STYLES[player_style], player_style))
	var opp: FighterState = fighter_for_style(&"F-B", STYLES[opp_style], opp_style)
	var look_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	look_rng.seed = seed
	opp.appearance = Appearance.random(look_rng, true)
	opp.appearance.shorts = 1 if opp.appearance.shorts == 0 else opp.appearance.shorts
	setup.fighter_b = FighterSnapshot.from_fighter(opp)
	setup.ruleset_id = &"rs_standard"
	setup.weight_class_id = &"m_lightweight"
	setup.is_title = title
	setup.round_seconds_override = ROUND_LENGTHS[round_length]
	setup.seed = seed
	setup.control_a = FightSetup.ControlMode.AI if watch_only else FightSetup.ControlMode.PLAYER
	setup.control_b = FightSetup.ControlMode.AI
	cfg.setup = setup
	cfg.watch_only = watch_only
	cfg.ai_b = CombatAI.new(defs.archetype(STYLE_ARCHETYPE[opp_style]), defs.cognitive_profile(PROFILES[profile]), 1, seed + 1)
	if watch_only:
		cfg.ai_a = CombatAI.new(defs.archetype(STYLE_ARCHETYPE[player_style]), defs.cognitive_profile(PROFILES[profile]), 0, seed + 2)
	return cfg

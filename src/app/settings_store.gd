class_name SettingsStore
extends RefCounted
## Preferências globais em ConfigFile (SAVE_AND_TESTING §1.1, GAME_SYSTEMS §7).

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var ambience_volume: float = 0.8
var voice_volume: float = 1.0
var hud_level: StringName = &"full"  # full / minimal / immersive (R-027)
var directions_relative_to_opponent: bool = true  # V-007, testar em E-03
var show_blood: bool = true  # R-029: sangue estilizado e opcional
## Teclas trocadas pelo jogador: StringName (ação) -> keycode.
var key_overrides: Dictionary = {}


func save_to(path: String) -> Error:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "ambience", ambience_volume)
	cfg.set_value("audio", "voice", voice_volume)
	cfg.set_value("hud", "level", String(hud_level))
	cfg.set_value("video", "blood", show_blood)
	cfg.set_value("controls", "relative_directions", directions_relative_to_opponent)
	for action: StringName in key_overrides:
		cfg.set_value("keys", String(action), int(key_overrides[action]))
	return cfg.save(path)


func load_from(path: String) -> Error:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(path)
	if err != OK:
		return err
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	ambience_volume = cfg.get_value("audio", "ambience", ambience_volume)
	voice_volume = cfg.get_value("audio", "voice", voice_volume)
	hud_level = StringName(cfg.get_value("hud", "level", String(hud_level)))
	show_blood = cfg.get_value("video", "blood", show_blood)
	directions_relative_to_opponent = cfg.get_value("controls", "relative_directions", directions_relative_to_opponent)
	key_overrides = {}
	if cfg.has_section("keys"):
		for action: String in cfg.get_section_keys("keys"):
			key_overrides[StringName(action)] = int(cfg.get_value("keys", action))
	return OK

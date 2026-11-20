extends Node
## Autoload AudioDirector (T-008): barramentos, efeitos com polifonia limitada, ambiente em laço, cliques de UI.
## Domínio nunca chama áudio; só a apresentação.

const BUSES: Array[String] = ["Music", "SFX", "Ambience", "Voice"]
const VOICES: int = 8
const SFX_DIR: String = "res://assets/audio/sfx/%s.wav"

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _ambience: AudioStreamPlayer
var _cache: Dictionary = {}


func _ready() -> void:
	for bus: String in BUSES:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for k: int in VOICES:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Ambience"
	_ambience.finished.connect(func() -> void: _ambience.play())  # laço
	add_child(_ambience)
	apply_volumes()


func apply_volumes() -> void:
	var s: SettingsStore = Settings.store
	_set_bus("Master", s.master_volume)
	_set_bus("SFX", s.sfx_volume)
	_set_bus("Music", s.music_volume)
	_set_bus("Ambience", s.ambience_volume)


func play(sound: StringName, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> void:
	if sound == &"":
		return
	var stream: AudioStream = _stream(sound)
	if stream == null:
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func start_ambience(sound: StringName, volume_db: float = -8.0) -> void:
	_ambience.stream = _stream(sound)
	_ambience.volume_db = volume_db
	if _ambience.stream != null:
		_ambience.play()


func stop_ambience() -> void:
	_ambience.stop()


func ui_click() -> void:
	play(&"ui_click", -10.0, 0.02)


func _stream(sound: StringName) -> AudioStream:
	if not _cache.has(sound):
		_cache[sound] = load(SFX_DIR % sound) as AudioStream
	return _cache[sound]


func _set_bus(bus: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(0.001, linear)))

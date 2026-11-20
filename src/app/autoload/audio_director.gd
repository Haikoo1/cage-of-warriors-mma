extends Node
## Autoload AudioDirector (T-008): barramentos de áudio e, nas próximas etapas, música/ambiente entre telas.

const BUSES: Array[String] = ["Music", "SFX", "Ambience", "Voice"]


func _ready() -> void:
	for bus: String in BUSES:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)

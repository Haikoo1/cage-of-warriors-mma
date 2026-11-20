class_name CareerRng
extends RefCounted
## Fluxos de aleatoriedade da carreira (T-013): derivados de (semente da carreira, semana, nome do fluxo).
## Nada para salvar além da semente; mudar o uso de um fluxo não altera os outros.


static func make(c: CareerState, stream: StringName, salt: int = 0) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([c.career_seed, c.week_index, String(stream), salt])
	return rng

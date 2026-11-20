# Marco M3 — "O mundo é coerente?" (E-08)

> Volta ao [ROADMAP](../ROADMAP.md). Ferramenta: `tests/runner/world_years.gd` (mundo sozinho, jogador aposentado).

## Medição (2026-11-20, semente 2026, 10 anos)
| Critério (ROADMAP §3) | Resultado | Situação |
|---|---|---|
| 20 anos sem colapso de população | 10 anos medidos: ativos 444 → 455 (faixa 455–543) | ✅ parcial (10 de 20 anos) |
| Campeões trocam com frequência plausível | 381 trocas em 48 cinturões em 10 anos (≈ 0,8 por cinturão/ano) | ✅ um pouco alta; revisar no balanceamento |
| Sem IDs órfãos | 0 campeões aposentados ou fora da organização | ✅ |
| Simulação de 1 ano em poucos segundos | ≈ 0,7–1,6 s por ano (≈ 22 ms por semana) | ✅ |
| Resolvedor dentro de ±10 p.p. do combate jogado | **Não medido**: falta a comparação com o lote IA × IA do motor | ⏳ pendente |

## Observações
- Lutadores aposentados continuam no save: 894 registros após 10 anos. O save cresce de forma linear; podar NPCs aposentados sem vínculo com o jogador é uma otimização futura (SAVE §1).
- Trocas de cinturão possivelmente frequentes demais: a disputa acontece a cada 4 eventos, e o resolvedor tem variância alta. Ajustar no E-13.

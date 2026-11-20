# Marco M1 — "A luta é divertida?" (E-05)

> Volta ao [ROADMAP](../ROADMAP.md). Critérios do marco em ROADMAP §3.
> Este documento registra o que foi **medido automaticamente** e o roteiro do **playtest humano**, que é o que decide o M1.

## 1. Medições automáticas (lotes IA x IA)

Ferramenta: `tests/runner/batch_ai.gd` (40 lutas por confronto, 3 × 5 min, IA intermediária, lutadores de exemplo da Luta Rápida). Números de balanceamento são todos `[PROV]`.

### 1.1 Antes do ajuste (primeira versão da E-05)
| Confronto | Métodos | Tempo médio | Vitórias de A |
|---|---|---|---|
| Trocador x Trocador | KO 38, TKO 1, decisão 1 | 26 s | 21/40 |
| Trocador x Wrestler | KO 27, finalização 10, decisão 3 | 178 s | 6/40 |
| Wrestler x Wrestler | KO 29, finalização 6, decisão 5 | 188 s | **6/40** |
| Equilibrado x Equilibrado | decisão 21, KO 18, TKO 1 | 529 s | 26/40 |

Problemas encontrados:
1. **Letalidade irreal:** trocador × trocador terminava por KO em 26 s, em média.
2. **Viés de ordem:** no espelho wrestler × wrestler, o lado A vencia 6 de 40. Causa: as duas IAs decidiam no mesmo quadro, e o lado A era sempre processado primeiro. Ele sempre iniciava a queda e sempre era lido pela IA B. Era um artefato da simulação, não uma vantagem de estilo.

### 1.2 Ajustes feitos
| Ajuste | Onde | Motivo |
|---|---|---|
| Ordem de processamento alternada a cada quadro | `CombatSim.step` | Nenhum lado com prioridade fixa em ações simultâneas |
| Relógio de decisão da IA começa desalinhado (aleatório com semente) | `CombatAI._init` | Evita IAs sincronizadas |
| `shock_base` 20 → 28, novo `damage_scale` = 0,5 | `data/balance/combat_balance.tres` (padrões) | Letalidade |
| Dano dividido: 70% agudo, 30% residual | `CombatPhysiology.apply_hit` | COMBAT §6.2 (o residual não era usado antes) |
| Double leg 16 → 20 quadros, single leg 12 → 15 | `tools/gen_grappling_data.js` | "Preparação visível" (COMBAT §4.4); a IA intermediária só tinha 1 quadro de janela |
| Defesa de queda do trocador de exemplo 52 → 64 | `QuickFight.STYLE_ATTRIBUTES` | Trocadores reais treinam defesa de queda |

### 1.3 Depois do ajuste
| Confronto | Métodos | Tempo médio | Vitórias de A |
|---|---|---|---|
| Trocador x Trocador | KO 20, TKO 2, decisões 16, empates 2 | 425 s | 26/40 |
| Trocador x Wrestler | decisões 27, finalização 11, empates 2 | 689 s | 7/40 |
| Wrestler x Wrestler | decisões 21, finalização 13, empates 5, TKO 1 | 669 s | 21/40 |
| Equilibrado x Equilibrado | decisões 35, finalização 2, TKO 2, empate 1 | 826 s | 22/40 |

**Leitura:**
- O viés de ordem acabou: os espelhos ficam perto de 50%.
- Três métodos de vitória aparecem (KO/TKO, finalização, decisão), um dos critérios do M1.
- **Pendência:** o trocador ainda perde para o wrestler (7/40). Parte disso é a IA trocadora ficar dentro do alcance de queda; a outra parte são os atributos de exemplo. Reavaliar com o playtest.
- **Pendência:** a IA não reage a golpes rápidos, porque a preparação do jab (100 ms) é menor que o atraso mínimo de percepção (150 ms). Isso é coerente com o design (ninguém "reage" a um jab), mas significa que a defesa da IA em pé é só preventiva (guarda e distância).

## 2. Roteiro do playtest humano (decide o M1)
1. Rode o jogo, aperte Enter (Luta Rápida) e jogue com:
   - você Trocador × Wrestler, IA Intermediária, 3 rounds de 2 min;
   - você Wrestler × Trocador, IA Elite;
   - IA × IA (assistir) por um round.
2. Responda:
   - Terminou as lutas por vontade própria e quis jogar outra?
   - Conseguiu explicar por que ganhou ou perdeu (HUD, intervalo, resultado)?
   - Viu pelo menos duas formas de vitória?
   - Alguma ação "sempre funciona" (spam)? Qual?
   - A IA pareceu injusta ou burra em algum momento? Quando?
   - O ritmo dos rounds está bom? Os KOs são frequentes demais ou de menos?
3. **Se o M1 falhar, não avançar para a carreira (E-07).** Ajustar combate e IA primeiro.

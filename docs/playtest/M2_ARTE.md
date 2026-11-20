# Marco M2 — "A arte é viável?" (E-06, spike do pipeline 3D → pixel)

> Volta ao [ROADMAP](../ROADMAP.md) · Decisões: D-012 (solo, sem artista), D-014 (decidir pipeline após spike), R-036, R-037.

## 1. O que foi construído
- `tools/art_pipeline/pipeline.py` (Blender 5.3, headless): gera por script um **manequim de segmentos rígidos** (sem assets de terceiros), anima 7 ações, renderiza com câmera ortográfica lateral e sombreamento toon de 3 tons, quantiza para a paleta, adiciona contorno de 1 px e monta spritesheets + JSON em `assets/sprites/fighters/m_medium/`.
- Os tempos de cada golpe vêm de `data/strikes` e `data/grappling`: a animação acompanha a regra (ART §6.1).
- No jogo: **F4** na Luta Rápida ou no treino alterna greybox ↔ sprites. O quadro de cada golpe é escolhido pela fase da simulação (preparação → execução → recuperação). O solo continua em greybox neste spike.

## 2. Medições (máquina do desenvolvedor, 2026-11-20)
| Item | Medido |
|---|---|
| Animações geradas | 7 (guarda, andar, jab, direto, chute baixo, double leg, reação de cabeça) |
| Quadros de sprite | 50 (15 fps de sprite, 1 quadro a cada 4 de simulação) |
| Tempo total do pipeline | 37,9 s (≈ 31 s de compilação de shaders na 1ª animação; depois ≈ 1 s por animação) |
| Tamanho em disco | ≈ 550 KB para 7 folhas PNG (224 × 160 por quadro) |
| Altura do lutador na tela | 136 px na resolução-base 640 × 360 (ART §3) |

## 3. Estimativa para o inventário completo (estimativa, não medição)
| Item | Pipeline 3D → pixel | Pixel à mão (referência ART §6.2) |
|---|---|---|
| Render de ≈ 175 animações × 4 biotipos (R-037) | ≈ 12 min de máquina | — |
| Autoria das animações | Feita **uma vez** no esqueleto e reaproveitada nos 4 biotipos. Estimativa de 30–60 min por animação com rig real no Blender → **≈ 90–175 h** | ≈ 8.000 quadros × 20–40 min → **≈ 2.700–5.300 h** |
| Variações (cabelo, calção, tons de pele) | Passes de render / troca de paleta, automáticos | Cada variação multiplica o trabalho |

Conclusão provisória: **o pipeline 3D → pixel cabe no escopo de um desenvolvedor solo; o desenho à mão não cabe.** A diferença é de mais de uma ordem de grandeza.

## 4. Limitações honestas do spike
- O manequim é **rudimentar**: segmentos rígidos (tronco em cone, juntas sem deformação). Mede o pipeline, **não** a qualidade final.
- O chute baixo e a double leg leem pior que os socos: falta trabalho de pose, que é exatamente o custo de autoria estimado acima.
- O solo e o clinch não foram renderizados (as animações pareadas por papel são o maior custo restante; ART §6.1).
- Ainda não houve limpeza manual dos quadros-chave (prevista em R-036).

## 5. O que falta para a arte final (decisões futuras do usuário)
1. **Modelo humanoide com skinning e rig:** adquirido com licença comercial (custo e licença a decidir) ou modelado.
2. Biotipos por *blend shapes* no mesmo rig (R-037).
3. Camadas de personalização como passes de render separados (P-004).
4. Animações de solo pareadas com âncoras comuns.

## 6. Critério do M2
| Critério (ROADMAP §3) | Situação |
|---|---|
| Custo medido permite estimar o inventário completo | ✅ render medido; autoria estimada (§3) |
| Leitura aprovada pelo usuário em jogo | ⏳ **Aguardando:** jogue com F4 ligado |
| Legibilidade de Z e golpes | ⏳ Avaliar junto: sombra de contato + deslocamento vertical com sprites |

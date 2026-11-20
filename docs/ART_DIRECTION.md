# ART DIRECTION — Projeto Jaula

> Versão 0.1 · Etapa 01 · Volta ao [GDD](GDD.md)
> Nenhuma arte foi produzida nesta etapa. Tudo aqui é direção e recomendação; itens visuais precisam de **validação com mockups** (Etapa E-06).

---

## 1. Referências descritivas

Sem copiar nenhum jogo específico. O alvo visual é descrito por qualidades:

- **Pixel art moderna "alta resolução":** personagens grandes com sombreamento em 3–4 tons por material, contorno escuro seletivo (não preto puro em todo lugar), iluminação de cima marcada (holofotes da jaula).
- **Animação com peso:** antecipação e recuperação claras (servem à jogabilidade: a preparação do golpe é o *telegraph*), *smear frames* nos golpes rápidos, *hit-stop* curto.
- **Atmosfera de evento ao vivo:** arena escura, lona clara sob luz forte, público em silhueta com pontos de luz (celulares, telões), fumaça leve.
- **Leitura acima do detalhe:** em qualquer quadro, deve ser possível dizer quem está atacando, qual membro e em que altura.

---

## 2. Pilares visuais

1. **Silhueta legível:** a pose de cada golpe é identificável apenas pela silhueta.
2. **O corpo conta a história:** cansaço, dano e perigo aparecem no sprite antes do HUD ([COMBAT §8.1](COMBAT_DESIGN.md#81-sinais-no-corpo-do-lutador-prioritários-sobre-hud)).
3. **Contraste lutador × cenário:** fundo dessaturado e escuro; lutadores com mais saturação e luz.
4. **Consistência de escala de pixel:** nunca misturar pixels de tamanhos diferentes (sem escala não inteira, sem rotação de sprites em jogo).

---

## 3. Resolução e escala — `RECOMENDAÇÃO R-003` (PENDENTE de validação visual)

| Resolução-base | 1080p | 1440p | 4K | Altura do lutador (≈40% da tela) | Custo de arte | Avaliação |
|---|---|---|---|---|---|---|
| 480 × 270 | ×4 | ×5,33 (não inteiro) | ×8 | ≈ 105 px | Baixo | Detalhe insuficiente para "personagens grandes e detalhados"; 1440p exige barras ou escala não inteira |
| **640 × 360** | **×3** | **×4** | **×6** | **≈ 130–150 px** | **Alto** | **Escala inteira nas três resoluções comuns; detalhe bom para rosto, mãos e luvas** |
| 960 × 540 | ×2 | ×2,67 (não inteiro) | ×4 | ≈ 210 px | Muito alto | Detalhe excelente, mas custo de animação proibitivo para o escopo independente |

- **Recomendação:** 640 × 360 com escala inteira; em resoluções sem múltiplo inteiro (ex.: 1366 × 768, ultrawide), barras laterais/superiores com moldura de arte ou ampliação da área visível horizontal (mais cenário, mesma escala).
- **Escala de sprite:** 1 pixel de sprite = 1 pixel da resolução-base. Sem sprites em "meia escala".
- **Revisado por D-022:** a luta roda em **960 × 540** (2x em 1080p) e o lutador médio tem **≈ 189 px** (105 px/m), corpo orgânico em 3/4 no estilo da referência do usuário. Os valores abaixo são o plano original em 640 × 360.
- **Altura dos lutadores na tela** `[PROV]`: biotipos leves ≈ 128 px, médios ≈ 136 px, pesados ≈ 144 px, superpesados ≈ 150 px (diferença intencionalmente menor que a real para manter a leitura; a largura comunica a massa).
- **Câmera:** sem zoom dinâmico (só existiria em múltiplos inteiros, o que é brusco). Panorâmica horizontal suave com *snap* de pixel. Jaula mais larga que a tela (≈ 700 px de diâmetro em X `[PROV]`).
- **Risco:** 640 × 360 com personagens de ~140 px é o fator que mais encarece animação. Ver §11.

---

## 4. Paleta de cores

- **Paleta-mestre limitada** (≈ 48–64 cores `[PROV]`) compartilhada por cenário, UI e efeitos; lutadores usam rampas próprias trocáveis por paleta (pele, cabelo, calção, luvas).
- **Pele:** 8–10 rampas de tom de pele com 4–5 tons cada, revisadas para representar diversidade com qualidade igual (sem tons "padrão" mais detalhados que outros).
- **Codificação de cor do jogo:**
  | Uso | Cor | Observação de acessibilidade |
  |---|---|---|
  | Impacto limpo | Branco/amarelo quente | Acompanha forma (faísca) e som |
  | Bloqueio | Azul frio | Faísca de forma diferente |
  | Contra-golpe | Laranja + *flash* | Forma distinta |
  | Perigo (finalização, atordoado) | Vermelho | Pulsação + ícone |
  | Fôlego | Verde → amarelo → vermelho | Barra também muda de padrão |
- Calções e luvas dos dois lutadores devem contrastar (o sistema escolhe cores de canto automaticamente se as escolhidas forem parecidas).

---

## 5. Personagens, proporções e biotipos

### 5.1 Proporções
- Proporção "atlética realista levemente estilizada": ≈ 7 cabeças de altura, mãos e luvas um pouco maiores que o real (leitura dos socos), pés firmes.
- Rosto com poucos pixels de detalhe; expressão comunicada por pose da cabeça, sobrancelha e boca em 1–2 pixels.

### 5.2 Biotipos — `RECOMENDAÇÃO R-005`
O corpo é definido por **biotipo**, não por categoria. Cada biotipo é um conjunto completo de animações.

| Biotipo | Categorias que o usam ([CHARACTER §6.2](CHARACTER_DESIGN.md#62-categorias-de-peso--aprovada-d-007-lista--limites-como-recomendação-r-020)) |
|---|---|
| M-Leve | Mosca, Galo, Pena |
| M-Médio | Pena, Leve, Meio-médio, Médio |
| M-Pesado | Médio, Meio-pesado, Pesado |
| M-Superpesado | Pesado |
| F-Leve | Palha, Mosca |
| F-Médio | Mosca, Galo, Pena |

- **6 biotipos** cobrem as 12 categorias com boa representação física. **Para o contexto solo (D-012), recomenda-se começar com 4** (`R-037`, alternativa abaixo) e expandir só se o spike mostrar custo baixo por biotipo. Variação de altura dentro do biotipo: 2 alturas por biotipo (ou deslocamento de pernas/tronco em camadas) `[PENDENTE: depende do pipeline]`.
- **Alternativa mais barata** (se o pipeline for desenho à mão): 4 biotipos (M-Leve, M-Médio, M-Pesado, F) com variação de largura por camadas de músculo. Pior representação física, custo bem menor.

### 5.3 Camadas do sprite (personalização)
Corpo base (pele por paleta) → tatuagens → calção → luvas/faixas → cabelo/barba → efeitos de dano (inchaço, cortes, suor). Todas as camadas precisam acompanhar **todos os quadros** de animação — cada opção de cabelo ou barba multiplica o trabalho (`P-004`).

---

## 6. Animações

### 6.1 Princípios ligados ao gameplay
- **A duração das fases do golpe vem dos dados de combate**; a animação é produzida para casar com ela (não o contrário). Em greybox, as fases existem sem animação.
- Toda preparação precisa de uma **pose de *telegraph* clara** nos primeiros quadros.
- Animações de solo são produzidas **por papel** (por cima / por baixo) com pontos de ancoragem comuns, para combinar qualquer par de biotipos sem animar cada combinação.

### 6.2 Inventário estimado por biotipo (1.0) `[PROV]`
| Grupo | Animações | Observação |
|---|---|---|
| Locomoção | ≈ 8 | guarda, andar frente/trás, passo lateral (2), passo rápido, circular/giro, guarda cansada |
| Golpes em pé | ≈ 15 | catálogo de [COMBAT §3.2](COMBAT_DESIGN.md#32-catálogo-de-golpes-em-pé) com variações de corpo |
| Defesa | ≈ 9 | guardas, check, esquivas, reações de bloqueio |
| Reações e quedas | ≈ 10 | cabeça leve/forte, corpo, perna, abalado, atordoado, knockdown, caído, levantar, apagão |
| Clinch (por papel) | ≈ 20 | entrada, neutro, pummel, golpes, grade, separação, giro, trip |
| Quedas | ≈ 8 | double, single, sprawl, queda na grade (por papel) |
| Solo (por papel) | ≈ 50 | 6 estados × 2 papéis, GnP, transições, levantar |
| Finalizações | ≈ 48 | 6 × (encaixe, aperto, desistência, escape) × 2 papéis |
| Apresentação | ≈ 6 | entrada, comemoração, decepção, encarada, mão levantada |
| **Total** | **≈ 175** | média ≈ 8 quadros → **≈ 1.400 quadros por biotipo** |

Com 6 biotipos: **≈ 8.000+ quadros**, antes de camadas de personalização. **Isto é inviável para desenho à mão quadro a quadro em uma produção independente pequena.** É o maior risco do projeto ([ROADMAP §5](ROADMAP.md#5-riscos)).

### 6.3 Protótipo
Greybox: formas simples (cápsulas/retângulos coloridos com indicação de membro ativo). **Nenhuma animação final antes da validação do combate (E-05).** Um conjunto de ≈ 20 animações de um biotipo pode ser produzido no spike de arte (E-06) para validar escala e leitura.

### 6.4 Estados e transições
Máquina de estados de animação espelha a máquina de estados de posição ([COMBAT §4.1](COMBAT_DESIGN.md#41-estados-de-posição)): cada estado de posição tem uma animação de repouso por papel; transições têm animação própria ou, quando não houver, um quadro de mistura (corte rápido com *smear*/poeira) — aceito para transições raras.

---

## 7. Cenários

| Elemento | Direção |
|---|---|
| Jaula | Grade visível nas extremidades X (interativas) e ao fundo (cenário); grade da frente omitida ou com transparência quando os lutadores estão perto da câmera |
| Lona | Clara, com logos fictícios da organização; marcas de suor/sangue acumulando por round (opcional) |
| Iluminação | Luz de cima concentrada; sombras de contato elípticas sob os lutadores (essenciais para ler a profundidade Z) |
| Público | Camadas de silhueta com animação de 2–4 quadros, pontos de luz; reage a momentos (KD, finalização) com troca de camada |
| Paralaxe | 3–4 camadas: arquibancada distante, público próximo, estrutura/telões, grade do fundo |
| Variação por organização | Circuito local (ginásio, arquibancada vazia, luz fluorescente) → elite (arena cheia, telões, fumaça). Mesmo layout, troca de camadas e paleta — barato e comunica progresso de carreira |

**Simulação de profundidade:** ordenação por Z, sombra de contato com tamanho constante, deslocamento vertical do sprite por Z. **Sem escala do sprite por profundidade** (quebraria a grade de pixels).

---

## 8. Efeitos

| Efeito | Direção | Configurável |
|---|---|---|
| Impacto | Faíscas com formas distintas por tipo (§4) + hit-stop | Tremor de tela on/off |
| Suor | Gotas em golpes fortes e no rosto em Fôlego baixo | — |
| Sangue | Pequenas gotas e manchas, cortes no rosto; estilizado, não gore | On/off (`R-029`, `P-006`) |
| Poeira/impacto na lona | Quedas e knockdowns | — |
| Inchaço | Camada de dano sobre a cabeça em 2–3 níveis | — |

---

## 9. Interface e tipografia

- UI desenhada na mesma resolução-base, com **fonte em pixel** para títulos e uma fonte bitmap de alta legibilidade para textos longos (carreira tem muito texto: legibilidade vence estilo).
- Telas de carreira em painel único com navegação por abas laterais; tudo navegável por teclado (principal), mouse e gamepad.
- HUD de combate nas bordas superiores, longe do espaço dos lutadores; overlay de grappling próximo ao lutador do jogador, pequeno.
- Escala da UI independente (1×–3×) — [GAME_SYSTEMS §7](GAME_SYSTEMS.md#7-configurações-e-acessibilidade--sys-26).
- Identidade gráfica (nome, logos das organizações) só depois de `P-008`.

---

## 10. Regras de consistência visual

1. Luz principal sempre de cima/levemente à frente.
2. Contorno: escuro colorido (não preto) nos lutadores; cenário sem contorno.
3. Mesmas rampas de tom para materiais iguais em todos os biotipos.
4. Mesma altura de olhos/ombros entre biotipos de mesma altura (ancoragem de golpes coerente).
5. Ponto de ancoragem (pés, quadril) fixo por animação, documentado.
6. Nenhum sprite rotacionado ou escalado em tempo de execução.
7. Toda nova animação passa pelo teste de silhueta (preenchida em preto, ainda legível).

---

## 11. Pipeline de produção de arte — método `APROVADA D-014` · escolha final `PENDENTE P-003` · contexto `D-012` (solo, sem artista)

| Opção | Como funciona | Prós | Contras |
|---|---|---|---|
| **A. Desenho à mão quadro a quadro** | Artista anima cada quadro em pixel | Estética mais "autoral" | Custo inviável para ≈ 8.000 quadros × camadas; cada biotipo e cada opção de cabelo multiplica tudo |
| **B. 3D → pixel (renderização de modelos 3D em baixa resolução + limpeza)** | Modelos 3D com rig e animação; renderização em 640×360 com sombreamento discreto (*toon*) e paleta limitada; limpeza manual de quadros-chave | Biotipos por *blend shapes* no mesmo rig; animações reaproveitadas entre biotipos; animações pareadas de grappling com alinhamento exato; personalização por camadas renderizadas automaticamente | Exige pipeline técnico (Blender + script de render); risco de aparência "3D filtrado" se não houver limpeza; precisa de alguém com habilidade 3D |
| **C. Animação 2D por partes (cutout/esqueleto) com peças em pixel** | Sprites recortados por membro animados por esqueleto | Barato, reaproveitável | Rotação de peças quebra a grade de pixels; visual "boneco articulado" contrário à direção |

**Decisão de método (D-014):** o pipeline será escolhido ao fim do spike E-06, com custo medido.

**Avaliação direta para o contexto solo sem artista (D-012):** a opção **A é inviável** para o escopo descrito. Mesmo com cortes fortes (4 biotipos, metade das posições), seriam milhares de quadros desenhados por alguém que também programa todo o jogo. Por isso o spike deve testar primeiro a opção **B** (`R-036`):

1. **Modelos-base 3D** adquiridos (corpo masculino e feminino com rig humanoide), com licença comercial que permita modificar e redistribuir em forma renderizada. Biotipos por *blend shapes*/escala de ossos.
2. **Animações** de bibliotecas de captura de movimento/keyframe com a mesma condição de licença (socos, chutes, quedas), ajustadas no Blender; grappling pareado será em grande parte animação própria, que é a parte mais cara e deve ser medida no spike.
3. **Renderização** em 640×360 com sombreamento discreto e paleta limitada; **limpeza manual** só nos quadros-chave (preparação e impacto), onde a leitura importa.
4. **Encomendas pontuais** (logos, UI, retratos) se houver orçamento.

**Não recomendado como base:** arte gerada por IA para sprites de animação (consistência entre quadros ruim e incerteza de licença).

**Critério de sucesso do spike (M2):** 1 biotipo com ≈ 20 animações (incluindo 1 transição de solo pareada) produzido em um esforço que, extrapolado para o inventário de 4 biotipos (`R-037`), seja compatível com a disponibilidade do desenvolvedor; leitura aprovada pelo usuário. **Se falhar**, o escopo de arte precisa ser revisto antes de E-10 (menos biotipos, menos estados de solo/finalizações, resolução 480×270, ou orçamento para contratar arte).

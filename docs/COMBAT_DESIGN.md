# COMBAT DESIGN — Projeto Jaula

> Versão 0.1 · Etapa 01 · Volta ao [GDD](GDD.md)
> Convenções de marcação (`APROVADA`, `RECOMENDAÇÃO`, `PENDENTE`, `[PROV]`) em [GDD §0](GDD.md#0-convenções-desta-documentação).

O combate é o núcleo do jogo (`REQ-01`). Este documento especifica regras de gameplay. Apresentação visual está em [ART_DIRECTION.md](ART_DIRECTION.md); atributos em [CHARACTER_DESIGN.md](CHARACTER_DESIGN.md).

---

## 1. Objetivos de design do combate

1. **Distância é o primeiro recurso.** Quem controla a distância escolhe o tipo de luta.
2. **Todo golpe é uma aposta.** Preparação, recuperação e custo de Fôlego tornam o golpe errado punível.
3. **A leitura vence a força, a força vence a falta de leitura.** Uma defesa lida corretamente sempre funciona; quando ninguém lê nada, os atributos decidem (ver §4.2, *Disputa*).
4. **Pouca aleatoriedade.** Resultados são determinísticos dado o estado; uma variação pequena (`±5%` `[PROV]`) evita repetição mecânica, mas nunca inverte um resultado claro.
5. **Tudo é explicável.** O jogador deve conseguir dizer por que um golpe entrou ou falhou (§8).
6. **Comandos enxutos.** Profundidade vem de contexto (distância, posição, estado), não de sequências longas de botões.

### Ritmo pretendido
- Luta de 3 × 5 min em **tempo real** `[PROV]`. Opção de configuração para rounds mais curtos na Luta Rápida.
- Ritmo médio: trocas curtas e decisivas separadas por momentos de movimentação e estudo. Não é uma troca contínua de golpes.
- Taxa-alvo de golpes significativos: comparável a uma luta real equilibrada (dezenas por round, não centenas) `[PROV]`.

---

## 2. Espaço e movimentação 2.5D — SYS-01

### 2.1 Modelo espacial — `RECOMENDAÇÃO R-006`
- A lógica acontece em um **plano de chão** com dois eixos:
  - **X (horizontal):** eixo principal, onde existe a distância entre os lutadores. Extensão ≈ diâmetro da jaula (≈ 9 m `[PROV]`).
  - **Z (profundidade):** faixa **estreita** (≈ 2,5–3 m `[PROV]`), representada na tela como deslocamento vertical e ordem de desenho.
- Não existe eixo vertical de gameplay (pulo). Altura é usada apenas para alvos (cabeça/corpo/pernas).
- Câmera lateral fixa, sem rotação. Acompanha horizontalmente o ponto médio entre os lutadores, sem zoom dinâmico (pixel art só escala em inteiros; ver [ART §3](ART_DIRECTION.md#3-resolução-e-escala--recomendação-r-003-pendente-de-validação-visual)).

### 2.2 Orientação e troca de lado
- **Auto-orientação:** os lutadores sempre se viram um para o outro no eixo X. O jogador nunca "dá as costas" por acidente.
- **Base (stance):** ortodoxa ou canhota (dado do lutador). Ao trocar de lado na tela, o sprite espelha, mas a base é preservada: mão da frente continua sendo a mão da frente.
- **Troca de lado** só ocorre por ações específicas, não por andar através do adversário (colisão impede):
  - **Circular** (passo lateral sustentado em curta distância até ultrapassar o limiar de ângulo) → animação de giro de 180° do par.
  - Reversões de clinch e de queda, *scrambles*, saída da grade com giro.
- **Por quê:** a troca de lado é o equivalente 2.5D de "sair da grade" e "mudar o ângulo". Torná-la uma ação deliberada mantém a leitura e evita o visual de jogo 3D disfarçado.

### 2.3 Distância e alcance
Faixas de distância definidas a partir do alcance de cada lutador (dependem de envergadura e altura):

| Faixa | Definição | O que acontece |
|---|---|---|
| **Fora de alcance** | Além do chute mais longo do atacante | Estudo, fintas, aproximação; quedas a distância não alcançam |
| **Distância de chute** | Alcança chutes, não socos retos | Chutes baixos, teep, entradas de queda longas |
| **Distância de soco** | Alcança jab/direto | Trocação principal |
| **Curta** | Ganchos, uppercuts, joelhadas; entrada de clinch | Troca de alto risco |
| **Clinch** | Contato; estado próprio (§4) | Luta agarrada em pé |

- **Alcance efetivo** de cada golpe = alcance-base do golpe × fator de envergadura do lutador `[PROV]`. Um lutador de envergadura maior acerta o jab de uma distância em que o adversário menor ainda não alcança. Isso cria vantagem real de físico sem atributo artificial.
- **Aproximação/recuo:** andar para frente é mais rápido que para trás (`recuo ≈ 85%` da velocidade de avanço `[PROV]`), o que torna a pressão viável e o recuo infinito arriscado (a grade chega).
- **Passo rápido (step):** deslocamento curto e rápido em qualquer direção com custo de Fôlego. Base para entrar e sair de distância.

### 2.4 Movimento lateral e ângulo
- Mover em Z (passo lateral) é a ferramenta de defesa e de ângulo:
  - Cada golpe tem **tolerância de profundidade**: golpes retos (jab, direto, teep) têm tolerância **estreita**; golpes curvos (ganchos, chutes circulares) têm tolerância **larga** `[PROV: reto 0,3 m; curvo 0,6 m]`.
  - Se a diferença de Z entre os lutadores excede a tolerância no momento do impacto, o golpe **erra** (passa ao lado).
- **Ângulo:** quando um lutador desloca Z e o outro não acompanha, o primeiro ganha **Vantagem de Ângulo** por uma janela curta `[PROV: 0,6 s]`: seus golpes saem com preparação menor e os retos do adversário têm tolerância ainda mais estreita até ele "re-esquadrar" (mover Z também).
- Resultado: o jogo pune quem só anda para frente e para trás, e recompensa o movimento lateral, que é exatamente o que diferencia 2.5D de 2D plano.
- **Contrapeso:** o lateral custa mais Fôlego que o avanço e é mais lento; ficar circulando o tempo todo cansa e conta pouco para os juízes (§7.4).

### 2.5 Limites da jaula — `RECOMENDAÇÃO R-007`
- A grade existe nas **extremidades do eixo X**. Lá acontecem: ficar encurralado, clinch na grade, quedas contra a grade, levantar pela grade.
- Os limites de Z (fundo e frente) são **bordas suaves**: impedem o movimento, sem interações próprias. A grade do fundo é cenário; a da frente é omitida ou desenhada transparente.
- **Por quê:** interações com grade em quatro lados quadruplicam animações e dificultam leitura em vista lateral. Duas grades (esquerda/direita) entregam todo o jogo de "grade" com metade do custo.
- **Encurralado:** quando um lutador está a menos de `≈1 m` `[PROV]` da grade, não pode recuar; só lateral (Z) ou circular. É a situação tática que dá sentido à pressão.

### 2.6 Colisão e zonas de interação
- Cada lutador tem uma **caixa de corpo** no plano (impede sobreposição) e, por golpe, uma **zona de acerto** ativa durante a execução, definida em X (alcance), Z (tolerância) e altura (alvo).
- Zonas de alvo no defensor: **cabeça**, **corpo**, **pernas**. A zona atingida decide o tipo de dano (§6).
- A colisão em Z é mais permissiva que em X para permitir passar "ao lado" em curtas distâncias, mas nunca atravessar.

### 2.7 Como evitar "2D plano" e "3D disfarçado"
| Risco | Regra que evita |
|---|---|
| Parecer 2D plano | Profundidade tem efeito mecânico (tolerância, ângulo, sair da grade); passos laterais têm animação própria |
| Parecer 3D disfarçado | Faixa Z estreita; câmera fixa; auto-orientação; troca de lado só por ação; nada de correr em círculos livres |

---

## 3. Combate em pé — SYS-02 e SYS-03

### 3.1 Esquema de controle — `APROVADA D-015` (teclado primeiro) · layout como `RECOMENDAÇÃO R-008` / `R-038`
Controle principal: **teclado**, com gamepad como alternativa completa. Tudo remapeável ([GAME_SYSTEMS §7](GAME_SYSTEMS.md#7-configurações-e-acessibilidade--sys-26)). Esquema por **membros**, com a mão esquerda no movimento e a direita nos golpes.

**Regras de entrada (`R-038`):**
- Todas as entradas são **digitais em 4 direções** (frente, trás, cima = Z para o fundo, baixo = Z para a frente). Nenhuma ação depende de pressão analógica ou de diagonais. Isso torna o teclado o caso principal e faz o gamepad funcionar igual.
- Nenhuma ação exige **mais de 3 teclas simultâneas** (ex.: mover + modificador + golpe). Evita o *ghosting* de teclados comuns.
- "Frente/trás" são relativos ao adversário (auto-orientação), não à tela. Quando o lutador troca de lado, D continua sendo "avançar" `[PROV — alternativa: relativo à tela; testar em E-03]`.

| Função | Teclado (padrão `[PROV]`) | Gamepad (alternativa) |
|---|---|---|
| Mover: X = avançar/recuar, Z = passo lateral | **W A S D** | Analógico esquerdo / direcional |
| Mão da frente · Mão de trás | **U** · **I** | X · Y (Xbox) |
| Perna da frente · Perna de trás | **J** · **K** | A · B |
| Golpe reto (tecla sozinha) | U/I/J/K | botão sozinho |
| **Modificador Curvo** + golpe | **E** (segurar) + golpe | RT + botão |
| **Modificador Corpo** + golpe | **Q** (segurar) + golpe | RB + botão |
| **Guarda** (segurar) | **Shift esquerdo**; com Q = guarda baixa | LB |
| **Agarrar** | **L** | LT |
| **Técnica** (segurar) | **Espaço** — enquanto segurada, WASD vira *direção de técnica* em vez de movimento | Analógico direito (direção de técnica direta) |
| Finta | Toque em Shift durante a preparação de um golpe | Toque em LB |
| Pausa | Esc | Start |

**Direção de técnica no teclado:**
- **Em pé:** Espaço + W = esquiva lateral (*slip*), Espaço + S = abaixar (*duck*), Espaço + trás = recuar o tronco (*pull*). Espaço + frente fica reservado. Sem Espaço, WASD é movimento. (Corrigido na E-03: a versão anterior usava S para duas esquivas.)
- **No clinch e no solo:** não há locomoção livre, então **WASD é diretamente a direção de técnica** (sem Espaço). L + direção inicia uma técnica; a direção sozinha durante o *telegraph* do adversário é a defesa (§4.2). No Aperto de finalização, atacante e defensor usam WASD (§4.6).
- **Quedas a partir de em pé:** L + S (abaixar o nível) = double leg; L + Q = single leg; L sozinho em curta distância = entrar no clinch `[PROV]`.

Princípio mantido: **existe uma única "direção de técnica"** em pé e no chão. No teclado ela é WASD, filtrada pela tecla Técnica quando o lutador está em pé. Isso dá um vocabulário único para todo o combate e evita minijogos com controles próprios.

**Risco a testar em E-03:** a mão esquerda acumula movimento, Guarda, Técnica e dois modificadores. Se o conforto for ruim, a alternativa é mover os modificadores Curvo/Corpo para a mão direita (O e ;).

### 3.2 Catálogo de golpes em pé

| Golpe | Entrada | Alvos | Faixa | Tolerância Z | Velocidade | Potência | Fôlego | Atributo técnico |
|---|---|---|---|---|---|---|---|---|
| Jab | Mão da frente | Cabeça/corpo | Soco | Estreita | Muito alta | Baixa | Baixo | Boxe |
| Direto | Mão de trás | Cabeça/corpo | Soco | Estreita | Alta | Média-alta | Médio | Boxe |
| Gancho da frente | Curvo + mão da frente | Cabeça/corpo | Curta | Larga | Média | Alta | Médio | Boxe |
| Gancho de trás / cruzado | Curvo + mão de trás | Cabeça | Curta | Larga | Média-baixa | Muito alta | Alto | Boxe |
| Uppercut | Curvo + mão + trás (A/D conforme o lado) | Cabeça | Curta | Média | Média | Alta | Médio | Boxe |
| Chute baixo | Perna de trás | Pernas | Chute | Larga | Média | Média | Médio | Kickboxing |
| Chute ao corpo | Corpo + perna de trás | Corpo | Chute | Larga | Média-baixa | Alta | Alto | Kickboxing |
| Chute alto | Curvo + perna de trás | Cabeça | Chute | Larga | Baixa | Muito alta | Muito alto | Kickboxing |
| Teep (chute frontal) | Perna da frente | Corpo | Chute | Estreita | Média | Baixa (empurra) | Médio | Kickboxing |
| Chute baixo da frente / panturrilha | Curvo + perna da frente | Pernas | Chute/soco | Média | Alta | Baixa-média | Baixo | Kickboxing |
| Joelhada | Perna (em curta distância ou clinch) | Corpo/cabeça | Curta/clinch | Média | Média | Alta | Médio | Kickboxing |
| Cotovelada | Curvo + mão (em curta distância ou clinch) | Cabeça | Curta/clinch | Média | Alta | Média + corte | Médio | Kickboxing |

- O mapeamento exato de botões é uma hipótese para o protótipo. O catálogo é **dado** (SYS-28): golpes podem ser adicionados ou ajustados sem mudar código.
- Golpes giratórios, voadores e superman punch ficam para expansão (custo de animação alto, valor baixo para o pilar 1).
- Regras da organização podem proibir golpes (ex.: cotoveladas) — `RuleSet.golpes_proibidos` (§7.1).

### 3.3 Fases do golpe
Cada golpe tem quatro fases definidas em dados (em quadros a 60 fps, `[PROV]` por golpe):

1. **Preparação (startup):** do comando até a zona de acerto ativar. Pode ser cancelada em finta até um ponto. É o que o adversário enxerga para reagir (o *telegraph*).
2. **Execução (active):** zona de acerto ativa.
3. **Recuperação (recovery):** o lutador fica vulnerável e não pode defender completamente.
4. **Retorno à guarda:** pode encadear o próximo golpe de uma combinação ou voltar ao neutro.

- **Velocidade (atributo)** reduz preparação e recuperação em uma faixa limitada (ex.: `−15% a +15%` em relação ao base `[PROV]`). Nunca transforma um golpe lento em rápido: um cruzado sempre é mais lento que um jab.
- **Fôlego baixo** aumenta preparação e recuperação (§6.1).
- **Interrupção:** um golpe que acerta durante a preparação do adversário cancela o golpe dele (**contra-golpe**, ver §3.5).

### 3.4 Combinações
- Golpes têm **janelas de encadeamento** na recuperação: se o próximo comando entra na janela, a recuperação é substituída pela preparação reduzida do próximo golpe.
- Combinações válidas não são listas fixas; seguem regras simples de mecânica corporal: alternar lados (frente→trás) encadeia melhor; repetir o mesmo membro encadeia pior; alternar níveis (cabeça→corpo) não tem penalidade.
- Cada golpe extra na sequência custa mais Fôlego (`+10% por golpe consecutivo` `[PROV]`). Combinações longas são possíveis, mas caras.
- **Por quê:** evita "decorar combos" e mantém o foco em leitura. A profundidade vem de escolher quando e onde encadear.

### 3.5 Precisão, potência, risco e contra-golpe
Sem atributo "Precisão" separado (decisão `R-013`). O resultado de um golpe depende de:

| Fator | Efeito |
|---|---|
| Geometria (X, Z, alvo) | Decide se a zona de acerto encontra o alvo. É o fator principal. |
| Atributo técnico do golpe (Boxe/Kickboxing) | Reduz desvio de alcance (golpe "sai torto" menos), aumenta dano limpo, melhora janelas de encadeamento |
| Força | Potência do golpe |
| Velocidade | Fases mais curtas |
| Fôlego atual | Reduz potência e velocidade quando baixo |
| Estado do defensor | Guarda, esquiva, recuperação, atordoamento |

- **Contra-golpe:** acertar o adversário durante a preparação ou a execução de um golpe dele multiplica o impacto (`×1,5` `[PROV]`). É a principal fonte de knockdowns "do nada" e é sempre consequência de uma leitura, não de sorte.
- **Golpe limpo × parcialmente bloqueado:** um golpe bloqueado ainda transfere uma fração de dano (`≈20%` `[PROV]`) e custo de Fôlego para quem bloqueia, proporcional à Força do atacante.

### 3.6 Defesa em pé
| Defesa | Entrada | Efeito | Custo/risco |
|---|---|---|---|
| Guarda alta | Segurar Guarda | Bloqueia socos e chutes à cabeça; reduz muito o dano | Custo de Fôlego por golpe bloqueado; deixa o corpo exposto a chutes e golpes ao corpo; movimento mais lento |
| Guarda baixa | Guarda + Modificador Corpo | Protege corpo | Cabeça exposta |
| Bloqueio de chute baixo (*check*) | Guarda + Técnica + baixo no momento do chute | Anula o chute baixo e causa dano à perna do atacante | Timing; se errar, fica parado |
| Esquiva lateral (*slip*) | Técnica + W | Desloca a cabeça em Z: golpes retos erram; abre contra-golpe | Não evita golpes curvos; janela curta |
| Abaixar (*duck*) | Técnica + S | Evita golpes altos curvos | Vulnerável a joelhada e uppercut |
| Recuar o tronco (*pull*) | Técnica + trás | Evita golpes na ponta do alcance | Não funciona contra golpes em curta distância |
| Movimentação | Passos | A defesa mais segura: sair de alcance ou de Z | Custo de Fôlego; perto da grade fica limitado |

- **Defesa em Pé (atributo)** amplia a janela de esquiva e reduz o dano que passa pela guarda. Não faz defender sozinho.
- Esquivas consomem Fôlego e têm recuperação; esquivar sem parar é punido com golpes na recuperação.

### 3.7 Fintas e leitura de padrões
- **Finta:** cancelar um golpe na preparação. O adversário vê o início do *telegraph* e pode reagir à toa (gastando Fôlego ou abrindo guarda).
- A finta tem custo pequeno de Fôlego e só é possível até certo ponto da preparação (`≈60%` `[PROV]`).
- **Leitura de padrões:** o jogador identifica hábitos do adversário (ex.: sempre responde jab com direto). A IA também lê o jogador (§9.4). O jogo ajuda a leitura pelo **Relatório de Scouting** e pelas **dicas do córner** (§5.1).

### 3.8 Estilos em pé
Estilos não são classes com movimentos exclusivos. Todo lutador pode executar todo golpe; o estilo é a soma de **atributos** e **tendências** (ver [CHARACTER §5](CHARACTER_DESIGN.md#5-estilos-e-tendências-táticas)). Exemplos de comportamento resultante:

| Perfil | Ferramentas preferidas | Como joga |
|---|---|---|
| Boxeador | Jab, direto, ganchos, esquivas | Distância de soco, contra-golpe, ângulos |
| Muay Thai / kickboxer | Chutes baixos e ao corpo, teep, clinch com joelhadas | Distância de chute, desgaste de pernas e corpo |
| Pressão / volume | Combinações, avanço constante | Encurrala na grade, desgasta Fôlego |
| Contra-golpeador | Recuo, esquivas, golpes únicos | Espera o erro, alto risco/alta recompensa |

---

## 4. Grappling e luta agarrada — SYS-04 a SYS-07

### 4.1 Estados de posição
Toda a luta é uma máquina de estados de **posição**. Cada estado tem papéis (quem está em vantagem e quem está em desvantagem) e uma lista de ações.

| ID | Estado | Papéis | Observação |
|---|---|---|---|
| EP | **Em pé (distância)** | Neutro | Trocação (§3) |
| CL | **Clinch** | Neutro, com *Vantagem de Clinch* de −2 a +2 | No centro |
| CG | **Clinch na grade** | Prensando / prensado | Só nas extremidades X |
| SG | **Guarda** | Por cima / por baixo | Guarda fechada e aberta unificadas (`R-031`) |
| SM | **Meia-guarda** | Por cima / por baixo | |
| SL | **Controle lateral** | Por cima / por baixo | |
| SO | **Montada** | Por cima / por baixo | |
| SC | **Costas** | Nas costas / de costas | Inclui "tartaruga" |
| SR | **Recuperação de base** | Levantando / segurando | Subir pela grade, *scramble*, voltar a ficar de pé |
| KD | **Caído (knockdown)** | De pé / caído | Estado curto após knockdown (§6.4) |

- **Por que só 7 estados de solo:** cada estado custa duas animações de base (um papel por lutador) e várias transições. Sete estados cobrem as situações de MMA que importam para decisão (controle, ameaça de finalização, ground and pound, escape) sem explosão de conteúdo. Posições como *north-south*, *crucifixo*, *50/50*, *X-guard* ficam fora (`R-031`).

### 4.2 Modelo único: a Disputa — `RECOMENDAÇÃO R-009`
Toda ação de grappling (entrar no clinch, pummel, queda, passagem, raspagem, levantar, finalizar, escapar) é resolvida pelo mesmo modelo, a **Disputa**:

```
1. ATACANTE escolhe uma técnica: tecla Agarrar (L) + direção de técnica (WASD; no gamepad, analógico direito).
   → a técnica tem uma preparação visível (telegraph) com duração definida em dados.
2. DEFENSOR pode reagir durante a preparação escolhendo uma direção de defesa.
   - A janela de reação = preparação da técnica − atraso de percepção.
3. Resolução:
   a) Defesa correta no tempo certo → técnica BLOQUEADA.
      Se o timing foi "perfeito" (início da janela) → abre CONTRA (reversão/escape) por um instante.
   b) Defesa errada ou ausente → comparação de PRESSÃO × RESISTÊNCIA:
        pressao     = atributo_técnico_atacante × fator_fôlego_atacante × bônus_de_posição
        resistencia = atributo_defensivo_defensor × fator_fôlego_defensor × peso_relativo
      - pressao ≥ resistencia × 1,0 → técnica SUCEDE
      - pressao entre 0,8 e 1,0 da resistência → PROGRESSO PARCIAL (barra de controle avança; próxima tentativa na mesma direção fica mais fácil)
      - abaixo de 0,8 → FALHA (sem progresso, custo de Fôlego)
      [faixas PROV]
4. Ambos pagam Fôlego. O atacante paga mais se falhar.
```

Propriedades:
- **A leitura sempre funciona.** Um lutador fraco que lê corretamente defende um mais forte. Isso garante que o jogador habilidoso tenha agência.
- **Sem leitura, os atributos decidem de forma determinística.** Um faixa-preta passa a guarda de um iniciante mesmo sem ser lido — o que é realista e explicável ("passou por pressão").
- **Peso relativo** entra na resistência (mesma categoria → diferença pequena, mas existe por causa de peso de luta e corte de peso).
- A **mesma entrada** (Agarrar + direção) serve para todas as técnicas; o contexto (estado de posição) decide qual técnica cada direção representa. A tela mostra as opções da posição atual em um *overlay* compacto (HUD nível Completo; §8.3).
- O feedback textual da resolução é um dos três: **"Defendido (leitura)"**, **"Resistiu"**, **"Passou"** (§8.2).

**Exemplo — passagem de guarda:** o jogador está na Guarda, por cima, com Controle de Solo 70. A IA tem Jiu-jitsu 55 e está com Fôlego em 40%. O jogador empurra a direção de "passar para meia-guarda". A IA reage para o lado errado. Pressão (70 × 0,95 × 1,0) contra resistência (55 × 0,7 × 1,0) → 66,5 ≥ 38,5 → passa. Se a IA tivesse lido a direção, a passagem seria bloqueada e, com timing perfeito, ela ganharia uma janela para raspagem.

### 4.3 Clinch — SYS-04
- **Entrada:** Agarrar em distância curta. É uma Disputa (o defensor pode empurrar/afastar ou golpear na entrada — um golpe na preparação do clinch é contra-golpe).
- **Vantagem de Clinch** (−2 a +2): representa pegadas (underhooks, colar). Aumentada por *pummel* (Disputa) e por Wrestling Ofensivo/Força. Define o que cada lado pode fazer:

| Vantagem | Ações possíveis |
|---|---|
| ≥ +1 | Joelhadas ao corpo/cabeça, empurrar para a grade, quedas de clinch (trips, arremesso) |
| 0 | Socos curtos, cotoveladas, pummel, separar |
| ≤ −1 | Defender, pummel para recuperar, separar com custo |

- **Clinch na grade (CG):** quem prensa tem `+1` de vantagem efetiva, gasta menos Fôlego segurando e tem acesso a quedas contra a grade; quem é prensado gasta mais Fôlego por segundo. Saídas: girar (troca de lado), separar, inverter a posição.
- **Separação pelo árbitro:** se o clinch ficar sem atividade por `≈10 s` `[PROV]`, o árbitro separa (§7.3). Evita "segurar" como estratégia infinita.

### 4.4 Quedas e defesa — SYS-05
| Queda | De onde | Requisito | Defesa principal |
|---|---|---|---|
| Double leg | Distância de soco/curta | Abaixar o nível; preparação visível | Sprawl (timing), joelhada (contra-golpe), recuar |
| Single leg | Distância de soco/curta | Preparação menor, mais longa para concluir | Sprawl, equilíbrio em uma perna (Disputa de continuação), cotoveladas |
| Trip / arremesso de clinch | Clinch com vantagem ≥ +1 | | Disputa de equilíbrio |
| Queda na grade | CG prensando | Mais fácil, mais lenta | Underhook, levantar pela grade |

- **Entrar em queda contra um golpe:** acertar a preparação de um golpe do adversário com a entrada de queda (ex.: entrar embaixo de um chute) dá bônus na Disputa (`+20% pressão` `[PROV]`). Espelha o contra-golpe em pé.
- **Sprawl:** defesa com timing. Bem-sucedido, coloca o atacante em posição ruim (defensor por cima, frente-a-frente, transição para Costas ou separação).
- **Queda bem-sucedida** leva para Guarda (padrão), Meia-guarda (se Wrestling Ofensivo superar muito o defensivo) ou Controle lateral (raro; arremessos).
- **Custo:** quedas falhadas custam muito Fôlego ao atacante (`2×` a de uma tentativa bem-sucedida `[PROV]`). Um wrestler que insiste sem preparar a entrada fica sem gás.

### 4.5 Solo — SYS-06
Grafo de transições (ações principais por papel). Toda transição é uma Disputa.

```
               ┌──────────── Recuperação de base (SR) ──── volta para EP/CG
               │                     ▲
   Guarda (SG) ─┼─ passar ─► Meia-guarda (SM) ─ passar ─► Controle lateral (SL) ─ montar ─► Montada (SO)
     ▲  │       │               ▲     │                       │   ▲                         │
     │  │ raspar│      repor    │     │ raspar                │   │ repor guarda            │ costas
     │  ▼       │               │     ▼                       ▼   │                         ▼
  (inversão: quem estava por baixo passa a estar por cima)     Costas (SC) ◄─── "dar as costas" para levantar
```

| Estado | Por cima: ações | Por baixo: ações |
|---|---|---|
| Guarda | Ground and pound (GnP) médio, passar, ficar de pé (sair), defender finalizações | Raspar, finalizar (triângulo, armlock, guilhotina), cotoveladas de baixo, levantar pela grade, segurar (anula GnP, árbitro pode levantar) |
| Meia-guarda | GnP, passar para controle lateral, kimura | Repor guarda, raspar, levantar |
| Controle lateral | GnP forte (cotoveladas, joelhadas ao corpo), montar, kimura, arm triangle | Repor guarda/meia-guarda, girar para levantar (expõe Costas), *bridge* |
| Montada | GnP muito forte, armlock, arm triangle | Escapar para meia-guarda/guarda (bridge), dar as costas |
| Costas | Mata-leão, GnP limitado | Escapar (virar para a guarda), levantar |
| Recuperação de base | Segurar e derrubar de novo | Levantar (Wrestling Defensivo) |

- **Barra de Controle (por posição):** a permanência em uma posição dominante acumula *tempo de controle* (conta para juízes, §7.4). Progresso parcial em Disputas também é armazenado ali.
- **Ground and pound:** golpes de solo usam os mesmos botões de membros (mão da frente/trás) com potência modulada pela posição (`Guarda 0,6×; Meia 0,8×; Lateral 1,0×; Montada 1,2×` `[PROV]`). O defensor por baixo pode defender com Guarda (cobertura) — "defesa inteligente" para o árbitro (§7.3).
- **Levantar:** o jogador por baixo pode tentar Recuperação de base a partir de Guarda, Meia-guarda ou via Costas. A grade facilita (levantar pela grade).

### 4.6 Finalizações — SYS-07 — `RECOMENDAÇÃO R-010`
Catálogo 1.0 (protótipo: só 1):

| Finalização | Posições de origem | Tipo |
|---|---|---|
| Mata-leão | Costas | Estrangulamento |
| Guilhotina | Clinch, Guarda (por baixo), defesa de queda | Estrangulamento |
| Triângulo | Guarda (por baixo) | Estrangulamento |
| Armlock | Guarda (por baixo), Montada | Chave articular |
| Kimura | Meia-guarda, Controle lateral (ambos os papéis) | Chave articular |
| Arm triangle | Controle lateral, Montada | Estrangulamento |

Funcionamento em três etapas, **com o mesmo vocabulário da Disputa** (sem minijogo novo):

1. **Encaixe:** uma Disputa normal (Agarrar + direção da finalização). Se o defensor ler, nada acontece. Se falhar, a finalização está **encaixada**.
2. **Aperto:** surge o **Medidor de Aperto** (0–100). A cada ciclo (`≈1 s` `[PROV]`) o atacante escolhe uma direção de ajuste e o defensor escolhe uma direção de escape (ambos com a direção de técnica: WASD no teclado).
   - Escape na direção certa → o medidor cai e o defensor acumula 1 *escape*.
   - Escape errado → o medidor sobe proporcional a `Jiu-jitsu atacante / Defesa de Finalização defensor` × fatores de Fôlego.
   - Estrangulamentos sobem mais rápido quando o defensor tem Fôlego baixo; chaves articulares sobem mais rápido quando o defensor tem Força baixa em relação ao atacante.
3. **Resultado:** medidor em 100 → desistência (*tap*) ou, em estrangulamento, apagão; 3 escapes acumulados `[PROV]` ou medidor em 0 → finalização desfeita, frequentemente com troca de posição (escapar de um triângulo pode deixar o defensor passando a guarda).

- **Custo:** o atacante gasta muito Fôlego no Aperto; uma finalização longa e falhada deixa o atacante exausto (risco real).
- **Chave articular e lesão:** se o defensor insistir em uma chave articular até perto de 100 e escapar, há chance de lesão leve no membro (consequência persistente, [CAREER §5](CAREER_DESIGN.md#5-saúde-lesões-envelhecimento-e-aposentadoria--sys-16-e-sys-24)). Escolha consciente de risco do defensor; a probabilidade sobe com o tempo acima de 80 no medidor.

### 4.7 Transições entre fases
```
EP ──Agarrar perto──► CL ──empurrar──► CG
EP ──queda────────────────────────────► SG / SM
CL/CG ──queda de clinch────────────────► SG / SM / SL
SG/SM/SL/SO/SC ──levantar (SR)─────────► EP ou CG
Qualquer ──knockdown──► KD ──seguir──► SG/SM (GnP) ou deixar levantar ──► EP
Árbitro: separar clinch inativo ──► EP | levantar solo inativo ──► EP
```
Princípio: nenhuma fase é um "modo" com regras próprias. Os mesmos recursos (Fôlego, dano por zona, Disputa, direção de técnica) valem em todas.

---

## 5. Estratégia e leitura tática

### 5.1 Como o jogador identifica hábitos e vulnerabilidades
| Fonte | Quando | O que revela |
|---|---|---|
| **Relatório de Scouting** (pré-luta) | Desbloqueado por blocos de Estudo do Adversário no camp ([CAREER §4](CAREER_DESIGN.md#4-treinamento-academia-e-equipe--sys-15)) | Estilo, faixas de atributo (precisão depende do estudo), 2–3 tendências (ex.: "baixa a mão de trás após chutar") |
| **Sinais na luta** | Em tempo real | Postura, respiração, recuos repetidos, mancar (pernas) |
| **Dicas do córner** (intervalo) | Entre rounds | Até 2 observações sobre o round anterior; qualidade depende da competência do treinador principal e do QI de Luta do jogador |
| **Estatísticas do round** (intervalo) | Entre rounds | Golpes tentados/acertados por tipo, tempo de controle, Fôlego |

O QI de Luta do lutador controlado pelo jogador **não joga pelo jogador**: ele melhora a qualidade das informações (precisão do scouting, número de dicas do córner) e a duração dos *tells* visuais, nunca toma decisões.

### 5.2 Gestão de distância, ritmo, energia e risco
- **Distância:** cada estilo tem uma faixa ideal; o jogador escolhe onde lutar.
- **Ritmo:** volume alto pontua e pressiona, mas drena Reserva (§6.1).
- **Energia:** Fôlego é a moeda de todas as ações. Gastar no 1º round compromete o 3º.
- **Risco:** golpes potentes e quedas têm preparação maior → mais chances de contra-golpe.

### 5.3 Ajustes no intervalo
Entre rounds, o jogador escolhe **um foco tático** para o próximo round entre opções contextuais (ex.: "Evitar a grade", "Atacar o corpo", "Mais quedas", "Recuperar o fôlego"). O foco:
- muda a recuperação no intervalo (ex.: "Recuperar o fôlego" recupera mais Fôlego, mas gera tendência a ritmo menor);
- muda dicas e destaques do HUD (ex.: realça a distância da grade);
- **não dá bônus de atributo** (evita penalidade/benefício arbitrário).

### 5.4 Adaptação do adversário
Ver IA (§9.4). O adversário pode trocar o plano de jogo entre rounds e mudar respostas a padrões repetidos do jogador dentro do round.

---

## 6. Fisiologia na luta: Fôlego, dano e nocaute — SYS-08

Diferenciação obrigatória de três níveis de consequência:

| Nível | Duração | Exemplos | Onde é tratado |
|---|---|---|---|
| **Dano temporário** | Dentro da luta | Fôlego, dano por zona, atordoamento, cortes | Este documento |
| **Lesão** | Semanas a meses | Lesão no joelho, fratura de mão, concussão | [CAREER §5](CAREER_DESIGN.md#5-saúde-lesões-envelhecimento-e-aposentadoria--sys-16-e-sys-24) |
| **Consequência persistente** | Carreira | Desgaste Acumulado (queixo), lesão crônica, declínio por idade | CAREER §5, [CHARACTER §7](CHARACTER_DESIGN.md#7-evolução-e-declínio) |

### 6.1 Fôlego e Reserva — `RECOMENDAÇÃO R-011`
- **Fôlego** (0–100%): energia imediata. Toda ação custa Fôlego (golpes, esquivas, passos, Disputas, segurar posição). Regenera continuamente quando o lutador não está gastando.
- **Reserva** (teto do Fôlego, começa em 100%): cai com o esforço acumulado e com dano ao corpo. O Fôlego nunca regenera acima da Reserva.
- **Por que dois níveis:** Fôlego cria a gestão momento a momento (não posso jogar tudo agora); Reserva cria a narrativa da luta (o 3º round é diferente do 1º). Um só medidor faria ou o round ou a luta sem significado.

| Fonte | Efeito |
|---|---|
| Condicionamento | Velocidade de regeneração do Fôlego e taxa de queda da Reserva |
| Recuperação | Quanto da Reserva e do Fôlego volta no intervalo |
| Dano ao corpo | Reduz Reserva diretamente e diminui a regeneração |
| Corte de peso pesado ([CAREER §6](CAREER_DESIGN.md#6-peso-corte-e-pesagem--sys-17)) | Reserva inicial menor que 100% |
| Fadiga Acumulada do camp | Reserva inicial menor |

**Efeitos do Fôlego baixo** `[PROV]`:
| Fôlego | Efeito |
|---|---|
| > 50% | Nenhum |
| 25–50% | Preparação/recuperação +10%, potência −10%, Disputas −10% |
| < 25% | +25% nas fases, potência −25%, Disputas −25%, guarda cai sozinha após bloqueios |

### 6.2 Dano por zona — `RECOMENDAÇÃO R-012`
Três zonas, cada uma com **Dano** (0–100) dividido em **agudo** (recupera parcialmente no intervalo) e **residual** (fica até o fim da luta).

| Zona | Efeitos crescentes | Atributo que reduz o dano recebido |
|---|---|---|
| Cabeça | Reduz o Limiar de Choque; inchaço e cortes; acima de 70 → *tells* de atordoamento mais frequentes | Queixo |
| Corpo | Reduz Reserva e regeneração; acima de 60 → golpes ao corpo podem causar **paralisação** (knockdown por fígado) | Robustez |
| Pernas | Reduz velocidade de movimento, potência de chute e resistência a quedas; acima de 70 → perna "falha" (knockdown por chute baixo) | Robustez |

### 6.3 Limiar de Choque, atordoamento e knockdown
Cada golpe à cabeça calcula um **Impacto**:
```
impacto = potência_do_golpe × multiplicador_contra_golpe × (1 − bloqueio) × variação(±5%)
limiar_de_choque = base(Queixo) × (1 − dano_cabeça/150) × fator_fôlego × (0,9 + Compostura/1000)
```
| Impacto / limiar | Resultado |
|---|---|
| < 0,6 | Dano normal |
| 0,6 – 1,0 | **Abalado** (micro-recuo, guarda abre por um instante) |
| 1,0 – 1,5 | **Atordoado** (*stun*): movimento lento, sem golpes potentes por 2–4 s, defesa reduzida |
| ≥ 1,5 | **Knockdown** (KD) |
| ≥ 2,2 ou golpe limpo em lutador atordoado/caído com impacto ≥ 1,0 | **Apagão** → KO |

Todas as faixas são `[PROV]`. Intenção: KO "relâmpago" acontece por contra-golpe em queixo cansado e machucado, nunca por sorte pura.

- **Recuperação do atordoamento:** tempo base reduzido por Compostura. O jogador pode clinchar, cobrir-se, recuar.
- **Knockdown:** o lutador cai (estado KD). O adversário escolhe seguir para o solo (GnP) ou se afastar e deixar levantar. Levantar leva `1–3 s` `[PROV]` conforme Compostura e dano.

### 6.4 Cortes
- Cotoveladas, ganchos limpos e cabeçadas acidentais (falta) podem abrir cortes (chance ligada a dano na cabeça acima de um limite e ao tipo de golpe).
- Gravidade 1–3. Corte perto do olho com gravidade 3 → **revisão médica** pelo árbitro; pode encerrar a luta (TKO por interrupção médica).
- Sangue é opcional em configurações (`R-029`, `P-006`).

### 6.5 Recuperação entre rounds
| Recurso | Recuperação no intervalo `[PROV]` |
|---|---|
| Fôlego | Volta até a Reserva × (0,6 + Recuperação/250) |
| Reserva | +5 a +15 pontos conforme Recuperação |
| Dano agudo | −30% a −50% |
| Dano residual | Não recupera |
| Cortes | Gravidade pode cair 1 nível com bom *cutman* (qualidade da equipe) |

---

## 7. Regras, rounds, arbitragem e julgamento — SYS-09 e SYS-10

### 7.1 Regras configuráveis (`RuleSet`)
Regras são **dados por organização** (SYS-28). Referência inicial: **Regras Unificadas de MMA** usadas por comissões norte-americanas — `RECOMENDAÇÃO R-020`, **precisa de validação** de fonte antes de virar texto no jogo. Itens marcados *(fictício)* são regras criadas para o jogo.

| Campo do RuleSet | Valor de referência | Configurável por organização |
|---|---|---|
| Duração do round | 5 min | Sim (ex.: circuito local 3 min *(fictício)*) |
| Rounds — luta normal | 3 | Sim |
| Rounds — luta principal/título | 5 | Sim |
| Intervalo | 1 min | Sim |
| Sistema de pontuação | 10 pontos obrigatórios por round | Sim (ex.: avaliação de luta completa *(fictício)*, ver `P-010`) |
| Cotoveladas | Permitidas | Sim |
| Joelhadas na cabeça de oponente no chão | Proibidas | Sim *(fictício: organização asiática permite)* |
| Pisões/tiros de futebol | Proibidos | Recomenda-se manter proibido sempre (sem animações extras) |
| Golpes na nuca, virilha, dedos nos olhos | Proibidos | Não (faltas universais) |
| Empate técnico/no contest | Previsto | Sim |
| Tolerância de peso (luta sem título) | +1 lb | Sim |

### 7.2 Condições de encerramento
| Resultado | Condição |
|---|---|
| **KO** | Apagão (§6.3) |
| **TKO — árbitro** | Lutador sem "defesa inteligente": recebe N golpes significativos sem resposta em T segundos estando atordoado, caído ou sob GnP (`N=5, T=4 s` `[PROV]`) |
| **TKO — médico** | Corte de gravidade 3 em área crítica ou lesão evidente (ex.: perna sem sustentação) |
| **TKO — córner** | Desistência do córner (NPC: pela IA; jogador: opção no intervalo) |
| **Finalização** | Desistência ou apagão por estrangulamento (§4.6) |
| **Decisão** | Fim dos rounds: unânime, dividida ou majoritária (§7.4) |
| **Empate** | Unânime, dividido ou majoritário |
| **Desqualificação** | Falta intencional grave ou acúmulo de faltas com perda de pontos |
| **No contest** | Falta acidental que impede a continuação antes do round mínimo (`2º round` na referência) |
| **Decisão técnica** | Falta acidental que impede a continuação após o round mínimo → juízes pontuam até ali |

### 7.3 Árbitro
O árbitro é um sistema de regras (presença visual mínima na 1.0, `R-030`):
- **Separa** clinch inativo e **levanta** a luta no solo sem atividade (`≈10–15 s` `[PROV]`; "atividade" = golpes ou tentativas de transição).
- **Interrompe** por TKO (§7.2), com pequena variação de "tolerância" por árbitro (dado do NPC árbitro, dentro de limites estreitos).
- **Faltas:** cabeçada acidental e golpe baixo acidental ocorrem como consequência de colisões específicas (raros). Faltas intencionais **não** são ações disponíveis para o jogador (decisão de escopo).
- **Advertência e perda de ponto:** acumuladas por faltas acidentais repetidas.

### 7.4 Julgamento — `RECOMENDAÇÃO R-019`
- **Três juízes simulados.** Cada juiz pontua o round no sistema de 10 pontos com base em estatísticas objetivas do round:

| Critério (ordem de prioridade da referência) | Medida no jogo |
|---|---|
| 1. Golpes e grappling efetivos | Impacto total aplicado, knockdowns, dano causado por zona, transições conquistadas, ameaças de finalização |
| 2. Agressividade efetiva | Avanço com golpes que conectam (não só andar para frente) |
| 3. Controle da área de luta | Tempo de controle (posição dominante, prensar na grade, ditar a distância) |

- Cada juiz tem **pesos individuais** (ex.: um valoriza mais grappling) e um **ruído pequeno** `[PROV]`. Isso produz decisões divididas naturalmente em rounds equilibrados, sem viés oculto contra o jogador.
- **10-8:** round com dominância ampla (knockdowns, dano grande, controle quase total). **10-7:** extremamente raro.
- **Decisões:** unânime (3 juízes para o mesmo lado), dividida (2 × 1), majoritária (2 para um lado e 1 empate).
- **Transparência:** na tela de resultado o jogador vê o placar de cada juiz por round e as estatísticas que o fundamentaram.

---

## 8. Feedback e legibilidade — SYS-12

### 8.1 Sinais no corpo do lutador (prioritários sobre HUD)
| Estado | Sinal visual | Sinal sonoro |
|---|---|---|
| Golpe limpo | Faísca de impacto, *hit-stop* de 2–4 quadros `[PROV]`, recuo da cabeça/corpo | Impacto forte |
| Golpe bloqueado | Faísca menor na guarda, empurrão | Impacto abafado |
| Contra-golpe | Faísca maior + *flash* curto | Impacto + acento |
| Fôlego baixo | Respiração ofegante, guarda mais baixa, ombros caídos | Respiração audível |
| Dano na cabeça | Inchaço, cortes (se ativado) | — |
| Dano nas pernas | Mancar, base mais aberta | — |
| Atordoado | Pernas bambas, cambaleio | Zumbido curto (abafamento do áudio ambiente) |
| Perigo de finalização | Medidor de Aperto + pulsação de borda | Tensão musical |

### 8.2 Explicar por que algo funcionou ou falhou
- Texto curto e opcional junto ao lutador (configurável): **"Fora de alcance"**, **"Errou o ângulo"** (falha de Z), **"Bloqueado"**, **"Contra-golpe!"**, **"Defendido (leitura)"**, **"Resistiu"**, **"Passou"**, **"Sem fôlego"**.
- Tela de estatísticas do intervalo e do resultado.
- Modo Treino com sobreposição de zonas de acerto e faixas de distância.

### 8.3 HUD em três níveis — `RECOMENDAÇÃO R-027`
| Nível | Conteúdo |
|---|---|
| **Completo** | Barras de Fôlego/Reserva, silhueta de dano por zona, relógio/round, overlay de opções de grappling, textos de feedback |
| **Mínimo** | Relógio/round, Fôlego discreto, Medidor de Aperto quando ativo |
| **Imersivo** | Apenas relógio/round; tudo comunicado pelo sprite e pelo áudio |

O nível padrão para iniciantes é Completo; recomenda-se que a dificuldade não dependa do nível de HUD.

---

## 9. IA dos adversários — SYS-11

### 9.1 Princípio: mesmas regras
A IA controla um lutador **com os mesmos dados, regras, custos e limites** do jogador (`REQ-07`):
- Não lê a entrada do jogador; só reage ao que é visível (a preparação do golpe) após um **atraso de percepção**.
- Não recebe atributos extras por dificuldade. A dificuldade escolhe **qual lutador** o jogador enfrenta (na carreira, o próprio matchmaking) e o **perfil cognitivo** da IA (§9.5).
- Não vê atributos ocultos do jogador além do que um scouting equivalente revelaria.

### 9.2 Arquitetura: seleção por utilidade (conceitual)
```
a cada decisão (a cada ~100–250 ms, conforme perfil):
  contexto = {distância, Z relativo, posição, Fôlego próprio/adversário,
              dano por zona, round, placar estimado, grade, plano de jogo,
              memória de hábitos do adversário}
  para cada ação disponível:
      utilidade = valor_base(arquétipo, ação)
                × ajuste_de_contexto(contexto)
                × ajuste_do_plano_do_round
                + bônus_de_exploração(memória de hábitos)
  escolhe entre as melhores com aleatoriedade controlada (temperatura do perfil)
```

### 9.3 Arquétipos
Pesos-base de ação por arquétipo (dados). Exemplos:

| Arquétipo | Prioriza | Evita |
|---|---|---|
| Boxeador | Distância de soco, jab, contra-golpes | Clinch prolongado, chutes altos |
| Kickboxer / Muay Thai | Chutes baixos e ao corpo, clinch com joelhadas | Solo |
| Wrestler | Pressão, quedas, controle por cima, GnP | Distância longa |
| Especialista de jiu-jitsu | Clinch, guarda, finalizações | Trocação longa |
| Pressão / volume | Avanço, combinações, grade | Recuo |
| Contra-golpeador | Esperar, esquivas, contra-golpes | Iniciar trocas |
| Completo | Equilibrado, adapta ao adversário | — |

### 9.4 Estratégia por round, adaptação e exploração
- **Plano de jogo:** definido antes da luta a partir do arquétipo e de uma comparação de atributos (ex.: wrestler contra striker → "levar para o chão").
- **Ajuste entre rounds:** se o plano falha (perdeu o round, está tomando dano), a IA recalcula o plano (ex.: troca para "trocar na distância de chute").
- **Memória de hábitos do adversário:** contagem de padrões do jogador por contexto (ex.: "após o jab dele, ele recua 70% das vezes"). Após amostra mínima, a IA aumenta a utilidade da resposta que explora o padrão. A memória decai com o tempo para o jogador poder "mudar de padrão" e enganar a IA.
- **Exploração de fraquezas:** dano por zona alto, Fôlego baixo e grade próxima aumentam a utilidade de ações que exploram esses estados.

### 9.5 Limitações humanas e níveis
| Parâmetro do perfil cognitivo | Iniciante | Intermediário | Elite `[PROV]` |
|---|---|---|---|
| Atraso de percepção | 350 ms | 250 ms | 180 ms |
| Taxa de erro de leitura | 40% | 25% | 12% |
| Hesitação (decisões adiadas) | Frequente | Ocasional | Rara |
| Memória de hábitos | Curta / amostra grande | Média | Longa / amostra pequena |
| Gestão de Fôlego | Ruim (gasta no 1º round) | Razoável | Boa |
| Temperatura (aleatoriedade) | Alta | Média | Baixa, mas nunca zero |

- Na carreira, o perfil cognitivo vem do **QI de Luta** e da experiência (número de lutas) do NPC, não de uma escolha global. A opção de dificuldade (§ [GAME_SYSTEMS §7](GAME_SYSTEMS.md#7-configurações-e-acessibilidade--sys-26)) aplica um **deslocamento** limitado ao perfil cognitivo, nunca aos atributos físicos.
- **Erros humanos:** a IA pode errar a leitura, gastar demais o Fôlego, insistir em um plano perdedor, e "congelar" atordoada.

### 9.6 Evitar IA injusta ou previsível
| Problema | Regra |
|---|---|
| Leitura de input (reação perfeita) | Atraso de percepção mínimo de 150 ms `[PROV]` e reação só a *telegraphs* visíveis |
| Previsibilidade | Temperatura > 0, memória com decaimento, variação de plano entre rounds |
| Spam de uma ação forte | Custo de Fôlego e memória de hábitos do jogador contra a IA valem também (o jogador pode ler a IA) |
| Dificuldade artificial | Proibido bônus de atributo por dificuldade |

---

## 10. Exemplos de situações de luta

**10.1 Encurralado na grade.** O jogador (boxeador, envergadura menor) é pressionado por um kickboxer até a grade. Não pode recuar. Opções: passo lateral para sair em Z (o kickboxer usa chute baixo de tolerância larga, que ainda acerta), circular para trocar de lado (preparação visível; se o adversário golpear durante, toma contra-golpe), ou entrar em curta distância com gancho, onde o alcance do kickboxer perde valor. Ele escolhe circular após uma finta de jab: o kickboxer reage à finta com um chute ao corpo, que tem preparação longa — o jogador sai pela lateral e fica com Vantagem de Ângulo.

**10.2 Wrestler sem gás.** Uma IA wrestler tenta 4 double legs no 1º round; 3 são defendidas por sprawl. Cada falha custa o dobro de Fôlego e reduz a Reserva. No 3º round, com Reserva em 55%, suas entradas ficam mais lentas (Fôlego < 50%), a janela de reação do jogador aumenta e o sprawl vira contra-ataque para as Costas.

**10.3 Passagem por pressão.** Jogador faixa-preta (Controle de Solo 82) contra striker (Jiu-jitsu 35). Mesmo sem leitura correta da IA, cada passagem sucede por pressão. O jogo comunica "Passou". A IA, com memória de hábitos, passa a tentar levantar pela grade, o que é sua melhor opção.

**10.4 Finalização contra o relógio.** Final do 3º round, jogador por baixo na Guarda, perdendo nos pontos. Encaixa um triângulo; o adversário tem Fôlego baixo, então o Medidor de Aperto sobe rápido. O adversário acerta 2 escapes, mas o medidor chega a 100 antes do 3º: finalização a 12 segundos do fim.

**10.5 Decisão dividida.** Round 2: o jogador conectou mais golpes significativos; a IA teve 2 minutos de controle por cima sem dano. Juiz A (valoriza trocação) dá 10-9 jogador; juiz B (valoriza grappling) dá 10-9 IA; juiz C dá ao jogador. A tela de resultado mostra os placares e as estatísticas de cada round.

# GLOSSARY — Vocabulário do projeto

> Versão 0.1 · Etapa 01 · Volta ao [GDD](GDD.md)
> Termo oficial em **negrito**. Sinônimos listados não devem ser usados na documentação nem na interface sem necessidade (usar o termo oficial).

---

## 1. Termos de MMA

| Termo | Definição | Evitar / sinônimos |
|---|---|---|
| **Jaula** | Área de luta cercada por grade. Nos documentos, "octógono" é aceito como termo genérico; no jogo, usar "jaula" (`R-001`) | "Octagon" (marca) |
| **Grade** | Cerca da jaula; interativa nas extremidades X | Cerca |
| **Lona** | Piso da jaula | — |
| **Round** | Período de luta com duração definida pelo RuleSet | Assalto |
| **Intervalo** | Pausa entre rounds | — |
| **Base** | Ortodoxa (mão esquerda à frente) ou canhota | Guarda (no sentido de postura) |
| **Clinch** | Luta agarrada em pé | — |
| **Pummel** | Disputa de pegadas no clinch | — |
| **Queda** | Levar o adversário ao chão (double leg, single leg, trip, arremesso) | Takedown |
| **Sprawl** | Defesa de queda lançando as pernas para trás | — |
| **Guarda** | (Solo) posição em que o lutador por baixo controla o de cima com as pernas. (Defesa em pé) postura de braços para bloquear — o contexto distingue; na UI, "Guarda alta/baixa" para a defesa | — |
| **Meia-guarda**, **Controle lateral**, **Montada**, **Costas** | Posições de solo ([COMBAT §4.1](COMBAT_DESIGN.md#41-estados-de-posição)) | Cem quilos (=controle lateral) |
| **Raspagem** | Inverter a posição a partir de baixo | Sweep |
| **Passagem** | Superar a guarda do adversário para posição melhor | — |
| **Ground and pound (GnP)** | Golpes desferidos no solo | — |
| **Finalização** | Estrangulamento ou chave articular que força desistência | Submissão |
| **Desistência** | Sinal de rendição (bater) | Tap |
| **KO** | Nocaute: lutador inconsciente (Apagão) | — |
| **TKO** | Nocaute técnico: interrupção pelo árbitro, médico ou córner | — |
| **Knockdown (KD)** | Lutador derrubado por golpe, ainda consciente | — |
| **Decisão unânime / dividida / majoritária** | 3×0 / 2×1 / 2 votos para um lado e 1 empate | — |
| **Sistema de 10 pontos** | Pontuação por round: vencedor 10, perdedor 9 ou menos | — |
| **No contest** | Luta sem resultado (falta acidental cedo) | — |
| **Decisão técnica** | Decisão dos juízes após interrupção por falta acidental após o round mínimo | — |
| **Corte de peso** | Perda de peso pré-pesagem, normalmente por desidratação | — |
| **Peso de caminhada** | Peso fora de camp | — |
| **Peso de luta** | Peso após reidratação, no dia da luta | — |
| **Camp** | Período de preparação para uma luta | Training camp |
| **Card** | Lista de lutas de um evento | — |
| **Córner** | Equipe do lutador no intervalo | Corner |
| **Callout** | Desafio público a um adversário | — |

## 2. Termos de gameplay (combate)

| Termo | Definição |
|---|---|
| **Eixo X** | Eixo horizontal do plano de chão (distância) |
| **Eixo Z** | Eixo de profundidade, faixa estreita |
| **Faixa de distância** | Fora de alcance / chute / soco / curta / clinch |
| **Tolerância de profundidade** | Diferença máxima de Z para um golpe acertar |
| **Vantagem de Ângulo** | Janela de vantagem após deslocamento lateral não acompanhado |
| **Encurralado** | Lutador perto da grade, sem recuo |
| **Troca de lado** | Inversão das posições em X por ação específica (circular, reversão) |
| **Preparação / Execução / Recuperação** | Fases do golpe (startup / active / recovery) |
| **Telegraph** | Sinal visível da preparação de uma ação |
| **Contra-golpe** | Acerto durante a preparação ou execução do golpe adversário |
| **Finta** | Golpe cancelado na preparação |
| **Direção de técnica** | Uma das 4 direções usada para técnicas: em pé, Técnica (Espaço) + WASD = esquivas; no clinch/solo, WASD direto = transição ou defesa. No gamepad, analógico direito |
| **Disputa** | Modelo único de resolução do grappling (leitura → pressão × resistência) |
| **Pressão / Resistência** | Valores comparados na Disputa quando não há leitura correta |
| **Vantagem de Clinch** | Valor de −2 a +2 que define opções no clinch |
| **Estado de posição** | Estado atual da luta (EP, CL, CG, SG, SM, SL, SO, SC, SR, KD) |
| **Papel** | Por cima/por baixo, prensando/prensado etc. |
| **Tempo de controle** | Tempo em posição dominante (critério dos juízes) |
| **Encaixe / Aperto / Medidor de Aperto** | Etapas e medidor da finalização |
| **Fôlego** | Energia imediata (0–100%), gasta por todas as ações |
| **Reserva** | Teto do Fôlego, cai ao longo da luta |
| **Dano (por zona)** | Cabeça, Corpo, Pernas; agudo (recupera parcial) e residual |
| **Impacto** | Força efetiva de um golpe ao acertar |
| **Limiar de Choque** | Valor que o Impacto na cabeça precisa exceder para abalar/atordoar/derrubar |
| **Abalado / Atordoado / Knockdown / Apagão** | Escala crescente de efeito de choque |
| **Defesa inteligente** | Critério do árbitro: o lutador está se defendendo ativamente |
| **Foco tático** | Escolha do intervalo que orienta o próximo round, sem bônus de atributo |
| **Relatório de Scouting** | Informação pré-luta sobre o adversário |
| **Perfil cognitivo** | Parâmetros da IA (percepção, erro, memória, temperatura) |
| **Arquétipo** | Conjunto de pesos de ação da IA por estilo |
| **Memória de hábitos** | Registro da IA sobre padrões do adversário |
| **Nível de HUD** | Completo / Mínimo / Imersivo |

## 3. Termos de lutador e carreira

| Termo | Definição |
|---|---|
| **Atributos visíveis** | 17 atributos 1–100: Força, Velocidade, Condicionamento, Recuperação, Mobilidade, Queixo, Robustez, Boxe, Kickboxing, Defesa em Pé, Wrestling Ofensivo, Wrestling Defensivo, Controle de Solo, Jiu-jitsu, Defesa de Finalização, QI de Luta, Compostura ([CHARACTER §2](CHARACTER_DESIGN.md#2-atributos-visíveis)) |
| **Características ocultas** | Potencial, Pico Físico, Fragilidade, Metabolismo |
| **Traços de personalidade** | Disciplina, Ambição, Temperamento, Carisma — só NPCs (Carisma também para o jogador, escolhido na criação) |
| **Perfil Público** | Rótulo emergente das escolhas de mídia |
| **Estilo** | Derivado dos atributos técnicos (Boxeador, Kickboxer/Muay Thai, Wrestler, Especialista de jiu-jitsu, Completo, Brawler) |
| **Biotipo** | Conjunto de corpo/animação (M-Leve, M-Médio, M-Pesado, M-Superpesado, F-Leve, F-Médio) |
| **Divisão** | Masculina ou feminina |
| **Categoria (de peso)** | Uma das 12 categorias; identificada por divisão + nome |
| **Origem** | Histórico inicial na criação |
| **Bloco de treino** | Unidade do plano semanal (12 por semana) |
| **Carga** | Fadiga gerada por uma atividade |
| **Fadiga Acumulada** | Cansaço de semanas de treino (0–100) |
| **Desgaste Acumulado** | Desgaste de carreira, sobretudo trauma na cabeça (0–100), permanente |
| **Lesão crônica** | Sequela permanente de uma lesão grave |
| **Suspensão médica** | Afastamento obrigatório após a luta |
| **Retorno precoce** | Voltar antes de curar uma lesão, com riscos |
| **Plano de corte** | Conservador / padrão / agressivo |
| **Prestígio** | Reputação esportiva |
| **Popularidade** | Interesse do público (por região e global) |
| **Relação com organização** | Afinidade com cada organização |
| **Valor de mercado** | Base das propostas de contrato |
| **Trabalho paralelo** | Atividade de renda que ocupa blocos de treino |
| **Legado** | Pontuação de carreira; define Hall da Fama |
| **Nível de organização** | 1 Local · 2 Regional · 3 Continental · 4 Elite |
| **Pouco prazo** | Luta aceita com menos de 4 semanas `[PROV]` |

## 4. Termos técnicos da documentação

| Termo | Definição |
|---|---|
| **APROVADA / RECOMENDAÇÃO / PENDENTE** | Estados de decisão ([GDD §0](GDD.md#0-convenções-desta-documentação)) |
| **[PROV]** | Valor provisório, não testado |
| **SYS-xx / E-xx / D-xxx / R-xxx / P-xxx / REQ-xx** | IDs de sistema, etapa, decisão, recomendação, pendência e requisito |
| **Greybox** | Protótipo com formas simples, sem arte final |
| **Spike** | Experimento curto para reduzir incerteza técnica |
| **FightSetup / FightResult** | Contratos de entrada e saída de uma luta |
| **Resolvedor estatístico** | Simulação rápida de lutas entre NPCs |
| **LOD (nível de detalhe)** | Detalhado / Agregado / Estatístico na simulação do mundo |
| **Tick** | Uma execução da simulação semanal |
| **RuleSet** | Conjunto de regras configurável por organização |
| **Resolução-base** | Resolução interna do jogo (recomendação 640×360) |
| **Hit-stop** | Pausa de poucos quadros no impacto |
| **Telegraph** | Ver §2 |

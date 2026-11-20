# DECISIONS — Registro de decisões

> Versão 0.1 · Etapa 01 · Volta ao [GDD](GDD.md)
> **APROVADA** = decidida pelo usuário. **RECOMENDAÇÃO** = proposta do Claude, *pendente de aprovação*. **PENDENTE** = exige resposta do usuário ou validação.
> Para aprovar, rejeitar ou alterar um item, basta citar o ID. Itens rejeitados permanecem no registro com o motivo.

---

## 1. Decisões aprovadas (requisitos fixos do prompt da Etapa 01)

| ID | Decisão | Origem / data |
|---|---|---|
| D-001 | Gênero MMA com foco principal em modo carreira | Prompt Etapa 01, 2026-11-19 |
| D-002 | Perspectiva lateral com profundidade simulada (2.5D) | idem |
| D-003 | Combate híbrido: estratégia, técnica e leitura; nem arcade simplificado nem simulação inacessível | idem |
| D-004 | Carreira realista e profunda, com progressão longa e consequências persistentes | idem |
| D-005 | Plataforma inicial: PC Windows | idem |
| D-006 | Pixel art moderna, personagens grandes e detalhados, animação fluida | idem |
| D-007 | Todas as categorias na primeira versão jogável: 8 masculinas (mosca, galo, pena, leve, meio-médio, médio, meio-pesado, pesado) e 4 femininas (palha, mosca, galo, pena) | idem |
| D-008 | Engine Godot 4 | idem |
| D-009 | GDScript (salvo justificativa técnica concreta) — nenhuma justificativa contrária encontrada | idem |
| D-010 | Organizações, atletas e marcas fictícios; sem licenças | idem |
| D-011 | Categorias, atributos, organizações, regras e eventos orientados a dados e configuráveis | Princípios 4 e 5 |
| D-012 | Equipe: **desenvolvedor solo, sem artista** (P-001) | Resposta do usuário, 2026-11-19 |
| D-013 | As 12 categorias são exigidas na **versão 1.0**; o protótipo usa 1 categoria (P-002, aprova R-002) | idem |
| D-014 | O pipeline de arte será decidido **após o spike E-06**, com custo medido (P-003 como processo; aprova R-004 como método) | idem |
| D-015 | Controle principal: **teclado primeiro**, gamepad como alternativa completa (P-007) | idem |
| D-016 | Todas as teclas são **remapeáveis pelo jogador**; padrões simples definidos pelo Claude (U/I mãos, J/K pernas, E curvo, Q corpo, Shift guarda, Espaço técnica, L agarrar) | Usuário, 2026-11-19 (E-03) |

---

## 2. Recomendações (pendentes de aprovação)

| ID | Recomendação | Justificativa | Alternativas consideradas | Impacto | Onde |
|---|---|---|---|---|---|
| R-001 | Codinome "Projeto Jaula"; no jogo usar "jaula/cage", não "Octagon" | "The Octagon" é marca associada a organização real | Usar "octógono" livremente (risco jurídico pequeno, mas desnecessário) | Baixo | GDD §0, §1.1 |
| ~~R-002~~ → **D-013** | "Primeira versão jogável" = **versão 1.0 completa**; o protótipo usa 1 categoria | Fazer 12 categorias no protótipo multiplica conteúdo sem validar o combate | 12 categorias já no protótipo (mais caro, sem ganho de validação) | Alto (escopo do protótipo) | GDD §1.8 |
| R-003 | Resolução-base 640 × 360, escala inteira, lutadores ≈ 128–150 px | Escala inteira em 1080p/1440p/4K; detalhe suficiente | 480×270 (pouco detalhe), 960×540 (custo proibitivo) | Alto (arte) | ART §3 |
| ~~R-004~~ → **D-014** (método) | Investigar pipeline **3D → pixel** em spike antes de decidir | Volume estimado ≈ 8.000+ quadros inviável à mão | Desenho à mão; cutout 2D | **Crítico** | ART §11 |
| R-005 | Corpo por **biotipo** (6), não por categoria | 12 conjuntos de animação seriam inviáveis | 4 biotipos (mais barato); 12 (inviável) | Alto | ART §5.2 |
| R-006 | Profundidade contínua em faixa Z estreita, auto-orientação, troca de lado só por ação | Profundidade com função mecânica sem virar 3D | Faixas discretas (lanes); 3D livre | Alto (combate) | COMBAT §2 |
| R-007 | Interação com grade só nas extremidades X | Metade das animações de grade; leitura lateral | Grade em 4 lados | Médio | COMBAT §2.5 |
| R-008 | Controle por membros (4 teclas U/I/J/K) + modificadores; **direção de técnica** = WASD com a tecla Técnica (em pé) ou WASD direto (no grappling); revisado para teclado primeiro (D-015) | Vocabulário único em pé e no chão, confortável no teclado | Teclas por golpe; comandos de sequência | Alto | COMBAT §3.1 |
| R-009 | Modelo único de **Disputa** para todo grappling (leitura vence; sem leitura, atributos decidem deterministicamente) | Evita minijogos; mantém agência do jogador e realismo | Minijogos por técnica; resolução por probabilidade pura | Alto | COMBAT §4.2 |
| R-010 | Finalização em etapas (Encaixe → Aperto) usando o vocabulário da Disputa | Tensão sem minijogo separado | Barra de apertar botão; QTE | Médio | COMBAT §4.6 |
| R-011 | Stamina em duas camadas: **Fôlego** (imediato) e **Reserva** (teto, cai na luta) | Gestão no momento + narrativa da luta | Medidor único | Alto | COMBAT §6.1 |
| R-012 | Dano por zona (cabeça/corpo/pernas) e **Limiar de Choque** determinístico com variação ±5% | KO explicável, sem sorte pura | Probabilidade de KO por golpe; barra de vida única | Alto | COMBAT §6.2–6.3 |
| R-013 | 17 atributos visíveis + 4 ocultos; **remover** "Resistência" (fundida em Condicionamento) e "Precisão" (coberta por Boxe/Kickboxing + geometria); Disciplina vira traço de NPC | Evitar redundância | Manter todos os sugeridos no prompt | Médio | CHARACTER §2 |
| R-014 | Escala de atributos 1–100; atributos relativos à divisão de peso | Familiar; permite comparar dentro da categoria | Escala 1–20; absolutos | Médio | CHARACTER §1.1, §6.3 |
| R-015 | Tempo em **turnos semanais** com avanço rápido | Granularidade de camps e suspensões | Diário; mensal | Alto | CAREER §3 |
| R-016 | Treino em **12 blocos semanais** com Carga e Fadiga Acumulada | Escolhas reais, sem maximizar tudo | Sliders de intensidade; treino automático | Alto | CAREER §4 |
| R-017 | Simulação do mundo com **LOD** e **resolvedor estatístico** | Custo computacional baixo | Simular todas as lutas no motor (caro) | Alto | CAREER §11 |
| R-018 | Contratos **FightSetup/FightResult** comuns a luta jogada, simulada e Luta Rápida | Desacoplamento combate ↔ carreira | Integração direta | Alto (arquitetura) | GAME_SYSTEMS §3 |
| R-019 | 3 juízes simulados com pesos individuais e ruído pequeno, sistema de 10 pontos | Decisões divididas naturais e transparentes | Juiz único determinístico | Médio | COMBAT §7.4 |
| R-020 | Regras Unificadas como referência (rounds, faltas, limites de peso), **a validar** antes de textos in-game | Familiaridade do público | Regras totalmente fictícias | Médio | COMBAT §7.1, CHARACTER §6.2 |
| R-021 | Organizações fictícias em 4 níveis (local procedural, 3 regionais, 1 continental, 2 de elite) | Escada de carreira clara + escolha entre elites | Uma organização única; dezenas de organizações | Médio | CAREER §7 |
| R-022 | Reputação em eixos separados: **Prestígio**, **Popularidade**, **Relação com organização** | Permite carreiras distintas (campeão discreto × astro popular) | Reputação única | Médio | CAREER §10.4 |
| R-023 | Jogador sem traços de personalidade numéricos; **Perfil Público** emergente; Carisma escolhido na criação | O jogador decide a personalidade | Traços fixos para o jogador | Médio | CHARACTER §4 |
| R-024 | **Trabalho paralelo** como mecânica do início da carreira; dívida dificulta mas não encerra | Economia com decisão e sem bloqueio | Salário fixo; game over por falência | Médio | CAREER §10.3 |
| R-025 | Modos 1.0: Carreira, Luta Rápida, Treino/Tutorial; sem online | Foco no pilar principal | Versus local na 1.0 | Médio | GDD §3 |
| R-026 | Sem lutas entre divisões masculina e feminina; a divisão é escolhida na criação | Coerência com o esporte | — | Baixo | CAREER §2.1 |
| R-027 | HUD em 3 níveis (Completo/Mínimo/Imersivo), independente da dificuldade | Legibilidade e acessibilidade | HUD fixo | Baixo | COMBAT §8.3 |
| R-028 | Autosave semanal e pré/pós-luta, 3 rotativos, escrita atômica, sem save no meio da luta, ≥ 5 slots | Integridade e anti *save-scum* | Save livre a qualquer momento | Médio | GAME_SYSTEMS §6 |
| R-029 | Sangue estilizado e opcional | Classificação etária e preferência | Sem sangue; sangue fixo | Baixo | ART §8 |
| R-030 | Árbitro como sistema de regras; presença visual mínima só na 1.0 | Custo de animação | Árbitro completo desde o protótipo | Baixo | COMBAT §7.3 |
| R-031 | Catálogo enxuto de estados de solo (Guarda unificada, Meia-guarda, Controle lateral, Montada, Costas, Recuperação de base, Caído) | Cada estado custa 2+ animações e várias transições | Catálogo amplo (north-south, crucifixo, X-guard...) | Alto (conteúdo) | COMBAT §4.1 |
| R-032 | Faltas intencionais não são ações do jogador; faltas acidentais raras por colisão | Escopo e tom | Permitir faltas intencionais | Baixo | COMBAT §7.3 |
| R-033 | Queixo não treinável; cai com Desgaste Acumulado | Peso de cada nocaute; realismo | Queixo treinável | Médio | CHARACTER §2.2 |
| R-034 | Ajustes táticos do intervalo e mídia **não** dão bônus de atributo | Evitar penalidades/benefícios arbitrários; IA justa | Buffs de "motivação" | Médio | COMBAT §5.3, CAREER §10.5 |
| R-035 | O jogador não escolhe o Potencial na criação; características ocultas sorteadas em faixas da origem | Manter incerteza e descoberta na carreira | Potencial escolhido com pontos | Baixo | CHARACTER §3 |
| R-036 | Para desenvolvedor solo sem artista: priorizar no spike o pipeline **3D → pixel** com modelos-base e animações adquiridos de bibliotecas com licença comercial que permita modificação, mais limpeza própria; encomendar só peças pontuais (logos, UI, retratos) se houver orçamento | O desenho à mão de ≈ 8.000 quadros sem artista é inviável | Contratar artista de pixel para tudo (caro); arte gerada por IA (risco de consistência e de licença; não recomendado como base) | **Crítico** | ART §11 |
| R-037 | Começar com **4 biotipos** (M-Leve, M-Médio, M-Pesado, F) e expandir para 6 só se o spike mostrar custo baixo por biotipo | Reduzir o maior custo da produção solo | 6 biotipos desde o início | Alto | ART §5.2 |
| R-038 | Todas as entradas de combate são **digitais em 4 direções**; nenhuma ação exige mais de 3 teclas simultâneas | Teclado primeiro; evita *ghosting* de teclados comuns; gamepad funciona igual | Entradas analógicas e 8 direções | Médio | COMBAT §3.1 |

---

## 3. Pendências (precisam de resposta do usuário ou validação)

### 3.1 Bloqueiam etapas próximas
Nenhuma no momento. P-001, P-002 e P-007 foram respondidas (D-012, D-013, D-015).

### 3.2 Não bloqueiam agora
| ID | Pergunta | Quando decidir |
|---|---|---|
| P-003 | Pipeline de arte final (3D→pixel × à mão × misto), segundo o método D-014 | Ao fim do spike E-06 (marco M2) |
| P-004 | Profundidade da personalização visual (quantos cabelos, barbas, tatuagens, biotipos selecionáveis) | Após E-06 |
| P-005 | Idioma(s) de lançamento (PT-BR? EN?) | E-02 (textos já em tabelas de localização) |
| P-006 | Nível de violência gráfica / classificação etária alvo | Antes de E-10 |
| P-008 | Nome definitivo e identidade; nomes finais das organizações (verificar marcas) | Após M1 |
| P-009 | Versus local entra na 1.0 ou expansão? | Após M1 |
| P-010 | Pontuação 10-9 fiel em todas as organizações ou sistema alternativo fictício em alguma (ex.: KFF) | E-08 |
| P-011 | Suporte a mods/edição de dados pelo jogador | Após 1.0 (a camada de dados já facilita) |
| P-012 | Simular a própria luta (sem jogar) como opção de acessibilidade | Após M1 |

---

## 4. Questões levantadas na validação cruzada

Ver resultado completo no relatório da Etapa 01. Itens que ficaram como questão em aberto (sem decisão silenciosa):

| ID | Questão | Situação |
|---|---|---|
| V-001 | Categorias com biotipo compartilhado (ex.: Pena masculino aceita M-Leve e M-Médio) exigem 2 alturas por biotipo? | Depende de `P-003`/`P-004` |
| V-002 | Atributos relativos à divisão + mudança de categoria exigem tabela de conversão a ser balanceada | Registrado; `[PROV]` em CHARACTER §6.3 |
| V-003 | A KFF (elite alternativa) tem menos categorias femininas *(fictício)*. Isso pode ser lido como desequilíbrio intencional entre divisões | **Usuário decide**: manter (cria escolha de carreira) ou dar paridade de categorias |
| V-004 | Variação de ±5% no impacto e ruído dos juízes são as únicas fontes de aleatoriedade no combate; precisa de playtest para confirmar que lutas não ficam repetitivas | Validar em M1 |

---

## 5. Decisões técnicas com impacto no design ou no planejamento

Registro completo em [architecture/TECH_DECISIONS.md](architecture/TECH_DECISIONS.md). Itens que afetam design/plano:

| ID técnico | Efeito | Relação com o design |
|---|---|---|
| T-019 | Roadmap: E-02 vira Arquitetura técnica e surge a E-02B Fundação técnica | ROADMAP v0.3; escopo de gameplay inalterado |
| T-004 | Combate em passo fixo de 60 Hz; quadros de golpe do COMBAT_DESIGN passam a ser exatamente passos de simulação | COMBAT §3.3 |
| T-005 | Posição de grappling é um estado único do par | COMBAT §4.1, R-031 |
| T-007 | Saves em JSON; Ironman e anti-save-scum dependem do autosave, não de criptografia | R-028 |
| T-011 | Resolução muda só configuração e escala visual; domínio em metros | R-003 (ainda pendente) |
| T-013 | Determinismo garantido na mesma máquina; entre máquinas é pendência | GAME_SYSTEMS §9.4 |
| T-018 | Entrada via InputMap com buffer; frente/trás relativos ao adversário por padrão | D-015, R-008, R-038 |

### Lacunas de design encontradas na Etapa 02 (não bloqueiam)
| ID | Lacuna | Proposta |
|---|---|---|
| V-005 | Não há documento de **áudio** (quais sons, música dinâmica, locução) | A arquitetura prevê AudioDirector + mapa evento→som; especificar o design de áudio antes de E-10 |
| V-006 | O "mundo-modelo" da Luta Rápida (GDD §3) não tem conteúdo definido | Usar um mundo gerado com semente fixa a partir de `data/world_seed/`; confirmar em E-05 |
| V-007 | Frente/trás relativos ao adversário × à tela no teclado (COMBAT §3.1) | Padrão: relativo ao adversário; opção em Settings (`directions_relative_to_opponent`). Confirmar no playtest da E-03 |
| V-008 | COMBAT §3.1 usava S para esquiva lateral e para abaixar | **Corrigido na E-03:** Espaço+W = slip, Espaço+S = duck, Espaço+trás = pull |

## 6. Histórico

| Versão | Data | Alteração |
|---|---|---|
| 0.1 | 2026-11-19 | Criação do registro na Etapa 01 |
| 0.2 | 2026-11-19 | Respostas a P-001, P-002, P-003 (método) e P-007 → D-012 a D-015; R-008 revisada; novas R-036 a R-038 |
| 0.4 | 2026-11-19 | E-03: usuário pediu controles configuráveis pelo jogador com padrões simples → **D-016** (abaixo). V-008 corrigida |
| 0.3 | 2026-11-19 | **Etapa 01 aprovada pelo usuário** ("Aprovar e seguir"). Os documentos de design passam a ser a base aprovada; os itens R-xxx continuam como recomendações vigentes até aprovação individual. Seção 5 (decisões técnicas e lacunas V-005 a V-007) adicionada na Etapa 02 |

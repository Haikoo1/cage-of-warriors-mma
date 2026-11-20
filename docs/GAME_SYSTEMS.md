# GAME SYSTEMS — Projeto Jaula

> Versão 0.1 · Etapa 01 · Volta ao [GDD](GDD.md)
> Mapa de sistemas no nível de design. **Não é arquitetura de código**: nomes como `FightSetup` são contratos conceituais que a Etapa 02 transformará em decisões técnicas.

---

## 1. Lista de sistemas e responsabilidades

| ID | Sistema | Responsabilidade | Recebe | Produz |
|---|---|---|---|---|
| SYS-01 | Movimento 2.5D | Posição no plano X/Z, orientação, distância, ângulo, limites da jaula | Comandos de movimento, Mobilidade, estado de Fôlego/dano nas pernas | Posições, faixa de distância, Vantagem de Ângulo, encurralado |
| SYS-02 | Trocação | Golpes, fases, combinações, acerto | Comandos, catálogo de golpes (dados), atributos, posições | Eventos de acerto/erro, impacto por zona |
| SYS-03 | Defesa em pé | Guarda, esquivas, check | Comandos, Defesa em Pé, Fôlego | Mitigação de impacto, janelas de contra-golpe |
| SYS-04 | Clinch | Estado de clinch, Vantagem de Clinch, grade | Disputas, atributos de wrestling, posição X | Estado de posição, ações disponíveis |
| SYS-05 | Quedas | Entradas, sprawl, resultado da queda | Disputas, atributos | Transição para estados de solo |
| SYS-06 | Solo | Estados de solo, transições, GnP, tempo de controle | Disputas, atributos | Estado de posição, impactos de GnP, tempo de controle |
| SYS-07 | Finalizações | Encaixe, Medidor de Aperto, resultado | Disputas, Jiu-jitsu/Defesa de Finalização, Fôlego | Fim de luta por finalização, lesões leves possíveis |
| SYS-08 | Fisiologia na luta | Fôlego, Reserva, dano por zona, Limiar de Choque, cortes | Ações (custos), impactos, atributos, modificadores do dia (corte, Fadiga) | Estados (atordoado, KD, apagão), dano final |
| SYS-09 | Regras e arbitragem | Relógio, rounds, intervenções, faltas, encerramentos | RuleSet (dados), estados da luta | Encerramentos, separações, advertências |
| SYS-10 | Julgamento | Pontuação dos juízes | Estatísticas do round, perfis dos juízes | Placar por round, decisão |
| SYS-11 | IA de combate | Escolhe ações de um lutador | Estado visível da luta, perfil cognitivo, arquétipo, tendências | Comandos (iguais aos do jogador) |
| SYS-12 | Feedback e HUD | Comunicar estados e causas | Eventos de todos os sistemas de combate, nível de HUD | Sinais visuais/sonoros, textos |
| SYS-13 | Lutador | Dados do atleta | Definições, evolução | Snapshot de atributos e estado |
| SYS-14 | Calendário | Tempo, turnos, agenda | Organizações (eventos), ações do jogador | Ordem do tick, datas |
| SYS-15 | Treino e equipe | Plano semanal, ganhos, Fadiga, academias, treinadores | Plano, academia, equipe, idade, Potencial | Ganhos de atributo, Fadiga, risco de lesão, scouting |
| SYS-16 | Saúde e envelhecimento | Lesões, suspensões, Desgaste, idade | FightResult, treino, tempo | Lesões, restrições, declínio, avisos de aposentadoria |
| SYS-17 | Peso | Peso de caminhada, corte, pesagem | Categoria, plano de corte, Metabolismo, prazo | Modificadores do dia, resultado da pesagem |
| SYS-18 | Organizações e eventos | Calendário de eventos, cards, campeões | Dados das organizações, rankings | Eventos, cards, vagas |
| SYS-19 | Matchmaking e contratos | Ofertas, negociação, dispensas, transferências | Rankings, reputação, disponibilidade | Lutas marcadas, contratos |
| SYS-20 | Rankings | Ordenação por categoria e organização | FightResults, Popularidade | Rankings |
| SYS-21 | Simulação do mundo | NPCs, LOD, resolvedor estatístico, geração | Tempo, dados, FightSetup de NPCs | FightResults simulados, novos atletas, aposentadorias |
| SYS-22 | Economia | Saldo, receitas, despesas | Contratos, FightResults, gastos | Saldo, restrições (dívida) |
| SYS-23 | Reputação e mídia | Prestígio, Popularidade, relações, rivalidades, Perfil Público | FightResults, escolhas de mídia | Valores de reputação, rivalidades |
| SYS-24 | Legado | Pontuação de legado, aposentadoria | Histórico de carreira | Legado, Hall da Fama |
| SYS-25 | Persistência | Salvar/carregar carreira e configurações | Estado de todos os sistemas de carreira | Arquivos de save |
| SYS-26 | Configurações e acessibilidade | Controles, áudio, vídeo, HUD, dificuldade | Escolhas do jogador | Configuração global |
| SYS-27 | Apresentação | Arte, animação, áudio, UI | Estados de jogo | — |
| SYS-28 | Camada de dados e regras | Definições configuráveis | Arquivos de dados | Definições validadas |

---

## 2. Diagrama de dependências (conceitual)

```
                    ┌──────────── SYS-28 Dados (categorias, golpes, regras, organizações, academias) ────────────┐
                    ▼                                                                                            ▼
COMBATE  SYS-01 ◄─► SYS-02/03 ◄─► SYS-04/05/06/07 ──► SYS-08 ──► SYS-09/10                     CARREIRA SYS-14 Calendário
            ▲          ▲                ▲                ▲          │                                    │ (ordem do tick)
            └──────────┴── SYS-11 IA ───┴────────────────┘          │                                    ▼
                                                                     ▼                   SYS-15 Treino → SYS-16 Saúde → SYS-17 Peso
                                          FightResult ◄──── [ LUTA ] ◄──── FightSetup ◄── SYS-13 Lutador
                                               │                               ▲
                                               ▼                               │
                     SYS-16, SYS-20, SYS-22, SYS-23, SYS-24  ──────► SYS-19 Matchmaking ◄── SYS-18 Organizações
                                                                               ▲
                                                SYS-21 Simulação do mundo ─────┘ (usa o mesmo contrato)
```

---

## 3. Integração combate ↔ carreira — `RECOMENDAÇÃO R-018`

O combate **não conhece** a carreira. A carreira **não conhece** os detalhes do combate. Eles se comunicam por dois contratos:

### 3.1 FightSetup (entrada de uma luta)
| Campo | Origem |
|---|---|
| Lutador A e B: snapshot de atributos, físico, base, biotipo, aparência | SYS-13 |
| Modificadores do dia por lutador: Reserva inicial, Queixo efetivo, penalidades de lesão (retorno precoce), peso de luta | SYS-15, SYS-16, SYS-17 |
| Controle: jogador / IA (com perfil cognitivo e plano de jogo) | Carreira ou Luta Rápida |
| RuleSet: rounds, duração, golpes proibidos, pontuação, árbitro e juízes | SYS-09/10 via SYS-28 |
| Contexto: título?, posição no card, organização, arena (apresentação) | SYS-18 |
| Informação do jogador: Relatório de Scouting, foco tático inicial | SYS-15 |

### 3.2 FightResult (saída de uma luta)
| Campo | Consumidores |
|---|---|
| Vencedor, método, round, tempo | SYS-20, SYS-22, SYS-23, SYS-24 |
| Placar dos juízes por round | Histórico, SYS-23 (controvérsia → rivalidade) |
| Estatísticas (golpes por tipo, quedas, tempo de controle, knockdowns, finalizações tentadas) | Histórico, bônus da noite, tendências do lutador |
| Dano final por zona, knockdowns sofridos, cortes | SYS-16 (suspensão, lesões, Desgaste) |
| Lesões ocorridas na luta | SYS-16 |
| Faltas/advertências, falha de peso | SYS-23 |

### 3.3 Regras do contrato
- O **combate jogado** e o **resolvedor estatístico** (SYS-21) produzem o mesmo `FightResult`. A carreira trata as duas origens igualmente.
- A Luta Rápida usa os mesmos contratos com lutadores sem carreira; isso permite testar o combate isoladamente desde o protótipo.
- Nenhum sistema de combate escreve diretamente em dados de carreira.

---

## 4. Ordem do tick e dependências circulares

Há ciclos **ao longo do tempo** (resultado → ranking → matchmaking → nova luta → resultado), mas não podem existir **dentro de um mesmo tick**. Solução: ordem fixa da simulação semanal ([CAREER §3.1](CAREER_DESIGN.md#31-turno-semanal--recomendação-r-015)):

```
1 Treino (SYS-15) → 2 Saúde (SYS-16) → 3 Mundo: eventos da semana (SYS-18, SYS-21) → 4 Resultados: rankings (SYS-20)
→ 5 Matchmaking (SYS-19) → 6 Economia (SYS-22) → 7 Reputação (SYS-23) → 8 Idade (mensal) → 9 Notificações
```
Cada passo lê o estado deixado pelos anteriores e só escreve no próprio domínio. Ciclos verificados:

| Ciclo aparente | Resolução |
|---|---|
| Ranking ↔ matchmaking | Matchmaking lê o ranking da semana atual (passo 5 após 4) |
| Reputação ↔ contrato | Contrato usa a reputação da semana anterior (passo 7 é posterior) |
| Fadiga ↔ lesão ↔ treino | Treino gera Fadiga; Saúde lê Fadiga e sorteia lesão; o treino da semana seguinte respeita a lesão |
| Popularidade ↔ ranking (ajuste promocional) | Ajuste limitado a ±2 posições e com dados da semana anterior |

---

## 5. Camada de dados e regras — SYS-28

Princípio (`D-011`): tudo que é conteúdo ou regra balanceável é **dado**, não código.

| Definição | Exemplos de campos | Usado por |
|---|---|---|
| `WeightClass` | divisão, nome, limite, tolerância, biotipos permitidos, multiplicadores de massa, distribuições físicas | SYS-13, 17, 18, 21 |
| `RuleSet` | rounds, duração, intervalo, golpes proibidos, sistema de pontuação, tempos de inatividade, regras de pesagem, suspensões médicas | SYS-09, 10, 16, 17 |
| `Organization` | nome, nível, região, categorias, RuleSet, calendário, faixa de bolsas, regras de contrato, ranking | SYS-18, 19, 20 |
| `Strike` | entrada, alvos, faixa, alcance, tolerância Z, fases, potência, Fôlego, atributo técnico, permite combinação | SYS-02 |
| `GrappleTechnique` | estado de origem/destino, direção, preparação, atributos de pressão/resistência, Fôlego | SYS-04..07 |
| `PositionState` | ID, papéis, ações disponíveis, multiplicadores de GnP | SYS-06 |
| `Archetype` | pesos de ação, plano de jogo padrão | SYS-11 |
| `TrainingActivity` | ganhos, Carga, risco, custo | SYS-15 |
| `Gym`, `Coach` | especialidades, estrutura, custo, competência | SYS-15 |
| `Origin` | atributos-base, faixas ocultas, dinheiro, academias | Criação |
| `InjuryType` | local, gravidade, afastamento, atributos afetados, chance de crônica | SYS-16 |
| `MediaQuestion` | contexto, respostas, efeitos | SYS-23 |
| `BalanceConstants` | todos os `[PROV]` globais (faixas de Fôlego, limiares de choque etc.) | todos |

- Todas as definições devem ter **validação** ao carregar (ex.: categoria sem limite, golpe sem atributo técnico) — requisito para a Etapa 02.
- Textos exibidos ao jogador ficam em tabelas de localização desde o início (`P-005`).

---

## 6. Persistência — SYS-25 — `RECOMENDAÇÃO R-028`

Requisitos de design (sem implementação):

| Requisito | Definição |
|---|---|
| O que salvar (por carreira) | Mundo completo: todos os lutadores (estado e histórico), organizações, rankings, campeões, calendário, eventos passados e futuros, contratos, economia, reputação, rivalidades, notícias recentes, semente de aleatoriedade, versão dos dados |
| Dados globais (fora da carreira) | Configurações, controles, progresso de tutorial, estatísticas globais/Hall da Fama entre carreiras (opcional) |
| Slots | Múltiplas carreiras (≥ 5 slots `[PROV]`) |
| Quando salvar | Autosave **no início de cada semana** e **antes e depois de cada luta**; salvar manual no Dashboard |
| Durante a luta | Sem save no meio da luta (evita *save-scum* e complexidade). Fechar o jogo durante a luta = retomar do autosave pré-luta, com a luta reiniciada |
| Integridade | Escrita atômica (arquivo temporário + troca) e 3 autosaves rotativos; verificação de integridade ao carregar |
| Encerramento inesperado | No máximo uma semana (ou uma luta) perdida |
| Versões | Cada save registra a versão do formato; migrações explícitas entre versões; saves de versão futura não são abertos |
| Modo "Ironman" (sem recarregar) | Opcional, 1.0 se barato |

---

## 7. Configurações e acessibilidade — SYS-26

| Área | Opções |
|---|---|
| Controles | **Teclado primeiro** (D-015), gamepad completo; remapeamento total dos dois; segurar × alternar para Guarda e Técnica; frente/trás relativos ao adversário ou à tela; buffer de entrada ajustável; zona morta do analógico (gamepad) |
| Dificuldade | Deslocamento do perfil cognitivo da IA (Fácil/Normal/Difícil/Elite) — **nunca** atributos; **assistências** separadas: janelas de reação maiores para o jogador, *tells* realçados, sugestões de grappling no overlay |
| Velocidade de jogo | Velocidade da luta 80%–100% `[PROV]` (assistência); duração de round em Luta Rápida |
| HUD | Completo / Mínimo / Imersivo; textos de feedback on/off |
| Legendas | Para comentário/locução (se houver) e falas de córner |
| Interface | Escala de UI (inteira, 1×–3× sobre a resolução-base); fonte alternativa de alta legibilidade |
| Áudio | Volumes separados: música, efeitos, ambiente/público, voz |
| Visual | Sangue on/off; tremor de tela on/off; *flash* reduzido; filtros para daltonismo (cores de HUD com forma + cor) |
| Carreira | Pausa a qualquer momento fora da luta; avanço automático configurável; confirmação antes de decisões irreversíveis |

---

## 8. Telas e UX

| Tela | Objetivo | Informações principais | Ações | Ligações |
|---|---|---|---|---|
| Menu principal | Entrada | Carreiras salvas | Nova carreira, continuar, Luta Rápida, Treino, Configurações, sair | Todas |
| Nova carreira / perfil | Criar lutador | Passos da criação, pré-visualização do sprite, resumo de atributos | Avançar/voltar, aleatorizar | Escolha de academia → Dashboard |
| **Dashboard** | Centro da carreira | Próxima luta (contagem de semanas), Fadiga, saúde, saldo, ofertas pendentes, notícias, ranking | Planejar semana, simular, avançar até, abrir demais telas | Todas da carreira |
| Perfil do lutador | Ver o atleta | Atributos com tendência (↑↓), físico, estilo, lesões, Desgaste, cartel, Perfil Público | — | Histórico |
| Academia e treino | Plano semanal | Grade de 12 blocos, previsão de Fadiga e ganhos, equipe, custo | Atribuir blocos, salvar plano padrão, contratar/demitir, trocar de academia | Finanças |
| Calendário | Visão do tempo | Semanas, eventos, luta marcada, fim de suspensão/lesão, fim de contrato | Avançar até uma data | Organização |
| Contratos e negociações | Decidir contratos e lutas | Proposta, comparação com a atual, valor de mercado | Aceitar, recusar, contrapropor | Organização |
| Rankings | Contexto competitivo | Ranking por organização/categoria, campeão, ranking global | Ver perfil de NPC | Perfil NPC |
| Organização e eventos | Ecossistema | Nível, regras, eventos futuros, cards | Ver cards e resultados | Rankings |
| Preparação para luta | Camp | Adversário, Relatório de Scouting, semanas, plano de corte, equipe do camp | Ajustar camp | Treino |
| Pesagem | Momento da pesagem | Peso, limite, efeitos do corte | Continuar (e opções em caso de falha) | Apresentação |
| Apresentação da luta | Entrada dramática | Lutadores, cartel, físico (tale of the tape), regras | Pular | Luta |
| HUD de combate | Jogar | Ver COMBAT §8.3 | Pausa (Luta Rápida e carreira; menu de pausa sem salvar) | Intervalo |
| Intervalo | Ajuste | Estatísticas do round, dicas do córner, Fôlego/dano | Escolher foco tático; desistência do córner | Luta |
| Resultado e estatísticas | Entender o resultado | Método, placar dos juízes por round, estatísticas, bolsa, suspensão, lesões | Entrevista pós-luta (mídia), continuar | Dashboard |
| Histórico e legado | Memória da carreira | Linha do tempo, lutas, títulos, pontuação de legado | Ver luta | — |
| Finanças | Dinheiro | Saldo, receitas e despesas por mês, projeção | Ajustar gastos | Treino |
| Configurações | Opções | §7 | Alterar | — |

---

## 9. Regras globais

1. **Mesmas regras para jogador e IA** em todo sistema de combate e de carreira (NPCs usam as mesmas fórmulas de treino, lesão e idade, com LOD).
2. **Sem bônus de atributo por dificuldade.**
3. **Números de balanceamento só em dados** (`BalanceConstants` e definições).
4. **Determinismo com semente:** a simulação da carreira usa uma semente salva, permitindo reproduzir bugs.
5. **Nenhuma consequência sem explicação** visível ao jogador (notificação, tooltip ou estatística).
6. **Ordem fixa do tick** (§4).

## 10. Sistemas que precisam ser desacoplados

| Separação | Por quê |
|---|---|
| Combate × carreira (contratos FightSetup/FightResult) | Testar o combate sozinho; trocar o resolvedor; Luta Rápida |
| Lógica de combate × apresentação (animação) | Greybox antes da arte; trocar pipeline de arte sem tocar regras; duração de fases vem dos dados, não da animação |
| IA × lutador | IA emite os mesmos comandos do jogador; um lutador não sabe se é controlado por IA |
| Regras (RuleSet) × motor | Organizações diferentes sem código novo |
| Simulação do mundo × UI | Simular semanas sem renderizar |
| Persistência × sistemas | Cada sistema expõe seu estado; o formato de save é versionado separadamente |

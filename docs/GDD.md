# GDD — Projeto Jaula (codinome)

> Jogo de MMA 2.5D em pixel art para PC (Windows), com foco no Modo Carreira.
> Versão do documento: **0.2 (Etapa 01 — pendências bloqueadoras respondidas)** · Data: 2026-11-19

Este é o documento central. Ele resume a visão e todos os sistemas e aponta para os documentos especializados:

| Documento | Conteúdo |
|---|---|
| [COMBAT_DESIGN.md](COMBAT_DESIGN.md) | Movimento 2.5D, trocação, grappling, stamina/dano, regras, julgamento, IA, feedback |
| [CAREER_DESIGN.md](CAREER_DESIGN.md) | Criação, calendário, treino, contratos, organizações, rankings, economia, reputação, simulação do mundo |
| [CHARACTER_DESIGN.md](CHARACTER_DESIGN.md) | Estrutura do lutador, atributos, estilos, categorias de peso, evolução e declínio |
| [ART_DIRECTION.md](ART_DIRECTION.md) | Resolução, escala, proporções, animações, cenários, efeitos, UI |
| [GAME_SYSTEMS.md](GAME_SYSTEMS.md) | Mapa de sistemas, dados de entrada e saída, dependências, integração combate ↔ carreira, telas |
| [ROADMAP.md](ROADMAP.md) | Etapas de produção, entregáveis, critérios de conclusão, riscos |
| [DECISIONS.md](DECISIONS.md) | Registro de decisões aprovadas, recomendações e pendências |
| [GLOSSARY.md](GLOSSARY.md) | Vocabulário oficial do projeto |

---

## 0. Convenções desta documentação

- **`APROVADA`**: decisão tomada pelo usuário (requisito fixo). Só muda com nova aprovação.
- **`RECOMENDAÇÃO`**: proposta do designer (Claude), **pendente de aprovação**. Pode ser usada como hipótese de trabalho, mas não é decisão.
- **`PENDENTE`**: questão em aberto que exige resposta do usuário ou validação (playtest, spike técnico).
- **`[PROV]`**: número provisório de balanceamento. **Nenhum número marcado assim foi testado.** Todos precisam de playtest.
- IDs: `D-xxx` (decisão aprovada), `R-xxx` (recomendação), `P-xxx` (pendência), `SYS-xx` (sistema, ver [GAME_SYSTEMS.md](GAME_SYSTEMS.md)), `E-xx` (etapa do roadmap, ver [ROADMAP.md](ROADMAP.md)).
- Nomes de atributos, estados e sistemas seguem o [GLOSSARY.md](GLOSSARY.md). Se um documento usar outro nome, o glossário vence.
- "Octógono" é usado nos documentos como termo genérico. No jogo, recomenda-se **"jaula"/"cage"**, porque "The Octagon" é marca associada a uma organização real (`R-001`).

---

## 1. Conceito e identidade

### 1.1 Nome provisório
**Projeto Jaula** é um codinome de trabalho, não uma marca. Direções de identidade possíveis (`P-008`):

| Direção | Exemplo de nome | Tom |
|---|---|---|
| Esportiva / sóbria | *Pound for Pound*, *Round a Round* | Simulação de carreira séria, foco em legado |
| Dramática / jornada | *Cagebound*, *Do Zero ao Cinturão* | Narrativa de ascensão, emoção |
| Seca / técnica | *JAULA*, *Corner* | Minimalista, identidade gráfica forte |

Recomendação: decidir o nome só após a Etapa de luta greybox (E-05), quando o tom do combate estiver claro.

### 1.2 Descrição curta
Um jogo de MMA em pixel art no qual você constrói a carreira de um lutador do primeiro evento regional até o topo do esporte. Combate lateral com profundidade (2.5D) baseado em distância, leitura e gestão de energia; fora da jaula, cada decisão de treino, contrato, peso e saúde muda o lutador que entra na próxima luta.

### 1.3 Fantasia central
**"Eu construí este lutador, e ele carrega as cicatrizes das minhas decisões."**
O jogador é ao mesmo tempo o atleta (dentro da luta) e o gestor da própria carreira (fora dela). A vitória vem de duas fontes que se reforçam: preparação inteligente e execução na luta.

### 1.4 Público-alvo e experiência pretendida
- **Primário:** jogadores de jogos de esporte/gestão (estilo "manager de carreira") que gostam de MMA e de progressão longa.
- **Secundário:** fãs de jogos de luta que preferem leitura e espaçamento a combos longos.
- **Não é para:** quem quer um arcade de combos extensos, nem quem quer uma simulação fiel de federação real.
- **Experiência:** sessões de 30–90 minutos com sensação de progresso; lutas tensas de 5–15 minutos de tempo real; uma carreira completa em 20–60 horas `[PROV]`.

### 1.5 Pilares (ordem de importância)
1. **Combate legível e tático.** Cada golpe tem custo, risco e alcance; a luta é decidida por distância, leitura e energia, não por velocidade de dedos.
2. **Consequência persistente.** Dano, lesões, idade, reputação e contratos carregam de uma luta para a próxima. Nada é reiniciado depois do evento.
3. **Escolhas com custo.** Treino, dinheiro, tempo e saúde são limitados; não dá para maximizar tudo.
4. **Mundo vivo.** Outros atletas lutam, evoluem, envelhecem, se lesionam e mudam de organização sem o jogador.
5. **Leitura visual em pixel art.** Personagens grandes, poses claras e estados visíveis no corpo do lutador.

Em conflito entre pilares, o de número menor vence (ex.: se um efeito visual atrapalha a leitura do combate, ele sai).

### 1.6 Diferenciais
- Carreira de longo prazo com envelhecimento, desgaste acumulado e mundo simulado, em um jogo de luta jogável (não só simulado).
- Combate 2.5D com profundidade usada para ângulos, não para movimento 3D livre.
- Grappling unificado em um único modelo de "disputa" (sem minijogos separados).
- Personagens grandes em pixel art com o estado físico visível no sprite (cansaço, inchaço, cortes).

### 1.7 O que o jogo oferece e o que não oferece

| Oferece | Não oferece (deliberadamente) |
|---|---|
| Carreira solo profunda, um lutador por carreira | Gestão de academia inteira ou de vários atletas (expansão possível) |
| Luta Rápida e Treino para praticar | Multiplayer online |
| Organizações, atletas e marcas fictícios | Licenças de atletas, marcas ou organizações reais |
| 12 categorias de peso (8 masculinas, 4 femininas) | Lutas entre homens e mulheres; categorias abertas/peso livre |
| Regras configuráveis por organização | Simulação médica detalhada (ossos, ligamentos individuais) |
| Contratos com poucas cláusulas significativas | Negociação contratual jurídica detalhada |
| Mídia por decisões curtas | Redes sociais simuladas, diálogos longos ramificados |

### 1.8 Primeira versão jogável e visão de expansão
- **Protótipo (E-03 a E-05):** uma luta completa greybox (formas simples), 1 categoria, 2 lutadores, trocação + clinch + quedas + 3 posições de solo + 1 finalização, stamina/dano, regras, juízes e IA básica.
- **Versão 1.0 (primeira versão jogável completa):** carreira completa, **12 categorias** (`D-007`), organizações fictícias, mundo simulado, arte final. Confirmado pelo usuário: "primeira versão jogável" = 1.0; o protótipo usa 1 categoria (`D-013`).
- **Expansão futura:** versus local, editor de lutadores, novas origens, técnicas giratórias, gestão de academia, modo "lenda" (começar com veterano), mods.

---

## 2. Core loop e ciclos

### 2.1 Ciclo principal (sessão)

```
[Dashboard da carreira]
      │
      ▼
[Planejar semana] ──► treino, descanso, equipe, finanças
      │
      ▼
[Simular semana] ──► evolução, fadiga, lesões, notícias, ofertas
      │
      ├─ sem luta marcada ──────────────► volta ao Dashboard
      │
      └─ semana da luta
             ▼
       [Mídia + pesagem] ──► corte de peso, coletiva
             ▼
       [LUTA (jogada)] ──► rounds, intervalos, decisão
             ▼
       [Pós-luta] ──► resultado, bolsa, lesões, suspensão médica, ranking
             ▼
       [Recuperação e nova oferta] ──► volta ao Dashboard
```

### 2.2 Ciclo de longo prazo (carreira)

```
Estreia (circuito local) → vitórias → contrato regional → ranking regional
 → convite continental → contrato de elite → ranking de elite → disputa de cinturão
 → defesas / mudança de categoria / declínio físico → aposentadoria → legado
```
Derrotas, lesões e escolhas ruins podem desviar esse caminho (dispensa, retorno ao regional, troca de organização). O ciclo não é linear.

### 2.3 Exemplo de sessão típica (≈60 min)
1. O jogador abre a carreira na semana 3 de um camp de 8 semanas. O lutador tem 74% de Fadiga Acumulada.
2. Troca dois blocos de sparring por recuperação (o médico alertou para risco de lesão).
3. Simula duas semanas. Recebe uma notícia: o adversário venceu por finalização no último evento e está em sequência de 4 vitórias.
4. Na semana 6 gasta blocos em **Estudo do Adversário**; o relatório revela que ele baixa a mão de trás após chutar.
5. Semana da luta: na coletiva escolhe resposta respeitosa (popularidade cresce pouco, relação com a organização melhora). Pesagem: corte de 7%, bate o peso.
6. Luta de 3 rounds: perde o 1º round no clinch, ajusta no intervalo (o treinador sugere evitar a grade), vence o 3º com contra-golpe depois do chute. Decisão dividida.
7. Pós-luta: bolsa + bônus de vitória, suspensão médica de 30 dias por dano na cabeça, sobe para #9 no ranking. Oferta de contrato de uma organização maior chega na semana seguinte.

### 2.4 Exemplo resumido de trajetória
Ver trajetória completa em [CAREER_DESIGN.md §12](CAREER_DESIGN.md#12-trajetórias-de-exemplo). Resumo: lutadora peso-palha, origem jiu-jitsu, estreia aos 21; 6-0 no circuito local; 4-1 na liga regional; lesão no joelho aos 24 a afasta por 5 meses; volta, conquista o cinturão continental aos 26; assina com a liga de elite; perde para uma striker de elite, investe 2 anos em boxe; vence o cinturão de elite aos 30; defende 3 vezes; declínio de Velocidade a partir dos 33; aposenta aos 35 com 24-5 e entra no Hall da Fama.

---

## 3. Modos de jogo

| Modo | Descrição | Prioridade |
|---|---|---|
| **Carreira** | Modo principal. Um lutador criado pelo jogador em um mundo persistente. | 1.0 (essencial) |
| **Luta Rápida** | Luta avulsa entre dois lutadores do mundo-modelo ou de uma carreira salva (apenas leitura). Serve para praticar e testar. | Protótipo (como ferramenta) e 1.0 |
| **Treino / Tutorial** | Treino livre contra boneco/IA configurável e lições guiadas por sistema. | 1.0 |
| Versus local | Dois jogadores no mesmo PC. Barato depois da Luta Rápida, mas exige testar balanceamento PvP. | Expansão (`P-009`) |
| Editor de lutadores | Criar e editar NPCs e rosters. | Expansão |

---

## 4. Estrutura geral de gameplay

### 4.1 Fluxo entre telas
```
Menu principal
 ├─ Nova carreira → Criação do lutador → Escolha de academia → Dashboard
 ├─ Continuar → Dashboard
 ├─ Luta Rápida → Seleção → Apresentação → Luta → Resultado → Menu
 ├─ Treino/Tutorial
 └─ Configurações

Dashboard ⇄ Perfil | Academia/Treino | Calendário | Contratos | Rankings | Organizações | Finanças | Histórico
Dashboard → (semana da luta) Preparação → Pesagem → Apresentação → Luta ⇄ Intervalo → Resultado → Dashboard
```
Detalhes de cada tela em [GAME_SYSTEMS.md §8](GAME_SYSTEMS.md#8-telas-e-ux).

### 4.2 Passagem de tempo — `RECOMENDAÇÃO R-015`
- **Unidade de turno: semana.** O jogador planeja a semana e a simula. Pode simular várias semanas de uma vez ("avançar até: próxima oferta / próxima luta / fim da recuperação"), com interrupção automática quando houver evento que exige decisão.
- **Dia** só existe dentro da semana da luta (pesagem no dia anterior, luta no dia do evento).
- **Justificativa:** semanas são a granularidade natural de camps (6–10 semanas) e suspensões médicas; dias criariam microgestão sem decisão interessante; meses perderiam o controle do camp.

### 4.3 Controle direto × simulação
| Controlado diretamente pelo jogador | Resolvido por simulação |
|---|---|
| Cada luta do próprio lutador (em tempo real) | Lutas de todos os outros atletas |
| Plano semanal de treino e descanso | Ganhos de atributo, fadiga, lesões de treino |
| Aceitar/recusar lutas e contratos, contrapropostas | Ofertas das organizações, rankings, matchmaking de NPCs |
| Academia, treinadores, gastos | Envelhecimento, evolução de NPCs, aposentadorias |
| Respostas de mídia, callouts | Reação do público, popularidade |
| Ajustes táticos no intervalo | Atuação do árbitro e dos juízes |

Opção futura (não 1.0): simular a luta do próprio jogador com o resolvedor estatístico. Útil para acessibilidade, mas reduz o pilar 1. `PENDENTE` para depois do protótipo.

---

## 5. Resumo dos sistemas

Mapa completo com entradas, saídas e dependências: [GAME_SYSTEMS.md](GAME_SYSTEMS.md).

| ID | Sistema | Resumo | Documento |
|---|---|---|---|
| SYS-01 | Movimento 2.5D | Plano de chão com eixo X (distância) e faixa estreita de profundidade Z; auto-orientação; ângulos por passo lateral | COMBAT §2 |
| SYS-02 | Trocação | 4 membros, golpes com preparação/execução/recuperação, alcance e tolerância de profundidade | COMBAT §3 |
| SYS-03 | Defesa em pé | Guarda alta/baixa, esquivas, bloqueio de chute, contra-golpe | COMBAT §3 |
| SYS-04 | Clinch | Vantagem de clinch, golpes curtos, empurrar para a grade | COMBAT §4 |
| SYS-05 | Quedas | Entradas a distância e no clinch, sprawl, defesa na grade | COMBAT §4 |
| SYS-06 | Solo | 7 estados de solo, transições por disputa, ground and pound | COMBAT §4 |
| SYS-07 | Finalizações | Encaixe → Aperto em etapas, mesmo vocabulário de disputa | COMBAT §4 |
| SYS-08 | Fisiologia na luta | Fôlego/Reserva, dano por zona, Limiar de Choque, cortes | COMBAT §6 |
| SYS-09 | Regras e arbitragem | Rounds, encerramentos, intervenções, faltas | COMBAT §7 |
| SYS-10 | Julgamento | 3 juízes simulados, sistema de 10 pontos | COMBAT §7 |
| SYS-11 | IA de combate | Utilidade por contexto, arquétipos, memória de hábitos, limites humanos | COMBAT §9 |
| SYS-12 | Feedback e HUD | Sinais no sprite, HUD em 3 níveis | COMBAT §8 |
| SYS-13 | Lutador | 17 atributos visíveis + 4 ocultos, físico, estilo | CHARACTER |
| SYS-14 | Calendário | Turnos semanais, agenda de eventos | CAREER §3 |
| SYS-15 | Treino e equipe | 12 blocos semanais, academias, treinadores, sparring | CAREER §4 |
| SYS-16 | Saúde e envelhecimento | Lesões, suspensão, desgaste acumulado, idade | CAREER §5, CHARACTER §7 |
| SYS-17 | Peso e pesagem | Peso de caminhada, corte, falha na pesagem | CAREER §6, CHARACTER §6 |
| SYS-18 | Organizações e eventos | 4 níveis de organizações fictícias | CAREER §7 |
| SYS-19 | Matchmaking e contratos | Ofertas, negociação, dispensas | CAREER §8 |
| SYS-20 | Rankings | Pontuação por qualidade de vitória + ajuste promocional | CAREER §9 |
| SYS-21 | Simulação do mundo | Níveis de detalhe, resolvedor estatístico, geração de atletas | CAREER §11 |
| SYS-22 | Economia | Bolsas, bônus, patrocínios, custos, trabalho paralelo | CAREER §10 |
| SYS-23 | Reputação e mídia | Prestígio, Popularidade, Relação com organização, rivalidades | CAREER §10 |
| SYS-24 | Legado e aposentadoria | Pontuação de legado, Hall da Fama | CAREER §5.5 |
| SYS-25 | Persistência | Saves por carreira, autosave, versionamento | GAME_SYSTEMS §6 |
| SYS-26 | Configurações e acessibilidade | Controles, dificuldade, HUD, áudio, legibilidade | GAME_SYSTEMS §7 |
| SYS-27 | Apresentação | Arte, animação, áudio, UI | ART_DIRECTION |
| SYS-28 | Camada de dados e regras | Definições configuráveis (categorias, regras, organizações, golpes) | GAME_SYSTEMS §5 |

---

## 6. Requisitos rastreáveis

| REQ | Requisito | Origem | Sistemas | Etapa |
|---|---|---|---|---|
| REQ-01 | Combate é o núcleo; precisa ser bom sem a carreira | Princípio 1 | SYS-01..12 | E-03..E-05 |
| REQ-02 | Decisões fora da luta geram consequências na luta | Princípio 2 | SYS-15..17, 22, 23 | E-07..E-09 |
| REQ-03 | Perspectiva lateral com profundidade simulada | D-002 | SYS-01, 27 | E-03 |
| REQ-04 | 12 categorias (8 M + 4 F) na 1.0 | D-007 | SYS-13, 17, 18, 21, 28 | E-11 |
| REQ-05 | Categorias, atributos, organizações, regras e eventos orientados a dados | D-011 | SYS-28 | E-02 |
| REQ-06 | Apenas entidades fictícias | D-010 | SYS-18, 21 | E-08 |
| REQ-07 | IA usa as mesmas regras do jogador | Prompt §3.8 | SYS-11 | E-05 |
| REQ-08 | Mundo continua sem o jogador | Prompt §3.11 | SYS-21 | E-08 |
| REQ-09 | Treino não permite maximizar tudo | Prompt §3.9 | SYS-15, 16 | E-07 |
| REQ-10 | Pixel art com personagens grandes e animação fluida | D-006 | SYS-27 | E-06, E-10 |
| REQ-11 | Godot 4 + GDScript | D-008, D-009 | todos | E-02 |
| REQ-12 | Regras configuráveis por organização | Prompt §3.5 | SYS-09, 10, 28 | E-05, E-08 |

---

## 7. Escopo e prioridades

Classificação dos recursos (complexidade relativa: Baixa, Média, Alta, Muito alta). A análise detalhada por sistema, com riscos e critérios mínimos, está em [ROADMAP.md §4](ROADMAP.md#4-matriz-de-sistemas-valor-complexidade-e-risco).

### 7.1 Essencial para o primeiro protótipo
Movimento 2.5D; trocação básica (jab, direto, gancho, chute baixo, chute ao corpo); guarda e esquiva; clinch neutro e na grade; 2 quedas + sprawl; 3 posições de solo (Guarda, Controle Lateral, Montada) + Costas opcional; 1 finalização (mata-leão ou guilhotina); Fôlego/Reserva; dano por zona; KO/TKO/finalização/decisão; 3 juízes; IA básica com 2 arquétipos; HUD completo de depuração; Luta Rápida como cena de teste. Tudo com arte greybox.

### 7.2 Essencial para a 1.0
Tudo do protótipo + catálogo completo de golpes e posições; 6 finalizações; IA com arquétipos e níveis; carreira completa (criação, calendário, treino, academias, contratos, rankings, organizações, economia, reputação, mídia, lesões, envelhecimento, aposentadoria, legado); mundo simulado com as 12 categorias; arte final com biotipos; UI completa; save robusto; opções e acessibilidade; tutorial.

### 7.3 Importante, mas pode entrar depois
Árbitro com animações completas além do mínimo; rivalidades com eventos narrativos especiais; trilogias; mudança de categoria com recálculo visual; patrocínios com metas; cortes com intervenção do médico detalhada; estatísticas avançadas de carreira; replays.

### 7.4 Expansão futura
Versus local; editor; gestão de academia; técnicas giratórias e golpes acrobáticos; modo lenda; mods; localização para outros idiomas além dos de lançamento.

---

## 8. Riscos principais (resumo)

| Risco | Impacto | Mitigação | Ref. |
|---|---|---|---|
| Volume de animação (personagens grandes × biotipos × golpes × posições de solo pareadas) | **Crítico** | Biotipos limitados, spike de pipeline 3D→pixel, catálogo de posições enxuto, animação por papel (por cima/por baixo) | D-014, R-005, R-036, R-037, ART §6 |
| Combate não ficar divertido | **Crítico** | Greybox completo antes de qualquer arte final; marco de validação "luta divertida" | E-05 |
| 12 categorias exigirem rosters e corpos distintos | Alto | Categorias são dados; corpo por biotipo, não por categoria; geração procedural de atletas | R-005, R-017 |
| Carreira virar planilha | Alto | Cada recurso ligado a uma decisão e a um efeito visível na luta | CAREER §1 |
| Grappling virar coleção de minijogos | Alto | Modelo único de disputa | R-009 |
| Desenvolvedor solo, sem artista | **Crítico** | Pipeline 3D→pixel com assets licenciados, 4 biotipos, cortes de escopo mapeados | D-012, R-036, R-037 |

---

## 9. Glossário
O vocabulário oficial está em [GLOSSARY.md](GLOSSARY.md). Termos mais usados neste documento: *Fôlego*, *Reserva*, *Limiar de Choque*, *Disputa*, *Bloco de treino*, *Fadiga Acumulada*, *Desgaste Acumulado*, *Biotipo*, *Prestígio*, *Popularidade*, *Resolvedor estatístico*, *FightSetup/FightResult*.

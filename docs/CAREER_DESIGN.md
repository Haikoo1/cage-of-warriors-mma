# CAREER DESIGN — Projeto Jaula

> Versão 0.1 · Etapa 01 · Volta ao [GDD](GDD.md)
> Atributos e nomes: [CHARACTER_DESIGN.md](CHARACTER_DESIGN.md). Combate: [COMBAT_DESIGN.md](COMBAT_DESIGN.md).

---

## 1. Princípios da carreira

1. **Toda decisão fora da jaula aparece dentro dela.** Se um recurso não muda o lutador que entra na luta (ou as lutas que ele recebe), ele não deveria existir.
2. **Escassez real:** tempo (blocos semanais, semanas até a luta), corpo (Fadiga, lesões, idade) e dinheiro. Não dá para ter tudo.
3. **Consequências recuperáveis, mas não apagáveis:** uma derrota dói, mas há caminho de volta; o Desgaste Acumulado e a idade não voltam.
4. **Menos planilha, mais decisão:** cada tela deve terminar em uma escolha clara (aceitar/recusar, treinar X ou Y, gastar ou guardar).
5. **O mundo não espera:** rivais evoluem, cinturões trocam de dono, oportunidades expiram.

---

## 2. Criação e início da carreira

### 2.1 Passos da criação
1. **Divisão e categoria** (masculina/feminina; categoria entre as permitidas) — `R-026`: não há lutas entre divisões.
2. **Identidade:** nome, apelido, nacionalidade, idade inicial (18–30).
3. **Físico:** biotipo (dos permitidos pela categoria), altura e envergadura dentro de faixas, base.
4. **Aparência** ([CHARACTER §8](CHARACTER_DESIGN.md#8-aparência-e-personalização)).
5. **Origem** (tabela abaixo).
6. **Pontos de criação:** distribuição limitada de pontos sobre a base da origem; Carisma (baixo/médio/alto) custa pontos.
7. **Academia inicial:** entre 2–3 opções acessíveis à origem e à cidade.

### 2.2 Idade inicial — trade-off
| Idade | Atributos iniciais | Tempo até o Pico | Perfil |
|---|---|---|---|
| 18–21 | Baixos | Longo | Carreira longa, começo lento |
| 22–25 | Médios | Médio | Equilibrado |
| 26–30 | Mais altos, menos pontos de crescimento | Curto | Corrida contra o relógio |

### 2.3 Origens — `RECOMENDAÇÃO` (4 na 1.0)
| Origem | Atributos-base fortes | Dinheiro inicial | Vantagem | Desvantagem |
|---|---|---|---|---|
| **Wrestler universitário** | Wrestling Ofensivo/Defensivo, Condicionamento | Baixo | Contato com academia de wrestling | Trocação muito baixa |
| **Competidor de jiu-jitsu** | Jiu-jitsu, Defesa de Finalização, Controle de Solo | Baixo | Desconto em academia de jiu-jitsu | Quedas e trocação baixas |
| **Kickboxer / Muay Thai** | Kickboxing, Defesa em Pé, Robustez | Médio | Popularidade inicial regional | Wrestling Defensivo baixo |
| **Atleta de academia de MMA** | Todos médios-baixos, QI de Luta | Médio | Acesso a academia de MMA média | Nenhum ponto forte |

Todos começam **0-0 como profissional** no circuito local (sem modo amador jogável). O histórico amador é texto de apresentação.

### 2.4 Situação financeira inicial
- Saldo pequeno (cobre 2–3 meses de despesas básicas `[PROV]`).
- Opção de **Trabalho paralelo** (§10.3) desde o início.

---

## 3. Calendário e passagem do tempo — SYS-14

### 3.1 Turno semanal — `RECOMENDAÇÃO R-015`
```
Semana N
 1. Planejamento (jogador): plano de treino (12 blocos), gastos, respostas a ofertas pendentes
 2. Simulação (sistema), em ordem fixa:
    a) treino → ganhos e Fadiga
    b) saúde → cura de lesões, risco de lesão de treino, decaimento
    c) mundo → eventos da semana (lutas simuladas), rankings, matchmaking de NPCs
    d) economia → receitas e despesas semanais
    e) reputação → decaimento/crescimento de popularidade
    f) idade → aplicada no 1º turno de cada mês
 3. Notificações: ofertas, notícias, lesões, convites (podem interromper o avanço automático)
```
A ordem fixa da simulação evita dependências circulares dentro de uma mesma semana ([GAME_SYSTEMS §4](GAME_SYSTEMS.md#4-ordem-do-tick-e-dependências-circulares)).

### 3.2 Avanço rápido
"Avançar até" próxima luta / fim da recuperação / próxima oferta. O jogador pode deixar um **plano de treino padrão** aplicado automaticamente. Paradas obrigatórias: oferta de luta ou contrato, lesão, pesagem, luta.

### 3.3 Ritmo de lutas (verificação de compatibilidade)
```
Luta → suspensão médica (1–9 semanas) → recuperação de lesão (se houver)
     → oferta e aceite → camp (normalmente 6–10 semanas) → luta
```
| Situação | Lutas por ano esperadas `[PROV]` |
|---|---|
| Circuito local, sem lesão | 4–6 |
| Liga regional/continental | 3–4 |
| Elite | 2–3 |
| Com lesão grave | 1–2 |

Essa faixa é compatível com o modelo de treino (o camp de 6–10 semanas cabe entre suspensões) e com a carreira de 10–17 anos (≈ 25–45 lutas), coerente com carreiras reais longas.

### 3.4 Semana da luta
Dias simulados: chegada → coletiva (mídia) → **pesagem** (véspera) → reidratação → **luta** → pós-luta.

---

## 4. Treinamento, academia e equipe — SYS-15

### 4.1 Blocos semanais — `RECOMENDAÇÃO R-016`
- Cada semana tem **12 blocos** (6 dias × 2 períodos `[PROV]`). Cada bloco recebe um tipo de atividade.
- Cada atividade tem **Carga** (Fadiga gerada), **ganhos** e **riscos**.

| Atividade | Ganhos principais | Carga | Risco de lesão | Custo extra |
|---|---|---|---|---|
| Técnico: Boxe | Boxe, Defesa em Pé (½) | Média | Baixo | — |
| Técnico: Muay Thai/Kickboxing | Kickboxing, Defesa em Pé (½) | Média | Baixo | — |
| Técnico: Wrestling | Wrestling Of./Def., Controle de Solo (½) | Alta | Médio | — |
| Técnico: Jiu-jitsu | Jiu-jitsu, Defesa de Finalização, Controle de Solo (½) | Média | Baixo-médio | — |
| Técnico: Movimentação | Mobilidade | Baixa | Baixo | — |
| Físico: Força | Força, Robustez (pouco) | Alta | Médio | — |
| Físico: Condicionamento | Condicionamento | Alta | Baixo | — |
| Físico: Explosão | Velocidade | Média | Médio | — |
| **Sparring** | QI de Luta, técnicos (pouco, todos), Compostura | Muito alta | Alto (inclui Desgaste Acumulado leve) | Precisa de parceiros |
| Tático: Estudo do Adversário | Relatório de Scouting do próximo adversário | Nenhuma | — | Só com luta marcada |
| Tático: Lições do treinador | QI de Luta | Baixa | — | — |
| Recuperação | Reduz Fadiga, acelera cura de lesões | Negativa | — | Estrutura da academia/fisioterapia |
| Descanso | Reduz Fadiga | Negativa | — | — |
| Mídia/Patrocínio | Popularidade, cumprir obrigações de patrocínio | Baixa | — | — |
| Trabalho paralelo | Renda (§10.3) | Baixa | — | — |

### 4.2 Fadiga Acumulada e sobrecarga
- **Fadiga Acumulada** (0–100) sobe com a Carga e cai com Recuperação/Descanso (taxa depende de Recuperação e idade).

| Fadiga `[PROV]` | Efeito |
|---|---|
| 0–40 | Nenhum |
| 41–70 | Ganhos −25%; risco de lesão de treino +50% |
| 71–90 | Ganhos −60%; risco de lesão ×2,5; aviso do treinador |
| > 90 | Treino pesado bloqueado (o treinador recusa) |

- **No dia da luta**, Fadiga > 40 reduz a Reserva inicial ([COMBAT §6.1](COMBAT_DESIGN.md#61-fôlego-e-reserva--recomendação-r-011)). Por isso o camp termina com 1–2 semanas de **polimento** (carga baixa).
- **Escolha real:** um plano "tudo no máximo" produz Fadiga > 70 em 2–3 semanas, reduzindo ganhos e arriscando lesão. O plano ótimo depende do objetivo (melhorar fraquezas × afiar forças × chegar descansado).

### 4.3 Camp de luta
- Começa quando a luta é aceita. Duração = semanas até o evento.
- Recursos exclusivos do camp:
  - **Estudo do Adversário:** cada bloco aumenta a precisão do Relatório de Scouting (faixas de atributos mais estreitas, mais tendências reveladas — [COMBAT §5.1](COMBAT_DESIGN.md#51-como-o-jogador-identifica-hábitos-e-vulnerabilidades)).
  - **Parceiros específicos:** contratar parceiros de sparring do estilo do adversário (custo) → o córner tem dicas melhores e a IA adversária tem menos hábitos "desconhecidos" — implementado como informação extra, não bônus de atributo.
  - **Plano de corte de peso** (§6).
- **Camp curto** (luta com pouco prazo, < 4 semanas `[PROV]`): menos semanas para ganhos e estudo, corte de peso mais difícil, mas bolsa maior e ganho de Popularidade/Relação com a organização (§8.4).

### 4.4 Academias
| Dado | Efeito |
|---|---|
| **Especialidades** (1–5 por área: boxe, kickboxing, wrestling, jiu-jitsu, físico) | Multiplicador de ganho por área |
| **Estrutura** (1–5) | Recuperação mais eficiente, menor risco de lesão de treino |
| **Parceiros de treino** (nível médio e mistura de estilos) | Eficiência e risco do sparring; quem é muito melhor que os parceiros ganha menos com sparring |
| **Mensalidade** | Despesa |
| **Reputação e exigência** | Algumas academias só aceitam lutadores com Prestígio mínimo |
| **Localização** (país/região) | Mercado de popularidade, organizações regionais próximas, custo de mudança |

### 4.5 Treinadores e equipe
- **Treinador principal** (1): competência tática (qualidade das lições, dicas do córner, precisão do scouting) + competência em uma área.
- **Especialistas** (até 3): competência por área (striking, wrestling, jiu-jitsu, preparação física). Multiplicam ganhos.
- **Equipe de apoio** (opcional, contratada por camp): cutman (cortes no intervalo), nutricionista (corte de peso), fisioterapeuta (recuperação).
- **Custo:** salário semanal ou % da bolsa (`10–20%` total da equipe `[PROV]`).
- **Relação com a equipe** (0–100): cai com recusas de conselhos sérios (ex.: treinar com Fadiga > 90 pedindo exceção), trocas frequentes e derrotas em que o jogador ignorou o plano; abaixo de 30, um treinador pode sair.

### 4.6 Mudança de academia
- Custos: taxa de mudança/viagem; **período de adaptação** (ganhos −20% por 4 semanas `[PROV]`); perda de relação com a equipe anterior; possível notícia/mídia negativa se a saída for durante o camp.
- Benefícios: especialidades diferentes, parceiros melhores, mercado novo.
- Consequência interessante: mudar para uma academia de elite de wrestling depois de perder por queda é uma resposta lógica, com custo de curto prazo.

---

## 5. Saúde, lesões, envelhecimento e aposentadoria — SYS-16 e SYS-24

### 5.1 Lesões
| Gravidade | Afastamento `[PROV]` | Exemplos | Efeito |
|---|---|---|---|
| Leve | 1–3 semanas | Contusão, corte, entorse leve | Treino restrito na área |
| Moderada | 4–10 semanas | Fratura na mão, costela, entorse de joelho | Sem luta; treino só em outras áreas |
| Grave | 3–9 meses | Ligamento do joelho, ombro, fratura orbital | Sem treino da área; risco de lesão crônica |
| Concussão | 4–12 semanas | Após KO ou luta com dano alto na cabeça | Sem sparring; aumenta Desgaste Acumulado |

- **Fontes:** luta (dano por zona e chaves articulares, [COMBAT §4.6](COMBAT_DESIGN.md#46-finalizações--sys-07--recomendação-r-010)), treino (Carga, Fadiga, Fragilidade, estrutura da academia).
- **Localização** liga a lesão a atributos (joelho → Mobilidade, Wrestling; mão → potência de socos).

### 5.2 Suspensão médica pós-luta
Afastamento obrigatório definido pela organização a partir do dano sofrido (ex.: KO → 60 dias; dano alto na cabeça → 30 dias; sem dano significativo → 7 dias) `[PROV, inspirado em práticas de comissões, a validar]`. Impede lutar, não treinar (exceto sparring após KO).

### 5.3 Retorno precoce
- O jogador pode **voltar antes da liberação completa** de uma lesão (não de suspensão obrigatória).
- Efeito: atributos da área com penalidade proporcional ao que falta para curar + **risco de reagravar** (aumenta afastamento e chance de crônica).
- **Por quê:** cria a decisão realista "aceitar a luta de título lesionado ou perder a chance".

### 5.4 Envelhecimento
Regras em [CHARACTER §7.3](CHARACTER_DESIGN.md#73-idade-e-declínio). Na carreira, o declínio aparece como notificações do treinador ("sua velocidade caiu este mês") e muda as escolhas: lutadores veteranos tendem a migrar para estilos que usam técnica e QI.

### 5.5 Aposentadoria e legado — SYS-24
- **Voluntária:** a qualquer momento.
- **Recomendada/exigida pelo médico:** Desgaste Acumulado acima dos limites ([CHARACTER §7.4](CHARACTER_DESIGN.md#74-desgaste-acumulado)).
- **De fato:** sem contratos por muito tempo (o jogo sugere encerrar).
- **Legado:** pontuação calculada de títulos, defesas, vitórias sobre adversários ranqueados, finalizações, longevidade, Popularidade máxima. Determina **Hall da Fama** e um resumo de carreira (linha do tempo).
- **Pós-carreira (1.0):** tela de legado e possibilidade de continuar observando o mundo por algumas semanas. Ser treinador/promotor = expansão.

---

## 6. Peso, corte e pesagem — SYS-17

### 6.1 Peso de caminhada e corte
- **Peso de caminhada:** peso fora de camp. Muda lentamente com treino de força e com a idade.
- **Corte necessário (%)** = (peso de caminhada − limite) / peso de caminhada.
- **Plano de corte** escolhido no camp: *conservador* (começa cedo, Fadiga extra pequena), *padrão*, *agressivo* (concentrado na última semana).

| Corte efetivo `[PROV]` | Efeito no dia da luta |
|---|---|
| ≤ 5% | Nenhum |
| 5–8% | Reserva inicial −5% |
| 8–12% | Reserva −10%, Queixo efetivo −3, risco de falhar a pesagem pequeno |
| > 12% | Reserva −20%, Queixo efetivo −6, risco alto de falhar; aviso médico |

- **Metabolismo** (oculto) e **nutricionista** reduzem o corte efetivo. **Luta com pouco prazo** aumenta o corte efetivo.
- **Lógica fisiológica:** desidratação reduz rendimento aeróbico e proteção do cérebro → Reserva e Queixo efetivos. É temporário (só aquela luta).
- **Peso de luta** (após reidratação) é usado no **peso relativo** das Disputas: cortar muito dá uma pequena vantagem de massa, ao custo acima. Essa tensão é a decisão interessante.

### 6.2 Falhar na pesagem
| Consequência | Regra (configurável por organização) |
|---|---|
| Multa | % da bolsa para o adversário (`20–30%` `[PROV]`) |
| Luta | Adversário decide: aceitar em peso combinado ou cancelar (NPC decide por personalidade) |
| Título | Lutador que falha não pode ganhar o cinturão |
| Reputação | Relação com a organização −; Popularidade − |
| Reincidência | 2 falhas em 12 meses → a organização exige subir de categoria |

### 6.3 Mudança de categoria
- Por escolha (subir/descer), por exigência (falhas) ou por oportunidade (oferta em outra categoria).
- Atributos sensíveis a massa recalculados ([CHARACTER §6.3](CHARACTER_DESIGN.md#63-princípios-das-categorias)); ranking começa sem posição na nova categoria, com pontos parciais de prestígio.
- Pode exigir troca de biotipo visual (se o biotipo atual não é permitido na nova categoria).

---

## 7. Organizações, eventos e ecossistema — SYS-18 — `RECOMENDAÇÃO R-021`

### 7.1 Níveis
Todas as organizações são **fictícias** (`D-010`) e definidas em dados.

| Nível | Organização (nome provisório) | Identidade | Categorias | Eventos `[PROV]` | Rounds | Bolsa típica `[PROV]` |
|---|---|---|---|---|---|---|
| 1 — Local | **Circuitos locais** (gerados proceduralmente por região, ex.: "Arena Norte Fight Night") | Ginásios, público pequeno | Varia; nem todas as categorias em todo evento | Mensal por região | 3 × 5 min (alguns 3 × 3 *(fictício)*) | $ 500 – 2.000 |
| 2 — Regional | **Liga Fronteira (LFC)** — Américas; **Iron Circle** — Europa; **Pacific Rise** — Ásia/Oceania | Profissionalizada, TV regional | Todas | 1–2 por mês | 3 × 5 / título 5 × 5 | $ 3.000 – 15.000 |
| 3 — Continental | **Pan-Continental Combat (PCC)** | Vitrine para a elite | Todas | 2 por mês | 3 × 5 / 5 × 5 | $ 10.000 – 50.000 |
| 4 — Elite | **Grand Cage League (GCL)** | Maior palco, rankings globais | Todas | Semanal (rodízio de categorias) | 3 × 5 / 5 × 5 | $ 12.000 – 500.000+ |
| 4 — Elite alternativa | **Kōgen Fighting Federation (KFF)** | Rival de elite com regras próprias | Menos categorias femininas *(fictício, cria escolha)* | Mensal, eventos grandes | Regras diferentes *(fictício)*: joelhada na cabeça no chão permitida | Alta, menos estável |

- A **KFF** existe para dar uma escolha de carreira interessante (dinheiro e estilo diferentes × ranking e prestígio menores) e para exercitar o RuleSet configurável. Pode ser cortada se o escopo apertar (valor médio, custo baixo — são dados).
- Nomes são provisórios (`P-008`); verificar conflito com marcas reais antes de fechar.

### 7.2 Eventos
- Cada evento tem um card (luta principal, co-principal, card principal, preliminares). A posição no card afeta bolsa, Popularidade e número de rounds (luta principal = 5 rounds).
- Eventos são gerados pelo calendário da organização; o matchmaking preenche os cards com NPCs e, quando há oferta aceita, com o jogador.
- **Cancelamentos e substituições:** lesões de NPCs (simuladas) cancelam lutas; o jogador pode receber oferta de **substituto** (pouco prazo) ou ter o adversário substituído (novo adversário, scouting reinicia).

### 7.3 Campeões e desafiantes
- Cada organização mantém um campeão por categoria; defesas são exigidas a cada `9–12 meses` `[PROV]`; campeão inativo por lesão longa → título interino.
- Desafiante: normalmente top 3 do ranking, com ajuste por Popularidade (realismo do "promotor").

---

## 8. Matchmaking, contratos e negociação — SYS-19

### 8.1 Ofertas de luta
- A organização (o "matchmaker", sistema) oferece ao jogador **1 a 3 opções** de adversário quando ele está disponível, considerando ranking próximo, estilo (lutas atraentes), Popularidade, rivalidades e necessidade dos cards.
- Cada oferta: adversário, evento, data (prazo do camp), posição no card, bolsa.
- **Recusar** tem custo de Relação com a organização (pequeno por recusa justificada — lesão — e maior se repetido).
- **Pedir adversário** (callout): via mídia pós-luta ou pedido direto; aceito se o pedido fizer sentido para o ranking ou para a Popularidade.

### 8.2 Contratos
Campos significativos (poucos, mas com impacto):

| Campo | Efeito |
|---|---|
| Número de lutas | Duração (ex.: 4 lutas) |
| Bolsa de participação + bônus de vitória | Renda por luta (escala por luta no contrato) |
| Exclusividade | Sim nas organizações nível 2+ |
| Cláusula de campeão | Ao ganhar o título, o contrato é estendido automaticamente |
| Participação em pay-per-view | Só para campeões e lutas principais de elite |
| Patrocínio próprio permitido | Algumas organizações restringem (afeta renda de patrocínio) |

### 8.3 Negociação
- A organização faz a proposta baseada no **valor de mercado** do jogador (Prestígio, Popularidade, cartel).
- O jogador pode aceitar, recusar ou fazer **até 2 contrapropostas** escolhendo prioridade (mais dinheiro / mais lutas garantidas / cláusulas). Cada contraproposta tem chance de ser aceita e custo de relação se exagerada.
- Ofertas concorrentes de outras organizações aumentam o poder de negociação (free agency no fim do contrato).

### 8.4 Pouco prazo
Aceitar substituição com < 4 semanas: bolsa maior (`+25%` `[PROV]`), Relação com a organização +, Popularidade + se vencer, perda de Prestígio menor se perder; camp curto e corte mais difícil (§4.3, §6.1).

### 8.5 Dispensas e sequências
- Sequência de derrotas (padrão: 3 em contrato, ou 2 seguidas sem Popularidade relevante `[PROV]`) → risco de dispensa; avaliado pela organização com base em Popularidade e desempenho (lutas boas perdidas pesam menos).
- Dispensa → agente livre: ofertas de organizações de nível igual ou inferior.
- Sequência de vitórias → ofertas de níveis superiores, pedidos de luta por cinturão, renegociação antecipada.

### 8.6 Transferências
- Ao fim do contrato, o jogador e NPCs podem trocar de organização. Campeões de nível 2/3 recebem convites do nível 4.
- NPCs com Ambição alta trocam mais.

---

## 9. Rankings — SYS-20

- **Ranking por organização e categoria**: campeão + top 15 `[PROV]`.
- **Pontuação** (conceitual):
```
pontos_por_luta = base(resultado) × qualidade_do_adversário × bônus_método (KO/finalização > decisão unânime > dividida)
                × peso_de_recência (decai ao longo de ~18 meses)
ranking = ordenação por pontos + ajuste_promocional (Popularidade, limitado a ±2 posições)
```
- Inatividade longa (> 12 meses `[PROV]`) remove do ranking.
- **Ranking global** (por categoria, entre organizações): exibido como "lista de imprensa" para dar contexto; não afeta matchmaking diretamente, mas afeta Prestígio.

---

## 10. Economia, reputação e mídia — SYS-22 e SYS-23

### 10.1 Função de cada recurso
| Recurso | Para que serve | Decisão associada |
|---|---|---|
| **Dinheiro** | Pagar academia, equipe, camp, recuperação; reduzir horas de trabalho paralelo | Investir em preparação × guardar |
| **Prestígio** | Ranking, ofertas de nível superior, valor de contrato | Lutas difíceis × lutas seguras |
| **Popularidade** | Bolsas, patrocínios, posição no card, ajuste de ranking, callouts aceitos | Estilo agressivo, mídia provocadora × reservada |
| **Relação com organização** | Ofertas melhores, aceitação de pedidos, tolerância a recusas | Aceitar lutas inconvenientes × recusar |

### 10.2 Receitas
| Receita | Fonte |
|---|---|
| Bolsa de participação | Contrato |
| Bônus de vitória | Contrato |
| Bônus da noite | Melhor luta / melhor performance (decidido por estatísticas da luta e método) |
| Patrocínios | Ofertas baseadas em Popularidade; obrigações de blocos de Mídia/Patrocínio por mês |
| Pay-per-view | Campeões e lutas principais de elite |
| Trabalho paralelo | Renda fixa pequena |

### 10.3 Despesas e trabalho paralelo — `RECOMENDAÇÃO R-024`
| Despesa | Periodicidade |
|---|---|
| Custo de vida | Semanal (fixo por região) |
| Academia | Mensal |
| Equipe | Semanal ou % da bolsa |
| Camp (parceiros, nutricionista, viagem) | Por camp |
| Médicas e fisioterapia | Por lesão/tratamento |
| Mudança de academia | Pontual |

- **Trabalho paralelo:** ocupa 4 blocos/semana `[PROV]` e paga renda pequena. No começo é quase obrigatório; deixar de trabalhar é um marco da carreira.
- **Sem bloqueio:** se o saldo ficar negativo, o jogo não termina a carreira: força mais blocos de trabalho, impede gastos opcionais e libera ofertas de luta com pouco prazo e bolsa maior. Dificulta, não bloqueia.
- **Excesso de dinheiro no fim da carreira:** esperado e aceitável (realista). Contrapesos: custos de academia/equipe de elite escalam, recuperação premium tem custo alto, e o dinheiro não compra atributos diretamente — só melhora as condições de treino e recuperação, com rendimento decrescente. Dinheiro acumulado entra pouco no Legado.

### 10.4 Reputação — `RECOMENDAÇÃO R-022`
- **Prestígio** (0–100): mérito esportivo. Sobe com vitórias sobre ranqueados e títulos; cai pouco com derrotas para melhores e muito com derrotas para piores.
- **Popularidade** (0–100, por mercado/região + global): interesse do público. Sobe com finalizações, bônus da noite, mídia, rivalidades; decai lentamente com inatividade.
- **Relação com organização** (por organização, 0–100).
- **Por que separar Prestígio e Popularidade:** permite as duas carreiras reais — o "campeão sem carisma" e o "lutador popular que não é o melhor". Cada uma abre portas diferentes.

### 10.5 Mídia, entrevistas e coletivas
- **Momentos:** coletiva pré-luta, encarada (só apresentação), entrevista pós-luta, eventuais notícias (lesão, troca de academia).
- **Formato:** 1–3 perguntas por momento, cada uma com 3–4 respostas de **tom** (Respeitoso, Confiante, Provocador, Reservado) e, no pós-luta, a opção de **callout** (escolher um adversário/título).
- **Efeitos:** Popularidade (mais com Provocador e Carisma alto), Relação com organização (Provocador contra a organização cai), rivalidade (Provocador contra um lutador), Perfil Público ([CHARACTER §4.2](CHARACTER_DESIGN.md#42-jogador-perfil-público-emergente)).
- **Sem efeito nos atributos de luta** do adversário (a IA não fica "mais forte" por estar irritada; `REQ-07`).

### 10.6 Rivalidades
- Surgem de: provocações, decisões controversas (dividida), revanches, mesma academia anterior, callouts.
- **Intensidade** (0–100). Efeitos: hype da luta (bolsa e Popularidade da luta ×), prioridade no matchmaking, perguntas de mídia específicas.
- Trilogias e eventos narrativos especiais: §7.3 do [GDD](GDD.md#73-importante-mas-pode-entrar-depois) (depois da 1.0).

---

## 11. Simulação do mundo — SYS-21 — `RECOMENDAÇÃO R-017`

### 11.1 Objetivo
O mundo continua sem o jogador: atletas lutam, evoluem, envelhecem, se lesionam, trocam de organização, aposentam-se, e novos atletas surgem. Com custo computacional baixo para simular semanas em segundos.

### 11.2 População
| Item | Valor inicial `[PROV]` |
|---|---|
| Lutadores ativos por categoria | ≈ 50–70 (todas as organizações) |
| Total ativo (12 categorias) | ≈ 600–800 |
| Novos lutadores gerados por ano | Para manter a população estável (substituir aposentados) |
| Mundo inicial | Gerado proceduralmente no início da carreira, com histórico de "anos anteriores" pré-simulado (cartéis, campeões) |

### 11.3 Níveis de detalhe (LOD)
| Nível | Quem | O que é simulado |
|---|---|---|
| **Detalhado** | Categoria do jogador: top 30 da organização atual e da próxima, adversários marcados, rivais | Treino semanal simplificado, lesões, evolução mensal, personalidade |
| **Agregado** | Demais lutadores | Evolução e envelhecimento mensais por fórmula, lesões por sorteio na luta |
| **Estatístico** | Circuitos locais | Apenas cartel e evolução trimestral; lutadores "promovidos" para Agregado quando ganham relevância |

### 11.4 Resolvedor estatístico de lutas
- Lutas entre NPCs são resolvidas por um **resolvedor estatístico** (sem combate em tempo real).
- Entrada: os mesmos dados que o combate jogado usa (`FightSetup`, [GAME_SYSTEMS §3](GAME_SYSTEMS.md#3-integração-combate--carreira--recomendação-r-018)).
- Conceito: compara forças por fase (em pé, clinch, solo), estilos (wrestler × striker), Fôlego (Condicionamento × número de rounds), Queixo e Desgaste; simula round a round com sorteios controlados; produz método, round, tempo, estatísticas resumidas, dano e lesões.
- Saída: o mesmo `FightResult` do combate jogado (dano, lesões e estatísticas no mesmo formato).
- **Calibração obrigatória:** a distribuição de resultados do resolvedor (taxa de KO por categoria, taxa de finalização, de decisão; vitória do favorito) deve ser comparada com a de lutas IA × IA jogadas no motor de combate. Se divergirem muito, o mundo simulado fica incoerente com o que o jogador vive. Critério de aceitação em [ROADMAP](ROADMAP.md).

### 11.5 Decisões de NPCs
- Aceitar lutas, trocar de organização, aposentar-se: regras simples por personalidade, idade, Desgaste Acumulado, resultados recentes.
- Aposentadoria NPC: probabilidade crescente após 34 anos, sequências de derrotas, Desgaste alto.

---

## 12. Trajetórias de exemplo

### 12.1 Trajetória completa — "Lia Moreira" (jogadora, peso-palha, origem jiu-jitsu)
| Idade | Momento | Decisão | Resultado / consequência |
|---|---|---|---|
| 21 | Criação | Origem jiu-jitsu, Carisma médio, academia de jiu-jitsu barata | Começa com Jiu-jitsu 62, trocação ~35, $ para 2 meses |
| 21 | Primeiros meses | Trabalho paralelo 4 blocos; treina wrestling para conseguir levar ao chão | Ganhos lentos, sem dívida |
| 21–22 | Circuito local | 6 lutas, todas finalizações | 6-0, Popularidade regional alta; oferta da Liga Fronteira |
| 22 | Contrato regional | Contraproposta pedindo mais lutas garantidas | 4 lutas; deixa o trabalho paralelo |
| 23 | Primeira derrota | Perde por TKO para striker; córner apontou que ela entrava em linha reta | Prestígio −; investe 2 camps em boxe e Movimentação |
| 24 | Lesão | Aceita luta com Fadiga 75 para não perder data; lesão de joelho moderada→grave em treino | 5 meses afastada; lesão crônica leve no joelho (Mobilidade −2) |
| 25 | Retorno | Volta com camp conservador | 3 vitórias; disputa o cinturão regional e vence |
| 26 | PCC | Aceita convite continental; luta de substituta com 3 semanas | Vence por finalização; Relação com organização alta; cinturão PCC aos 26 |
| 27 | GCL | Contrato de elite | Perde para striker de elite (#2) por decisão; muda para academia com especialista de boxe (adaptação −20%) |
| 28–29 | Ascensão | 4 vitórias, rivalidade com a campeã por provocações | Popularidade global alta; luta de título como evento principal |
| 30 | Título de elite | Estudo do adversário intenso: campeã cai o nível ao chutar | Queda em contra-golpe, mata-leão no 4º round. Campeã. |
| 30–32 | Reinado | 3 defesas; uma por decisão dividida | Legado cresce; PPV |
| 33 | Declínio | Velocidade e Recuperação caem; perde o título por KO | Desgaste Acumulado 60 |
| 34 | Decisão | Pode descer? Já está na mais leve. Escolhe 2 lutas finais de prestígio | 1-1 |
| 35 | Aposentadoria | Voluntária | 24-5, 2 cinturões de nível 4/3, Hall da Fama |

### 12.2 Trajetória de queda — "Davi Rocha" (jogador, peso-leve, academia de MMA)
Começa aos 20, 4-0 local, assina com a Liga Fronteira cedo e perde 3 seguidas aceitando lutas difíceis por dinheiro (dívida com equipe de elite cara). Dispensado aos 22, volta ao circuito local, reduz custos, muda para academia de wrestling, reconstrói (7-1), retorna aos 25 em outra liga regional, e sobe de categoria aos 27 porque o corte para peso-leve ficou acima de 12% (falhou uma pesagem). Ilustra que derrotas não encerram a carreira, mas mudam o caminho.

### 12.3 Trajetória do veterano — origem tardia aos 29
Começa forte (atributos altos), mas com pouco tempo antes do Pico Físico. Precisa subir rápido: aceita pouco prazo frequentemente, chega ao nível continental aos 32, decide entre uma chance de título com lesão não curada (retorno precoce) ou esperar e envelhecer. Ilustra a pressão do tempo.

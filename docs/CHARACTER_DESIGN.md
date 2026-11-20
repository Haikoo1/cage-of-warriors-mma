# CHARACTER DESIGN — Projeto Jaula

> Versão 0.1 · Etapa 01 · Volta ao [GDD](GDD.md)
> Este documento é a **fonte de verdade** dos nomes e definições de atributos. Outros documentos devem usar exatamente estes nomes ([GLOSSARY.md](GLOSSARY.md)).

---

## 1. Estrutura conceitual do lutador — SYS-13

Estrutura de dados conceitual (não é código):

```
Lutador
├─ Identidade: id, nome, apelido, nacionalidade, data de nascimento, divisão (masculina/feminina)
├─ Físico: altura, envergadura, peso de caminhada, categoria de peso atual, biotipo, base (ortodoxa/canhota)
├─ Atributos visíveis (17, escala 1–100)
│   ├─ Físicos: Força, Velocidade, Condicionamento, Recuperação, Mobilidade
│   ├─ Durabilidade: Queixo, Robustez
│   ├─ Em pé: Boxe, Kickboxing, Defesa em Pé
│   ├─ Agarrados: Wrestling Ofensivo, Wrestling Defensivo, Controle de Solo, Jiu-jitsu, Defesa de Finalização
│   └─ Mentais: QI de Luta, Compostura
├─ Características ocultas (4): Potencial, Pico Físico, Fragilidade, Metabolismo
├─ Estilo: estilo principal, estilos secundários (derivados), tendências táticas (dados de IA)
├─ Personalidade (somente NPCs): Disciplina, Ambição, Temperamento, Carisma
├─ Perfil Público (jogador e NPCs): rótulo emergente das decisões de mídia
├─ Estado de saúde: lesões ativas, lesões crônicas, Desgaste Acumulado, Fadiga Acumulada, suspensão médica
├─ Carreira: cartel, histórico de lutas, títulos, rankings, contrato, organização, academia, equipe
├─ Reputação: Prestígio, Popularidade, relações (organizações, rivais, equipe)
├─ Finanças (jogador; NPCs simplificados): saldo, salário/bolsas, despesas
└─ Aparência: camadas do sprite (pele, cabelo, barba, tatuagens, calção, luvas) e paleta
```

### 1.1 Escala de atributos — `RECOMENDAÇÃO R-014`
- Escala **1–100**, inteira, visível ao jogador.
- Faixas de referência `[PROV]`: 1–29 iniciante; 30–49 amador/estreante; 50–64 profissional regional; 65–79 nível continental; 80–89 elite; 90–100 excepcional (raros no mundo inteiro).
- **Por que 1–100:** familiar ao público de jogos de esporte, granularidade suficiente para progresso semanal visível.
- **Overall (nota geral):** exibida apenas como resumo, calculada por média ponderada pelo estilo. Não é usada por nenhuma regra (evita o jogador otimizar um número que não significa nada na luta).

---

## 2. Atributos visíveis

Para cada atributo: (1) o que representa, (2) onde influencia, (3) como evolui, (4) como diminui, (5) o que o influencia.

### 2.1 Físicos

#### Força
1. Potência muscular aplicada em golpes e no grappling.
2. Potência dos golpes; custo de Fôlego do adversário ao bloquear; pressão e resistência em Disputas de clinch e controle; Aperto de chaves articulares.
3. Treino físico de força. Ganho lento depois de 25 anos.
4. Declínio após o Pico Físico (lento); lesões em membros; corte de peso severo (temporário, só no dia da luta).
5. Biotipo e categoria limitam o teto prático (mais massa → teto maior); Potencial.

#### Velocidade
1. Rapidez de execução e de reação.
2. Duração da preparação e recuperação de golpes (faixa limitada, [COMBAT §3.3](COMBAT_DESIGN.md#33-fases-do-golpe)); velocidade das entradas de queda; janela de reação em Disputas.
3. Treino físico de explosão/velocidade. Teto é atingido cedo.
4. **Primeiro atributo a cair** após o Pico Físico; lesões em pernas.
5. Fôlego atual (na luta); Potencial.

#### Condicionamento
1. Capacidade aeróbica e anaeróbica na luta.
2. Regeneração do Fôlego e taxa de queda da Reserva ([COMBAT §6.1](COMBAT_DESIGN.md#61-fôlego-e-reserva--recomendação-r-011)).
3. Treino físico de condicionamento e sparring. **Responde rápido ao treino e cai rápido sem ele** (único atributo com "forma" de curto prazo).
4. Inatividade (semanas sem treino), lesões longas, idade.
5. Fadiga Acumulada e corte de peso afetam a Reserva inicial no dia da luta, não o atributo.

> **Decisão de modelagem (`R-013`):** "Resistência" e "Condicionamento" foram fundidos em **Condicionamento**. Separá-los criaria dois números com efeitos indistinguíveis para o jogador. A resistência a golpes está em **Queixo** e **Robustez**.

#### Recuperação
1. Velocidade com que o corpo se recupera.
2. Recuperação no intervalo entre rounds; velocidade de cura de lesões e de queda da Fadiga Acumulada entre semanas.
3. Pouco treinável (blocos de recuperação e estrutura de recuperação da academia dão ganhos pequenos).
4. Idade (declínio contínuo após o Pico Físico); Desgaste Acumulado alto.
5. Estrutura da academia (instalações de recuperação) e gastos médicos afetam o **resultado** da recuperação, não o atributo.

#### Mobilidade
1. Trabalho de pés, agilidade lateral e flexibilidade.
2. Velocidade de movimento em X e Z e do passo rápido; custo de Fôlego do movimento; tempo para re-esquadrar após perder o ângulo; jogo de guarda por baixo (flexibilidade) como fator secundário em raspagens.
3. Treino técnico de movimentação e físico de agilidade.
4. Idade; lesões nas pernas/joelhos (forte impacto); dano nas pernas durante a luta (temporário).
5. Biotipo pesado tem teto prático menor.

### 2.2 Durabilidade

#### Queixo
1. Resistência a golpes na cabeça.
2. Base do Limiar de Choque ([COMBAT §6.3](COMBAT_DESIGN.md#63-limiar-de-choque-atordoamento-e-knockdown)); redução do dano na cabeça.
3. **Não é treinável** (decisão de realismo e para dar peso a cada nocaute).
4. **Desgaste Acumulado** ([§7.4](#74-desgaste-acumulado)): cada knockdown, KO e luta com dano alto na cabeça reduz o Queixo de forma permanente. Sparring pesado também contribui pouco.
5. Fôlego, dano na cabeça e Compostura modulam o limiar na luta.

#### Robustez
1. Resistência a golpes no corpo e nas pernas.
2. Redução de dano nas zonas Corpo e Pernas; limiar de paralisação por golpe no fígado e de perna "falhando".
3. Treino físico de força e condicionamento dão ganhos pequenos; sparring dá ganhos pequenos.
4. Idade (lento), lesões crônicas de costela/joelho.
5. Biotipo (massa muscular).

### 2.3 Técnicos em pé

#### Boxe
1. Técnica de socos.
2. Dano limpo e desvio de alcance de socos; janelas de encadeamento entre socos; custo de Fôlego dos socos.
3. Treino técnico de boxe; sparring; especialista de striking.
4. Inatividade técnica (lento); lesões de mão (temporárias).
5. Velocidade e Força entram no golpe junto, mas são atributos separados.

#### Kickboxing
1. Técnica de chutes, joelhadas, cotoveladas e golpes no clinch (cobre Muay Thai e kickboxing).
2. Dano limpo, desvio e custo dos chutes, joelhadas e cotoveladas; golpes curtos no clinch; *check* de chute baixo (junto com Defesa em Pé).
3. Treino técnico de Muay Thai/kickboxing.
4. Inatividade técnica (lento); lesões de perna/canela.
5. Mobilidade (equilíbrio após chutar), Força.

#### Defesa em Pé
1. Capacidade de evitar e mitigar golpes em pé.
2. Janela de esquiva; dano que passa pela guarda; eficiência do *check*; custo de Fôlego ao bloquear.
3. Treino técnico de boxe e de kickboxing (metade do ganho cada); sparring.
4. Idade (reflexos, lento após o Pico Físico, mais devagar que Velocidade).
5. Velocidade (reação).

### 2.4 Técnicos agarrados

#### Wrestling Ofensivo
1. Capacidade de derrubar e de dominar o clinch.
2. Pressão em Disputas de queda e de pummel; Vantagem de Clinch; qualidade da posição após a queda.
3. Treino de wrestling.
4. Inatividade técnica; lesões de joelho/ombro.
5. Força, Velocidade (entrada).

#### Wrestling Defensivo
1. Capacidade de evitar quedas e de voltar a ficar de pé.
2. Resistência em Disputas de queda; sprawl; Recuperação de base (levantar); defesa na grade.
3. Treino de wrestling.
4. Dano nas pernas (temporário), lesões de joelho, idade.
5. Força, Mobilidade.

#### Controle de Solo
1. Domínio por cima no chão.
2. Pressão em passagens e para manter posições dominantes; potência e precisão do ground and pound; resistência contra raspagens e escapes (do lado de cima).
3. Treino de wrestling e de jiu-jitsu (metade do ganho cada).
4. Inatividade técnica.
5. Força.

#### Jiu-jitsu
1. Técnica de finalização e de jogo por baixo.
2. Encaixe e Aperto de finalizações; raspagens e reposição de guarda; escapes de posições inferiores.
3. Treino de jiu-jitsu.
4. Inatividade técnica (muito lento — é o atributo técnico que mais dura com a idade).
5. Mobilidade (flexibilidade), Força (chaves).

#### Defesa de Finalização
1. Capacidade de reconhecer e escapar de finalizações.
2. Resistência no Encaixe; velocidade com que o Medidor de Aperto sobe ([COMBAT §4.6](COMBAT_DESIGN.md#46-finalizações--sys-07--recomendação-r-010)).
3. Treino de jiu-jitsu; sparring de grappling.
4. Inatividade técnica (lento).
5. Fôlego (estrangulamentos), Força (chaves).

### 2.5 Mentais

#### QI de Luta
1. Leitura de luta, tomada de decisão e eficiência.
2. **NPC:** define o perfil cognitivo da IA (atraso de percepção, erro de leitura, memória de hábitos; [COMBAT §9.5](COMBAT_DESIGN.md#95-limitações-humanas-e-níveis)). **Jogador:** duração dos *tells* visuais do adversário, precisão do Relatório de Scouting, número de dicas do córner. Nunca joga pelo jogador.
3. Experiência de luta (cada luta dá ganho, mais em lutas difíceis); treino tático; estudo do adversário.
4. Não diminui com a idade; pode cair levemente com Desgaste Acumulado muito alto.
5. Treinador principal (qualidade das lições táticas).

#### Compostura
1. Controle emocional sob dano e pressão.
2. Recuperação de atordoamento e de knockdown; pequeno ajuste no Limiar de Choque; desempenho em lutas grandes (títulos, eventos principais): Compostura baixa reduz a regeneração de Fôlego nos primeiros 30 s da luta para qualquer lutador e, no NPC, também aumenta o atraso de percepção (equivalente ao efeito de QI de Luta) `[PROV]`.
3. Experiência em lutas grandes; sobreviver a situações de perigo; treino tático (pouco).
4. Sequência de derrotas por nocaute (temporário, recupera com vitórias).
5. —

> **Atributos descartados (`R-013`):**
> - **Precisão** como atributo separado: a precisão já é coberta por Boxe/Kickboxing (técnica do golpe) e pela geometria. Um atributo global de precisão seria redundante com os técnicos.
> - **Resistência**: fundida em Condicionamento (ver acima).
> - **Disciplina** como atributo de luta: virou traço de personalidade de NPC (§4), porque para o jogador é ele quem decide a disciplina.

---

## 3. Características ocultas

Ocultas por padrão; podem ser **reveladas parcialmente** (faixas, não números) por scouting, por observação ao longo do tempo e por treinadores competentes. Valem igualmente para o jogador e para NPCs. A IA **não** as conhece do jogador.

| Característica | O que define | Como se revela |
|---|---|---|
| **Potencial** | Teto de cada atributo treinável (por atributo, derivado de um valor global + variação) | O treinador informa "pouco espaço para crescer" quando o atributo se aproxima do teto |
| **Pico Físico** | Idade de início do declínio físico (27–33 `[PROV]`) | Visível só por efeito (declínio) e por avaliação médica cara |
| **Fragilidade** | Multiplicador de risco de lesão em treino e luta | Histórico de lesões; avaliação médica |
| **Metabolismo** | Facilidade de corte de peso e de manter o peso de caminhada | Experiência de cortes anteriores; nutricionista |

Na criação do personagem, o jogador escolhe a origem e o físico; as características ocultas são sorteadas dentro de faixas da origem. O jogador **não** escolhe diretamente o Potencial, para manter a incerteza da carreira (`R-035`).

---

## 4. Personalidade e Perfil Público — `RECOMENDAÇÃO R-023`

### 4.1 NPCs: traços de personalidade (1–5)
| Traço | Efeito na simulação |
|---|---|
| **Disciplina** | Aderência ao treino (ganhos), sucesso no corte de peso, chance de "problemas fora da jaula" (falhar pesagem, faltar a camp) |
| **Ambição** | Aceitar lutas difíceis, pedir disputas de título, trocar de organização por dinheiro |
| **Temperamento** | Probabilidade de rivalidades e provocações; plano de jogo mais agressivo |
| **Carisma** | Ganho de Popularidade por vitória e por mídia |

### 4.2 Jogador: Perfil Público emergente
- O lutador do jogador **não tem traços de personalidade numéricos** que joguem por ele. Sua personalidade é o que o jogador decide.
- As escolhas de mídia ([CAREER §10.5](CAREER_DESIGN.md#105-mídia-entrevistas-e-coletivas)) acumulam um **Perfil Público** com rótulos como *Respeitoso*, *Confiante*, *Provocador*, *Reservado*. O perfil afeta a reação do público e das organizações a falas futuras (um "Respeitoso" que provoca causa mais impacto).
- **Carisma do jogador:** é escolhido na criação como um dos três níveis (baixo/médio/alto) ao custo de pontos de criação ([CAREER §2](CAREER_DESIGN.md#2-criação-e-início-da-carreira)). Escolha consciente: carisma alto acelera dinheiro e oportunidades, ao custo de atributos iniciais.

---

## 5. Estilos e tendências táticas

### 5.1 Estilo principal e secundários
- **Estilo é derivado**, não escolhido como classe. É calculado a partir dos atributos técnicos dominantes e atualizado conforme o lutador evolui (mudança de estilo ao longo da carreira acontece naturalmente).

| Estilo | Regra de derivação `[PROV]` |
|---|---|
| Boxeador | Boxe é o técnico mais alto e ≥ 10 pontos acima da média técnica |
| Kickboxer / Muay Thai | Kickboxing mais alto, idem |
| Wrestler | Média de Wrestling Ofensivo + Controle de Solo mais alta |
| Especialista de jiu-jitsu | Jiu-jitsu mais alto |
| Completo | Nenhum técnico ≥ 10 pontos acima da média técnica e média técnica ≥ 60 |
| Brawler (trocador bruto) | Força e Queixo altos, técnicos em pé baixos |

- **Estilos secundários:** até dois técnicos ≥ 5 pontos acima da média.

### 5.2 Tendências táticas
- Conjunto de **pesos de IA** por NPC (ex.: preferência por distância, frequência de quedas, agressividade, uso de contra-golpe). São inicializados pelo arquétipo do estilo e variados por indivíduo, para dois wrestlers não lutarem igual.
- Para o jogador, as tendências são **observadas** (estatísticas de carreira: "você tenta 4,2 quedas por luta") e usadas pela IA dos adversários que fazem scouting do jogador.

---

## 6. Características físicas e categorias de peso

### 6.1 Dados físicos
| Dado | Efeito em gameplay |
|---|---|
| **Altura** | Escolha de biotipo/sprite; altura do alvo cabeça (uppercut melhor contra mais altos, golpes altos mais difíceis contra mais baixos) `[PROV]` |
| **Envergadura** | Alcance efetivo dos golpes ([COMBAT §2.3](COMBAT_DESIGN.md#23-distância-e-alcance)) |
| **Peso de caminhada** | Quanto precisa cortar para a categoria; peso de luta (após reidratação) entra no **peso relativo** das Disputas |
| **Idade** | Evolução e declínio (§7) |
| **Nacionalidade** | Mercado de popularidade (fãs locais), organizações regionais acessíveis, apresentação |
| **Base** | Ortodoxa/canhota. Canhoto contra ortodoxo: golpes de trás alinham melhor (pequeno bônus de tolerância Z `[PROV]`) para ambos — vantagem simétrica, sem atributo extra |

### 6.2 Categorias de peso — `APROVADA D-007` (lista) · limites como `RECOMENDAÇÃO R-020`
Limites de referência das divisões profissionais mais conhecidas (Regras Unificadas). **Configuráveis por organização** (`WeightClass` em SYS-28). Os valores em kg são conversões e **precisam de validação**.

| Divisão | Categoria | Limite (lb) | Limite (kg) | Biotipos permitidos (`R-005`) |
|---|---|---|---|---|
| Masculina | Peso-mosca | 125 | 56,7 | M-Leve |
| Masculina | Peso-galo | 135 | 61,2 | M-Leve |
| Masculina | Peso-pena | 145 | 65,8 | M-Leve, M-Médio |
| Masculina | Peso-leve | 155 | 70,3 | M-Médio |
| Masculina | Peso meio-médio | 170 | 77,1 | M-Médio |
| Masculina | Peso-médio | 185 | 83,9 | M-Médio, M-Pesado |
| Masculina | Peso meio-pesado | 205 | 93,0 | M-Pesado |
| Masculina | Peso-pesado | 265 | 120,2 | M-Pesado, M-Superpesado |
| Feminina | Peso-palha | 115 | 52,2 | F-Leve |
| Feminina | Peso-mosca | 125 | 56,7 | F-Leve, F-Médio |
| Feminina | Peso-galo | 135 | 61,2 | F-Médio |
| Feminina | Peso-pena | 145 | 65,8 | F-Médio |

Total: **12 categorias (8 masculinas + 4 femininas)**, sem duplicatas (peso-mosca, galo e pena existem nas duas divisões como categorias distintas, identificadas por divisão + categoria).

### 6.3 Princípios das categorias
- **A categoria limita o peso; não determina estilo nem qualidade.** Um peso-pesado pode ser rápido e técnico; um peso-mosca pode ter Força alta *para a categoria*.
- **Atributos são relativos à divisão** `RECOMENDAÇÃO`: Força 70 significa "forte para a categoria". Isso permite comparar atletas da mesma categoria sem que todos os pesados tenham Força 90.
  - Consequência: em mudança de categoria, o jogo recalcula atributos sensíveis a massa (Força, Velocidade, Mobilidade, Robustez) com uma tabela de conversão `[PROV]` (subir: Força relativa cai, Velocidade relativa sobe pouco; descer: o inverso, com custo de corte maior).
- **Efeitos de massa** que não dependem de atributo, aplicados pela física da categoria (dados do `WeightClass`) `[PROV]`:

| Fator | Categorias leves | Categorias pesadas |
|---|---|---|
| Multiplicador de dano do impacto | Menor | Maior (KOs mais frequentes) |
| Custo de Fôlego do movimento | Menor | Maior |
| Velocidade base de movimento | Maior | Menor |
| Ritmo resultante | Mais volume, lutas mais longas | Menos volume, mais finalizações por KO |

Essas diferenças emergem das regras, sem dar vantagem artificial a nenhum estilo.

### 6.4 Faixas físicas esperadas (geração de NPCs, não regra rígida)
Faixas de altura e envergadura por categoria são **distribuições** para gerar NPCs (média e desvio, dados `[PROV]`), com atletas fora da curva possíveis (ex.: peso-leve alto e magro). O jogador, na criação, escolhe altura dentro da faixa permitida pelo biotipo da categoria.

### 6.5 Pesagem
Regras de pesagem, corte e falha estão em [CAREER §6](CAREER_DESIGN.md#6-peso-corte-e-pesagem--sys-17).

---

## 7. Evolução e declínio

### 7.1 Ganho de atributos (conceito)
```
ganho_semanal(atributo) = Σ blocos_de_treino_relevantes × base_do_bloco
                        × qualidade_do_treinador(área)
                        × estrutura_da_academia(área)
                        × fator_fadiga (cai com Fadiga Acumulada alta)
                        × fator_idade (alto até ~25, médio até o Pico, baixo depois)
                        × fator_teto (cai à medida que o atributo se aproxima do Potencial)
```
Todos os fatores `[PROV]`. Detalhes de blocos em [CAREER §4](CAREER_DESIGN.md#4-treinamento-academia-e-equipe--sys-15).

**Garantias contra evolução ilimitada:**
1. **Teto por Potencial** (ganho tende a zero perto do teto).
2. **Blocos limitados por semana** (12) e Fadiga.
3. **Manutenção:** atributos sem treino decaem (Condicionamento rápido; técnicos devagar). Não é possível manter tudo no máximo.
4. **Idade** reduz ganhos e inicia declínio físico.

### 7.2 Ganho por luta
Cada luta dá experiência: QI de Luta e Compostura sobem mais em lutas contra adversários melhores e em situações de perigo sobrevividas; atributos técnicos usados na luta ganham um pequeno bônus.

### 7.3 Idade e declínio
| Fase `[PROV]` | Idade | Efeito |
|---|---|---|
| Desenvolvimento | até ~25 | Ganhos altos |
| Maturidade | ~25 até Pico Físico | Ganhos médios, sem declínio |
| Declínio inicial | Pico até Pico+3 | Velocidade e Recuperação caem lentamente; técnicos e QI ainda sobem |
| Declínio acentuado | Pico+3 em diante | Físicos caem mais rápido; Mobilidade e Defesa em Pé acompanham |

O declínio é aplicado mensalmente com pequena variação individual.

### 7.4 Desgaste Acumulado
- Valor 0–100 que representa o desgaste físico de carreira, principalmente trauma na cabeça.
- Aumenta com: knockdowns e KOs sofridos (muito), lutas com dano alto na cabeça (médio), sparring pesado frequente (pouco).
- Efeitos: reduz Queixo permanentemente; aumenta o tempo de recuperação; acima de limites `[PROV]` (70, 85), o médico recomenda e depois exige a aposentadoria (com opção de o jogador continuar até um limite final, para evitar perder a carreira por um único evento).
- Tema sensível: tratado com sobriedade (médico, avaliações), sem dramatização gráfica.

### 7.5 Lesões crônicas
Lesões graves podem deixar uma **lesão crônica** em um local (joelho, ombro, mão, costas): modificador permanente pequeno em atributos ligados ao local e risco de recorrência maior. Ver [CAREER §5](CAREER_DESIGN.md#5-saúde-lesões-envelhecimento-e-aposentadoria--sys-16-e-sys-24).

---

## 8. Aparência e personalização

`PENDENTE P-004` (profundidade de personalização). Recomendação mínima para a 1.0, compatível com o custo de animação ([ART §5](ART_DIRECTION.md#5-personagens-proporções-e-biotipos)):

| Elemento | Método | Custo de arte |
|---|---|---|
| Biotipo | Escolha entre os permitidos pela categoria | Alto (um conjunto de animações por biotipo) |
| Tom de pele | Troca de paleta | Baixo |
| Cabelo, barba | Camadas sobre a cabeça; poucos estilos (8–12 cada `[PROV]`) | Médio (acompanham todos os quadros da cabeça) |
| Tatuagens | Poucas opções de posição fixa, camada | Médio-alto |
| Calção, luvas, faixas | Paleta + poucos modelos | Baixo |
| Rosto | Não personalizável em detalhe (escala de pixel não suporta) | — |

---

## 9. Exemplos de perfis distintos

Valores `[PROV]`, apenas para ilustrar coerência.

| Atributo | **"Trator" Ruiz** (M, pesado, wrestler, 29) | **Aiko "Vespa" Tanaka** (F, palha, jiu-jitsu, 23) | **Marcus Bell** (M, meio-médio, kickboxer, 33) | **Davi Rocha** (jogador recém-criado, M, leve, 20) |
|---|---|---|---|---|
| Força | 82 | 55 | 64 | 48 |
| Velocidade | 58 | 72 | 66 (caindo) | 60 |
| Condicionamento | 70 | 78 | 62 | 55 |
| Recuperação | 66 | 74 | 55 | 62 |
| Mobilidade | 50 | 76 | 68 | 58 |
| Queixo | 80 | 62 | 58 (Desgaste 45) | 65 |
| Robustez | 78 | 60 | 70 | 50 |
| Boxe | 52 | 48 | 70 | 45 |
| Kickboxing | 40 | 45 | 84 | 38 |
| Defesa em Pé | 55 | 58 | 76 | 42 |
| Wrestling Ofensivo | 85 | 62 | 45 | 52 |
| Wrestling Defensivo | 80 | 58 | 66 | 50 |
| Controle de Solo | 83 | 70 | 42 | 40 |
| Jiu-jitsu | 50 | 88 | 40 | 35 |
| Defesa de Finalização | 64 | 80 | 55 | 38 |
| QI de Luta | 70 | 72 | 85 | 40 |
| Compostura | 75 | 60 | 82 | 50 |
| **Estilo derivado** | Wrestler | Jiu-jitsu (sec.: Wrestling) | Kickboxer (sec.: Boxe) | Completo em formação |
| Envergadura vs altura | +0 cm | +3 cm | +8 cm | +5 cm |
| Como luta | Pressiona, prensa na grade, GnP | Puxa para a guarda, caça as costas | Distância de chute, chute baixo, experiência | — |
| Fraqueza explorável | Gás em lutas de 5 rounds contra móveis | Trocação em distância | Velocidade caindo, queixo desgastado | Tudo ainda baixo |

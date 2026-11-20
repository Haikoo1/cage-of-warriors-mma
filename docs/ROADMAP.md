# ROADMAP — Projeto Jaula

> Versão 0.1 · Etapa 01 · Volta ao [GDD](GDD.md)
> **Sem prazos em dias/semanas**: a equipe é **um desenvolvedor solo, sem artista** (`D-012`), mas disponibilidade e produtividade ainda são desconhecidas. Complexidade relativa: Baixa · Média · Alta · Muito alta.
> A numeração das etapas a partir da E-02 é uma **proposta**; a definição oficial da Etapa 02 cabe ao usuário.

---

## 1. Princípio de ordenação

1. **Combate primeiro, em greybox.** Nada de arte final ou carreira antes de a luta ser divertida (`REQ-01`).
2. **Contratos antes de conteúdo.** Dados, FightSetup/FightResult e save versionado cedo, para não reescrever depois.
3. **Risco maior, mais cedo.** O pipeline de arte é o maior risco de produção → spike logo após o combate em pé.
4. **Conteúdo em massa por último** (12 categorias, população, todas as animações).

---

## 2. Etapas

| Etapa | Objetivo | Depende de | Entregáveis | Critério de conclusão |
|---|---|---|---|---|
| **E-01 GDD** ✅ | Documentar o design | — | `docs/` (este conjunto) | **Concluída e aprovada pelo usuário em 2026-11-19** |
| **E-02 Arquitetura técnica** ✅ | Traduzir o design em arquitetura Godot/GDScript (só documentação) | E-01 | `docs/architecture/` (8 documentos), atualizações de ROADMAP e DECISIONS | Documentos aprovados pelo usuário; pendências técnicas registradas em TECH_DECISIONS |
| **E-02B Fundação técnica** *(nova, T-019)* ✅ | Projeto Godot 4, convenções, camada de dados, contratos | E-02 | Versão da Godot fixada (T-001), Git + `.gitignore` (T-014), `CLAUDE.md` e `README`, estrutura de pastas sob demanda (T-010), autoloads vazios com responsabilidades (T-008), classes de definição + `DataRegistry` com validação, contratos `FightSetup`/`FightResult`/`FighterCommand`, `CareerState` mínimo com `to_dict`/`from_dict` e envelope de save versionado, runner de testes (T-009), configuração pixel-perfect (T-011) e `InputMap` (T-018) | Dados de exemplo (1 categoria, 5 golpes, 1 RuleSet) carregam e são validados; testes de validação, round-trip e imutabilidade rodam headless e passam (execução registrada); nenhuma regra de combate implementada |
| **E-03 Movimento e trocação (greybox)** ✅ (playtest do usuário em 2026-11-19) | SYS-01, 02, 03, 08 parcial | E-02B | Arena greybox, 2 lutadores em formas simples, movimento X/Z, catálogo de golpes básico, guarda/esquiva, Fôlego, dano por zona, Limiar de Choque, modo de depuração (zonas de acerto, faixas de distância) | Duas pessoas (ou pessoa × boneco) conseguem trocar golpes; jab/direto erram por Z; contra-golpe funciona; métricas registradas |
| **E-04 Grappling (greybox)** ✅ (playtest do usuário em 2026-11-19) | SYS-04..07 | E-03 | Clinch, grade, 2 quedas + sprawl, Guarda/Lateral/Montada (+ Costas), 1 finalização, Disputa | Todas as transições do grafo do protótipo funcionam com feedback "Defendido/Resistiu/Passou"; nenhum estado sem saída |
| **E-05 Luta completa (greybox)** ✅ · **M1 aprovado pelo usuário em 2026-11-20** ([relatório](playtest/M1_COMBATE.md)) | SYS-09, 10, 11, 12 | E-04 | Rounds, árbitro (regras), juízes, encerramentos, IA com 2 arquétipos e 3 perfis cognitivos, HUD completo, Luta Rápida | **Marco M1** (§3) |
| **E-06 Spike de pipeline de arte** | Decidir `P-003` pelo método `D-014`, priorizando 3D→pixel (`R-036`) | E-03 (pode correr em paralelo com E-04/05) | 1 biotipo, ≈ 20 animações em um ou dois pipelines, mockup de arena 640×360, comparação de custo por quadro | **Marco M2** (§3); decisão registrada em DECISIONS |
| **E-07 Núcleo da carreira** | SYS-13..17 | E-05 | Criação, calendário semanal, treino (blocos/Fadiga), academias/treinadores, saúde/lesões, peso/pesagem, integração com a luta via contratos | Carreira de 1 lutador por 2 anos de jogo sem mundo (adversários gerados), com lutas jogadas |
| **E-08 Mundo e ecossistema** | SYS-18..21 | E-07 | Organizações (dados), eventos, rankings, matchmaking, contratos, simulação com LOD, resolvedor estatístico | **Marco M3** (§3) |
| **E-09 Economia, reputação e mídia** | SYS-22..24 | E-08 | Economia, Prestígio/Popularidade/Relação, mídia, rivalidades, aposentadoria, legado | Carreira completa jogável do início à aposentadoria (com arte placeholder); **Marco M4** |
| **E-10 Produção de arte e UI** | SYS-27 | E-06, E-05 | Biotipos, animações finais, cenários, UI final, áudio | Luta completa com arte final de 1 biotipo, depois todos |
| **E-11 Conteúdo completo** | REQ-04 | E-08, E-10 | 12 categorias com distribuições físicas, população, todas as organizações, golpes/finalizações completos | Todas as 12 categorias jogáveis e populadas; validação de dados sem erros |
| **E-12 Persistência, opções e acessibilidade** | SYS-25, 26 | E-07 (início), E-11 | Save robusto (rotativo, atômico, migração), configurações completas, tutorial | Testes de corrupção/encerramento; remapeamento completo |
| **E-13 Balanceamento e beta** | — | Todas | Telemetria local de playtest, ajustes de `[PROV]` | **Marco M5** |

> Persistência aparece em E-02B (formato) e E-12 (robustez). Implementar o esquema de save só no fim é um erro comum e caro.

---

## 3. Marcos de validação

| Marco | Pergunta | Critérios observáveis |
|---|---|---|
| **M1 — A luta é divertida?** (E-05) | O combate greybox se sustenta sem carreira? | Playtesters terminam lutas de 3 rounds voluntariamente e pedem outra; conseguem explicar por que ganharam/perderam; pelo menos 3 formas distintas de vencer (KO, finalização, decisão) aparecem; nenhuma estratégia dominante única (ex.: spam de jab) vence a IA intermediária de forma consistente. **Se falhar, não avançar para carreira.** |
| **M2 — Arte viável?** (E-06) | O pipeline escolhido entrega a qualidade e o volume? | Custo medido por animação permite estimar o inventário completo; leitura aprovada pelo usuário em mockup; legibilidade de Z e golpes confirmada |
| **M3 — O mundo é coerente?** (E-08) | O mundo simulado se comporta como esporte crível? | 20 anos simulados sem colapso de população; distribuição de métodos do resolvedor dentro de ±10 pontos percentuais das lutas IA×IA do motor `[PROV]`; campeões trocam com frequência plausível; simulação de 1 ano em poucos segundos em PC modesto `[PROV]` |
| **M4 — A carreira tem decisões?** (E-09) | Fora da jaula há escolhas reais? | Playtesters relatam pelo menos 3 decisões difíceis por "temporada"; nenhum plano de treino único domina; economia sem falência permanente nem excesso cedo demais |
| **M5 — Pronto para lançamento?** (E-13) | Qualidade 1.0 | Todas as funções da §7.2 do GDD presentes; sem bugs bloqueadores; desempenho estável |

---

## 4. Matriz de sistemas: valor, complexidade e risco

| Sistema | Valor | Complexidade | Dependências | Riscos | Simplificação possível | Critério mínimo de "funcional" | Fase |
|---|---|---|---|---|---|---|---|
| SYS-01 Movimento 2.5D | Muito alto | Média | SYS-28 | Profundidade parecer inútil ou confusa | Faixa Z menor; ângulo só em curta distância | Golpes retos erram por Z; troca de lado por ação | Protótipo |
| SYS-02/03 Trocação/defesa | Muito alto | Alta | SYS-01 | Sensação de impacto; timing | Menos golpes | 5 golpes + guarda + esquiva com contra-golpe | Protótipo |
| SYS-04..06 Clinch/quedas/solo | Muito alto | Muito alta | SYS-02, Disputa | Explosão de estados; visual pareado | Menos estados (5) | Grafo do protótipo completo e sem becos | Protótipo |
| SYS-07 Finalizações | Alto | Alta | SYS-06 | Virar minijogo | Só Encaixe + Aperto simples | 1 finalização com 3 resultados | Protótipo |
| SYS-08 Fisiologia | Muito alto | Média | SYS-02..07 | KO aleatório demais/de menos | Sem cortes no protótipo | Fôlego/Reserva/dano/choque funcionando | Protótipo |
| SYS-09/10 Regras/juízes | Alto | Média | SYS-08 | Decisões percebidas como injustas | Juízes sem perfis | Rounds, encerramentos, 3 juízes | Protótipo |
| SYS-11 IA | Muito alto | Alta | SYS-01..10 | Injusta ou burra | Menos arquétipos | 2 arquétipos jogáveis e distintos | Protótipo |
| SYS-12 Feedback/HUD | Muito alto | Média | Combate | Poluição visual | Só HUD completo | Causas de falha explicadas | Protótipo |
| SYS-13 Lutador | Muito alto | Baixa | SYS-28 | Atributos redundantes | — | 17 atributos com efeito verificável | 1.0 (protótipo parcial) |
| SYS-14 Calendário | Alto | Baixa | — | Microgestão | Avanço automático | Turno semanal com paradas | 1.0 |
| SYS-15 Treino/equipe | Muito alto | Média | SYS-13, 16 | Plano ótimo único | Menos atividades | Fadiga impede maximizar tudo | 1.0 |
| SYS-16 Saúde/idade | Alto | Média | SYS-15, FightResult | Punição excessiva | Menos tipos de lesão | Lesões com causa e efeito visíveis | 1.0 |
| SYS-17 Peso | Médio | Baixa | SYS-13 | Tédio | Corte automático | Corte afeta Reserva/Queixo | 1.0 |
| SYS-18 Organizações | Alto | Baixa (dados) | SYS-28 | — | Menos organizações | 4 níveis jogáveis | 1.0 |
| SYS-19 Matchmaking/contratos | Muito alto | Média | SYS-18, 20, 23 | Ofertas sem sentido | Sem contrapropostas | Ofertas coerentes com ranking | 1.0 |
| SYS-20 Rankings | Alto | Baixa | FightResult | Rankings estranhos | Sem ajuste promocional | Ranking crível por 20 anos | 1.0 |
| SYS-21 Simulação do mundo | Muito alto | Alta | SYS-13, 18..20 | Desempenho; incoerência com o combate | LOD mais agressivo | Marco M3 | 1.0 |
| SYS-22 Economia | Médio | Média | SYS-19 | Planilha; inflação | Menos despesas | Dinheiro muda decisões de treino/camp | 1.0 |
| SYS-23 Reputação/mídia | Alto | Média | FightResult | Texto demais | Menos perguntas | Mídia muda ofertas e Popularidade | 1.0 |
| SYS-24 Legado | Médio | Baixa | Histórico | — | Só resumo | Tela de legado | 1.0 |
| SYS-25 Persistência | Muito alto | Média | Todos | Corrupção, migração | Sem Ironman | Autosave rotativo e migração | 1.0 (formato em E-02) |
| SYS-26 Opções/acessibilidade | Alto | Média | — | — | — | Remapeamento + HUD + volumes | 1.0 |
| SYS-27 Apresentação | Muito alto | **Muito alta** | Pipeline | **Volume de animação** | Menos biotipos/posições | Marco M2 | 1.0 |
| SYS-28 Dados | Muito alto | Média | — | Esquema mal pensado | — | Validação ao carregar | E-02 |
| Versus local | Médio | Baixa (após Luta Rápida) | SYS-11 não | Balanceamento PvP | — | — | Expansão |
| Editor | Médio | Média | SYS-28 | Suporte | — | — | Expansão |

---

## 5. Riscos

| # | Risco | Impacto | Probabilidade | Mitigação |
|---|---|---|---|---|
| 1 | Volume de animação inviável (§6.2 do ART) | **Crítico** | Alta | Spike E-06; pipeline 3D→pixel; biotipos limitados; animação por papel; cortar posições/finalizações |
| 2 | Combate não divertido | **Crítico** | Média | Greybox completo; marco M1 bloqueante; iterar antes da arte |
| 3 | Desenvolvedor solo sem artista (`D-012`): toda a produção (código, arte, áudio, UI, balanceamento) depende de uma pessoa | **Crítico** | Certa | Pipeline 3D→pixel com assets licenciados (`R-036`); 4 biotipos (`R-037`); assets de áudio licenciados; cortes de escopo já mapeados na §4 (coluna "Simplificação possível"); marcos M1/M2 como pontos de revisão de escopo |
| 4 | Resolvedor estatístico incoerente com o combate jogado | Alto | Média | Calibração (M3) com lutas IA×IA |
| 5 | Grappling confuso para iniciantes | Alto | Média | Overlay de opções; tutorial por sistema; feedback textual |
| 6 | Carreira tediosa | Alto | Média | Princípios da CAREER §1; marco M4 |
| 7 | Desempenho da simulação com 600–800 lutadores | Médio | Baixa | LOD; simulação fora da renderização |
| 8 | Saves quebrando entre versões | Médio | Média | Versionamento desde E-02 |
| 9 | Nomes fictícios conflitando com marcas reais | Médio | Baixa | Verificação antes de fechar nomes (`P-008`) |
| 10 | Regras reais citadas sem validação | Baixo | Média | `R-020`; validar fonte antes de textos in-game |

---

## 6. O que não deve ser antecipado

- **Arte final** antes do marco M1 e da decisão do pipeline (M2).
- **Carreira** antes do M1.
- **Conteúdo das 12 categorias** (populações, distribuições, biotipos) antes do M3 — no protótipo, 1 categoria basta.
- **UI final** antes de os fluxos de carreira estarem estáveis (usar UI funcional simples).
- **Balanceamento fino** de `[PROV]` antes de os sistemas existirem juntos.
- **Recursos de expansão** (versus, editor, técnicas giratórias, gestão de academia).
- **Otimizações** (threads, GDExtension) antes de medição real (T-002, T-016).

---

## 7. Histórico
| Versão | Data | Alteração |
|---|---|---|
| 0.1 | 2026-11-19 | Criação (Etapa 01) |
| 0.2 | 2026-11-19 | D-012 a D-015 incorporadas (solo, teclado, spike de arte) |
| 0.3 | 2026-11-19 | Etapa 02: E-02 vira Arquitetura técnica; nova E-02B Fundação técnica (T-019); E-01 marcada como aprovada. Escopo de gameplay inalterado |
- **Áudio final, localização completa, marca/nome definitivo.**

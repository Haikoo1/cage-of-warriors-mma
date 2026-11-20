# PROJECT STRUCTURE — Projeto Jaula

> Versão 0.1 · Etapa 02 · Volta ao [overview](ARCHITECTURE_OVERVIEW.md)
> Estrutura **proposta** (`RECOMENDAÇÃO T-010`). Nenhuma pasta foi criada nesta etapa. As pastas serão criadas **quando o primeiro arquivo de cada uma existir** (sem pastas vazias).

---

## 1. Princípios

1. **Organização por domínio**, não por tipo de arquivo: tudo do combate fica perto do combate. Exceção: assets de produção (arte, áudio) ficam em `assets/`, porque o pipeline de arte os gera em lote e eles são compartilhados.
2. **Código de domínio separado de nós.** `src/domain/` nunca contém `.tscn` nem scripts que estendem `Node`.
3. **Definições (dados) separadas do código** em `data/`, para balancear sem abrir scripts.
4. **Ferramentas e fontes de arte fora do jogo exportado.** Arquivos Blender e scripts de pipeline ficam fora de `res://` exportável (pasta `tools/` com `.gdignore`, `art_source/` fora do projeto ou ignorada).

---

## 2. Árvore

```
mma-25d/                              ← raiz do repositório = raiz do projeto Godot (res://)
├─ project.godot
├─ CLAUDE.md                          ← instruções para desenvolvimento assistido (criado em E-02B)
├─ README.md                          ← como abrir, rodar e testar (criado em E-02B)
├─ .gitignore / .gitattributes
├─ docs/                              ← design (Etapa 01) e arquitetura (Etapa 02); .gdignore
│  └─ architecture/
│
├─ src/                               ← todo o código GDScript
│  ├─ app/                            ← orquestração e autoloads (camada de aplicação)
│  │  ├─ autoload/                    ← data_registry.gd, settings.gd, scene_router.gd, audio_director.gd, game_session.gd
│  │  ├─ combat_controller.gd         ← Node que liga CombatSim ↔ entrada ↔ view
│  │  ├─ career_controller.gd         ← API de ações do jogador sobre a carreira
│  │  └─ save/                        ← save_system.gd, migrations/ (uma migração por arquivo)
│  │
│  ├─ domain/                         ← regras puras (RefCounted), sem Nodes
│  │  ├─ common/                      ← ids, rng (fluxos com semente), log, result helpers
│  │  ├─ fighters/                    ← fighter_state.gd, attributes.gd, physique.gd, derived_stats.gd
│  │  ├─ rules/                       ← judging.gd, fight_end_rules.gd, weigh_in.gd
│  │  ├─ combat/                      ← combat_core
│  │  │  ├─ combat_sim.gd             ← orquestra o passo fixo
│  │  │  ├─ fight_state.gd, fighter_combat_state.gd
│  │  │  ├─ movement.gd, striking.gd, defense.gd
│  │  │  ├─ grappling/                ← position_machine.gd, contest.gd (Disputa), submissions.gd
│  │  │  ├─ physiology.gd, referee.gd, combat_stats.gd
│  │  │  └─ contracts/                ← fight_setup.gd, fight_result.gd, fighter_command.gd, combat_event.gd
│  │  ├─ combat_ai/                   ← ai_controller.gd, utility_scoring.gd, habit_memory.gd, perception.gd
│  │  ├─ career/                      ← career_state.gd, week_simulator.gd e um arquivo por sistema
│  │  │                                  (calendar, training, health, weight, contracts, matchmaking,
│  │  │                                   rankings, economy, reputation, media, legacy)
│  │  └─ world_sim/                   ← world_simulator.gd, fight_resolver.gd, fighter_generator.gd, lod.gd
│  │
│  ├─ presentation/                   ← Nodes e scripts de apresentação
│  │  ├─ combat_view/                 ← fighter_view.gd, cage_view.gd, camera_rig.gd, fx/, hud/
│  │  ├─ input/                       ← player_input_controller.gd (teclas → FighterCommand)
│  │  └─ ui/                          ← telas: main_menu/, career/, fight_prep/, results/, settings/, widgets/
│  │
│  └─ definitions/                    ← scripts das classes de Resource (class_name XxxDef)
│     └─ strike_def.gd, weight_class_def.gd, rule_set_def.gd, organization_def.gd, ...
│
├─ scenes/                            ← .tscn, espelhando src/presentation e src/app
│  ├─ main.tscn                       ← raiz: contém a área onde o SceneRouter troca telas
│  ├─ combat/                         ← combat_scene.tscn, fighter_view.tscn, cage_*.tscn, hud.tscn
│  └─ ui/                             ← uma cena por tela + widgets reutilizáveis
│
├─ data/                              ← definições estáticas (.tres) — conteúdo balanceável
│  ├─ weight_classes/                 ← 12 arquivos (8 M + 4 F)
│  ├─ rulesets/, organizations/, strikes/, grappling/ (positions, techniques, submissions)
│  ├─ attributes/, archetypes/, training/, gyms/, coaches/, origins/, injuries/, media/
│  ├─ balance/                        ← balance_constants.tres (todos os [PROV] globais)
│  └─ world_seed/                     ← dados para gerar o mundo inicial (nomes, nacionalidades, distribuições)
│
├─ assets/                            ← assets de produção importados pela Godot
│  ├─ sprites/fighters/<biotipo>/     ← spritesheets renderizados/limpos por biotipo e camada
│  ├─ sprites/arenas/, sprites/fx/, ui/, fonts/
│  └─ audio/music/, audio/sfx/, audio/ambience/, audio/voice/
│
├─ localization/                      ← textos (CSV de tradução da Godot); chaves desde o início (P-005)
│
├─ tests/                             ← testes automatizados (fora do export)
│  ├─ unit/<domínio>/                 ← espelha src/domain
│  ├─ integration/                    ← combate completo headless, fluxo de carreira, save
│  ├─ fixtures/                       ← saves antigos para migração, replays, dados mínimos de teste
│  └─ runner/                         ← script de execução headless (depende de T-009)
│
└─ tools/                             ← .gdignore; ferramentas de desenvolvimento
   ├─ data_validation/                ← validador de definições executável via linha de comando
   ├─ art_pipeline/                   ← scripts de render 3D→pixel (se D-014 escolher B)
   └─ sim_reports/                    ← relatórios de simulação do mundo (calibração M3)

art_source/  (FORA do repositório principal ou em Git LFS — PENDENTE T-014)
   ← arquivos .blend, modelos e animações-fonte de terceiros (licenças guardadas junto)
```

---

## 3. Responsabilidade das pastas e regras de localização

| Pasta | Contém | Nunca contém | Regra |
|---|---|---|---|
| `src/domain/` | Classes `RefCounted`, funções puras | `Node`, `.tscn`, `Input`, `get_tree()`, autoloads | Pode ser carregado e testado sem a árvore de cena. Exceção única: ler definições recebidas por parâmetro |
| `src/app/` | Autoloads, controladores, save | Regras de jogo | Liga camadas; código curto |
| `src/presentation/` | Scripts de Nodes visuais/entrada/UI | Cálculo de regra (dano, chance, pontuação) | Lê estado, envia comandos/ações |
| `src/definitions/` | Classes `XxxDef extends Resource` | Lógica além de validação e acessores | Um arquivo por tipo de definição |
| `scenes/` | `.tscn` | Scripts embutidos (`built-in scripts`) | Script sempre em `src/presentation` ou `src/app` |
| `data/` | `.tres` de definições | Estado de carreira | Uma definição por arquivo quando editável individualmente (golpe, organização); tabelas grandes em um arquivo |
| `assets/` | Arte, áudio, fontes importados | Arquivos-fonte de edição (.blend, .aseprite grandes) | Nome de arquivo = ID do recurso que o usa |
| `tests/` | Testes, fixtures | Código usado pelo jogo | Espelha a árvore de `src/domain` |
| `tools/` | Ferramentas de desenvolvimento | Código carregado pelo jogo | `.gdignore` impede importação |
| `docs/` | Documentação | — | `.gdignore` |

**Onde colocar um arquivo novo?**
1. Calcula ou decide uma regra de jogo? → `src/domain/<domínio>/`.
2. É um tipo de dado editável? → classe em `src/definitions/`, instâncias em `data/`.
3. Desenha, toca som ou lê teclado? → `src/presentation/` + cena em `scenes/`.
4. Liga sistemas, troca telas ou salva? → `src/app/`.
5. Só serve ao desenvolvimento? → `tools/` ou `tests/`.

---

## 4. Itens fora do export

`docs/`, `tests/`, `tools/` ficam fora do pacote exportado (filtros do preset de exportação + `.gdignore` em `docs/` e `tools/`). `tests/` **não** recebe `.gdignore`, porque o runner de testes precisa que a Godot importe os scripts; é excluída pelo filtro de exportação.

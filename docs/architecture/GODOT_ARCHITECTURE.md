# GODOT ARCHITECTURE — Projeto Jaula

> Versão 0.1 · Etapa 02 · Volta ao [overview](ARCHITECTURE_OVERVIEW.md)
> Nomes de configurações do projeto e APIs da Godot citados aqui devem ser **confirmados na versão fixada** (T-001) durante E-02B.

---

## 1. Cenas e nós

### 1.1 Quando criar uma cena
| Situação | Decisão |
|---|---|
| Tela inteira (menu, dashboard, treino, luta) | Cena independente, carregada pelo `SceneRouter` |
| Elemento reutilizado em 2+ lugares (cartão de lutador, barra de atributo, botão de semana) | Cena instanciada em `scenes/ui/widgets/` |
| Elemento visual com estrutura própria (lutador, jaula, HUD) | Cena instanciada dentro da cena de combate |
| Algo que só existe uma vez e tem 1–3 nós | Nós diretos na cena-mãe, sem cena própria |
| Lógica sem desenho | **Não é cena**: classe `RefCounted` em `src/domain/` |

**Limite contra cenas gigantes:** uma cena com mais de ~40 nós próprios ou com um script de mais de ~400 linhas deve ser dividida (diretriz, não regra rígida).

### 1.2 Árvore principal
```
Main (Node)                         scenes/main.tscn
├─ ScreenRoot (Node)                ← SceneRouter coloca aqui a tela ativa (uma por vez)
├─ OverlayLayer (CanvasLayer)       ← pausa, diálogos de confirmação, notificações
└─ TransitionLayer (CanvasLayer)    ← fade entre telas
```
Autoloads ficam fora dessa árvore (são irmãos de `Main` sob a raiz).

### 1.3 Cena de combate
```
CombatScene (Node2D)                       scenes/combat/combat_scene.tscn
├─ CombatController (Node)                 ← src/app/combat_controller.gd: dono do CombatSim, passo fixo
│  ├─ PlayerInputController (Node)         ← teclas → FighterCommand
│  └─ (AIController é RefCounted, criado pelo CombatController, não é nó)
├─ World (Node2D)                          ← tudo que a câmera vê
│  ├─ CageBack (Node2D)                    ← paralaxe e grade do fundo (ParallaxBackground/ParallaxLayer ou equivalente)
│  ├─ Floor (Node2D)                       ← lona + logos
│  ├─ Actors (Node2D, ordenação por Z)     ← FighterView A, FighterView B, RefereeView (1.0), sombras
│  ├─ FX (Node2D)                          ← faíscas, suor, poeira (pool)
│  └─ CageFront (Node2D)                   ← grade frontal transparente (se usada)
├─ CameraRig (Camera2D)                    ← segue o ponto médio em X, snap de pixel
├─ HUD (CanvasLayer)                       ← hud.tscn: barras, relógio, overlay de grappling, textos
└─ RoundBreakUI (CanvasLayer, oculto)      ← intervalo: estatísticas, dicas, foco tático
```
- `FighterView` (cena) = `Node2D` com `AnimatedSprite2D`/`Sprite2D` por camada (corpo, calção, cabelo, dano) + sombra. **Não tem script de regra**: recebe um snapshot e escolhe animação e posição.
- Jaula: variações por organização são **cenas de arena** intercambiáveis (`cage_local.tscn`, `cage_elite.tscn`) com a mesma interface (pontos de ancoragem: limites X, linha do chão).

### 1.4 Fluxo de carreira e demais telas
| Tela | Cena | Script | Observação |
|---|---|---|---|
| Menu principal | `ui/main_menu.tscn` | presentation/ui/main_menu | Slots via `SaveSystem.list_slots()` |
| Criação | `ui/career/create_fighter.tscn` | idem | Produz `CareerSetup` → `CareerController.new_career()` |
| Dashboard | `ui/career/dashboard.tscn` | idem | Lê `CareerState` via `GameSession` |
| Academia/treino | `ui/career/training.tscn` | idem | Edita `TrainingPlan` via `CareerController` |
| Preparação/pesagem | `ui/fight_prep/*.tscn` | idem | Mostra scouting e corte |
| Apresentação/resultado | `ui/results/*.tscn` | idem | Recebe `FightResult` |
| Calendário, contratos, rankings, organização, finanças, histórico | uma cena cada em `ui/career/` | idem | Somente leitura + ações via controller |
| Configurações | `ui/settings/settings.tscn` | idem | Escreve em `Settings` |

### 1.5 Separação apresentação × regras
- Telas **nunca** alteram `CareerState` diretamente: chamam métodos do `CareerController` (ex.: `accept_offer(offer_id)`), que valida e aplica.
- Views de combate **nunca** alteram `FightState`; só leem o snapshot do passo.
- Regras **nunca** chamam nós. Se uma regra precisa "avisar" algo, ela retorna dados (eventos, notificações) para quem a chamou.

### 1.6 Ciclo de vida e troca de cenas
- `SceneRouter.go_to(screen_id, params)` libera a tela atual (`queue_free`) e instancia a próxima em `ScreenRoot`. Parâmetros são objetos de dados (ex.: `FightSetup`), não referências a nós.
- A cena de combate é instanciada por luta e destruída ao fim; nenhum estado de combate sobrevive além do `FightResult`.
- Carregamento: telas leves com `load()` síncrono; cena de combate e arenas com carregamento em segundo plano (`ResourceLoader` com requisição em thread) se o tempo de carga passar de ~0,5 s (medir em E-10).

---

## 2. Autoloads — `RECOMENDAÇÃO T-008`

### 2.1 Recomendados (5)
| Autoload | Motivo de existir | Responsabilidade | Dados que mantém | Depende de | Risco de acoplamento | Alternativa sem autoload |
|---|---|---|---|---|---|---|
| **DataRegistry** | Definições são usadas em quase todo lugar e devem ser carregadas e validadas uma vez | Carregar `data/`, validar, servir por ID (somente leitura) | Dicionários `id → Def` | — | Domínio chamar o autoload diretamente esconde dependência → **regra:** o domínio recebe um objeto `Definitions` por parâmetro; só a camada de aplicação acessa o autoload | Passar `Definitions` manualmente desde `Main` (possível, mas verboso em telas) |
| **Settings** | Configurações valem antes de qualquer carreira e em todas as telas | Ler/gravar `user://settings.cfg`, aplicar vídeo/áudio/InputMap | Preferências | AudioServer, InputMap | Baixo | Nó em `Main` (perde acesso em cenas de teste isoladas) |
| **SceneRouter** | Trocar telas a partir de qualquer tela sem que telas se conheçam | Trocar a tela ativa, transições, pilha de "voltar" | Tela atual, histórico | Main/ScreenRoot | Telas chamarem rotas arbitrárias → **regra:** rotas são IDs enumerados | `get_tree().change_scene_to_*` direto (espalha caminhos de cena) |
| **AudioDirector** | Música e ambiente precisam continuar entre telas | Tocar música/ambiente com crossfade, SFX de UI; barramentos Music/SFX/Ambience/Voice | Faixas ativas | Settings (volumes) | Domínio pedir som → **proibido**; só apresentação | Nó persistente em `Main` (equivalente; autoload é mais simples) |
| **GameSession** | A carreira ativa precisa sobreviver às trocas de tela | Guardar a referência à carreira ativa (`CareerController` + `CareerState`), criar/carregar/fechar sessão | Referência à sessão | SaveSystem | Virar "deus global" → **regra:** sem lógica de jogo; só segura a sessão e delega | Passar a sessão como parâmetro em cada `go_to` (frágil) |

### 2.2 Sistemas que permanecem locais
| Sistema | Onde vive | Por que não é global |
|---|---|---|
| CombatSim e subsistemas | Dentro do `CombatController` da cena de combate | Existe só durante uma luta |
| IA de combate | Criada por luta | Idem |
| Sistemas de carreira (treino, saúde, economia…) | Instâncias dentro do `CareerController` | Pertencem a uma carreira; testáveis sem árvore |
| WorldSimulator / FightResolver | Dentro do `CareerController` | Idem |
| SaveSystem | Classe com métodos estáticos (`class_name SaveSystem`) | Não guarda estado entre chamadas |
| Log | Classe estática (`class_name Log`) | Não precisa de nó |
| Localização | `TranslationServer` nativo | Já é global na engine |
| **EventBus global** | **Não existe** (T-012) | Sinais globais escondem quem depende de quem |

---

## 3. Recursos (`Resource`)
- Classes de definição (`StrikeDef`, `WeightClassDef`, `RuleSetDef`…) estendem `Resource` com `@export` tipados → editáveis no Inspector e salvas como `.tres` texto (diffs legíveis no Git).
- **Recursos são compartilhados por referência**: alterar um `StrikeDef` em tempo de execução altera para todos. Proteções em [DATA_ARCHITECTURE §4](DATA_ARCHITECTURE.md#4-proteção-das-definições-contra-alteração).
- Recursos **não** são usados para estado de carreira nem para saves (T-007).

---

## 4. Sinais e comunicação — `RECOMENDAÇÃO T-012`

### 4.1 Quando usar cada mecanismo
| Mecanismo | Usar quando | Exemplo |
|---|---|---|
| **Chamada direta** | Quem chama possui ou recebeu explicitamente o alvo; fluxo de cima para baixo | `CombatController` → `combat_sim.step(cmds)`; `CareerController` → `training.run_week(state)` |
| **Valor de retorno / fila de eventos** | Domínio precisa informar o que aconteceu | `step()` retorna `Array[CombatEvent]`; `run_week()` retorna `Array[Notification]` |
| **Sinal da Godot (local)** | Um nó avisa o pai/dono sobre algo, sem conhecer quem ouve | `CombatController.fight_finished(result)`; botão → tela |
| **Recurso compartilhado** | Dados estáticos lidos por muitos | `DataRegistry` → `Definitions` |
| **Classe-base / duck typing** | Só onde há **dois ou mais** implementadores reais hoje | Fonte de comandos: `PlayerInputController` e `AIController` expõem `get_command(perception: FighterPerception) -> FighterCommand` |
| **Injeção de dependência** | Apenas por parâmetro de construtor (`_init(defs, rng)`), sem framework | Sistemas de domínio recebem `Definitions` e fluxo de RNG |

### 4.2 Regras
1. **Dependências só para baixo** (camadas da [overview §2](ARCHITECTURE_OVERVIEW.md#2-visão-geral-em-camadas)). Domínio nunca importa apresentação ou aplicação.
2. **Sinais só entre nós com relação de posse** (pai/filho ou dono explícito). Proibido conectar sinais a autoloads para comunicação entre telas.
3. **Nenhum sinal no domínio.** Classes `RefCounted` podem declarar sinais na Godot, mas aqui não declaram: retornam dados. Isso torna o fluxo legível em sequência e testável.
4. **Conexões de sinal no código** (`connect` no `_ready` do dono) **ou** no editor, nunca nas duas formas para o mesmo sinal; preferir código (visível em busca de texto).
5. **Sem `get_node` com caminhos longos** para fora da própria cena; usar `@onready` para filhos e `%UniqueName` dentro da cena.
6. **Ciclos:** se A chama B e B precisa avisar A, B retorna dado ou emite sinal local — nunca chama A.

### 4.3 Exemplos conceituais
1. **Combate → HUD:** a cada passo, `CombatController` chama `hud.present(snapshot, events)`. O HUD não segura referência ao `CombatSim`.
2. **Combate → resultados:** `CombatSim.step()` sinaliza fim na própria resposta (`StepResult.fight_over`). O `CombatController` monta o `FightResult` (via `CombatSim.build_result()`) e emite `fight_finished(result)`.
3. **Resultado → carreira:** a tela de resultado (ou o roteamento pós-luta) chama `GameSession.career.apply_fight_result(result)` — chamada direta, um ponto de entrada só ([CAREER §4](CAREER_ARCHITECTURE.md#4-aplicação-de-um-fightresult)).
4. **Treino → atributos:** `TrainingSystem.run_week(fighter_state, plan, defs, rng)` altera `fighter_state` e retorna um `TrainingReport`. Nenhum sinal.
5. **Lesões → calendário:** `HealthSystem` grava `unavailable_until` no `FighterState`. O `CalendarSystem` e o `MatchmakingSystem` **leem** esse campo no tick (passos posteriores). Não há chamada entre eles.
6. **Organização → matchmaking:** `MatchmakingSystem` lê `OrganizationState` (eventos com vagas) e rankings, gera `FightOffer`s. A organização não chama o matchmaking.

---

## 5. Máquinas de estado

| Onde | Necessária? | Problema que resolve | Forma |
|---|---|---|---|
| Fluxo geral do jogo (menu → carreira → luta) | **Não** como FSM formal | O `SceneRouter` com rotas enumeradas basta | Rotas + validação de parâmetros |
| Fases da luta (apresentação, round, intervalo, fim) | **Sim, simples** | Impede passo de simulação no intervalo, pontuação fora de hora | `enum FightPhase` + `match` no `CombatSim` |
| Ação do lutador (neutro, golpe em preparação/execução/recuperação, esquiva, atordoado, caído) | **Sim** | Garante que fases de golpe e estados de choque não se sobreponham | `enum FighterActionState` + tempo restante, transições em um só lugar (`FighterCombatState.set_action`) |
| Posição / grappling (EP, CL, CG, SG, SM, SL, SO, SC, SR, KD) | **Sim, a principal** | Combinações inválidas entre em pé, clinch, queda e solo | **Uma** máquina do **par** de lutadores dirigida por tabela de dados; ver [COMBAT §3](COMBAT_ARCHITECTURE.md#3-estados-e-transições) |
| IA | **Não** como FSM | Seleção por utilidade substitui estados de IA; "plano do round" é só um dado | Pontuação por contexto |
| Menus e UI | **Não** | Cada tela é simples; navegação é do router | — |
| Semana da carreira | **Não** como FSM | Pipeline em ordem fixa (WeekSimulator) | Lista ordenada de passos |
| Semana da luta (coletiva → pesagem → luta) | **Sim, simples** | Impede pular pesagem, salvar no meio da luta | `enum FightWeekStep` no `CareerState` |

---

## 6. Estratégia de atualização

| Contexto | Atualização |
|---|---|
| Combate | Passo **fixo** de 1/60 s no `_physics_process` do `CombatController` (taxa de física = 60, confirmar em E-02B). Um passo de simulação por tick de física; renderização lê o último snapshot. Hit-stop e câmera lenta são feitos **pulando passos** de simulação (o estado congela), não alterando o tempo da engine |
| Pausa | `CombatController` deixa de chamar `step()`; UI de pausa em `OverlayLayer` com `process_mode = ALWAYS` |
| Carreira | Sem atualização por frame. Ações e "simular semana" são chamadas explícitas. Simular várias semanas: uma semana por frame (ou por fatia de tempo ~8 ms) para manter a UI responsiva e permitir interromper (T-016) |
| UI | Atualiza ao receber dados (após ação ou tick), não por `_process` contínuo |

# TECH DECISIONS — Registro de decisões técnicas

> Versão 0.1 · Etapa 02 · Volta ao [overview](ARCHITECTURE_OVERVIEW.md)
> Estados: **APROVADA** (usuário) · **RECOMENDAÇÃO** (pendente de aprovação) · **PENDENTE** (exige validação ou resposta).
> Decisões de design ficam em [../DECISIONS.md](../DECISIONS.md); aqui só decisões técnicas, com referência cruzada.

---

## 1. Plataforma, linguagem e ferramentas

### T-001 — Versão da Godot · RECOMENDAÇÃO / versão exata PENDENTE
- **Contexto:** D-008 fixa Godot 4. A Godot não está instalada no ambiente atual (verificado em 2026-11-19), então nenhuma versão foi testada.
- **Decisão proposta:** usar a **versão 4.x estável mais recente disponível no início de E-02B**, versão padrão (não .NET), e **fixá-la** no `README` e no `project.godot`. Atualizar de versão menor só entre etapas, com a suíte de testes passando.
- **Alternativas:** versão LTS antiga (menos recursos de 2D/pixel), versões beta (instáveis).
- **Consequências:** nomes de configurações citados nestes documentos (escala inteira, snap de pixel, avisos de tipagem) devem ser confirmados na versão escolhida.

### T-002 — GDScript tipado · APROVADA (D-009) + RECOMENDAÇÃO de tipagem obrigatória
- **Contexto:** nenhuma justificativa técnica concreta para C#/GDExtension foi encontrada: a simulação do mundo (600–800 lutadores com LOD, resolvedor leve) e o combate (2 lutadores, 60 Hz) têm custo baixo.
- **Decisão:** GDScript com tipagem estática obrigatória (avisos como erro).
- **Reavaliar se:** medição em E-08 mostrar simulação de 1 ano acima do orçamento mesmo com LOD; nesse caso, só o `FightResolver` seria candidato a GDExtension.

### T-014 — Controle de versão e assets binários · RECOMENDAÇÃO / LFS PENDENTE
- **Decisão:** Git (instalado, 2.55) com repositório criado em E-02B na raiz do projeto, `.gitignore` para `.godot/` e exportações, `.gitattributes` com finais de linha consistentes.
- **Assets-fonte** (`.blend`, animações de terceiros): fora do repositório principal **ou** com Git LFS. Decidir quando o spike E-06 mostrar o volume real. **Licenças** de assets de terceiros guardadas junto aos arquivos (R-036).
- **Alternativa:** um único repositório sem LFS (incha rapidamente com binários).

### T-020 — Dependências externas · RECOMENDAÇÃO
- **Decisão:** nenhum addon além do framework de testes (T-009), e só após aprovação.
- **Ferramentas de produção** (fora do jogo, nada instalado agora):

| Ferramenta | Uso | Benefício | Risco | Alternativa |
|---|---|---|---|---|
| Blender | Pipeline 3D→pixel (se D-014 escolher B) | Gratuito, scriptável em Python para render em lote | Curva de aprendizado | Desenho à mão (inviável no escopo solo) |
| Editor de pixel art (Aseprite, pago; Pixelorama/LibreSprite, gratuitos) | Limpeza de quadros-chave, UI | Ferramentas de animação em pixel | Custo (Aseprite) | Editor nativo nenhum na Godot para isso |
| Editor de áudio (Audacity, gratuito) | Ajuste de SFX licenciados | — | — | — |

---

## 2. Arquitetura

### T-003 — Domínio em `RefCounted`, sem Nodes · RECOMENDAÇÃO
- **Contexto:** regras precisam ser testáveis sem cena (prompt E-02 §6.12) e independentes da arte (P-003 pendente).
- **Alternativas:** lógica em scripts de nós (rápido no começo, acopla regra à cena e dificulta testes); Resources com lógica (estado compartilhado acidental).
- **Consequências:** camada de aplicação um pouco maior (controllers que ligam domínio e nós).

### T-004 — Combate em passo fixo 60 Hz, determinístico, geometria própria · RECOMENDAÇÃO
- **Contexto:** fases de golpe em quadros (COMBAT §3.3), replay de regressão, mundo lógico X/Z diferente da tela.
- **Alternativas:** delta variável; física da Godot; animação dirigindo regras — rejeitadas em [COMBAT_ARCHITECTURE §2](COMBAT_ARCHITECTURE.md#2-modelo-de-atualização--recomendação-t-004).
- **Consequências:** colisões/acertos implementados à mão (intervalos simples). Determinismo de `float` entre máquinas não garantido (ver T-013).

### T-005 — Posição de grappling como máquina de estados do par, dirigida por dados · RECOMENDAÇÃO
- **Contexto:** evitar combinações inválidas (COMBAT §4, R-009, R-031).
- **Alternativas:** estado por lutador (permite inconsistências); FSM em nós/`AnimationTree` (acopla à apresentação).
- **Consequências:** teste de grafo obrigatório (sem becos, tudo alcançável).

### T-006 — Definições em `Resource` personalizados; estado guarda só IDs · RECOMENDAÇÃO
- **Contexto:** D-011 (orientação a dados), edição no Inspector, `.tres` texto versionável.
- **Alternativas:** JSON/CSV para definições (sem Inspector, sem tipagem); dados em código.
- **Consequências:** risco de mutação de recurso compartilhado, mitigado em DATA_ARCHITECTURE §4.

### T-007 — Saves em JSON compactado; nunca `.tres`/`ResourceSaver` · RECOMENDAÇÃO
- **Contexto:** carregar Resources de `user://` pode executar scripts embutidos (risco com saves compartilhados); necessidade de migração legível.
- **Alternativas:** `ResourceSaver` (rápido de escrever, inseguro e frágil a renomeações); `var_to_bytes`/`store_var` (binário, difícil de migrar e depurar).
- **Consequências:** `to_dict/from_dict` manuais em cada classe de estado.

### T-008 — Cinco autoloads; sem EventBus · RECOMENDAÇÃO
- `DataRegistry`, `Settings`, `SceneRouter`, `AudioDirector`, `GameSession`. Justificativas em [GODOT_ARCHITECTURE §2](GODOT_ARCHITECTURE.md#2-autoloads--recomendação-t-008).
- **Alternativa rejeitada:** barramento global de sinais — desacopla na aparência, mas esconde dependências e ordem de execução.

### T-009 — Framework de testes · **APROVADA** (2026-11-19): runner próprio mínimo
- Decisão do usuário: runner próprio em `tests/runner/`, executado com `godot --headless`; migrar para addon só se houver necessidade real.
- GUT × GdUnit4 × runner próprio mínimo ([SAVE_AND_TESTING §2.3](SAVE_AND_TESTING.md#23-ferramenta-de-testes--pendente-t-009)). Decidir em E-02B com a versão da Godot fixada; instalar só com aprovação.

### T-010 — Estrutura de projeto por domínio · RECOMENDAÇÃO
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md). Pastas criadas sob demanda.

### T-011 — Renderização pixel-perfect · RECOMENDAÇÃO (valores dependem de R-003, PENDENTE)
- Resolução interna = resolução-base aprovada (recomendação atual 640×360, ART §3); modo de esticamento por **viewport** com **escala inteira**; filtro de textura padrão **nearest**; mipmaps desligados para sprites; snap de transformações 2D ao pixel; câmera com posição arredondada.
- UI desenhada na mesma resolução interna; escala de UI (1×–3×) implementada como layouts alternativos/tema, não como escala fracionária.
- **Validar no spike E-06:** se a resolução mudar (ex.: 480×270), só a configuração do projeto e `PIXELS_PER_METER` mudam; o domínio usa metros e não é afetado.

### T-012 — Regras de comunicação · RECOMENDAÇÃO
- Chamadas diretas para baixo, retornos/filas de eventos para cima, sinais só entre nós com posse, nenhum sinal no domínio ([GODOT_ARCHITECTURE §4](GODOT_ARCHITECTURE.md#4-sinais-e-comunicação--recomendação-t-012)).

### T-013 — Fluxos de RNG por sistema, com semente salva · RECOMENDAÇÃO / determinismo entre máquinas PENDENTE
- [DATA_ARCHITECTURE §9](DATA_ARCHITECTURE.md#9-aleatoriedade-e-determinismo--recomendação-t-013).

### T-015 — Localização desde o início · RECOMENDAÇÃO
- Todo texto visível por chave, em CSV de tradução da Godot em `localization/`; idioma de lançamento ainda PENDENTE (P-005). Custo baixo agora, alto depois.

### T-016 — Simulação do mundo no thread principal com orçamento de tempo · RECOMENDAÇÃO
- Uma semana por frame ou fatias de ~8 ms; threads apenas se a medição de E-08 exigir (threads complicam determinismo e acesso ao estado).

### T-017 — Log como classe estática · RECOMENDAÇÃO
- `class_name Log` com categorias e níveis; sem autoload.

### T-018 — Entrada por `InputMap` → `FighterCommand` · RECOMENDAÇÃO (conforme D-015, R-008, R-038)
- Ações nomeadas no `InputMap` (ex.: `move_forward`, `lead_hand`, `mod_curved`, `technique`, `grapple`), com padrões de teclado e gamepad; o `PlayerInputController` converte o estado das ações em `FighterCommand` com **buffer de entrada** de poucos quadros `[PROV]`. "Frente/trás" convertidos para relativo ao adversário dentro do controller.
- Remapeamento salvo por `Settings` em `settings.cfg`.

### T-019 — Divisão da etapa de fundação · RECOMENDAÇÃO
- **Contexto:** o ROADMAP v0.1 previa a E-02 como "Fundação técnica" com criação do projeto; o prompt oficial da Etapa 02 é só documentação.
- **Decisão proposta:** E-02 = Arquitetura técnica (documentos); nova **E-02B = Fundação técnica** (projeto Godot, `CLAUDE.md`, `README`, Git, esquema de dados com validação, contratos, runner de testes, esqueleto de save). Numeração das demais etapas preservada.

---

## 3. Histórico
| Versão | Data | Alteração |
|---|---|---|
| 0.1 | 2026-11-19 | Criação na Etapa 02 |
| 0.2 | 2026-11-19 | **Etapa 02 aprovada pelo usuário.** T-009 aprovada (runner próprio). Git com commits locais autorizado (T-014, sem LFS por enquanto). Godot será instalada pelo usuário (T-001) |

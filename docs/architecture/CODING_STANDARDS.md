# CODING STANDARDS — Projeto Jaula

> Versão 0.1 · Etapa 02 · Volta ao [overview](ARCHITECTURE_OVERVIEW.md)
> Base: guia de estilo oficial de GDScript da Godot, com as regras abaixo específicas do projeto. Cada regra existe por um motivo prático.

---

## 1. Nomes

| Item | Convenção | Exemplo |
|---|---|---|
| Arquivos e pastas | `snake_case` | `fighter_state.gd`, `combat_scene.tscn` |
| Classes (`class_name`) | `PascalCase`; nome do arquivo = classe em snake_case | `FighterState` ↔ `fighter_state.gd` |
| Definições (Resource) | Sufixo `Def` | `StrikeDef`, `WeightClassDef` |
| Variáveis e funções | `snake_case`; funções começam com verbo | `stamina`, `apply_fight_result()` |
| Privado por convenção | Prefixo `_` | `_resolve_contest()` |
| Constantes | `UPPER_SNAKE_CASE` | `MAX_BLOCKS_PER_WEEK` (só constantes não balanceáveis) |
| Enums | Tipo `PascalCase`, valores `UPPER_SNAKE_CASE` | `enum Zone { HEAD, BODY, LEGS }` |
| Sinais | Verbo no passado, `snake_case` | `fight_finished`, `offer_accepted` |
| Nós em cena | `PascalCase` | `CameraRig`, `HudRoot` |
| IDs de definição | `snake_case` com prefixo de divisão/tipo quando ambíguo | `&"m_flyweight"`, `&"f_flyweight"`, `&"org_gcl"` |
| Termos de jogo no código | **Inglês** no código, com correspondência 1:1 ao [GLOSSARY](../GLOSSARY.md) mantida no §6 abaixo | `stamina` = Fôlego, `reserve` = Reserva |

## 2. GDScript
- **Tipagem estática obrigatória** em variáveis, parâmetros e retornos (`var x: float`, `func f(a: int) -> void`). Ativar como **erro** os avisos de variável/parâmetro sem tipo nas configurações do projeto (nome exato da configuração a confirmar em E-02B). Motivo: erros aparecem antes da execução e o código fica legível para IA e humanos.
- Arrays e dicionários tipados quando possível (`Array[CombatEvent]`).
- `@export` só em definições e em nós de apresentação; nunca em classes de domínio.
- Sem scripts embutidos em cenas.
- Sem `await` no domínio (é síncrono e determinístico).
- Domínio não usa `Input`, `get_tree()`, `Engine`, autoloads, `Time` do sistema ou `randf()` global: recebe tudo por parâmetro (definições, RNG, data do jogo).

## 3. Organização de um script
```
class_name / extends
## Comentário de documentação da classe (uma frase: responsabilidade)
signals → enums → constantes → @export → variáveis públicas → variáveis privadas → @onready
_init / _ready → métodos públicos → métodos privados
```
- Um script = uma responsabilidade. Alertas de tamanho: ~400 linhas por script, ~40 linhas por função. Passou? Dividir pelo domínio, não por "helpers" genéricos.

## 4. Comentários e documentação
- Comentar o **porquê**, nunca o óbvio. Fórmulas citam a seção de design: `# COMBAT_DESIGN §6.3`.
- Comentários de documentação (`##`) em classes públicas e funções de contrato.
- Mudou uma regra ou decisão? Atualizar o documento de design/arquitetura no mesmo commit.

## 5. Erros, logs e depuração
| Situação | Tratamento |
|---|---|
| Erro de programação (estado impossível) | `assert()` (some no export) + `push_error` |
| Dado inválido (definição, save) | Validador retorna lista de erros legíveis; carregamento falha de forma controlada |
| Ação inválida do jogador (UI) | Método do controller retorna resultado com motivo (ex.: `ActionResult.fail("fadiga_alta")`); UI mostra texto localizado |
| Log | Classe estática `Log` com categorias (`combat`, `career`, `save`, `data`, `ai`) e níveis; categorias ativadas por configuração de depuração |
| Depuração de combate | Overlay de depuração (zonas de acerto, faixas de distância, estado de posição, decisões da IA) ligado por tecla em build de depuração |

- Nunca engolir erros em silêncio. Nunca usar números mágicos de balanceamento no código (ver DATA_ARCHITECTURE §2).

## 6. Correspondência de termos (código ↔ glossário)
| Glossário (PT) | Código (EN) |
|---|---|
| Fôlego / Reserva | `stamina` / `reserve` |
| Dano por zona (agudo/residual) | `zone_damage` (`acute` / `residual`) |
| Limiar de Choque | `shock_threshold` |
| Abalado / Atordoado / Knockdown / Apagão | `ROCKED` / `STUNNED` / `KNOCKDOWN` / `KNOCKOUT` |
| Disputa | `Contest` |
| Pressão / Resistência | `pressure` / `resistance` |
| Vantagem de Clinch / de Ângulo | `clinch_advantage` / `angle_advantage` |
| Medidor de Aperto | `squeeze_meter` |
| Estado de posição | `PositionState` |
| Direção de técnica | `technique_direction` |
| Fadiga Acumulada / Desgaste Acumulado | `fatigue` / `career_wear` |
| Bloco de treino / Carga | `TrainingBlock` / `load` |
| Prestígio / Popularidade / Relação | `prestige` / `popularity` / `relationship` |
| Biotipo | `biotype` |
| Resolvedor estatístico | `FightResolver` |

Atributos usam IDs em português sem acento, iguais ao CHARACTER_DESIGN (`forca`, `velocidade`, `condicionamento`, `recuperacao`, `mobilidade`, `queixo`, `robustez`, `boxe`, `kickboxing`, `defesa_em_pe`, `wrestling_ofensivo`, `wrestling_defensivo`, `controle_solo`, `jiu_jitsu`, `defesa_finalizacao`, `qi_luta`, `compostura`), porque são dados exibidos e editados por quem lê o design.

## 7. Git
- Commits pequenos, mensagem no imperativo, referenciando IDs (`SYS-07`, `T-005`) quando aplicável.
- Branch principal `main`; branches curtos por etapa/tarefa (`e03-movement`) — opcional para desenvolvedor solo, recomendado antes de mudanças grandes.
- Nunca commitar `.godot/` (cache) nem arquivos de `art_source/` sem a decisão T-014.

## 8. Boas práticas específicas
1. Regra nova → teste primeiro (SAVE_AND_TESTING §2.1).
2. Número novo de balanceamento → `BalanceConstants` ou definição, marcado `[PROV]` no design.
3. Campo novo serializado → `schema_version` + migração + teste.
4. Nova tela → nunca altera estado direto; usa `CareerController`.
5. Novo golpe/técnica/organização → só dados + validação; se exigir código novo, registrar o porquê.
6. IA nunca recebe `FightState` inteiro, só `FighterPerception`.

# SAVE AND TESTING — Projeto Jaula

> Versão 0.1 · Etapa 02 · Volta ao [overview](ARCHITECTURE_OVERVIEW.md)
> Requisitos de design: [GAME_SYSTEMS §6](../GAME_SYSTEMS.md) (R-028). Skill consultada para a estratégia de testes: *test-driven-development*.

---

## 1. Persistência

### 1.1 Separação de dados
| Dados | Onde | Formato | Dono |
|---|---|---|---|
| Configurações (vídeo, áudio, controles, HUD, acessibilidade) | `user://settings.cfg` | `ConfigFile` | `Settings` |
| Dados globais entre carreiras (tutorial concluído, Hall da Fama global opcional) | `user://profile.json` | JSON | `SaveSystem` |
| Carreira (mundo inteiro) | `user://saves/slot_<n>/` | JSON + gzip | `SaveSystem` |

### 1.2 Estrutura de um slot
```
user://saves/slot_1/
├─ meta.json            ← leve: nome do lutador, data do jogo, cartel, versão, timestamp (lista no menu sem abrir o save)
├─ career.json.gz       ← save principal (manual)
├─ auto_0.json.gz       ← autosave mais recente
├─ auto_1.json.gz
└─ auto_2.json.gz       ← 3 autosaves rotativos (R-028)
```
Mínimo de 5 slots `[PROV]`.

### 1.3 Envelope
```json
{
  "schema_version": 3,
  "game_version": "0.4.1",
  "data_version_hash": "a91f…",       // hash das definições do jogo no momento do save (diagnóstico)
  "saved_at": "2027-01-10T21:33:00Z",
  "trigger": "week_start | pre_fight | post_fight | manual",
  "ironman": false,
  "career": { … CareerState.to_dict() … }
}
```

### 1.4 Quando salvar
| Gatilho | Arquivo |
|---|---|
| Início de cada semana | autosave rotativo |
| Antes da luta do jogador (após pesagem) | autosave rotativo |
| Depois de aplicar o `FightResult` | autosave rotativo |
| Manual (Dashboard) | `career.json.gz` |
| Durante a luta | **nunca** (fechar no meio = recomeçar a luta do autosave pré-luta) |

### 1.5 Salvamento seguro
1. Serializar `CareerState` → `Dictionary` (no thread principal; o estado não pode mudar durante).
2. `JSON.stringify` → compactar → gravar em `*.tmp`.
3. Reabrir `*.tmp`, descompactar e parsear (verificação de leitura).
4. Rotacionar autosaves (`auto_1 → auto_2`, `auto_0 → auto_1`) e renomear `*.tmp` → destino.
5. Atualizar `meta.json` por último.
6. Qualquer falha: manter os arquivos anteriores intactos, registrar no log e avisar o jogador.
> Se a serialização ficar lenta (medir em E-08), mover os passos 2–5 para uma thread com uma cópia do dicionário.

### 1.6 Carregar, migrar e validar
```text
load(slot, file):
  doc = parse(gunzip(read(file)))                     # erro → tentar próximo autosave
  v = doc.schema_version
  if v > CURRENT_SCHEMA: recusar ("save de versão mais nova")
  while v < CURRENT_SCHEMA: doc = MIGRATIONS[v].migrate(doc); v += 1   # um arquivo por migração
  career = CareerState.from_dict(doc.career)
  errors = CareerValidator.validate(career, defs)     # IDs de definições existem, referências entre entidades existem,
                                                      # valores em faixa, um único lutador do jogador, data coerente
  if errors críticos: oferecer autosave anterior; nunca abrir estado inválido em silêncio
```
- **Migrações** são funções puras `Dictionary → Dictionary`, testadas com *fixtures* de saves de cada versão anterior (`tests/fixtures/saves/v1.json` …).
- Toda mudança em `to_dict()` que altere estrutura **exige** incrementar `schema_version` e escrever a migração (regra de revisão).

### 1.7 Recuperação de falhas
| Falha | Recuperação |
|---|---|
| Encerramento durante gravação | `.tmp` incompleto é ignorado; arquivo anterior intacto |
| Save corrompido | Tentar `auto_0`, `auto_1`, `auto_2` em ordem; informar o que foi perdido (data do jogo) |
| Definição removida em atualização | Migração mapeia para substituta; senão, erro claro de validação |
| Crash durante a luta | Autosave pré-luta |

---

## 2. Testes e qualidade

### 2.1 Princípios
- **Testes primeiro nas regras puras** (`src/domain/`): seguir o ciclo vermelho → verde → refatorar da skill de TDD — escrever o teste, vê-lo falhar pelo motivo certo, implementar o mínimo. Aplica-se a fórmulas, transições, Disputa, juízes, sistemas de carreira, serialização e migrações.
- **Exceção que precisa de autorização do usuário:** ajuste de "sensação" de combate em greybox (tempos, velocidades) é exploratório; os números ficam em dados e não exigem teste por valor — mas a mecânica que os usa, sim.
- **Testar comportamento, não implementação:** nada de mocks para regras; usar definições de teste reais e pequenas em `tests/fixtures/`.
- O domínio não depende de nós, então quase tudo roda **headless** sem abrir a cena principal.

### 2.2 Tipos de teste
| Tipo | Escopo | Exemplos | Quando roda |
|---|---|---|---|
| **Unidade** | Uma função/sistema do domínio | Golpe reto erra com ΔZ > tolerância; Disputa com leitura correta sempre bloqueia; juiz dá 10-8 com 2 KDs; Fadiga > 90 bloqueia treino pesado | Sempre (rápidos) |
| **Transições de estado** | Tabela de posições/ações | Sem becos, todos alcançáveis, ações proibidas recusadas por posição | Sempre |
| **Validação de dados** | Todas as definições de `data/` | Categoria sem limite, golpe sem atributo técnico, técnica com estado inexistente; 12 categorias presentes (8 M + 4 F) | Sempre e no carregamento |
| **Integração — combate** | `CombatSim` + 2 IAs headless | Luta termina; invariantes; nenhum evento sem causa | Sempre (curto) |
| **Regressão por replay** | Semente + comandos gravados | Mesmo `FightResult` e hash final | Sempre |
| **Integração — carreira** | Fluxo de N semanas | Criar carreira, simular 104 semanas, jogar 2 lutas com resultados fabricados; dinheiro nunca bloqueia; nenhuma lesão sem causa | Sempre (médio) |
| **Simulação longa** | Mundo por 20 anos | População estável, campeões trocam, sem IDs órfãos, tempo de execução | Sob demanda / antes de marcos |
| **Serialização** | `to_dict`/`from_dict` | Round-trip idêntico de `CareerState` grande; enums por nome | Sempre |
| **Migração** | Fixtures de versões antigas | v1 → atual abre e valida | Sempre |
| **Imutabilidade das definições** | Hash antes/depois | Luta + 2 anos não alteram definições | Sempre |
| **Manual** | Sensação, leitura visual, áudio | Roteiro de playtest de combate (M1), checklist de telas | Por marco |

### 2.3 Ferramenta de testes — `PENDENTE T-009`
| Opção | Benefício | Risco | Manutenção | Alternativa nativa |
|---|---|---|---|---|
| **GUT** (addon) | Maduro, roda headless pela linha de comando | Compatibilidade com a versão exata da Godot precisa ser confirmada | Atualizar com a engine | — |
| **GdUnit4** (addon) | Recursos ricos, integração com editor | Idem; mais complexo | Idem | — |
| **Runner próprio mínimo** | Zero dependência: script `tests/runner/run_tests.gd` executado com `godot --headless --script`, descobre `test_*.gd` e conta asserções | Menos recursos (sem relatórios bonitos) | Pequena | É a própria alternativa nativa |

Recomendação: decidir em E-02B instalando **somente após aprovação**; se houver qualquer incompatibilidade com a versão fixada, usar o runner próprio. Comando único documentado no `README` para rodar tudo.

### 2.4 Estratégia de validação contínua
- Rodar a suíte completa antes de cada commit relevante (local; CI é opcional e pode vir depois).
- `tools/data_validation/` roda o validador de definições fora do jogo.
- Relatórios de simulação (`tools/sim_reports/`) geram CSV para calibração M3.
- Nenhum teste é dado como passando sem execução real registrada (regra do projeto).

# CLAUDE.md — Projeto Jaula

Jogo de MMA 2.5D em pixel art, Godot 4.7.2 + GDScript tipado, foco no modo carreira. Desenvolvedor solo, sem artista.

## Fonte da verdade
O repositório é a fonte oficial. Antes de qualquer tarefa, consulte:
- Design: `docs/GDD.md` e especializados (`COMBAT_DESIGN`, `CAREER_DESIGN`, `CHARACTER_DESIGN`, `ART_DIRECTION`, `GAME_SYSTEMS`), vocabulário em `docs/GLOSSARY.md`.
- Arquitetura: `docs/architecture/` (comece por `ARCHITECTURE_OVERVIEW.md`; convenções em `CODING_STANDARDS.md`).
- Decisões: `docs/DECISIONS.md` (design) e `docs/architecture/TECH_DECISIONS.md` (técnicas). Hierarquia: decisão aprovada pelo usuário > DECISIONS > docs aprovados > este arquivo > recomendações.
- Plano: `docs/ROADMAP.md`. **Não avance de etapa sem autorização explícita do usuário.**

## Regras de trabalho
1. Consulte e use as skills instaladas quando forem relevantes (ex.: TDD para regras); não invente skills.
2. **Testes primeiro** para regras em `src/domain/` (vermelho → verde → refatorar). Nunca declare teste passando sem rodar.
3. `src/domain/` não usa Nodes, autoloads, `Input`, `get_tree()` nem `randf()` global: recebe `Definitions` e RNG por parâmetro.
4. Definições (`data/*.tres`) são somente leitura; estado guarda IDs, nunca Resources. Número de balanceamento só em dados, marcado `[PROV]` no design.
5. Campo serializado novo → incrementar `SaveSystem.CURRENT_SCHEMA` + migração + teste.
6. Telas não alteram estado direto; usam controllers. Sem EventBus global.
7. Mudou uma decisão ou regra? Atualize o documento no mesmo commit. Conflito com o design: explique, proponha alternativas e aguarde aprovação.
8. Commits pequenos, mensagem em português no imperativo, com IDs (`SYS-xx`, `T-xxx`) quando couber.

## Comandos
Godot: `C:\Users\sousa\Downloads\Godot_v4.7.2-stable_win64.exe` (defina `GODOT_EXE`).
- Testes: `.\tests\run_tests.ps1 -Godot $env:GODOT_EXE` (falha também se houver "SCRIPT ERROR").
- Bash: `"$GODOT" --headless --path . --import` e depois `"$GODOT" --headless --path . --script res://tests/runner/run_tests.gd`.
- Rodar o jogo: `"$GODOT" --path .` (Enter na tela inicial abre o treino de combate)
- Dados de grappling: edite `tools/gen_grappling_data.js` e rode `node tools/gen_grappling_data.js` (gera `data/grappling/*.tres`).
- Smoke da Luta Rápida IA x IA até o resultado: `"$GODOT" --headless --path . --script res://tests/runner/smoke_quick_fight.gd`
- Lote de balanceamento IA x IA (~2,5 min): `"$GODOT" --headless --path . --script res://tests/runner/batch_ai.gd`
- Pipeline de sprites (Blender 5.3): `"C:/Program Files/Blender Foundation/Blender 5.3/blender.exe" -b --factory-startup --python tools/art_pipeline/pipeline.py -- <raiz>`
- Smoke dos sprites: `"$GODOT" --headless --path . --script res://tests/runner/smoke_sprites.gd`
- Dados da carreira: `node tools/gen_career_data.js` (categorias, organizações, origens, treino, academias).
- Smokes da carreira: `smoke_career.gd` (telas) e `smoke_career_fight.gd` (luta jogada até o resultado).
- Geradores de conteúdo (node): `tools/gen_strike_data.js`, `gen_grappling_data.js`, `gen_career_data.js`, `gen_audio.js`, `gen_icons.js`.
- Sprites v3 (Blender 5.3, ~8 min por biótipo; `-- <raiz> f_medium` gera só um): corpo orgânico em 3/4 a 105 px/m (D-022), camadas corpo x4 físicos + cabelo1..8 + barba1..4; o jogo recolore por shader (assets/shaders/palette_swap.gdshader). Ensaio rápido: `JAULA_OUT=<pasta> JAULA_ANIMS=guard,jab`; prancha de revisão: `tools/art_pipeline/preview_sheet.py`.
- A luta é desenhada em unidades de 640x360 e o nó GreyboxView é escalado 1,5x numa SubViewport de 960x540 (sprites em 1:1).
- Lotes: `calibrate_resolver.gd` (resolvedor x motor), `career_batch.gd` (M4, ~2,5 min), `world_years.gd` (M3, 10 anos).
- Capturas em HD (precisa de janela): `"$GODOT" --path . --resolution 1920x1080 --script res://tests/runner/screenshots.gd -- <pasta>`
- Smoke da cena de combate: `"$GODOT" --headless --path . --script res://tests/runner/smoke_combat.gd`

## Armadilhas conhecidas (Godot 4.7)
- Nomes de enum/classe que colidem com tipos globais da engine geram erro de parse: evite `Control`, `Corner`, `Side` em enums/classes e métodos com nomes de virtuais do `Object` como `_set`, `_get`, `_init` em uso indevido.
- Scripts com erro de parse carregam como GDScript "vazio"; o runner trata isso como falha (`can_instantiate()`).
- Em scripts `--script` (SceneTree), dê `await process_frame` antes de carregar cenas que usam autoloads.
- O render do Blender sai em sRGB: compare com a paleta convertida para sRGB ao quantizar (pipeline.py).
- Neste ambiente o heredoc do bash falha com certos textos: para edições grandes, grave um .js no scratchpad e rode com node.

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
- Smoke da cena de combate: `"$GODOT" --headless --path . --script res://tests/runner/smoke_combat.gd`

## Armadilhas conhecidas (Godot 4.7)
- Nomes de enum/classe que colidem com tipos globais da engine geram erro de parse: evite `Control`, `Corner`, `Side` (e confira outros nomes genéricos).
- Scripts com erro de parse carregam como GDScript "vazio"; o runner trata isso como falha (`can_instantiate()`).

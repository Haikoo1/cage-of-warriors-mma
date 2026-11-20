# Projeto Jaula (codinome)

Jogo de MMA 2.5D em pixel art para PC (Windows), com foco em modo carreira. Projeto em pré-produção.

- **Engine:** Godot **4.7.2-stable** (versão padrão, não .NET) — fixada em T-001.
- **Linguagem:** GDScript com tipagem obrigatória (avisos de declaração sem tipo são erro).
- **Estado atual:** fundação técnica (E-02B). Nenhuma mecânica de jogo implementada ainda.

## Abrir e rodar
1. Instale a Godot 4.7.2 e abra `project.godot` pelo gerenciador de projetos, ou rode `Godot_v4.7.2-stable_win64.exe --path .`.
2. A tela inicial mostra a versão e o estado dos dados de exemplo.

## Testes
```powershell
$env:GODOT_EXE = "C:\caminho\para\Godot_v4.7.2-stable_win64.exe"
.\tests\run_tests.ps1
```
Runner próprio sem dependências (T-009) em `tests/runner/`. Testes em `tests/unit/` (regras puras) e `tests/integration/` (dados, save, configurações do projeto).

## Estrutura
Ver `docs/architecture/PROJECT_STRUCTURE.md`. Resumo: `src/domain` (regras puras), `src/app` (autoloads, carga de dados, save), `src/presentation` (telas), `src/definitions` (tipos de dados), `data/` (definições .tres), `scenes/`, `tests/`, `docs/`.

## Documentação
Design em `docs/` (comece por `docs/GDD.md`), arquitetura em `docs/architecture/`, plano em `docs/ROADMAP.md`.

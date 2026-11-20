# Relatório da sessão autônoma — Projeto Jaula

> Data: 2026-11-20 (madrugada). Trabalho feito sem supervisão, por pedido do usuário ("siga trabalhando... não pergunte por aprovação... no final faça um relatório em .md e desligue meu computador").
> **Desligamento programado para 04:30** (horário do PC). Para cancelar: `shutdown /a` no terminal.

## Resumo em 30 segundos
- O jogo está **semi-pronto e jogável do começo ao fim**: menu principal → tutorial → Luta Rápida → carreira completa (criação com visual personalizado, treino, ofertas, lutas jogadas ou simuladas, rankings, cinturões, aposentadoria).
- **Menus e HUD em HD**, com ícones e cinturões estilo RPG. A luta continua em pixel art.
- **Sprites refeitos do zero, em camadas**, com **criador de visual** (pele, cabelo, cor do cabelo, barba, calção, luvas) e prévia animada.
- **Corpo feminino próprio** e **sprites de clinch e de chão**: os lutadores não viram mais formas cinza ao agarrar.
- **165 testes automatizados, 0 falhas.** Smokes de combate, sprites, Luta Rápida, carreira e tutorial passando.
- **Não gerei o .exe**: exportar exige baixar os *export templates* da Godot (~1 GB), e você pediu que downloads fossem autorizados antes. Veja "Como gerar o .exe".

## O que foi feito (por commit, do mais antigo ao mais novo nesta sessão)
| Commit | Entrega |
|---|---|
| `65e46d9` | **Menus em HD** (D-018): UI na resolução da janela com fonte do sistema e luta numa SubViewport 640×360 em pixel art. Arena com grade, público e holofotes. Sprites v1 refinados. Conteúdo de combate da 1.0: **9 golpes**, **meia-guarda**, **6 finalizações** (mata-leão, triângulo, chave de braço, kimura, katagatame, guilhotina), golpes no clinch |
| `84f65e0` | **Áudio sintetizado por código** (D-021): impactos, bloqueio, golpe no ar, queda, sino, público, cliques de menu |
| `56edac0` | **Carreira mais profunda**: relatório de scouting real, **rivalidades** (a provocação na entrevista cria rival), **contraproposta** de bolsa (tecla C), relação com cada organização, dicas do córner conforme a academia |
| `bb672b7` | **Calibração** do resolvedor de lutas simuladas contra o motor real. **Poda de aposentados** no save, que fica menor. **Suporte a gamepad** nos menus e na luta |
| `bee6ebf` | **Cortes e parada médica** (o médico pode encerrar a luta entre rounds) e **opção de desligar o sangue** |
| `2d0bbc2` | **Tutorial interativo com 11 lições**, cada uma verificada por eventos reais do combate (não basta apertar a tecla, é preciso acertar) |
| `93ee1e1` | **HUD e telas estilo RPG** (D-020): 17 ícones em pixel art gerados por código, **cinturão** na HUD em luta de título, tela de "NOVO CAMPEÃO", selo de nível, ficha de atributos com ícones |
| `c6d951e` | **Sprites refeitos em camadas** e **criador de visual** (D-019): veja abaixo |
| `c7ce8ba` | Correção: a vista de luta não depende mais de configuração global (smoke dos sprites voltou a passar) |
| `5517c88` | Documentação: marco M4, decisões D-018 a D-021, roadmap |
| `2aedb21` | Primeira versão deste relatório |
| `3e2987e` | **Luta Rápida com o seu visual**: padrão, aleatório (R) ou o do lutador da carreira. O adversário sempre usa calção de outra cor |
| `832d90b` | **Aba "6 Visual" na carreira** (barbeiro e equipamento): muda cabelo, cor, barba, calção e luvas com prévia animada, sem efeito nas lutas |
| `6075099` | **Biótipo feminino** (`f_medium`): menor, ombros estreitos, quadril largo, top esportivo na cor do calção. Cada lutador usa o corpo da sua divisão |
| `6e88173` | **Sprites de grappling**: clinch, por cima (ajoelhado) e por baixo (na guarda). **Correção importante do shader**, que escurecia todos os sprites e não trocava a cor do calção |

## Sprites e criador de visual (pedido "refazer do início" + "criador de skins")
- **Manequim novo** gerado no Blender por script: rosto (olho, sobrancelha, nariz, orelha), trapézio, peitoral, abdômen, bíceps, panturrilha, luvas com polegar e fita, calção com cós e faixa lateral, luz de contorno.
- **Renderização em 5 camadas** por animação: corpo, cabelo curto, moicano, coque e barba (85 PNGs, 17 animações, ~75 s de Blender). Cada camada esconde as outras como *holdout*, então a oclusão fica correta.
- **Quantização por camada em sRGB**: acabou com as manchas cinza/bege da versão anterior.
- **Shader de troca de paleta** (`assets/shaders/palette_swap.gdshader`) recolore em tempo real. Opções:
  - 8 tons de pele;
  - careca, curto, moicano ou coque;
  - 6 cores de cabelo;
  - barba;
  - 8 cores de calção;
  - 6 cores de luva.
- **Tela Nova Carreira**: seção "VISUAL" com prévia animada do lutador. A tecla **R** sorteia um visual.
- O visual do jogador fica salvo e aparece nas lutas da carreira. Os NPCs recebem visuais aleatórios (lutadoras sem barba). Na Luta Rápida, o adversário recebe um visual aleatório com calção de cor contrastante.

### Defeito encontrado e corrigido no fim da sessão
Ao conferir as capturas, vi que os dois lutadores apareciam com o mesmo calção azul e que os sprites estavam mais escuros que a paleta. Medi pixel a pixel e encontrei duas causas:
1. Na Godot 4.7, o `COLOR` de entrada do shader já vem multiplicado pela textura. Eu multiplicava de novo (0,80 × 0,80 = 0,64), o que escurecia tudo.
2. Arrays `vec3` em uniform ficam desalinhados, então o calção não encontrava a cor de origem.

Agora as cores saem exatas (medido). Há um teste de regressão e as duas armadilhas estão documentadas no próprio shader.

## Medições de balanceamento
- **M3 — mundo simulado** (`docs/playtest/M3_MUNDO.md`): resolvedor calibrado contra o motor real e 10 anos de mundo sem degenerar.
- **M4 — carreira** (`docs/playtest/M4_CARREIRA.md`), em 10 carreiras × 8 anos com política automática:
  - antes: 83% de vitórias, 9/10 chegavam à elite, US$ 1,6 milhão (fácil demais);
  - agora: **68% de vitórias, 6/10 chegam à elite, 2,4 títulos por carreira, US$ 494 mil**.

## Como testar quando acordar
1. Rode o jogo: `C:\Users\sousa\Downloads\Godot_v4.7.2-stable_win64.exe --path C:\Users\sousa\Downloads\Projetos_DEV\mma-25d`, ou abra o projeto no editor e aperte F5.
2. No menu principal:
   - **Tutorial**: 11 lições guiadas.
   - **Luta Rápida**: escolha os estilos e lute contra a IA.
   - **Nova Carreira**: monte o visual (setas para mudar, R para sortear) e avance semanas, treine, aceite ofertas e lute. A aba **6 Visual** troca o visual depois.
   - **Luta Rápida**: a última linha, "Seu visual", usa o lutador da carreira se houver uma carregada.
   - **Opções**: controles, sangue, volume.
3. Testes automáticos: `.\tests\run_tests.ps1 -Godot C:\Users\sousa\Downloads\Godot_v4.7.2-stable_win64.exe`. Esperado: **165 testes, 0 falhas**.
4. Capturas em HD, inclusive o grappling: `tests/runner/screenshots.gd` e `tests/runner/shot_grapple.gd`, com resultado em `tools/screenshots/`.

## Como gerar o .exe (não feito, exige download)
1. Na Godot: *Editor → Gerenciar modelos de exportação → Baixar e instalar* (~1 GB).
2. *Projeto → Exportar → Adicionar → Windows Desktop → Exportar projeto*.
Não fiz isso porque você pediu que downloads fossem autorizados antes.

## Limitações conhecidas e próximos passos sugeridos
- **Arte**: ainda é um manequim de segmentos rígidos, mais detalhado que antes mas sem malha com *skinning*. O chão usa 2 poses genéricas (por cima e por baixo) para as 5 posições. As montadas, as costas e as finalizações não têm pose própria, e a posição SR segue em greybox. Próximo passo: modelo humanoide com esqueleto e poses por posição (E-10).
- **Biótipos**: há `m_medium` e `f_medium`. Lutadores leves e pesados usam o médio da sua divisão, na escala física correta. Faltam corpos próprios para leves e pesados.
- **Áudio**: sintetizado e provisório (D-021). Falta trilha.
- **Playtest humano**: os números do M4 estão saudáveis, mas falta você julgar se as decisões da carreira são divertidas.
- **Exportação**: depende dos export templates (acima).

## Arquivos úteis
- Design: `docs/GDD.md` e documentos especializados. Decisões: `docs/DECISIONS.md`. Plano: `docs/ROADMAP.md`.
- Marcos medidos: `docs/playtest/M1_COMBATE.md`, `M2_ARTE.md`, `M3_MUNDO.md`, `M4_CARREIRA.md`.
- Capturas em HD: `tools/screenshots/`.

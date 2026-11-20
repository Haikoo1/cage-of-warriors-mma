# Conteúdo base do Discord — Projeto Jaula

Cada bloco abaixo é uma mensagem pronta para colar (todas abaixo de 2000 caracteres). Fixe a primeira mensagem de cada canal.

---

## CENTRAL

### #roadmap
```
# 🗺️ Roadmap — Projeto Jaula
Jogo de MMA 2.5D em pixel art para PC, com foco no **Modo Carreira**. Desenvolvido por uma pessoa só, sem prazos fixos.

**Princípio:** combate primeiro, arte depois, conteúdo em massa por último.

✅ **E-01** Documento de design (GDD)
✅ **E-02** Arquitetura técnica e fundação na Godot 4
✅ **E-03** Movimento e trocação (greybox)
✅ **E-04** Grappling: clinch, quedas, sprawl, posições de solo, finalização
✅ **E-05** Luta completa: rounds, árbitro, juízes, IA, Luta Rápida — *marco M1*
✅ **E-06** Teste do pipeline de arte (3D → pixel) — *marco M2*
🧪 **E-07** Núcleo da carreira: criação, calendário, treino, academias, lesões, pesagem — *aguardando playtest*
🧪 **E-08** Mundo: organizações, eventos, rankings, contratos
🧪 **E-09** Economia, reputação, mídia, rivalidades e aposentadoria
🎨 **E-10** Arte e UI final ← **estamos aqui**
⏳ **E-11** Conteúdo completo (todas as categorias e animações)

Legenda: ✅ concluído · 🧪 implementado, em teste · 🎨 em andamento · ⏳ futuro
```

### #changelog
```
# 📜 Changelog
Aqui sai um resumo de cada atualização. Formato: **data — o que mudou**.

**2026-11-20**
• HUD de luta no estilo de transmissão de TV + HUD de dano opcional
• Sprites novos no estilo da referência (189 px), luta em 960×540
• Criador de personagem ampliado: 4 físicos, 8 cabelos, 4 barbas, cores de pele e cabelo
• Sprites de grappling (clinch, por cima, por baixo) e biótipo feminino
• Aba Visual na carreira: barbeiro e equipamento com prévia animada
• Luta Rápida usa o visual do seu lutador (padrão, aleatório ou da carreira)

**2026-11-19**
• Combate em pé e grappling aprovados em playtest
• Primeira luta completa com árbitro, juízes e IA
```

---

## PLANEJAMENTO

### #backlog
```
# 📋 Backlog
O que está na fila, por prioridade. Sugestões vão em #ideias; o que for aceito vem pra cá.

**🔥 Agora**
• Modelo humanoide com skinning para os sprites
• Animações de solo (guarda, lateral, montada, costas)
• Playtest da carreira (2 anos de jogo)

**⏭️ Próximo**
• Balanceamento da IA e do resolvedor de lutas simuladas
• Mais arenas e variações de jaula
• Polimento das telas da carreira

**💭 Depois**
• Todas as categorias de peso
• Catálogo completo de golpes e finalizações
• Mais biótipos, cabelos e equipamentos

Formato de item: `[ID] título — status`
```

### #bugs
```
# 🐞 Reportar bugs
Use este modelo (uma mensagem por bug):

**Título:** curto e direto
**Versão:** (ex.: build de 2026-11-20)
**Modo:** Luta Rápida / Carreira / Treino / Criador
**Passos:**
1.
2.
3.
**Esperado:**
**O que aconteceu:**
**Frequência:** sempre / às vezes / uma vez
**Anexos:** print, vídeo ou arquivo de save

Reações usadas pela moderação:
👀 visto · 🔁 reproduzido · 🛠️ corrigindo · ✅ corrigido · ❌ não é bug
```

### #decisoes
```
# ⚖️ Decisões de design
Registro das decisões já tomadas, pra ninguém precisar perguntar duas vezes. Discussões vão em #ideias.

• **Combate antes de tudo** — a luta precisa ser divertida em greybox antes de receber arte.
• **2.5D com profundidade (eixo Z)** — dá pra sair da linha do golpe; jab e direto erram se você mudar de faixa.
• **Arte 3D → pixel** — personagens modelados no Blender e renderizados como pixel art, com troca de cor por shader (pele, cabelo, shorts).
• **Sprites a 189 px, luta em 960×540** (D-022).
• **HUD estilo transmissão de TV**, com HUD de dano opcional (D-023).
• **Nada de marcas reais** — organizações e lutadores são fictícios; usamos "jaula", não "Octagon".
• **Números de balanceamento são provisórios** até passarem por playtest.
```

---

## GAME DESIGN

### #visao-geral
```
# 🥊 Visão geral — Projeto Jaula
*(codinome)*

Um jogo de MMA em **pixel art 2.5D** para PC, centrado no **Modo Carreira**: você cria um lutador do zero, escolhe academia e treinador, treina semana a semana, faz a pesagem, assina contratos, sobe no ranking e decide quando parar.

**Pilares**
1. **Luta que parece MMA** — trocação, clinch, quedas e chão conectados, sem estado sem saída.
2. **Carreira com consequência** — fadiga, lesões, corte de peso, reputação e dinheiro importam.
3. **Mundo vivo** — outros lutadores evoluem, ganham, perdem e se aposentam enquanto você treina.

**Modos:** Carreira · Luta Rápida · Treino
**Motor:** Godot 4 · **Plataforma:** Windows
```

### #combate
```
# 👊 Combate
**Em pé:** movimento em X e Z (profundidade), guarda, esquiva, contra-golpe e dano por zona (cabeça, corpo, pernas). Golpes retos erram se o oponente sai da faixa.
**Fôlego:** todo golpe e defesa gasta. Cansado, você bate mais fraco e se defende pior.
**Limiar de Choque:** acúmulo de dano que leva a knockdown e nocaute.
**Grappling:** clinch, grade, quedas e sprawl. No chão: Guarda, Lateral, Montada e Costas, com transições disputadas (Defendido / Resistiu / Passou).
**Finalizações:** disputa entre os dois lutadores.
**Regras:** rounds, árbitro, três juízes e decisão por pontos.

Dúvida sobre como algo funciona? Pergunte aqui.
```

### #sprites
```
# 🧍 Sprites
**Como são feitos:** corpo modelado e animado no Blender, renderizado em 3/4 e convertido em pixel art com paleta limitada.
**Escala:** 189 px de altura em jogo.
**Camadas:** corpo (4 físicos) + cabelo (8) + barba (4). Cores de pele, cabelo e equipamento trocadas por shader.
**Biótipos:** masculino e feminino.

**Prontos:** guarda, golpes básicos, clinch, por cima e por baixo
**Em produção:** animações de solo e modelo com skinning

Poste aqui comparações, prévias e feedback de leitura (silhueta, contraste, animação).
```

### #interface-ui
```
# 🖥️ Interface / UI
• **HUD de luta** no estilo de transmissão de TV: nomes, round, tempo e Fôlego.
• **HUD de dano opcional**: mostra cabeça, corpo e pernas de cada lutador.
• **Telas da carreira:** calendário semanal, treino, academia, contratos, ranking e aba Visual (barbeiro e equipamento com prévia animada).
• **Criador de personagem** com físico, cabelo, barba e cores.
• UI em HD, separada da luta em pixel art.

Feedback de legibilidade e fluxo de telas é bem-vindo, com print.
```

### #arenas-octogono
```
# 🏟️ Arenas e jaula
A luta acontece numa **jaula de oito lados** vista em 2.5D. A grade é parte do jogo: dá pra pressionar o oponente nela e lutar em clinch contra a grade.

**Planejado**
• Academias e eventos pequenos (luz forte, público pequeno)
• Eventos regionais
• Grandes eventos (telão, iluminação de palco, público cheio)

Usamos "jaula" de propósito: nenhuma organização ou arena real é reproduzida. Mande referências de clima e iluminação aqui.
```

### #efeitos-visuais
```
# ✨ Efeitos visuais
O que existe ou está planejado:
• Faísca e tremor de tela no impacto, mais fortes em golpes limpos
• Flash de knockdown e câmera lenta no nocaute
• Suor e cansaço visual com Fôlego baixo
• Texto de feedback no grappling: Defendido / Resistiu / Passou
• Luzes e flashes de câmera do público

Regra: efeito ajuda a ler a luta, nunca esconde o que está acontecendo.
```

### #icones-e-badges
```
# 🏅 Ícones e badges
**No jogo:** ícones estilo RPG para atributos, treinos, lesões, contratos e conquistas.

**No servidor (cargos):**
🥋 **Faixa-branca** — entrou no servidor
🥊 **Sparring** — testou uma build e deu feedback
🐞 **Caçador de bugs** — reportou um bug confirmado
🏆 **Campeão** — contribuição de destaque
🛠️ **Dev** — equipe do projeto

Ideias de ícone ou badge? Poste aqui.
```

---

## LABORATÓRIO

### #ideias
```
# 💡 Ideias
Tem uma ideia para o jogo? Uma mensagem por ideia:

**Ideia:** em uma frase
**Por quê:** o que melhora na experiência
**Onde:** Combate / Carreira / Visual / Outro

Reaja com 👍 nas que você quer ver. As mais votadas são avaliadas e, se aceitas, vão para o #backlog.
Nem toda ideia entra, mas todas são lidas.
```

### #prototipos
```
# 🧪 Protótipos
Testes rápidos, experimentos e coisas que podem ser descartadas. Nada aqui é versão final.

Formato:
**O que é:**
**O que estou testando:**
**Mídia:** GIF, vídeo ou print
**Resultado:** aprovado / descartado / em teste

Primeiro protótipo: combate em greybox (formas simples), aprovado em playtest antes de qualquer arte.
```

---

## ARQUIVOS

### #documentacao
```
# 📚 Documentação
Resumo dos documentos de design do projeto:

• **GDD** — visão geral e todos os sistemas
• **Combate** — movimento 2.5D, trocação, grappling, regras, IA
• **Carreira** — criação, calendário, treino, contratos, rankings, economia
• **Personagens** — atributos, estilos, categorias de peso, evolução
• **Direção de arte** — resolução, escala, animações, cenários, UI
• **Glossário** — vocabulário oficial (Fôlego, Limiar de Choque, Disputa…)

Trechos e resumos são postados aqui conforme o projeto avança.
```

### #versoes-antigas
```
# 🗄️ Versões antigas
Builds anteriores, para comparar e ver a evolução.

**Formato:** `vX.Y — data — principais mudanças — link`

Marcos até agora:
• **M1 (2026-11-20)** — luta completa em greybox, aprovada
• **M2 (2026-11-20)** — pipeline de arte 3D → pixel escolhido

Builds antigas podem ter bugs já corrigidos e saves incompatíveis com a versão atual.
```

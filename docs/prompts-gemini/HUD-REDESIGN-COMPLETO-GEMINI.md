# Prompt Gemini — Redesenhar a HUD inteira do Legendary Catch

> Cole este arquivo inteiro no Gemini **junto com o PDF** `art/ui-reference/LegendaryCatch-Interfaces.pdf`
> (anexe o PDF na conversa). O PDF tem capturas reais de TODAS as telas.

---

## 0. Missão

Você é um(a) UI/UX artist + programador Roblox (Luau). Quero **redesenhar a HUD completa** do jogo
**Legendary Catch** (pesca + coleção, Roblox, mobile-first, público **infantil**).

Estilo desejado: **bem colorido, animado, infantil e "dopaminado"** — jogo de celular tipo Pet/Fishing
Simulator. A referência de estilo são **os ícones do menu hambúrguer** (página 2 do PDF): botões
gordinhos, gradiente vivo, borda grossa escura, brilho/gloss no topo, ícone ilustrado grande,
rótulo na base, cantos bem redondos. **Tudo na HUD deve parecer da mesma família desses ícones.**

## 1. O que está no PDF (anexo)

`LegendaryCatch-Interfaces.pdf` — 16 páginas, cada uma com a legenda do que é a tela:
1 HUD base · 2 menu hambúrguer (ESTILO ALVO) · 3 Coleção · 4 Oficina · 5 Desafios · 6 Conquistas ·
7 Maré Nova · 8 Placar · 9 Ajustes · 10 Aquário · 11 Loja Robux · 12 Barra de Força ·
13 fluxo de pesca (sorte "1 em N", revelação) · 14 Roleta/CatchShow · 15 índice das telas que
existem no código mas sem captura (toasts, DailyGift, eventos, tutorial, guia, portais, treino…).

**Leia o PDF inteiro antes de responder.** Redesenhe **todas** as telas dele.

## 2. Como a HUD existe hoje (fatos, não invente)

- 100% feita por código Luau (`--!strict`), cliente. Pasta `src/client/Features/Hud/`:
  `init.luau` (ScreenGui `AdventureHud`: Coins, FishingLevel, NextGoal, RecentRarity, Perks, Toast,
  QuickMenu + `MoreButton`), `Panel.luau` (`Panel.create(nome, título, cor, ...)` → cabeçalho colorido +
  botão X + corpo creme; helpers `Panel.label/button/card/tintButton/stack`), `Art.luau`
  (`Art.panel/image/button/caption`), `Motion.luau` (`Motion.mount(alvo)` → `.pulse()`),
  `RodHotbar.luau`, `FishingPower.luau`, `ZoneHud.luau`, `Assets.luau` (IDs de imagens enviadas).
- Tema: `src/shared/UiTheme.luau` — `ink, outline, cream, gold, crystal, rose, track…`, fonte
  `FredokaOne`, `Theme.corner/surface/iridescent`, `Theme.rarity` (cores por raridade).
- Painéis em `Features/{Collection,Shop,Missions,Achievements,Prestige,Leaderboard,Settings}`, pesca em
  `Features/Fishing/*` (Ui, PowerBar, Minigames, Roulette, OddsMoment, RevealCard, CatchShow…).
- Os ícones atuais do menu são **imagens** (`rbxassetid://…`) feitas por IA e enviadas — por isso têm
  aquele visual. O resto da HUD (moedas, nível, barras, painéis, botões) é UIStroke/UICorner simples e
  está **fraco** perto dos ícones. Esse é o problema a resolver.
- Raridades: Comum verde-água, Incomum azul, Raro roxo, Épico rosa, Lendário dourado, Místico.
- Pronto e funcionando: `src/shared/Vfx/{VfxKit,SfxKit,Palette}` (partículas/anéis/confete/som) —
  **reuse**, não refaça. `SfxKit` está mudo (ids 0 = trocar depois).

## 3. Regras duras

1. **Não edite** arquivos de `Hud/`, `Collection/`, `Shop/` etc. diretamente. Entregue
   **módulos novos** (camada de tema + componentes) que eu integro. Dê, pra cada tela, **o diff exato /
   o trecho** a trocar (nome do arquivo + função + o que substituir), ou um módulo `HudSkin`
   que recebe o `ScreenGui` e re-estiliza achando elementos **pelo nome** (`Coins`, `FishingLevel`,
   `QuickMenu`, `MoreButton`, `NotificationBadge`, `LevelFill`…).
2. `--!strict`, `game:GetService`, `task.wait/spawn/delay` (nunca `wait()`), conexões desconectadas,
   `Parent` por último, `ScreenGui.ZIndexBehavior = Sibling`. Sem dependências externas.
3. **Mobile primeiro**: tudo em Scale + `UIAspectRatioConstraint`/`UISizeConstraint`, alvos de toque
   ≥ 44 px, nada sob o botão de pular nem sobre a hotbar/joystick. Teste mentalmente 360×640 e 1920×1080.
4. **Performance**: poucos tweens simultâneos, reaproveite instâncias, sem `Heartbeat` pesado por
   elemento (um único loop compartilhado para brilhos/pulsos).
5. **`ReduceEffects`** (atributo do Player = true) desliga shimmer/partículas/tremida/flash; o layout
   continua igual. Crianças: nada de flash agressivo, nada de dark pattern, sem cronômetro opressivo.
6. O cliente **nunca decide** moeda/item/raridade; só mostra dados do servidor.
7. Textos de UI ficam em `src/shared/StringsUi.luau` (PT-BR). Código e comentários em inglês.
8. Não invente API do Roblox. Se não tiver certeza, diga.

## 4. O que eu quero (entregáveis)

### A) Sistema de design ("UI Kit") — `UiKit.luau`
Componentes reutilizáveis, todos no estilo dos ícones do menu (gradiente vertical vivo + `UIStroke`
grossa escura + gloss branco translúcido no topo + sombra "de baixo" + cantos grandes):
`candyButton`, `candyPanel` (substitui o cartão creme chato), `candyPill` (moedas/nível),
`candyBar` (barra de progresso com listras animadas e brilho passando), `candyBadge` (bolinha de
notificação com pop), `candyTab`, `candyToggle`, `candySlider`, `candyCard` (carta de item/missão/
conquista), `candyHeader` (título com ícone). Paleta: ciano cristal, rosa/lilás, dourado, laranja,
verde-limão, roxo — saturadas, **cada tela com uma cor-tema** (como os botões do menu).

### B) Animação de tudo ("dopamina")
- Botões: **squash & stretch** ao tocar, pulinho elástico, brilho que varre de tempos em tempos.
- Moedas: contagem rolando + **moedinhas voando** até o contador + pulo do ícone ao ganhar.
- XP/nível: barra enchendo com brilho; **level-up** com estouro, confete e selo "NÍVEL UP!".
- Painéis: abrem com "pop" elástico (overshoot), fecham rápido; itens da lista entram em cascata.
- Menu hambúrguer: ícones saltam em leque ao abrir, balançam de leve parados (idle).
- Badges/avisos: pulsam; toasts entram deslizando com bounce e saem suave.
- Idle: cada ícone grande respira/balança em fase diferente (nunca todos juntos).
- Barra de Força, Roleta, "1 em N", Carta da criatura: mais brilho e cor, mas **sem tampar o jogo**.

### C) Redesenho tela a tela (todas as do PDF)
Para **cada página do PDF**, entregue: (1) layout novo (descrição curta + o código do componente),
(2) cor-tema, (3) animações, (4) o que muda em relação à captura. Ordem de prioridade:
**1) HUD base + menu hambúrguer → 2) Barra de Força/pesca/roleta/"1 em N" → 3) Coleção, Oficina,
Desafios, Conquistas, Placar, Ajustes → 4) Aquário, Maré Nova, Loja → 5) toasts, DailyGift, eventos,
tutorial, guia, portais, treino (descritos na última página).**
Os "círculos laranja soltos" da Coleção/Conquistas são ícones faltando: substitua por ícone ou emoji
bonito dentro de um `candyBadge`.

### D) Ícones: Luau **e** imagem
Ícones ilustrados (como os do menu) são **imagens**; Luau não desenha ilustração. Então:
1. Faça o máximo em Luau (formas, gradientes, emojis grandes com stroke, `ViewportFrame` p/ 3D).
2. Para o que precisar de arte, escreva uma **lista de prompts de geração de imagem** (um por ícone:
   moeda, nível/estrela, XP, hambúrguer, X, cadeado, presente, relógio, ✔, seta, coroa, troféu, peixe por
   raridade, vara, baú, gemas, etc.) — todos **no mesmo estilo dos ícones do menu** (3D cartoon
   gordinho, borda escura grossa, brilho, fundo transparente, 512×512, sem texto). Eu gero e envio; você
   deixa os `rbxassetid://` num único `IconIds.luau` com `-- TROCAR` e um **fallback em Luau** (emoji)
   enquanto não houver id.

### E) Integração
- Um `HudSkin.luau`/`HudJuiceFx` que se aplica sozinho (`start()`, ordem alta) e re-estiliza o que já
  existe pelo nome, **sem quebrar** os scripts atuais. Lista de nomes de instâncias que você assume.
- Passo a passo de instalação (caminho de cada arquivo, ordem), e checklist de teste.
- Marque claramente o que **depende de eu mexer em arquivo de outra IA** (Codex é dono de `Hud/**`).

## 5. Formato da resposta

1. Responda **em PT-BR**, objetivo. Comece com um **resumo do estilo** (paleta + regras do kit) em ≤ 10 linhas.
2. Depois os arquivos, **um bloco de código por arquivo**, com o caminho no título
   (ex.: `src/shared/UiKit.luau`). Código completo, sem "…" e sem pseudo-código.
3. Se a resposta ficar grande, entregue **por etapas** (A+B primeiro, depois C por grupos) e diga
   "continuo?" no fim de cada etapa.
4. No final: lista "**o que preciso que você me mande**" (imagens, sons, decisões).

## 6. Não esqueça

Infantil, colorido, animado, alegre — mas **legível**: texto sempre com contorno, contraste alto,
números grandes. Se tudo brilhar, nada brilha: **comum é simples, raro é festa**.

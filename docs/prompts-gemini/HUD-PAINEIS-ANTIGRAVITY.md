# Prompt Antigravity — HUD dos painéis no estilo do menu hambúrguer

> Abra a pasta do projeto no Antigravity (`C:\Users\Evojota\dev\jogo ainda sem nome`) e cole este arquivo
> inteiro no agente. Ele tem acesso ao PDF e aos prints dentro do repositório.

## 0. Missão

Jogo: **Legendary Catch** (Roblox, pesca + coleção, mobile-first, público infantil).
Redesenhar **todas as telas/painéis** para ficarem **idênticas em estilo aos ícones do menu hambúrguer**:
3D cartoon gordinho, gradiente vivo, **borda escura grossa**, gloss branco no topo, sombra de baixo,
cantos bem redondos, bem colorido, infantil, "dopaminado".

**NÃO redesenhar:** (a) o próprio menu hambúrguer e seus ícones (já estão ótimos, são a referência);
(b) a HUD da tela inicial (moedas, nível, próxima meta, raridade recente, perks, botão do menu).

## 1. Leia antes de tudo (no repositório)

- `art/ui-reference/LegendaryCatch-Interfaces.pdf` — capturas reais. **Página 2 = estilo alvo.**
  Redesenhar as páginas 3–14 (Coleção, Oficina, Desafios, Conquistas, Maré Nova, Placar, Ajustes,
  Aquário, Loja Robux, Barra de Força, fluxo de pesca/"1 em N"/revelação, Roleta) + itens da página 15
  (toasts, DailyGift, eventos, tutorial, guia, portais, treino). Pule páginas 1 e 2.
- `art/ui-reference/src/*.png|jpg` — as mesmas capturas em tamanho cheio.
- `art/ui-reference/ICON_PROMPTS_512x512.md` — prompts de ícone já escritos (reaproveite o estilo).
- `src/client/Features/Hud/Assets.luau` — IDs dos ícones atuais do menu (olhe a arte de perto e copie o estilo).
- `src/client/Features/Hud/Panel.luau` e `Art.luau` — **todos os painéis nascem de `Panel.create(...)`**,
  `Panel.button/card/label/tintButton/stack`. Reskinar essas funções reskina tudo de forma nativa.
- `src/shared/UiTheme.luau` — cores, fonte `FredokaOne`, `Theme.rarity`.
- `CONTEXTO_MESTRE.md`, `AGENTS.md`, `docs/COORDENACAO.md` — regras do projeto.

## 2. Por que a tentativa anterior falhou (não repita)

Uma camada `HudSkin` por cima, que re-estilizava por nome, deu mudança sutil e o João odiou.
O look dos ícones do menu vem de **imagens ilustradas**, não de UIStroke. Então:
**gere arte de verdade e use-a na estrutura dos painéis (Panel.create etc.), não como overlay.**

## 3. Entregáveis

### A) Arte (imagens) — gere de fato, salve em `art/ui-generated/`
Mesmo estilo dos ícones do menu (3D cartoon gordinho, borda escura grossa, gloss, fundo transparente,
PNG, **≤ 1024 px**, sem texto embutido). Mínimo:
1. **Moldura de painel 9-slice** (corpo + cabeçalho/faixa de título) em ~7 cores-tema:
   ciano (Coleção), laranja (Oficina), verde-limão (Desafios), dourado (Conquistas),
   roxo (Maré Nova), rosa (Placar), azul-aço (Ajustes). Definir os `SliceCenter`.
2. **Botão** gordinho 9-slice (normal, pressionado, desativado) em verde, azul, laranja, rosa, vermelho (fechar).
3. **Botão X de fechar**, **abas** (ativa/inativa), **cartão de item** (normal / selecionado / bloqueado),
   **barra de progresso** (trilho + preenchimento 9-slice), **toggle**, **slider**, **bolinha de badge**.
4. **Ícones**: cadeado, ✔, seta, coroa, troféu, presente, relógio, estrela, gema, baú, vara, peixe,
   moeda, XP, engrenagem, som, "reduzir efeitos"… (use `ICON_PROMPTS_512x512.md` como base e complete).
5. Moldura de **carta de criatura por raridade** (Comum, Incomum, Raro, Épico, Lendário, Místico):
   quanto mais raro, mais festa; comum é simples.
Liste cada arquivo + tamanho + 9-slice em `art/ui-generated/MANIFEST.md`.
(Eu faço o upload no Roblox e te passo os `rbxassetid://`; até lá use fallback em Luau/emoji.)

### B) Código Luau
- Reescrever **nativamente** `Panel.create`, `Panel.button`, `Panel.card`, `Panel.tintButton` e `Art.*`
  para usarem as imagens 9-slice, mantendo **assinaturas e nomes de instâncias** (outros arquivos dependem deles).
- Novo módulo `src/shared/Ui/UiAssets.luau` com os ids (`-- TROCAR` onde faltar) e fallback em Luau.
- Telas com layout próprio (Barra de Força, Roleta, "1 em N", RevealCard, DailyGift, tutorial, portais…):
  entregar o trecho a trocar (arquivo + função) **ou** editar direto se for só visual.
- Animações (sem tampar o jogo): botão com squash & stretch ao tocar e brilho que varre de tempos em tempos;
  painel abre com pop elástico e fecha rápido; itens de lista entram em cascata; badges pulsam;
  ícones grandes respiram em fases diferentes. **Um único loop compartilhado** para brilhos/pulsos.
- Reusar `src/shared/Vfx/{VfxKit,SfxKit,Palette}` (confete, anéis, som). Não refazer.

### C) Cor-tema por tela
Uma cor por painel (lista acima), usada em moldura, cabeçalho e botões principais.

## 4. Regras duras

1. `--!strict`, `game:GetService`, `task.wait/spawn/delay` (nunca `wait()`), conexões com dono e desconectadas,
   `Parent` por último, `ScreenGui.ZIndexBehavior = Sibling`. Sem dependências novas.
2. Mobile primeiro: Scale + `UIAspectRatioConstraint`/`UISizeConstraint`, alvos ≥ 44 px; testar mentalmente
   360×640 e 1920×1080. Nada sob o botão de pular nem sobre hotbar/joystick.
3. `ReduceEffects` (atributo do Player = true) desliga shimmer/partículas/tremida/flash; layout igual.
   Sem flash agressivo, sem dark pattern, sem cronômetro opressivo.
4. O cliente **nunca decide** moeda/item/raridade: só mostra dados do servidor.
5. Textos de UI em `src/shared/StringsUi.luau` (PT-BR). Código e comentários em inglês.
6. **Não mexer:** `src/server/**`, `src/shared/Config/**`, `Net.luau`, `Types.luau`, mapa/hub, e a HUD da tela
   inicial (`Hud/init.luau`: Coins, FishingLevel, NextGoal, MoreButton, QuickMenu…).
7. `Hud/Panel.luau`, `Art.luau` etc. pertencem ao Codex (`docs/COORDENACAO.md`). Antes de editar,
   escreva no Mural de `docs/COORDENACAO.md` o que vai tocar. Commits só dos seus arquivos, **sem push**.
8. Não invente API do Roblox; se não tiver certeza, diga.
9. Não commite nada que o João não pediu; não apague os arquivos de `art/ui-reference/`.

## 5. Ordem de trabalho (pare e mostre ao final de cada etapa)

1. Arte-base: molduras, botões, X, cartões, barras (A.1–A.3) + `MANIFEST.md`. **Mostre as imagens.**
2. Reskin nativo de `Panel.*`/`Art.*` com fallback. Capturas de Coleção, Oficina e Desafios (dá pra abrir
   cada painel com o atributo de Player `DevOpenPanel` = nome, só no Studio).
3. Restante dos painéis + pesca/Roleta/"1 em N"/Carta.
4. Ícones faltantes, toasts, DailyGift, eventos, tutorial, guia, portais, treino.

No fim: lista do que preciso enviar (uploads, sons, decisões) e checklist de teste. Responda em PT-BR, objetivo.

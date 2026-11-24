# Prompt para o Codex: pendências visuais da pesca (24/11/2026)

Cole este arquivo inteiro no Codex aberto na pasta do projeto. Leia antes: `AGENTS.md`, `docs/COORDENACAO.md` (Mural), `docs/REVISAO-VISUAL-PESCA.md`.
Regra de sempre: o cliente só mostra o que o servidor mandou. Tudo com `ReduceEffects`. Mobile primeiro. Não mexa em `src/server/**`, `Config/**`, `Fishing/init.luau`, `CastCutscene.luau`, `PowerBar.luau`, `CatchShow.luau` (são do Claude).

Ligar para testar (Studio, Server, só dentro do Play, nunca salvar):

```lua
game.ReplicatedStorage:SetAttribute("FishingPower", true)
game.ReplicatedStorage:SetAttribute("FishingRoulette", true)
```

## 1. Revelação 3D começando da mão
`Reveal.luau`: quando `info.fromShow == true`, o peixe já voou até a mão no show da captura. Não refaça a entrada pela água: comece o modelo na mão do personagem (ou no centro da tela, na escala em que o show terminou) e siga para o giro/anel/nome/estrelas.

## 2. Minigames com som e impacto
`Minigames/Reel|Precision|Rhythm`: use `Features/Audio` (`Audio.play(cue, volume, speed)`; cues `hit`, `miss`, `click`). Clique por acerto, parada de ~60 ms no acerto perfeito, tremida pequena no erro. Respeite `ReduceEffects`.

## 3. Linha e boia no lançamento
`Line.luau`: rastro de luz mais forte na boia durante o arremesso (combina com a cutscene) e respingo maior ao cair na água.

## 4. HUD do Poder de Pesca e painel do campo
Pendente desde `docs/PLANO-TREINO-PODER.md` §5 e §7.

## 5. Coleção com mutação e maior tamanho
`Features/Collection`: mostrar mutação e maior tamanho (plano da roleta, R4).

Ao começar e terminar cada item, escreva no Mural (`docs/COORDENACAO.md`, só adicionar no fim). Commit só dos seus arquivos.

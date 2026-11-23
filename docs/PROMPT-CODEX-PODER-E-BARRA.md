# Prompt para o Codex: barra de força, momento das chances e Poder de Pesca (visual)

Cole este arquivo inteiro no Codex aberto na pasta do projeto. O servidor já está pronto (Claude, 23/11/2026), atrás de duas flags **desligadas**. Leia antes: `AGENTS.md`, `docs/COORDENACAO.md` (Mural), `docs/PESCA-FORCA-CONTRATO.md`, `docs/TREINO-PP-CONTRATO.md`, `docs/PLANO-PESCA-FORCA-ODDS.md` §4–§5 e `docs/PLANO-TREINO-PODER.md` §5 e §7.

Ligar para testar (Studio, Server):

```lua
game.ReplicatedStorage:SetAttribute("FishingPower", true)
game.ReplicatedStorage:SetAttribute("TrainingPower", true)
```

Regra de sempre: **o cliente só mostra** o que o servidor mandou (faixa, "1 em N", poder). Tudo pulável e com `ReduceEffects` (sem tremida, sem flash, sem partícula pesada). Máximo de 3 pulsos de luz por segundo. Mobile primeiro.

## Tarefa 1: barra de força (P3)

Arquivo: `src/client/Features/Fishing/PowerBar.luau` (hoje é um placeholder funcional do Claude; **pode reescrever**). Mantenha a interface:

- `PowerBar.show(layout, aimStart)`: `layout` = `{ {band, from, to} }` 0..1; o ponteiro segue `FishingConfig.aimPosition(workspace:GetServerTimeNow() - aimStart)`. **Não invente outra fórmula**: o servidor calcula a faixa com essa mesma.
- `PowerBar.result(band)`: congela e mostra o resultado (`Strings.powerBand[band]`), some sozinho.
- `PowerBar.hide()`: limpa tudo (o controlador chama em qualquer cleanup).

Visual pedido: moldura de madeira e cristal, faixas com brilho (roxo com shimmer), ponteiro com rastro, "PERFEITO!" grande no roxo, tremida leve no vermelho. Barra a ~70% da altura, sem cobrir o botão de pular nem a hotbar. O toque é o `Tool.Activated` normal (o controlador já manda o `PowerTap`).

## Tarefa 2: cutscene do arremesso (P3)

Plano §4 (`docs/PLANO-PESCA-FORCA-ODDS.md`): ≤ 2,2 s, pulável. Câmera atrás do ombro durante a mira, vara para trás (procedural; ombro é `AnimationConstraint`, armadilha 9 do AGENTS.md), lançamento quando chega o evento `cast` (`powerBand` diz a força: distância/altura do arco e cor do anel d'água). Roxo: câmera lenta de 0,15 s e anel duplo. Gancho: o controlador (`Fishing/init.luau`, do Claude) chama `PowerBar.show/result`; se precisar de mais ganchos (por exemplo `onAim`/`onCastBand` para a câmera), peça no Mural que o Claude adiciona.

## Tarefa 3: momento das chances (P4)

Entre "ganhou o minigame" e a revelação atual. Dado: `caught.odds` ("1 em N" real; `nil` = pular este momento). Plano §5:

- Silhueta = a criatura real em preto num `ViewportFrame` (o mesmo modelo de `ReplicatedStorage.Creatures`), crescendo por degrau: `<=50`, `<=150`, `<=500`, `<=2.000`, `<=10.000`, `<=50.000`, `>50.000`.
- Contador "1 em N" sobe em escala logarítmica até o N final; a cada degrau, sobe um tamanho, troca de cor e um "bum" grave.
- Tempos: até 1,2 s para Comum/Incomum; espetáculo longo só a partir de 1 em 2.000; Mística 6 a 8 s. Pular sempre disponível depois da primeira vez naquele degrau.
- **Trocar no `RevealCard.luau`**: hoje ele mostra `Fishing.baseOdds(rarity, #ofRarity)`, que assume chance igual dentro da raridade (errado agora). Use `update.odds`; se vier `nil`, esconda o número.

## Tarefa 4: HUD do Poder de Pesca (T3)

Contrato: `docs/TREINO-PP-CONTRATO.md`.

- Número grande "Poder de Pesca" = soma de `Train_Control_PP` + `Train_Instinct_PP` (atributos). Formato: `TrainingConfig.formatPower(valor, ",")` em PT (`"."` em EN). Cor: `TrainingConfig.TIER_COLORS[TrainingConfig.tier(valor)]`; tier 7 (teto) = gradiente arco-íris + dourado animado. Tier 5 e 6 com gradiente/brilho.
- Contador sobe suave (interpolar o **logaritmo**, a 10 Hz), "+X/s" embaixo (evento `power`, campo `gain`), pop-ups "+1,2M" nas argolas (`ringResult.gain`) e no bônus do dia.
- `powerMilestone`: faixa "NOVO PATAMAR!" na cor nova, confete curto, som. Não mais que uma por vez.
- `islandLocked`: toast com o poder exigido (`gate`, formatado).
- Mostre Controle e Instinto separados no painel do treino, com a lista de multiplicadores (`TrainingConfig.multiplier` por partes: campo, ilha, prestígio).

## Tarefa 5: painel do campo de treino (T3)

- Placa/painel "Melhorar campo": nível atual (`TrainField`), próximo nível (`TrainingConfig.FIELD[n+1]`: multiplicador, custo, poder exigido), botão comprar → `TrainingBuyField(requestId)`; resposta `fieldResult` (`ok`, `reason`: `max` / `power` (+`gate`) / `coins` / `changed` / `disabled`).
- Cor do botão pela comparação **real** de números (não pelo texto formatado).
- Ao comprar: troca da camada visual do campo (kit `ReplicatedStorage.TrainingLevels.Levels.training_lvNN`, feito pelo Antigravity com `docs/prompts-antigravity/CAMPO-TREINO-E-ILHAS.md`) **só no cliente do jogador**, alinhado ao `TrainingOrigin`, com uma "obra" curta (peças subindo + brilho), pulável. Enquanto o kit não existir, só o painel e o número.

## Como entregar

- Ciclo do AGENTS.md (§5): stylua, selene, sourcemap, luau-lsp, Play com as flags ligadas, `.studio-lock`, commit só dos seus arquivos, Mural ao começar e ao terminar cada tarefa.
- Não edite `src/server/**`, `src/shared/Config/**`, `Net.luau`, `Types.luau`, `Strings.luau`, `Fishing/init.luau`, `Fishing/Control.luau`, `Fishing/PressInput.luau`. Precisa de campo, evento ou gancho novo: peça no Mural.
- Teste em celular simulado (retrato e paisagem) e diga o que não testou (celular real, 2 jogadores).

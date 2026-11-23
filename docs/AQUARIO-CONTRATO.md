# Aquário — contrato S0 (servidor → cliente)

[Plano Claude](PLANO-AQUARIO-CLAUDE.md) · [Economia S0](ECONOMIA-AQUARIO-S0.md) · [Coordenação §4.7](COORDENACAO.md)

Estado: **implementado no servidor (S1, 2026-11-22), ainda não testado com Play/Rojo**. Código: `src/shared/Config/Aquarium.luau`, `src/shared/AquariumState.luau`, `src/server/Features/Aquarium`. Tudo é **aditivo**: nenhum campo atual muda. Codex pode construir fixtures a partir dos exemplos abaixo. Valores monetários são explicados na seção 1.

## 1. Unidades

| Valor | Unidade | Observação |
|---|---|---|
| `snapshot.coins` | moedas inteiras | como hoje |
| `aquarium.fractionCents` | centésimos de moeda, 0–99 | resto ainda não pago; saldo exato = `coins + fractionCents/100` |
| qualquer `*Cpm` | **centésimos de moeda por minuto**, inteiro | `cpm 180` = 1,80 moedas/min. Mostrar `cpm / 100` com 1 casa, em moedas/min (`+1,8/min`) |
| `cost`, `reward`, `value` | moedas inteiras | |

Fatores de variante vivem em `Config.Aquarium.VARIANT_FACTOR` (`base 1.00, giant 1.30, gold 1.60, both 1.90`). Sinergia em `synergyPct` (0, 5 ou 10). A taxa efetiva de uma vaga vem **sempre pronta do servidor**; o cliente nunca recalcula para decidir nada, só para rótulo de fixtures.

## 2. Carregar: quatro estados que o cliente distingue

| Situação | O que o cliente vê |
|---|---|
| Perfil ainda carregando | `Data.get()` é `nil` (como hoje). `Player:GetAttribute("DataLoaded")` falso. |
| Recurso desligado (flag) | `snapshot.aquarium = { status = "disabled" }`. Mostrar o card da captura sem exposição e esconder o atalho ao aquário. |
| Veterano migrado, tanque vazio | `status = "ready"`, `slots` todos vazios, `inventory` preenchido. |
| Tanque ativo | `status = "ready"` com ocupantes, taxas e sinergias. |
| Servidor antigo (campo ausente) | `snapshot.aquarium == nil` com perfil carregado: tratar como `disabled`. |

```lua
-- Tipo (vai para src/shared/Types.luau em S1)
export type AquariumSlot = { index: number, occupant: { creatureId: string, variant: string }? }
export type AquariumSnapshot = {
	status: string, -- "disabled" | "ready"
	paramsVersion: number?, -- versão da tabela de taxas/preços usada
	levelId: string?, -- "aquarium_lv1_nursery" | "_lv2_reef" | "_lv3_gallery" | "_lv4_sanctuary"
	level: number?, -- 1..4
	version: number?, -- versão da montagem: +1 a cada mudança aceita
	slots: { AquariumSlot }?, -- tamanho = capacidade do nível
	inventory: { [string]: { base: number, giant: number, gold: number, both: number } }?, -- DISPONÍVEL (fora das vagas), por espécie
	totalCpm: number?, -- renda do tanque, com sinergia
	slotCpm: { number }?, -- lista: índice = vaga, 0 quando vazia (tamanho = capacidade)
	synergies: { { id: string, members: { string }, bonusPct: number, active: boolean, missing: { string }? } }?,
	fractionCents: number?,
	nextLevel: { levelId: string, slots: number, cost: number, requirement: string?, canBuy: boolean, reason: string? }?,
}
```

**Exemplo — recurso desligado**
```lua
snapshot.aquarium = { status = "disabled" }
```

**Exemplo — perfil novo, recurso ligado, primeira captura ainda não exposta**
```lua
snapshot.aquarium = {
	status = "ready", paramsVersion = 1,
	levelId = "aquarium_lv1_nursery", level = 1, version = 0,
	slots = { { index = 1 }, { index = 2 }, { index = 3 } },
	inventory = { C04_Baiacu_Nuvem = { base = 1, giant = 0, gold = 0, both = 0 } },
	totalCpm = 0, slotCpm = { 0, 0, 0 }, synergies = {}, fractionCents = 0,
	nextLevel = { levelId = "aquarium_lv2_reef", slots = 5, cost = 3000, canBuy = false, reason = "noCoins" },
}
```

**Exemplo — veterano migrado** (tanque vazio; 12 `base` + 2 `gold` antigos de uma espécie)
```lua
snapshot.aquarium.inventory.C09_Exemplo = { base = 10, giant = 0, gold = 2, both = 0 }
-- base = count antigo - shiny; gold = shiny; giant/both = 0 (não dá para reconstruir). Ver Economia S0 §5.3.
```

**Exemplo — tanque ativo, 2 vagas ocupadas de 3**
```lua
snapshot.aquarium = {
	status = "ready", paramsVersion = 1, levelId = "aquarium_lv1_nursery", level = 1, version = 7,
	slots = {
		{ index = 1, occupant = { creatureId = "C04_Baiacu_Nuvem", variant = "gold" } },
		{ index = 2, occupant = { creatureId = "C01_Bolhinha_Azul", variant = "base" } },
		{ index = 3 },
	},
	inventory = { C01_Bolhinha_Azul = { base = 4, giant = 0, gold = 0, both = 0 } },
	totalCpm = 852, slotCpm = { 672, 180, 0 }, synergies = {}, fractionCents = 42,
	nextLevel = { levelId = "aquarium_lv2_reef", slots = 5, cost = 3000, canBuy = false, reason = "noCoins" },
}
```
Valores reais da tabela: Bolhinha Azul 180, Baiacu-Nuvem 420 (Dourado = 420 × 1,6 = 672). Total = 672 + 180 = 852.

IDs de geometria **conferidos no Studio em 2026-11-22** (`Workspace._AquariumA1Showcase`): níveis `aquarium_lv1_nursery`, `aquarium_lv2_reef`, `aquarium_lv3_gallery`, `aquarium_lv4_sanctuary` (atributos `LevelId`, `Capacity` 3/5/8/12, `LevelIndex`), iguais aos do servidor. Vaga de índice N = instância `Slot_NN` dentro de `Slots` (`Slot_01`..`Slot_12`, dois dígitos). Pontos de decoração do mapa: `DecorAnchor_01_Plaque`, `_02_Lamp`, `_03_LeftBed`, `_04_RightBed`, `_05_LeftPost`, `_06_RightPost`, `_07_Crown` (níveis 2+); os cosméticos de meta de renda (`aqdeco_*`) ainda precisam ser mapeados a esses pontos.

## 3. Capturar

`FishingUpdate` mantém todos os campos atuais. Novos campos, só no evento `caught`:

| Campo | Tipo | Significado |
|---|---|---|
| `variantId` | string | `"base"` \| `"giant"` \| `"gold"` \| `"both"` (o campo antigo `variant` continua `""`/`"Shiny"`, e `isGiant` continua) |
| `newVariant` | boolean | primeira vez que essa combinação é pescada (separado de `isNew`, que é espécie nova) |
| `potentialCpm` | number | taxa individual desta captura, sem sinergia (`cpm da espécie × fator`) |
| `rewardCoins` | number | igual a `value` (prêmio imediato), publicado também com esse nome para a UI do card |
| `aquariumVersion` | number? | versão da montagem após a captura (para ordenar contra o snapshot) |

`value` segue sendo o prêmio imediato em moedas inteiras; **a taxa potencial nunca vira moeda**, só vira renda se a criatura entrar numa vaga. No evento `bite` continua só `rarity` (e `tier`/`kind`): nada da espécie, nem da variante.

```lua
{ event = "caught", castId = 12, creatureId = "C04_Baiacu_Nuvem", weight = 0.9, value = 118,
  isNew = false, count = 3, variant = "Shiny", isGiant = false,
  variantId = "gold", newVariant = true, potentialCpm = 672, rewardCoins = 118, aquariumVersion = 7 }
```

## 4. Comparar (prévia)

Cliente → servidor: `AquariumPreview` (RemoteEvent; a resposta vem por `AquariumResult` com `kind = "preview"`, igual a apply/buy).

```lua
-- pedido
{ requestId = "c-0001", op = "place" | "swap" | "remove", slot = 2,
  creatureId = "C04_Baiacu_Nuvem", variant = "gold", expectedVersion = 7 }
```

Resposta `AquariumResult`:
```lua
{ requestId = "c-0001", kind = "preview", ok = true, version = 7,
  preview = {
	slot = 2,
	current = { creatureId = "C01_Bolhinha_Azul", variant = "base", cpm = 180 },
	candidate = { creatureId = "C04_Baiacu_Nuvem", variant = "gold", cpm = 672 },
	slotBeforeCpm = 180, slotAfterCpm = 672,
	totalBeforeCpm = 852, totalAfterCpm = 1344, deltaCpm = 492,
	synergiesGained = {}, synergiesLost = {},
	usedVersion = 7, -- a confirmação deve mandar expectedVersion = 7
  } }
```
**Vaga vazia:** `current = nil`, `slotBeforeCpm = 0`.
**Perda de sinergia** (números ilustrativos, famílias ainda não existem): trocar o Baiacu Dourado (672) por uma Bolhinha (180) retorna `slotBeforeCpm = 672`, `slotAfterCpm = 180`, `synergiesLost = { "reef" }` e `deltaCpm` já com a perda dos outros participantes; mostrar a perda antes de confirmar.
**Conflito:** `{ ok = false, reason = "staleVersion", version = 9, snapshot = <AquariumSnapshot atual> }`: pedir nova prévia com `expectedVersion = 9`.

## 5. Confirmar (colocar, trocar, retirar, comprar)

C→S `AquariumApply(request)` (mesmo formato do pedido da prévia, com `op`), `AquariumBuyLevel({ requestId, levelId, expectedVersion })`. Resposta única `AquariumResult` (S→C):

```lua
{ requestId, kind = "apply" | "buy", ok = true | false, reason?, version = number,
  snapshot = AquariumSnapshot, -- estado canônico depois da ação (ou o estado atual em caso de rejeição)
  deltaCoins?, coins? } -- compra: moedas gastas/saldo
```

**Identificação:** `requestId` é texto de até 36 caracteres escolhido pelo cliente, único por pedido. Repetir o mesmo `requestId` devolve o resultado guardado sem reaplicar (cliques repetidos e retentativa de rede). O servidor guarda os últimos 20 por sessão.

**Fora de ordem:** o estado com **maior `version` vence**. Se a resposta (`result.version`) e o `ProfileSnapshot` (`aquarium.version`) chegarem trocados, o cliente guarda o de maior versão e ignora o menor. Versão igual tem conteúdo igual. Moedas (`coins`) seguem a regra existente de `ProfileSnapshot`.

**Motivos de rejeição que a UI mostra:**

| `reason` | Mensagem sugerida |
|---|---|
| `disabled` | Aquário indisponível agora |
| `notReady` | Perfil ainda carregando |
| `staleVersion` | O tanque mudou, confira de novo (vem com `snapshot`) |
| `notOwned` | Você não tem mais essa criatura disponível |
| `badSlot` / `slotLocked` | Vaga inexistente / vaga ainda bloqueada |
| `emptySlot` | Nada para retirar |
| `sameOccupant` | Já está nessa vaga |
| `noCoins` | Faltam moedas (inclui `needed`) |
| `maxLevel` | Tanque no nível máximo |
| `levelLocked` | Requisito não cumprido (`requirement` do `nextLevel`) |
| `rateLimited` | Muitos pedidos, tente de novo |
| `badRequest` | Pedido inválido (não mostrar; só log) |

**Implementação S1:** pedidos aceitos a 6/s (prévia), 4/s (apply) e 2/s (compra) por jogador; `requestId` até 36 caracteres. Requisito de espécies dos níveis 2–4 (`minSpecies` 15/40/70) é provisório até o João decidir; falha com `levelLocked` e `requirement = "species:N"`. Flags: atributos `AquariumUI` e `AquariumCredit` em `ReplicatedStorage` (`false` desliga). `ProfileSnapshot` ganha `aquarium` mesmo se o recurso estiver desligado (`status = "disabled"`).

## 6. Comportamento do servidor (para o Codex animar com segurança)

- Troca de taxa: o servidor liquida o intervalo anterior com a taxa **anterior** e só então muda a montagem; o contador animado nunca precisa "voltar".
- Pagamento em lote, mais ou menos a cada 5 s por jogador online; `coins` sobe em saltos pequenos. Renda offline desligada no piloto.
- Comprar upgrade: cobra uma vez, mantém ocupantes, `slots` ganha índices novos; `version` +1.
- Retirar tudo: `totalCpm = 0`; a renda para na hora.

## 7. S2: sinergias, metas e prêmios (implementado no servidor, 2026-11-22)

**Famílias** (`Config.Aquarium.FAMILY`, uma por criatura, nomes de trabalho a confirmar): `reef` (bolhas/respingo/prisma, 37 espécies), `tempest` (tempestade/nuvem, 19), `abyss` (faíscas/cristal/magma/gelo, 34), `celestial` (cósmico, 10), `festival` (Natal, 6). 2 espécies distintas da mesma família no tanque = **+5%**, 3 ou mais = **+10%** para os participantes. Variante da mesma espécie não conta como outra espécie.

`snapshot.aquarium.synergies` lista as famílias com ao menos uma espécie no tanque:
```lua
{ id = "reef", members = { "C01_Bolhinha_Azul", "C02_Sardinha_Solar" }, bonusPct = 5, active = true, count = 2, nextAt = 3 }
```
`nextAt` = espécies necessárias para a próxima faixa (`nil` na maior). A prévia traz `synergiesGained` / `synergiesLost` com os ids das famílias que ligam/desligam.

**Metas de renda** (`snapshot.aquarium.goals.income`): `bestCpm` é a maior taxa confirmada do tanque; `list` tem `{ id, cpm, cosmetic, reached, claimed }`; `nextId` e `remainingCpm` apontam a próxima. Faixas em moedas/min: 10 / 25 / 60 / 120 / 250 / 500 (cpm 1.000 … 50.000). Resgate guarda o ID para sempre; trocar e recolocar criaturas não zera nada.

| Meta | cpm | Prêmio (ID de cosmético, proposta p/ Antigravity) |
|---|---:|---|
| `income_1` | 1.000 | `aqdeco_plaque` placa do aquário |
| `income_2` | 2.500 | `aqdeco_lamp` luminária |
| `income_3` | 6.000 | `aqdeco_coral` coral especial |
| `income_4` | 12.000 | `aqdeco_fountain` fonte |
| `income_5` | 25.000 | `aqdeco_frame` moldura |
| `income_6` | 50.000 | `aqdeco_trophy` troféu |

Cosméticos desbloqueados vêm em `snapshot.aquarium.cosmetics` (lista de IDs). Critério de desbloqueio = a meta de renda correspondente resgatada.

**Metas de sessão** (`goals.session`): `list` com `{ id, kind, target, progress, coins, claimed }` e `coinsLeftToday`. `catch3` (3 capturas manuais, 40 moedas), `kinds2` (2 modos de minigame vencidos, 60), `discover1` (1 espécie nova, 100). Só ações confirmadas, pesca automática não conta. Voltar em até 10 min mantém a mesma sessão; depois disso nasce uma nova. Teto de 600 moedas por dia UTC vindas de metas de sessão.

**Resgate:** C→S `AquariumClaimGoal({ requestId, goalId })` com `goalId = "income:<id>"` ou `"session:<id>"`. Resposta `AquariumResult` com `kind = "claim"`: `ok`, `reward = { coins?, cosmetic? }`, `already = true` se já tinha sido resgatada (nada é pago de novo), `coins` (saldo) e `snapshot`. Motivos: `notReady`, `unknown`, `dailyCap`, `badRequest`, `disabled`, `notReady` (perfil).

Fora do S2 ainda: eventos do oceano e minigames (S3).

## 8. S3: campos de pesca (aditivos)

`FishingUpdate`: `caught.comboMilestone` (3/5/8), `caught.eventId` (bônus de evento que valeu), `escaped`/`cancelled` com `comboLost`. `ReplicatedStorage`: `OceanEventNextAt`. Regras e decisões em [PESCA-S3.md](PESCA-S3.md).

## 9. Tanque no mundo e troca de nível (A0, 2026-11-22)

- **No mapa:** `Workspace.Island.AquariumNursery` (tag `AquariumTank`, `ModelStreamingMode = Persistent`) é o tanque do jogador no hub, na ponta sudoeste, sobre a água (origem em x -40, y 10.4, z 47.5; a frente do modelo aponta para o leste, para a praça; atributo `OriginCFrame` no modelo). Ponto de interação: peça `AquariumSpot` dentro dele, com o prompt `OpenAquarium` criado pelo servidor (ativo só quando o recurso está ligado).
- **Kit de runtime:** `ReplicatedStorage.AquariumLevels` com `Levels` (`aquarium_lv1..4`), `Decor` (props) e `Variants` (referências de variante). Para ampliar: clonar `Levels[levelId]`, posicionar com `PivotTo(origemAtual * origemDoClone:Inverse() * clone:GetPivot())` (a origem é a peça `AquariumOrigin` de cada nível), apagar o modelo antigo e manter o nome `AquariumNursery`. Vagas: `Anchors.Slots.Slot_NN` com NN = índice do servidor (dois dígitos).
- Cada nível do kit tem `Layer_00_Platform` (deck/estacas/guarda-corpo do tamanho daquele nível; níveis 1 e 2 incluem a rampa `Ramp`). Trocar o modelo troca a plataforma.
- A vitrine completa dos quatro níveis lado a lado fica em `ServerStorage.AquariumShowcase` (referência, não vai ao cliente).

## 10. Cosméticos das metas de renda (2026-11-22)

`Config.Aquarium.COSMETICS[id] = { prop, anchor, fallback? }`: o modelo em `ReplicatedStorage.AquariumLevels.Decor` e a âncora (`Anchors.<nome>`, busca recursiva) onde ele encaixa no nível atual. Conferido nos 4 níveis.

| Cosmético | Prop | Âncora |
|---|---|---|
| `aqdeco_plaque` | `decor_income_plaque` | `DecorAnchor_01_Plaque` |
| `aqdeco_lamp` | `decor_reef_lamp` | `DecorAnchor_02_Lamp` |
| `aqdeco_coral` | `decor_crystal_coral` | `DecorAnchor_03_LeftBed` |
| `aqdeco_fountain` | `decor_bubble_fountain` | `DecorAnchor_04_RightBed` |
| `aqdeco_frame` | `decor_golden_frame` | `DecorAnchor_07_Crown` (nível 1: `DecorAnchor_05_LeftPost`) |
| `aqdeco_trophy` | `decor_astral_obelisk` | `DecorAnchor_06_RightPost` |

Nomes das famílias para a UI: `Strings.aquariumFamily[familyId]` (PT/EN).


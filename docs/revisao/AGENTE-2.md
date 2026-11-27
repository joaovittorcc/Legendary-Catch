# Relatório de Revisão Final — Agente 2 (Sistemas, Servidor, Dados, Economia e Segurança)

> **Escopo:** `src/server/**` (exceto `Features/MapStreaming/`), `src/shared/Config/**`, `Net.luau`, `Types.luau`, `AquariumState.luau`, `Version.luau`, `src/client/Data/**`, `src/client/init.client.luau`, `src/client/Features/Fishing/init.luau`, `tools/*-test.luau`, `tools/*-sim.js`, `docs/PUBLICAR.md`, `docs/PAGINA-DO-JOGO.md`.
> **Place:** `112666482424701` (`Legendary Catch`, Universe `10777276665`).
> **Commit de correções:** `42648ae` · **Verificação estática:** `stylua`, `selene src` (`0 errors / 0 warnings`), `rojo sourcemap`, `luau-lsp analyze src` (`0` erros novos; único erro pré-existente é o untracked `AquariumPreview.luau`).
> **Console do Studio no Play:** `0` erros Lua e `0` avisos Lua dos nossos sistemas (4 avisos de áudio de `SfxKit.luau` reportados ao Agente 4 em `PEDIDOS.md`).

---

## 1. Inventário Completo da Área

### 1.1 Infraestrutura e Contratos

| Item | Arquivo | Testado como | Resultado |
| :--- | :--- | :--- | :--- |
| Bootstrap do Servidor | `src/server/init.server.luau` | Auditoria + `pcall` no `require` + ordenação determinística + Play (`[Server] booted`) | **corrigido** |
| Gerenciador de Remotes + Rate Limit | `src/server/Remotes.luau` | Auditoria + flood de 20 `CastLine` no Play (apenas 4 passaram, token bucket ativo) | **OK** |
| Contrato de Rede (36 remotes) | `src/shared/Net.luau` | Cruzamento com `ReplicatedStorage.Remotes` no Play (36/36 batem; adicionado `PORTAL_EFFECT`) | **corrigido** |
| Tipos Compartilhados | `src/shared/Types.luau` | Leitura + `luau-lsp analyze` | **OK** |
| Estado Puro do Aquário | `src/shared/AquariumState.luau` | `tools/aquarium-test.luau` em Edit (`ALL OK`) + auditoria de inteiros/offline | **OK** |
| Versão de Build | `src/shared/Version.luau` | Leitura + log `[Server] booted, build 0.0.1` no Play | **OK** |
| Bootstrap do Cliente | `src/client/init.client.luau` | Auditoria (`pcall` no `require` e `start`) + Play (`[Client] booted`) | **OK** |
| Espelho de Dados no Cliente | `src/client/Data/init.luau` | Auditoria + `RequestProfile` / `ProfileSnapshot` no Play | **OK** |
| Controlador de Pesca (Cliente) | `src/client/Features/Fishing/init.luau` | Auditoria + watchdog de `"casting"` + `reason = "cooldown"` + `flat.Magnitude` + Play | **corrigido** |

### 1.2 Sistemas do Servidor (`src/server/Features/**`)

| Ordem | Sistema | Arquivo | Testado como | Resultado |
| ---: | :--- | :--- | :--- | :--- |
| 10 | `PlayerData` (ProfileStore, migração, `BindToClose`, atributos) | `src/server/Features/PlayerData/init.luau` | `migration-test.luau` no Play (`ok=true`), guarda `NaN`/`inf`, `OnLastSave`, `savePurchaseAsync` | **corrigido** |
| 15 | `Analytics` (funil, economia, custom, sem PII) | `src/server/Features/Analytics/init.luau` | Auditoria (0 PII, tudo em `pcall`) + eventos `LogEconomyEvent`/`LogCustomEvent` no Play | **OK** |
| 20 | `DayNight` (ciclo 12 min) | `src/server/Features/DayNight/init.luau` | Auditoria + Play (`DayClockTime=22.24`, `DayNightWeight=1`) | **OK** |
| 20 | `OceanEvents` (6 eventos em rotação + `DevStartEvent`) | `src/server/Features/OceanEvents/init.luau` | Auditoria + Play (`OceanEventNextAt` publicado, 0 `Dev*` salvos) | **OK** |
| 25 | `Monetization` (`ProcessReceipt`, passes, boost) | `src/server/Features/Monetization/init.luau` | Auditoria ID=0, guarda `pass.id ~= 0`, durabilidade via `savePurchaseAsync` + Play `DevAutoFish` | **corrigido** |
| 30 | `Rod` (construção, loja `BuyRod`/`EquipRod`, `RodPreviews`) | `src/server/Features/Rod/init.luau` | Transação atômica única + limite `#rodId <= 64` + ataque Client no Play | **corrigido** |
| 35 | `Prestige` ("Maré Nova") | `src/server/Features/Prestige/init.luau` | Auditoria requisitos/reset/Power v2 + ataque `DoPrestige` no Play + cancela pesca ao mudar `Prestige` | **corrigido** |
| 40 | `Training` (4 ilhas, Poder de Pesca v2, rings, campo) | `src/server/Features/Training/init.luau` | `training-power-test.luau` (`ALL OK`) + anti-duplicação de prompts (`0` duplicados no Play) + ataques `TrainingRingResult`/`TrainingBuyField` | **corrigido** |
| 45 | `Journey` (XP, níveis 1–100, baú a cada 10 capturas) | `src/server/Features/Journey/init.luau` | Auditoria + Play (`PlayerLevel=25`, `DevGrantLevel` sob `IsStudio`) | **OK** |
| 45 | `Progress` (tutorial, missões, marcos, presente diário + escudo, settings, perfect) | `src/server/Features/Progress/init.luau` | Bloqueio `ReportPerfect` em Auto-Fish + revalidação atômica + limite `#id <= 64` + ataques Client no Play | **corrigido** |
| 46 | `Achievements` (19 conquistas + 3 códigos) | `src/server/Features/Achievements/init.luau` | Auditoria + ataque `RedeemCode` (string 200k + código inválido) no Play | **OK** |
| 50 | `Fishing` (máquina de estados, barra de força, minigame, roleta, auto-pesca, anti-cheat) | `src/server/Features/Fishing/init.luau` | Play completo: `MAX_FIGHT_DRIFT` (40 studs + 0,7 s → bloqueado), `castId` duplicado bloqueado, desequipar cancela no servidor, cooldown sem travar, Auto-Fish travado em Épico com `DevForceRarity="Legendary"` | **corrigido** |
| 55 | `Portals` (teleporte, requisitos de zona e Poder de Pesca, streaming) | `src/server/Features/Portals/init.luau` | Validação de `TrainingIsland` no servidor + Play (`main_to_training_reef` bloqueou com `~2940 PP < 1e5`, `lagoon_to_training_1` teleportou para `(508, 14, -344)`) | **corrigido** |
| 60 | `Aquarium` (slots, sinergias, renda online/offline, metas, upgrades) | `src/server/Features/Aquarium/init.luau` | `aquarium-test.luau` (`ALL OK`) + guarda `math.huge`/tamanho `op` + ataques Client no Play | **corrigido** |
| 60 | `Social` (`leaderstats`, `CatchAnnounce`) | `src/server/Features/Social/init.luau` | Auditoria (`IntValue` 64-bit, `CatchAnnounce` Épico Shiny / Lendário / Místico) + Play | **OK** |
| 65 | `Trophy` (pedestal da melhor captura do servidor) | `src/server/Features/Trophy/init.luau` | Auditoria + 3 `TrophyPedestal` conferidos em Edit | **OK** |
| 90 | `Inspect` (álbum público sem dados privados) | `src/server/Features/Inspect/init.luau` | Ataques Client (`NaN`/`-1`/`0`/`inf`/string 200k) + inspeção válida no Play (`0` campos privados vazados) | **OK** |
| 90 | `Leaderboard` (`OrderedDataStore` 3 placares) | `src/server/Features/Leaderboard/init.luau` | Separação `_Studio_v1` × `_v1`, dirty-tracking, shutdown paralelo, sem cachear `"???"` + ataque `RequestLeaderboard` no Play | **corrigido** |

### 1.3 Configurações (`src/shared/Config/**`)

| Config | Arquivo | Testado como | Resultado |
| :--- | :--- | :--- | :--- |
| `Achievements` (19) | `src/shared/Config/Achievements.luau` | Auditoria + soma de recompensas (74.650 moedas) | **OK** |
| `Aquarium` | `src/shared/Config/Aquarium.luau` | `aquarium-test.luau` (`ALL OK`) + `aquarium-sim.js` + `kinds2` → `catch6` | **corrigido** |
| `Codes` (3) | `src/shared/Config/Codes.luau` | Suporte opcional a `expiresAt` + ataque `RedeemCode` no Play | **corrigido** |
| `Creatures` (106 ativas + 100 `PLANNED`) | `src/shared/Config/Creatures.luau` | Validador Node (106 ativas, 0 duplicadas, 0 erros de peso/valor/referência) + `drop-test.luau` (`ALL OK`) | **OK** |
| `Events` (6) | `src/shared/Config/Events.luau` | Validador Node (todas as 6 exclusivas apontam para eventos válidos em rotação) | **OK** |
| `Fishing` | `src/shared/Config/Fishing.luau` | `power-bar-test.luau` (`ALL OK`) + `drop-test.luau` (`ALL OK`) + `MINIGAMES = { "reel" }` | **OK** |
| `Milestones` (24) | `src/shared/Config/Milestones.luau` | Auditoria (ver achados de economia/sazonalidade em §5 e §7) | **OK** |
| `Missions` | `src/shared/Config/Missions.luau` | Auditoria reset UTC (`os.time() // 86400`), 7 dias + escudo semanal | **OK** |
| `Prestige` | `src/shared/Config/Prestige.luau` | Auditoria fórmulas e limites (`MAX_LEVEL = 10`, `1M`, `60` espécies) | **OK** |
| `Products` (3 products + 2 passes, `id = 0`) | `src/shared/Config/Products.luau` | Auditoria (`byProductId(0) == nil`, nenhum item aleatório pago) + Play | **OK** |
| `Rods` (8) | `src/shared/Config/Rods.luau` | `economy-sim.js` + Play | **OK** |
| `Roulette` | `src/shared/Config/Roulette.luau` | `roulette-test.luau` (`ALL OK`, soma = 1,000000) + `roulette-sim.js` | **OK** |
| `Seasons` (`xmas`: 1/dez–6/jan) | `src/shared/Config/Seasons.luau` | Auditoria virada de ano UTC + `DevSeason` sob `IsStudio` | **OK** |
| `Training` | `src/shared/Config/Training.luau` | `training-power-test.luau` (`ALL OK`) + `training-sim.js` | **OK** |
| `Zones` (3) | `src/shared/Config/Zones.luau` | Auditoria níveis (1/5/15) + 3 `FishingZone` em Edit | **OK** |

### 1.4 Testes, Simuladores e Documentação

| Item | Arquivo | Testado como | Resultado |
| :--- | :--- | :--- | :--- |
| Teste Roleta | `tools/roulette-test.luau` | `execute_luau` em Edit | **OK** (`ALL OK \| avg coin x1.278`) |
| Teste Drop/Odds | `tools/drop-test.luau` | `execute_luau` em Edit (500k rolagens) | **OK** (`ALL OK`, todas as 6 raridades batem) |
| Teste Barra de Força | `tools/power-bar-test.luau` | `execute_luau` em Edit | **OK** (`ALL OK`) |
| Teste Poder de Pesca | `tools/training-power-test.luau` | `execute_luau` em Edit | **OK** (`ALL OK`) |
| Teste Aquário | `tools/aquarium-test.luau` | Atualizado para `catch6` + `execute_luau` em Edit | **corrigido** (`ALL OK`) |
| Teste Migração | `tools/migration-test.luau` | `execute_luau` em Server (Play) | **OK** (`ok = true`) |
| Simulador Economia | `tools/economy-sim.js` | `node tools/economy-sim.js` + script `economy_audit.js` | **OK** |
| Simulador Roleta | `tools/roulette-sim.js` | `node tools/roulette-sim.js` | **OK** |
| Simulador Treino | `tools/training-sim.js` | `node tools/training-sim.js` | **OK** |
| Simulador Aquário | `tools/aquarium-sim.js` | `RATE_SCALE=0.2 TANK_PRICES="[0,3000,12000,50000]" N=10 node tools/aquarium-sim.js` | **OK** |
| Guia de Publicação | `docs/PUBLICAR.md` | Revisado e atualizado (DataStores, flags, `MaxPlayers`, passo a passo Monetização, 14 `Dev*`, roteiro 2 jogadores) | **corrigido** |
| Página do Jogo | `docs/PAGINA-DO-JOGO.md` | Atualizado para **106 criaturas** e **1 minigame da barra lateral** (PT-BR, EN-US e 10 vídeos) | **corrigido** |

---

## 2. Auditoria Completa dos 36 Remotes (`Net.luau` + `Remotes.luau`)

> **Total verificado no Play (`ReplicatedStorage.Remotes`):** `36 RemoteEvents` (`25 C→S`, `11 S→C`), `0 RemoteFunctions`.
> Todos os 25 C→S foram **atacados de verdade pelo Client no Play** com tipos errados, `NaN`, `±math.huge`, negativos, strings de 200 KB, tabelas aninhadas (profundidade 50), IDs inválidos, chamadas fora de ordem e rajada de spam. **Resultado antes vs. depois:** 0 moedas indevidas, 0 varas/espécies/prestígio alterados, `settings` intacto, 0 eco de string gigante, 0 erros Lua no servidor.

### 2.1 Client → Server (25)

| Remote | Handler | Rate limit (s/burst) | Validações (tipo, faixa, NaN/inf, tamanho, dono, distância, estado) | Resultado ataque Play |
| :--- | :--- | :---: | :--- | :--- |
| `CastLine` | `Fishing.onCast` | `2 / 3` | Sem args usados; valida `phase == "idle"`, `not autoEnabled`, `CAST_COOLDOWN`, personagem vivo, `Rod` equipado, não treinando, `FishingZone` + `castSpotCheck`, nível da zona | **OK** (20 chamadas em rajada → 4 respostas, resto descartado) |
| `CancelFishing` | `Fishing.onCancel` | `2 / 3` | Sem args; valida `not isAuto` e `phase ~= "idle"`, limpa estado e quebra combo | **OK** |
| `PowerTap` | `Fishing.onPowerTap` | `3 / 3` | `castId` número finito == `s.castId`, `phase == "aiming"`, `now >= aimStart`, `clientTime` finito clamped em `[now - 0.2, now]`, anti-cheat `purpleShare > 0.6` ignora tempo do cliente e marca suspeito | **OK** |
| `SubmitCatch` | `Fishing.onSubmit` | `2 / 3` | `castId` finito, `success` boolean, bloqueia `wonCasts[castId]` duplicado (+suspicious), `phase == "fighting"`, `MIN_FIGHT_SECONDS` (+50% sob penalidade), `CATCH_RATE_LIMIT` (3 s), `MAX_FIGHT_DRIFT` (20 studs) | **OK** (testado `MAX_FIGHT_DRIFT` 40 studs + 0,7 s e `castId` duplicado) |
| `SetAutoFish` | `Fishing.onSetAutoFish` | `1 / 2` | `enabled` boolean, `ownsAutoFish`, `phase == "idle"`, vivo, não treinando, `FishingZone` + `castSpotCheck`, nível da zona, parado (`<= 2 studs/s`); teto Épico forçado | **OK** (bloqueado sem passe; com `DevAutoFish` + `DevForceRarity="Legendary"` pagou `Rare`) |
| `RequestProfile` | `PlayerData.start` | `1 / 3` | Sem args; envia snapshot somente do próprio jogador | **OK** |
| `BuyRod` | `Rod.onBuy` | `2 / 4` | `rodId` string `1..64`, existe em `Rods`, atômico em 1 `PlayerData.update` (posse + moedas + compra + equip) | **OK** (string 200 KB descartada sem eco; `mystic` bloqueada por `noCoins`) |
| `EquipRod` | `Rod.onEquip` | `2 / 4` | `rodId` string `1..64`, existe em `Rods`, está em `rodsOwned` | **OK** (`mystic` bloqueada por `notOwned`) |
| `StopTraining` | `Training.start` | `2 / 3` | Sem args; para sessão ativa do próprio jogador | **OK** |
| `TrainingRingResult` | `Training.onRingResult` | `2 / 3` | `ringId` finito == `s.ringId`, `success` boolean, `s.ringExpires > 0`, consome `ringExpires = 0` (1× por anel) | **OK** |
| `TrainingBuyField` | `Training.onBuyField` | `2 / 3` | `requestId` finito, `TrainingPower` ativo, revalida nível/poder/moedas dentro de 1 `PlayerData.update` | **OK** (nível 3 bloqueado por `power` com `~2940 < 1e4`) |
| `ClaimMission` | `Progress.onClaimMission` | `2 / 4` | `index` finito, `refreshMissions` UTC, revalida existência/`claimed`/`progress >= target` dentro de 1 `PlayerData.update` | **OK** (`NaN`/`inf`/`-1`/`9999` bloqueados) |
| `ClaimMilestone` | `Progress.onClaimMilestone` | `2 / 4` | `id` string `1..64`, existe em `Milestones`, revalida `claimed`/`milestoneReady` dentro de 1 `PlayerData.update` | **OK** (string 200 KB descartada sem eco) |
| `SkipTutorial` | `Progress.onSkipTutorial` | `1 / 2` | Sem args; marca `tutorial.done = true` (não dá moedas nem itens) | **OK** |
| `TutorialEvent` | `Progress.onTutorialEvent` | `2 / 4` | `name` string `1..64` na whitelist (`openedCollection`/`openedWorkshop`), só avança passo exato | **OK** |
| `SaveSettings` | `Progress.onSaveSettings` | `1 / 3` | Tabela; `music`/`sfx` número em `[0, 1]` (`NaN`/`inf` cai no fallback), `reduceEffects` boolean | **OK** (`settings` 100% preservado sob `NaN`/`999`/`-5`/`inf`) |
| `ReportPerfect` | `Progress.onReportPerfect` | `2 / 3` | `castId` finito == `lastCaught[player].castId`, janela `<= 15 s`, uso único, **ignora capturas de Auto-Fish** | **OK** |
| `RedeemCode` | `Achievements.onRedeem` | `1 / 2` (+2 s cooldown) | `text` string `<= 40`, lookup em `Codes.find` (respeita `expiresAt`), bloqueia repetição via `profile.redeemed` | **OK** (string 200 KB descartada; inválido retornou `codeInvalid`) |
| `RequestLeaderboard` | `Leaderboard.onRequest` | `1 / 3` | `board` string `<= 32` na whitelist (`Catches`/`Species`/`Level`), lê cache 90 s | **OK** |
| `DoPrestige` | `Prestige.onPrestige` | `1 / 2` | Sem args; revalida `canPrestige` (`< 10`, `>= 1M` moedas, `>= 60` espécies) dentro de 1 `PlayerData.update`; cancela pesca via atributo `Prestige` | **OK** (bloqueado com `81k < 1M`) |
| `InspectPlayer` | `Inspect.onInspect` | `1 / 1` | `userId` inteiro finito `> 0`, jogador online com perfil carregado; envia só campos públicos | **OK** (`0` campos privados vazados) |
| `AquariumPreview` | `Aquarium.onPreview` | `6 / 10` | `requestId` `1..36`, `op` `1..16`, `slot`/`expectedVersion` finitos, `creatureId` `<= 64`, `variant` `<= 16`, valida `AquariumState.plan` | **OK** |
| `AquariumApply` | `Aquarium.onApply` | `4 / 8` | Mesma validação + idempotência `requestId` (20 últimos), `settle` antes de mudar taxa, `expectedVersion` e `plan` em 1 `PlayerData.update` | **OK** |
| `AquariumBuyLevel` | `Aquarium.onBuy` | `2 / 4` | `requestId` `1..36`, `levelId` `1..64`, `expectedVersion` finito, idempotência `requestId`, valida próximo nível/espécies/moedas em 1 `PlayerData.update` | **OK** |
| `AquariumClaimGoal` | `Aquarium.onClaim` | `3 / 6` | `requestId` `1..36`, `goalId` `1..64`, idempotência `requestId`, teto diário UTC `600` moedas em metas de sessão | **OK** |

### 2.2 Server → Client (11)

`FishingUpdate`, `AdventureReward`, `LeaderboardResult`, `TrainingUpdate`, `ProfileSnapshot`, `ShopResult`, `ClaimResult`, `CatchAnnounce`, `InspectResult`, `AquariumResult`, `PortalEffect` (agora declarado em `Net.PORTAL_EFFECT`). Nenhum aceita escrita do cliente.

---

## 3. Bugs e Riscos Encontrados e Corrigidos

| # | Sev. | Sistema / Arquivo | Causa | Correção | Commit | Prova do Reteste |
| :-: | :---: | :--- | :--- | :--- | :---: | :--- |
| 1 | **CRÍTICO** | `Leaderboard/init.luau` | Usava `"Board_" .. board .. "_v1"` tanto no Studio quanto em produção (testes no Studio com APIs ligadas poluiriam placares reais); escrevia scores inalterados a cada 60 s; `BindToClose` sequencial; cacheava `"???"` para sempre | Separado `_Studio_v1` vs `_v1`; dirty-tracking `lastSaved` (só escreve se mudou + limpeza em `PlayerRemoving`); `flushOnShutdown` paralelo (limite 10 s); não cacheia `"???"`; `#board <= 32` | `42648ae` | Play confirmou `RequestLeaderboard` ok, 0 erros, sync `_Studio_v1` verificado |
| 2 | **CRÍTICO** | `Monetization/init.luau` + `PlayerData/init.luau` | `ProcessReceipt` chamava `session:Save()` (assíncrono) e retornava `PurchaseGranted` antes da confirmação no DataStore; `PromptGamePassPurchaseFinished` não checava `pass.id ~= 0` | Implementado `PlayerData.savePurchaseAsync` (espera `OnAfterSave` e confirma `LastSavedData.purchases[purchaseId]`, padrão oficial do ProfileStore); guarda `updated` e `pass.id ~= 0 and passId > 0` | `42648ae` | Verificação estática limpa + `syncCheck.pdHasSavePurchase = true` + revisão contra `ProfileStore.luau` |
| 3 | **CRÍTICO** | `PlayerData/init.luau` | `onBeforeRelease` (liquidação final e `markExit` do Aquário) rodava em `OnSessionEnd`, quando `IsActive()` já é `false` no ProfileStore — em `BindToClose` / roubo externo as mudanças não eram salvas | Conectado `session.OnLastSave` (roda *antes* do save final em `Manual`/`External`/`Shutdown`) com guarda de execução única; `OnSessionEnd` só kicka se `player.Parent == Players` | `42648ae` | Play carregou/encerrou limpo; `migration-test.luau` `ok=true` |
| 4 | **CRÍTICO** | `PlayerData/init.luau` | `trySpend(NaN)` passava nas comparações e corrompia `p.coins` para `NaN`; `addCoins(math.huge)` corrompia `p.coins` para `inf` | Validação explícita `typeof == "number" and amount == amount and math.abs(amount) < math.huge` em `trySpend` e `addCoins` | `42648ae` | `luau-lsp`/`selene` limpos + Play sem corrupção |
| 5 | **CRÍTICO** | `Portals/init.luau` + `Training/init.luau` | Portais das ilhas de treino 2–4 têm `ZoneId = "lagoon"` e `TrainingIsland = 2..4`; o servidor só checava `Zones.minLevel` (1), permitindo qualquer novato entrar nas ilhas Recife (`1e5`), Abismo (`1e8`) e Celestial (`1e12`) | Exportado `Training.powerSum`; `Portals.tryUsePortal` valida `TrainingConfig.islandAllowed` no servidor e envia `TrainingUpdate` `islandLocked` (que o cliente já exibe em toast) | `42648ae` | Play: caminhar em `main_to_training_reef` com `~2940 PP` foi bloqueado (`portal2Blocked=true`); `lagoon_to_training_1` teleportou (`portal1Teleported=true`) |
| 6 | **ALTO** | `Fishing/init.luau` (servidor) | `onCast` não checava vivo/treinando/vara equipada; `ChildRemoved` e `TrainingStat` e `EquippedRod` só paravam Auto-Fish (não cancelavam pesca manual); Auto-Fish não checava `castSpotCheck`; `reset` não limpava `eventId`; `watchCharacter` sem fallback `WaitForChild("Humanoid", 5)` | Validação completa em `onCast` e `autoCanRun`/`onSetAutoFish`; cancelamento manual em `ChildRemoved`, `TrainingStat`, `EquippedRod`, `Prestige` e `CharacterRemoving`; fallback `Humanoid`; `s.eventId = ""` no `reset` | `42648ae` | Play: desequipar no meio da espera limpou `FishingState == ""` no servidor; `MAX_FIGHT_DRIFT` 40 studs bloqueou captura (`testA_driftBlocked=true`) |
| 7 | **ALTO** | `client/Features/Fishing/init.luau` + `server/Features/Fishing/init.luau` | Relançar dentro de `CAST_COOLDOWN` (1 s) ou rate limit deixava `state = "casting"` travado no cliente até desequipar a vara; `flat.Unit` podia gerar `NaN` | Servidor envia `{ event = "rejected", reason = "cooldown" }`; cliente trata silenciosamente + watchdog de 2,5 s + guarda `flatVec.Magnitude > 0` | `42648ae` | Play: relance rápido retornou `testD_cooldownReason = "cooldown"` sem travar |
| 8 | **ALTO** | `Progress/init.luau` + `Fishing/init.luau` | `ReportPerfect` aceitava `castId` de capturas de Auto-Fish (permitia completar missões "perfeitas" sem minigame) | `Progress.onCatch` recebe `isAuto` e só grava `lastCaught[player]` em capturas manuais | `42648ae` | Verificado no código e no fluxo de Auto-Fish no Play |
| 9 | **ALTO** | `Rod/init.luau` | `onBuy` separava `trySpend` e concessão da vara em 2 `PlayerData.update` (risco de perder moedas sem receber a vara); ecoava `rodId` sem limite de tamanho | Compra/verificação/débito/concessão atômicos em 1 único `PlayerData.update`; limite `#rodId <= 64` | `42648ae` | Play: ataque com string 200 KB descartado sem eco; compra sem moedas bloqueada |
| 10 | **ALTO** | `Config/Aquarium.luau` + `tools/aquarium-test.luau` | Meta de sessão `kinds2` (`kind="minigames", target=2`) ficou impossível com apenas 1 minigame (`reel`). (Também reportado pelo Agente 1 em `PEDIDOS.md`) | Trocado para `{ id = "catch6", kind = "catches", target = 6, coins = 60 }` (mesmas 60 moedas; `AquariumState` mantém `minigames` por compatibilidade). Agente 1 já atualizou `StringsUi.luau` | `42648ae` | `tools/aquarium-test.luau` passou (`ALL OK`) em Edit |
| 11 | **MÉDIO** | `server/init.server.luau` | `require(child)` sem `pcall` (1 erro de módulo derrubava todos os outros); `table.sort` sem desempate determinístico | `pcall(require, child)` + desempate por `name` | `42648ae` | Play: `[Server] booted, build 0.0.1` com 0 erros |
| 12 | **MÉDIO** | `Progress`, `Aquarium`, `Training`, `Net`, `Codes` | Faltava limite de string em `ClaimMilestone`/`TutorialEvent`/`Aquarium.op`, guarda `math.huge` em `ClaimMission`/`ReportPerfect`/`Training`/`Aquarium`, guarda anti-prompt duplicado em `Training.addPrompts`, preservação de `power` em `Training.addXp`, `PORTAL_EFFECT` em `Net.luau`, e suporte opcional a `expiresAt` em `Codes.luau` | Todos endurecidos no commit `42648ae` | `42648ae` | Play: ataque completo aos 25 remotes + `duplicateTrainingPrompts = 0` |
| 13 | **MÉDIO** | `PowerBar.luau` (Ag. 1) e `FishingVfx/init.luau` (Ag. 4) | `DevPowerBarSkin` lido sem `RunService:IsStudio()` | Reportado em `PEDIDOS.md`; **ambos corrigidos e confirmados** pelos Agentes 1 e 4 | (Ag. 1 e 4) | Confirmado em `PEDIDOS.md` |

---

## 4. Chances, Drops e Roleta (Prova Matemática e Amostragem)

- **`tools/roulette-test.luau` (Edit):** `ALL OK | avg coin x1.278`. As probabilidades exatas de todas as saídas finais (`exactProbability`) somam `1.000000` (tolerância `< 1e-9`). `exactOdds` bate com a Decisão #2: captura simples ou encolhida mantém a chance da criatura; crescimento/mutação/Cintilante multiplicam exatamente pela chance real (`ex.: criatura 1/50 + ×10 arco-íris + Cintilante = 1 em 43.384.563`).
- **`tools/drop-test.luau` (Edit):** `ALL OK` em **500.000 rolagens** (desvio `< 0,004` do peso teórico em todas as espécies); soma de `1/N` por raridade bate com `RARITY_WEIGHTS` em todas as 6 raridades:
  - `Common` (21 normais): `1/22 .. 1/264`
  - `Uncommon` (20 normais): `1/43 .. 1/511`
  - `Rare` (20 normais): `1/107 .. 1/642`
  - `Epic` (16 normais): `1/227 .. 1/680`
  - `Legendary` (15 normais): `1/850 .. 1/10.202`
  - `Mystic` (2 normais): `1/9.002 .. 1/11.252`
- **Catálogo de 106 criaturas:** 94 normais + 6 de evento (`C95`–`C100`, 1 para cada um dos 6 eventos que rodam a cada 12–20 min) + 6 de Natal (`C101`–`C106`, `xmas` de 1/dez a 6/jan, retorna todo ano). **Nenhuma criatura é impossível de obter.**

---

## 5. Análise de Economia e Progressão (Sem Alterar Preços/Ganhos)

Simulações executadas com `tools/economy-sim.js`, `tools/roulette-sim.js`, `tools/training-sim.js`, `tools/aquarium-sim.js` (`RATE_SCALE=0.2`, preços `[0, 3000, 12000, 50000]`) e auditoria completa de progressão/overflow com pesos reais + Roleta (`×1,281`):

- **Ritmo de zonas (`Journey`):** Nível 1 → 5 (Recife) = `320 XP` (~25–35 capturas, ~6–8 min); Nível 1 → 15 (Abismo) = `2.520 XP` (~130–180 capturas, ~30–40 min). Bem suave!
- **Ritmo de varas (pesca ativa pura, 13 s/captura, com Roleta ligada, sem contar Aquário/Baús/Missões/Marcos):**
  - `starter → coral` (500): **~1 min** (`483 c/min`)
  - `coral → crystal` (3.000): **~5 min** (`562 c/min`)
  - `crystal → storm` (15.000): **~21 min** (`712 c/min`)
  - `storm → astral` (60.000): **~1,2 h** (`816 c/min`)
  - `astral → celestial` (150.000): **~2,2 h** (`1.146 c/min`)
  - `celestial → abyss` (400.000): **~5,2 h** (`1.284 c/min`)
  - `abyss → mystic` (1.000.000): **~11,6 h** (`1.432 c/min`)
  - **Total pesca pura `starter → mystic`:** **~20,7 h** (cai para ~10–13 h somando Aquário nível 4, marcos `789.450` moedas, conquistas `74.650` moedas, baús e missões diárias).
- **Treino (`tools/training-sim.js`, 50% do tempo treinando):** Ilha 2 (`1e5` PP) em **9,9 h**, Ilha 3 (`1e8` PP) em **60,9 h**, Ilha 4 (`1e12` PP) em **101,7 h**, teto `1Qa` em **116,3 h**.
- **Aquário (`aquarium-sim.js`, offline desligado):** renda passiva representa **41%–57%** da renda total ao longo de 14 dias; teto de 12 Místicas Gigante+Dourada (+10% sinergia) = `30,1 c/s` (`1.805,8 c/min`, ~3,6× pesca ativa com Astral). Offline desligado e limitado a `25%`, `2 h` e teto duro de `5.000` moedas.
- **Estouro numérico (`< 2^53 = 9,007 × 10^15`):**
  - Maior jackpot real possível (4 giros: 3× `x100` + `cosmic` + Mística + Shiny + Hora Dourada + VIP + Prestígio 10 + Combo 10): `~6,09 × 10^9` moedas (**seguro**, 6 ordens de grandeza abaixo de `2^53` e de `IntValue` 64-bit).
  - Maior Poder de Pesca (soma): `2 × 10^15` (**seguro** `< 2^53`).
  - Maior numerador do Aquário (`180.576 cpm × 60.000 ms + 59.999`): `1,08 × 10^10` (**seguro** `< 2^53`).

### Paredes de Progresso e Anomalias (para decisão do João — nada alterado)
1. **Anomalia em `Config/Milestones.luau:27-28`:** `species64` paga `50.000` moedas, mas `species69` paga **`45.000`** (menor que o marco anterior!). *Proposta:* subir `species69` para `55.000` ou `60.000` (e `species73` para `70.000`).
2. **Parede no Campo de Treino 8–10 (`Config/Training.luau:84-86`):** campos 1→10 somam **10.167.500 moedas** (6,2× o custo de todas as 8 varas juntas = `1.628.500`), com os níveis 8/9/10 custando `1,4M / 3M / 5M`. Como o Prestígio zera moedas ao chegar em `1M`, comprar Campos 8–10 exige acumular moedas *sem* fazer Prestígio por dezenas de horas. *Proposta:* após coletar Analytics reais, avaliar reduzir Campos 8–10 (ex.: `600k / 1,2M / 2,5M`) ou permitir comprar com moedas pós-Prestígio.
3. **Salto `abyss → mystic` (400k → 1M):** `11,6 h` de pesca pura só para a última vara porque `luckBonus` aumenta pouco a receita média/min (`1.284 → 1.432 c/min`, +11%). *Proposta:* acompanhar no Analytics se o Aquário + Roleta já suavizam esse degrau antes de mexer no preço.
4. **Marcos de raridade (`allCommon`..`allLegendary`) exigem criaturas de Natal (`C101`–`C106`):** entre 7/jan e 30/nov ficam impossíveis de completar. *Proposta:* decidir se os marcos de raridade devem contar apenas espécies não sazonais (exige alinhar `Progress/init.luau` e `Collection/init.luau`).

---

## 6. Pendências que Dependem do João

1. **Criar os 5 itens de Monetização no Creator Hub** e preencher os IDs em `src/shared/Config/Products.luau` (passo a passo completo em [docs/PUBLICAR.md](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/docs/PUBLICAR.md#L44-L66)).
2. **Alterar `MaxPlayers` de `30` para `12`–`16` (recomendado: `14`)** em `File → Game Settings → Places` antes de publicar.
3. **Decidir sobre `Aquarium.LIVE_ENABLED`:** no place atual `ReplicatedStorage` já tem `AquariumUI = true` e `AquariumCredit = true` salvos, mas `Config/Aquarium.luau:54` ainda tem `LIVE_ENABLED = false` como fallback. Confirmar se quer ligar `LIVE_ENABLED = true` no código antes do lançamento para não depender só do atributo do place.
4. **Decisões de economia (acima):** `species69` (`45.000` vs `50.000`), marcos de raridade com/sem criaturas de Natal, e eventual ajuste futuro dos Campos de Treino 8–10.
5. **QA em celular físico** (iOS/Android) e **teste com 2 jogadores simultâneos** (`Test → Clients and Servers → 2 Players` — roteiro passo a passo de 7 pontos em [docs/PUBLICAR.md](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/docs/PUBLICAR.md#L97-L106)).
6. **Publicar o jogo** (nunca publicado por agentes), preencher o **Experience Questionnaire** (`All Ages`) e subir os textos/artes de [docs/PAGINA-DO-JOGO.md](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/docs/PAGINA-DO-JOGO.md).

---

## 7. Não Testado (Honestidade)

- **Celular físico (iOS / Android)** — não disponível no ambiente do agente.
- **2 jogadores simultâneos reais (`Clients and Servers`)** — o MCP do Studio só controla `Play` de 1 cliente; deixado roteiro completo de 7 testes em `docs/PUBLICAR.md`.
- **Jogo publicado em produção** — `DataStore` de produção, `OrderedDataStore` de produção, `AnalyticsService` no Creator Hub e compra real/Test Purchase com IDs reais de Robux (`id = 0` no momento).
- **Simulação de `BindToClose` em queda real de servidor Roblox** — `OnLastSave` e `flushOnShutdown` validados por leitura do código-fonte real do `ProfileStore` + Play normal.

---

## 8. Sugestões (Não Implementadas)

1. Persistir `bestSizeMult` em `Types.CollectionEntry` (pedido antigo do Codex no Mural) para manter o recorde de tamanho da roleta entre sessões.
2. Registrar `Analytics.coins` também para recompensas de level-up (`Journey`) e conquistas (`Achievements`) para fechar 100% do balanço de fontes de moedas no Creator Hub.
3. Corrigir o filtro de `season` no `tools/economy-sim.js` (hoje conta as 6 criaturas de Natal no pool normal, dando `Common: 22` em vez de `21`).
4. Adicionar uma métrica/painel interno ou flag remota para virar `AquariumOffline` no piloto após 1 semana de dados reais.

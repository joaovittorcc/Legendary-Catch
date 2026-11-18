# Bug Bash — Legendary Catch (2026-11-18)

Roteiro ponta a ponta no `Play` (Studio, Device Emulator mobile landscape `~750×381`) simulando um jogador novo.

## Resumo por Bloco

| Bloco | Escopo | Resultado |
|---|---|---|
| **1. Jogador novo** | Tutorial (`Siga a seta até o píer.`, `Pular`), 1ª pesca guiada (`2.36 s`, `Uncommon`, `reel`), presente de boas-vindas (`DailyGift`), `Próxima meta` (`NextGoal`) | **OK** (`Pular` liberou `NextGoal`: `Faltam 322 moedas para Vara de Coral`, `TextFits=true`) |
| **2. Minigames** | `precision` (`Rare`, `NOVA DESCOBERTA`), `rhythm` (`Epic`), `reel` (`Common`/`Uncommon`) e falha (`Escapou!`) | **OK via remote QA** (input de toque real não disparou no emulador via `user_mouse_input`) |
| **3. Oficina** | Compra de `coral`, bloqueio `noCoins` em `crystal`, `EquipRod` (`starter`/`coral`) | **OK** (`buy`/`equip`/`noCoins` validados; `ShopScreen` reconstrói apenas via `Hud.panelChanged`) |
| **4. Treino** | `TrainControl` (`dailyBonus` +15 XP, `levelUp`, `ring`, `TrainingRingResult`, `TrainingCombo = 1`), `TrainInstinct` | **Bug corrigido** (morto continuava ganhando XP; revalidado OK após correção) |
| **5. Telas e sistemas** | Conquistas, Placar vazio (`Seja o primeiro!`), Ajustes (`BEMVINDO`, `INVALIDO99`, sliders, `ReduceEffects`), Marcos (`species10`), Prestígio (requisitos) | **Bug corrigido** em `Achievements` (`Memórias do oceano` com `TextFits=false`); Coleção/Desafios não reabertos via toque (ver abaixo) |
| **6. Eventos do oceano** | `Workspace:SetAttribute("DevStartEvent", "aurora")`, banner `OceanEventHud`, pesca com evento ativo | **OK no banner e multiplicador** (`Aurora Boreal`, timer, `1 espécie exclusiva`); sem pesca longa até sortear `C100` |
| **7. Edge cases** | Desequipar vara na luta (`cancelled`), lançar fora da zona (`notInZone`), morrer treinando, morrer pescando, sair da zona na luta | **2 bugs corrigidos** (morte em treino e pesca); desvio `>20` studs via teleporte local `0.15 s` antes de `SubmitCatch` passou (ver abaixo) |
| **8. `ReduceEffects`** | `ReduceEffects = true` via `SaveSettings` durante treino, pesca e revelação | **OK** (0 erros no console) |
| **9. Device Emulator** | Mobile landscape (`~750×381`) verificado; iPhone retrato não alternado por falta de controle de preset do emulador via MCP | **Parcial** (landscape OK; retrato não testado) |

## Bugs Encontrados e Correções

| Data | Bloco/Passo | Bug | Causa | Correção | Status |
|---|---|---|---|---|---|
| 2026-11-18 | 4 / 7 (Treino + Morte) | Jogador morto (`Health = 0`) continuava com `TrainingStat` ativo e ganhando XP por ~5 s até `CharacterRemoving` | `near()` em `src/server/Features/Training/init.luau` checava apenas distância ao `spot`, e `initPlayer` só parava treino em `CharacterRemoving` | Exigido `humanoid.Health > 0` em `near()` e conectado `humanoid.Died -> stop(player, "respawn")` em `initPlayer` | **Corrigido e retestado no Play** (`TrainingStat == ""` e XP congelado em `0.3 s`) |
| 2026-11-18 | 7 (Pesca + Morte) | Morrer enquanto pescava (`waiting`/`fighting`) mantinha `FishingState = "waiting"` no cadáver por ~5 s até `CharacterRemoving` (a vara continuava dentro do `Character`, sem disparar `Unequipped`) | `watchCharacter` em `src/server/Features/Fishing/init.luau` só cancelava `autoEnabled` em `humanoid.Died`; `onCharacter` em `src/client/Features/Fishing/init.luau` não limpava em `hum.Died` | Adicionado cancelamento imediato de sessão manual (`reset` + `cancelled`) em `humanoid.Died` no servidor e `cleanup()` em `hum.Died` no cliente | **Corrigido e retestado no Play** (`FishingState == ""` imediato ao morrer) |
| 2026-11-18 | 5 (Conquistas) | Título `"Memórias do oceano"` (`species100.Title`) reportava `TextFits = false` na grade de 3 colunas em viewport mobile landscape | `leftLabel` em `src/client/Features/Achievements/init.luau` usava tamanho fixo 16 px sem `TextWrapped` nem `TextScaled` | Habilitado `TextScaled = true`, `TextWrapped = true` e `UITextSizeConstraint (MaxTextSize = size)` em `leftLabel` | **Corrigido e retestado no Play** (`badFits = []`, 0 estouros em toda a tela) |

## Itens Não Testados ou Parciais (para o João validar em aparelho/Studio)

1. **Input real de toque/mouse nos minigames (`Reel`/`Precision`/`Rhythm`) e abertura do menu `Mais` (`Collection`, `Missions`, `Shop`):** o emulador Touch do Studio não converteu os cliques enviados via `user_mouse_input` para `Activated` nos botões de HUD/minigame, então a resolução dos minigames foi validada com `SubmitCatch` e `CollectionScreen`/`MissionsScreen` (que dependem de `Hud.panelChanged` pelo menu `Mais`) não puderam ser re-inspecionadas via toque nesta sessão.
2. **Sair da zona no meio da luta (`MAX_FIGHT_DRIFT = 20`):** ao mover o `HumanoidRootPart` no cliente `-40` studs `0.15 s` antes de disparar `SubmitCatch`, a captura ainda foi aceita (`coins` subiu) provavelmente porque a janela de `0.15 s` no cliente congelado não replicou a nova posição ao servidor antes do `SubmitCatch` ser processado. Requer teste caminhando/puxando em condição real se desbloquear movimento ou testar com delay maior (`~0.5 s`).
3. **Rolagem orgânica de `C100_Aurora_Boreal_Viva` durante evento `aurora`:** validado o banner e a captura com o evento ativo, sem rodar dezenas de lançamentos até sortear especificamente a lendária exclusiva de evento (em `Play`, a 1ª captura sem histórico prévio ativa o override amigável Uncommon).
4. **iPhone retrato (`Device Emulator`):** os testes visuais desta sessão rodaram no preset ativo mobile landscape (`~750×381`); retrato e aparelho físico não foram testados.
5. **Console do Studio (`get_console_output`):** `0` erros e `0` warnings nos scripts do jogo; restam apenas os avisos normais do ambiente Studio sem APIs (`DataStoreService: StudioAccessToApisNotAllowed`, `rbxassetid://203785492` e reset de câmera do `ExecuteLuauActions`).

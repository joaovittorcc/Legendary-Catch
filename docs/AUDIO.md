# Áudio do Legendary Catch (`ReplicatedStorage.Audio`)

> Gerado pelo **Antigravity (Agente B)** para o **Codex** integrar em `src/client/Features/Audio/init.luau` (item 71 do `docs/PLANO-NOITE-2.md`).  
> Todos os **14** `Sound`s abaixo estão instalados em `ReplicatedStorage.Audio`, com `Volume` e `Looped` configurados, e foram validados em `Play` (`Client`) via `ContentProvider:PreloadAsync` (`14/14 Success`, `IsLoaded = true`, `TimeLength > 0`).

---

## 1. Como o áudio funciona hoje e o que faltava

### Estado atual (`src/client/Features/Audio/init.luau`)
- Cria dois `SoundGroup`s em `SoundService`: `Music` (`Volume = 0.5`) e `Effects` (`Volume = 0.7`), controlados na tela de Ajustes (`Features/Settings/init.luau`).
- Usa uma tabela fixa `IDs` com sons antigos publicados pela Roblox:
  - `hit`, `capture` e `level` usavam **o mesmo** `rbxassetid://12221990` (`electronicpingshort.wav`), diferenciados só por `PlaybackSpeed`.
  - `water` usava `rbxassetid://365551014` (`BathRunning`, som de água corrente de banheira, não de mar/gaivotas).
  - `coins` reutilizava `10066947742` (`RBLX UI Purchase`), `click` usava `10128760939`, `panel` `10066968815`, `miss` `10066914500`, `legendary` `10128766965`, `cast` `12222200`, `bite`/`tension` `12221944`, `music` `130053244401794`.
- Pontos de chamada existentes:
  - `Audio/init.luau`: `music`, `water` (por distância a `FishingZone`/`TrainingSpot`), `cast`, `bite`/`tension`, `TrainingUpdate.levelUp` (`level`), botões (`click`), `Hud.panelChanged` (`panel`), aumento de `Coins` (`coins`).
  - `Fishing/Ui.luau`: `hit` (com pitch por combo/`perfect`) e `miss` em `Ui.feedback`.
  - `Fishing/Reveal.luau`: `legendary` (abertura `rank >= 5`), `Audio.capture(rarity, shiny)` na chegada do peixe e `level` para `isRecord` / `isGiant`.
  - `RevealStyles/init.luau`: toca `style.cue` (`cast`/`hit`/`click`/`panel`/`bite`/`legendary`).
  - `Features/Juice/init.luau`: `level` no level-up de jogador (`AdventureReward`) e `coins` nas moedas voando.
  - `Features/Announcements/init.luau`: `panel` no anúncio global.

### Lacunas preenchidas com `ReplicatedStorage.Audio`
1. **Stingers distintos por raridade** (`Stinger_Common` .. `Stinger_Mystic`) para substituir o ping único repetido em `Audio.capture`.
2. **Ambiente marinho real** (`Ambience_Waves` com ondas e gaivotas em loop) no lugar de `BathRunning`.
3. **Música calma de ilha** (`Music_Island`, 151 s em loop, percussão melódica e clima tropical/cristal).
4. **Ding dedicado de `LevelUp`** (`Glockenspiel C6`, 2,71 s) separado dos acertos de minigame.
5. **Som dedicado de `Chest`** (baú a cada 10ª captura via `AdventureReward { kind = "chest" }`, hoje sem som próprio).
6. **Padronização centralizada** em `ReplicatedStorage.Audio` para o cliente ler/clonar ou copiar o `SoundId` diretamente da pasta sem depender de `IDs` soltos.

---

## 2. Catálogo em `ReplicatedStorage.Audio`

| Nome | Asset ID (`SoundId`) | Origem / Nome no Creator Store | Duração | Volume | Looped | Onde usar no cliente (`Codex`) |
|---|---|---|---:|---:|:---:|---|
| `Music_Island` | `rbxassetid://9039805221` | `APMOfficial` — *Crystal Pools* | 151.12 s | 0.25 | `true` | Trilha ambiente calma da ilha em loop (`SoundGroup = Music`). |
| `Ambience_Waves` | `rbxassetid://9112871354` | `ProSoundEffects` — *Shoreline Gulls 1 (SFX)* | 67.52 s | 0.18 | `true` | Ondas e gaivotas perto do mar/píer/lagoa (substitui `BathRunning`; modular volume pela distância à `FishingZone`/`TrainingSpot`). |
| `Stinger_Common` | `rbxassetid://9039611645` | `APMOfficial` — *Asleep in the Rocking Chair (sting)* | 3.47 s | 0.35 | `false` | Revelação de criatura `Common` (harpa leve e curta). |
| `Stinger_Uncommon` | `rbxassetid://1841173394` | `APMOfficial` — *Magical (a)* | 5.64 s | 0.38 | `false` | Revelação de criatura `Uncommon` (glissando ascendente mágico). |
| `Stinger_Rare` | `rbxassetid://9048764753` | `APMOfficial` — *Magical Meetup - Hit4* | 4.99 s | 0.42 | `false` | Revelação de criatura `Rare` (pizzicato + sinos encantados). |
| `Stinger_Epic` | `rbxassetid://1841173434` | `APMOfficial` — *Magical (b)* | 8.41 s | 0.48 | `false` | Revelação de criatura `Epic` (arpejo mágico longo). |
| `Stinger_Legendary` | `rbxassetid://1848016523` | `APMOfficial` — *Global Success StingA* | 7.99 s | 0.55 | `false` | Revelação de criatura `Legendary` (fanfarra triunfante; tocar na entrada/exibição da carta). |
| `Stinger_Mystic` | `rbxassetid://1836077264` | `APMOfficial` — *Epic And Ceremonial* | 10.00 s | 0.60 | `false` | Revelação de criatura `Mystic` (fanfarra épica/cerimonial máxima + anúncio global `Mystic`). |
| `LevelUp` | `rbxassetid://72644163309528` | Creator Store (gratuita) — *Glockenspiel C6* | 2.71 s | 0.45 | `false` | Subida de nível de jogador (`AdventureReward { kind = "level" }`), subida de nível de treino (`TrainingUpdate.levelUp`) e recorde/gigante. |
| `Coin` | `rbxassetid://10066947742` | `Roblox` — *RBLX UI Purchase (SFX)* | 0.87 s | 0.35 | `false` | Ganho de moedas (`Coins` subindo), compra na Oficina e moedas voando em `Features/Juice`. |
| `UiClick` | `rbxassetid://10128760939` | `Roblox` — *RBLX UI Select 01 (SFX)* | 0.58 s | 0.25 | `false` | Clique em qualquer `GuiButton` (Coleção, Oficina, Ajustes, Desafios, Pular). |
| `HitGood` | `rbxassetid://10066968815` | `Roblox` — *RBLX UI Select 02 (SFX)* | 0.49 s | 0.35 | `false` | Acerto no minigame (`Fishing/Ui.feedback` com `success = true`, mantendo variação de `PlaybackSpeed` por combo/`perfect`) e anel de treino (`Training`). |
| `HitMiss` | `rbxassetid://10066914500` | `Roblox` — *RBLX UI Back (SFX)* | 0.56 s | 0.35 | `false` | Erro no minigame (`Fishing/Ui.feedback` com `success = false`), erro no treino ou escape/rejeição leve. |
| `Chest` | `rbxassetid://1846248237` | `APMOfficial` — *Five Card Tricks "Win"* | 4.31 s | 0.50 | `false` | Abertura do baú surpresa (`AdventureReward { kind = "chest" }` a cada 10 capturas) e resgate de marcos/missões importantes. |

> **Observação para o Codex:** manter os sons de pesca que já funcionam bem em `Audio/init.luau` (`cast = 12222200`, `bite/tension = 12221944`, `panel = 10066968815`, `legendary` intro = `10128766965`) e apontar `music`, `water`, `capture(rarity)`, `level`, `coins`, `click`, `hit`, `miss` e o novo `chest` para `ReplicatedStorage:WaitForChild("Audio")` (atribuindo `SoundGroup = Audio.group("Music" | "Effects")`).

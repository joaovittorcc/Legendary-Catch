# Áudio do Legendary Catch

> Atualizado na **Revisão Final (Agente 4 — 2026-11-26)**.
> Cobre as **3 fontes de áudio** do cliente:
> 1. **14 templates** em `ReplicatedStorage.Audio` (usados por `src/client/Features/Audio/init.luau`)
> 2. **5 cues legados/oficiais Roblox** em `IDs` dentro de `src/client/Features/Audio/init.luau`
> 3. **6 cues ativos** (mais slots opcionais em `rbxassetid://0`) em `src/shared/Vfx/SfxKit.luau`

---

## 1. Arquitetura e Controle de Volume

- **SoundGroups unificados em `SoundService`:**
  - `Music` (`Volume` padrão `0.5`) — trilha ambiente (`Music_Island`).
  - `Effects` (`Volume` padrão `0.7`) — todos os efeitos sonoros, stingers, cliques, ambiente marinho e **todos os sons 2D/3D do `SfxKit`** (`SFX` e `UI` foram unificados ao grupo `Effects` para respeitar o slider de Ajustes em `Features/Settings/init.luau`).
- **Preload:** `Audio.start()` e `SfxKit.init()` chamam `ContentProvider:PreloadAsync` de forma assíncrona sobre todos os `Sound`s / `AssetId`s ativos (ignorando placeholders `rbxassetid://0`).
- **Proteções implementadas:**
  - `Audio.play(cue, volume?, speed?)` restaura o volume padrão do catálogo quando `volume` não é passado (evitando contaminação de chamadas anteriores com volume reduzido).
  - Cooldown curto (`0.22 s`) em `"cast"` impede som dobrado entre `CastCutscene.release` e o evento `FishingUpdate("cast")`.
  - Loop de tensão (`tension`) encerra tanto em `CharacterRemoving` quanto em `Humanoid.Died`, e em qualquer fim/cancelamento de pesca.
  - Volume de `Ambience_Waves` só dispara tween quando a distância a `FishingZone`/`TrainingSpot` muda significativamente (`> 1.5%`).

---

## 2. Catálogo em `ReplicatedStorage.Audio` (14 templates)

| Nome | Asset ID (`SoundId`) | Origem / Licença (Creator Store) | Duração | Volume | Looped | Uso no cliente (`Audio/init.luau`) |
|---|---|---|---:|---:|:---:|---|
| `Music_Island` | `rbxassetid://9039805221` | `APMOfficial` — *Crystal Pools* | 151.12 s | 0.25 | `true` | Trilha ambiente calma da ilha em loop (`SoundGroup = Music`). |
| `Ambience_Waves` | `rbxassetid://9112871354` | `ProSoundEffects` — *Shoreline Gulls 1 (SFX)* | 67.52 s | 0.18 | `true` | Ondas e gaivotas perto de `FishingZone` / `TrainingSpot` (`SoundGroup = Effects`). |
| `Stinger_Common` | `rbxassetid://9039611645` | `APMOfficial` — *Asleep in the Rocking Chair (sting)* | 3.47 s | 0.35 | `false` | Revelação `Common` (`Audio.capture`). |
| `Stinger_Uncommon` | `rbxassetid://1841173394` | `APMOfficial` — *Magical (a)* | 5.64 s | 0.38 | `false` | Revelação `Uncommon` (`Audio.capture`). |
| `Stinger_Rare` | `rbxassetid://9048764753` | `APMOfficial` — *Magical Meetup - Hit4* | 4.99 s | 0.42 | `false` | Revelação `Rare` (`Audio.capture`). |
| `Stinger_Epic` | `rbxassetid://1841173434` | `APMOfficial` — *Magical (b)* | 8.41 s | 0.48 | `false` | Revelação `Epic` (`Audio.capture`). |
| `Stinger_Legendary` | `rbxassetid://1848016523` | `APMOfficial` — *Global Success StingA* | 7.99 s | 0.55 | `false` | Revelação `Legendary` (`Audio.capture`). |
| `Stinger_Mystic` | `rbxassetid://1836077264` | `APMOfficial` — *Epic And Ceremonial* | 10.00 s | 0.60 | `false` | Revelação `Mystic` (`Audio.capture`). |
| `LevelUp` | `rbxassetid://72644163309528` | Creator Store (gratuita) — *Glockenspiel C6* | 2.71 s | 0.45 | `false` | Level-up do jogador (`Juice`), level-up de treino (`TrainingUpdate`), recorde/gigante (`Reveal`). |
| `Coin` | `rbxassetid://10066947742` | `Roblox` — *RBLX UI Purchase (SFX)* | 0.87 s | 0.35 | `false` | Ganho de moedas (`Coins` subindo) e moedas voando (`Juice`). |
| `UiClick` | `rbxassetid://10128760939` | `Roblox` — *RBLX UI Select 01 (SFX)* | 0.58 s | 0.25 | `false` | Clique em qualquer `GuiButton`. |
| `HitGood` | `rbxassetid://10066968815` | `Roblox` — *RBLX UI Select 02 (SFX)* | 0.49 s | 0.35 | `false` | Acerto no minigame (`Fishing/Ui.feedback`) e anel de treino (`Training`). |
| `HitMiss` | `rbxassetid://10066914500` | `Roblox` — *RBLX UI Back (SFX)* | 0.56 s | 0.35 | `false` | Erro no minigame (`Fishing/Ui.feedback`) e erro no treino. |
| `Chest` | `rbxassetid://1846248237` | `APMOfficial` — *Five Card Tricks "Win"* | 4.31 s | 0.50 | `false` | Baú surpresa (`AdventureReward { kind = "chest" }`). |

---

## 3. Cues em `src/client/Features/Audio/init.luau` (`IDs`)

Todos publicados oficialmente pela **Roblox** no Creator Store:

| Cue | Asset ID | Origem | Uso |
|---|---|---|---|
| `cast` | `rbxassetid://12222200` | `Roblox` — *swoosh.wav* | Arremesso (`CastCutscene.windup/release` e fallback `FishingUpdate("cast")`). |
| `bite` | `rbxassetid://12221944` | `Roblox` — *bass.wav* | Fisgada (`FishingUpdate("bite")`). |
| `tension` | `rbxassetid://12221944` | `Roblox` — *bass.wav* (loop grave + crescendo) | Luta durante o minigame; encerrado em fim/cancelamento/morte. |
| `legendary` | `rbxassetid://10128766965` | `Roblox` — *RBLX UI Swipe* | Abertura dramática de `Legendary` / `Mystic` (`Reveal` / `Cinematics`). |
| `panel` | `rbxassetid://10066968815` | `Roblox` — *RBLX UI Select 02* | Abertura de painéis (`Hud.panelChanged`) e anúncios globais. |

---

## 4. Cues em `src/shared/Vfx/SfxKit.luau`

### Ativos (IDs licenciados no Creator Store)

| Cue | Asset ID | Origem / Licença | Categoria (`SoundGroup`) | Uso |
|---|---|---|---|---|
| `charge_perfect_ding` | `rbxassetid://9048764475` | `APMOfficial` — *Magical Meetup - Hit2* | `SFX` (`Effects`) | Barra de força atinge faixa roxa perfeita (`FishingVfx`). |
| `minigame_perfect` | `rbxassetid://9048764475` | `APMOfficial` — *Magical Meetup - Hit2* | `SFX` (`Effects`) | Acerto perfeito no minigame (`MinigameFx`). |
| `water_splash_small` | `rbxassetid://9125702803` | `ProSoundEffects` — *splash 13* | `SFX` (`Effects`, 3D) | Queda leve/média da boia (`CastFlightFx`). |
| `water_splash_big` | `rbxassetid://9125703162` | `ProSoundEffects` — *splash 19* | `SFX` (`Effects`, 3D) | Queda forte da boia (`CastFlightFx`). |
| `bobber_dip` | `rbxassetid://9125702439` | `ProSoundEffects` — *splash 6* | `SFX` (`Effects`, 3D) | Mergulho de antecipação da boia (`BobberFx`). |
| `portal_teleport` | `rbxassetid://10128766965` | `Roblox` — *RBLX UI Swipe* | `SFX` (`Effects`) | Transição de portal entre ilhas. |

### Slots opcionais (`rbxassetid://0` — no-op silencioso intencional)

Entradas como `cast_whoosh`, `bite_*`, `minigame_hit/miss/win/lose`, `reveal_*`, `music_*`, `ui_hover/click` permanecem propositalmente como `"rbxassetid://0"` em `SfxKit.luau` porque **esses eventos já são sonorizados pelo `Audio/init.luau`** (evitando sons duplicados). `resolveSoundAsset()` ignora `"0"` silenciosamente sem gerar erro nem aviso de console. Caso no futuro o João queira sons extras exclusivos nesses slots, basta preencher o ID ou chamar `SfxKit.registerId(name, id)`.

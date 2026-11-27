# Relatório de Revisão Final — Agente 4 (Criaturas, Modelos, Animações, Efeitos, Cinemáticas e Som)

**Place:** `112666482424701` (Legendary Catch)
**Período:** 2026-11-26 21:30 BRT → 2026-11-27 00:45 BRT
**Status:** **CONCLUÍDO** — 106/106 criaturas e 8/8 varas inspecionadas em Edit + grades visuais, 17 módulos corrigidos (commits `cfcc1b9`, `aaddf77`, `ab8771a` + final), `stylua`/`selene`/`luau-lsp` 100% limpos, bateria completa provada em Play com 0 erros/warnings Lua novos, Studio deixado limpo em Edit e `.studio-lock` liberado.

---

## 1. Inventário Completo da Área

### 1.1 Modelos 3D e Assets no Place
| Item | Caminho / Local | Testado como | Resultado |
|---|---|---|---|
| 106 criaturas ativas (`C01`–`C106`) | `ReplicatedStorage.Creatures` (`Config/Creatures.LIST`) | Inspeção automatizada em Edit (`0` scripts, `0` `CanCollide`, `0` `MeshId` vazios) + `PreloadAsync` (`624/624 Success`) + 5 grades visuais (`106/106` conferidas) + framing/mutações/extremos em Play | **ok** (3 modelos sinalizados ao João na §4, sem gerar/subir mesh) |
| 100 criaturas planejadas (`C107`–`C206`, fora de `LIST`) | `ReplicatedStorage.Creatures` (`Config/Creatures.PLANNED`) | Conferência de presença em Edit (`206` modelos totais) | **ok** (fora do pool ativo) |
| 8 modelos de varas (`starter`..`mystic`) | `ServerStorage.RodModels`, `ReplicatedStorage.RodPreviews`, `tools/RodModelsBuilder.luau` | Edit (`8/8` presentes, `PrimaryPart` + `Tip` OK, 0 scripts/colisão) + grade visual `grid-rods.jpg` + Play (`RODS_8_REAL_CHECK ok=8/8`, pega conferida na mão) | **ok** (`RodModelsBuilder.luau` desatualizado 5/8 anotado na §4) |
| 14 templates de áudio + 5 IDs `Audio` + 6 IDs ativos `SfxKit` | `ReplicatedStorage.Audio`, `Audio/init.luau`, `SfxKit.luau`, `docs/AUDIO.md` | Play: `AUDIO_PRELOAD_ALL ok=22 fail=0`, `AUDIO_LIVE 19/19`, `AUDIO_GROUPS Music/Effects` unificados, `AUDIO_MUTE_SYNC 0.00/0.00`, 0 warnings no Output, `docs/AUDIO.md` atualizado | **corrigido e provado em Play** |
| Pipeline Blender | `tools/blender/**` | Leitura de `tools/blender/README.md` (nenhuma mesh gerada/enviada sem aprovação) | **ok** |

### 1.2 Módulos de Cliente e Compartilhados sob Responsabilidade do Agente 4
| Módulo | Arquivo | Testado como | Resultado |
|---|---|---|---|
| Paleta VFX | `src/shared/Vfx/Palette.luau` | Leitura + Play (raridades/carga) | **ok** |
| Motor VFX (pools/budget/flash/shake) | `src/shared/Vfx/VfxKit.luau` | Correções (`ALTO`) + Play 20 ciclos (`tasks 0->0`, `lights 0->0`, `camOff=0.0000`) + `ReduceEffects` ao vivo (`tempCcCleared=true`) | **corrigido e provado em Play** |
| Motor SFX (2D/3D/pools/grupos) | `src/shared/Vfx/SfxKit.luau` | Correções (`ALTO`: grupos `Music`/`Effects` unificados + `PreloadAsync` via instâncias `Sound`) + Play (`ok=22/22`, `SFX/UI/Music=0.00` ao mutar, 0 warnings) | **corrigido e provado em Play** |
| Áudio principal | `src/client/Features/Audio/init.luau` | Correções (`MÉDIO`: `defaultVolumes`, anti-duplo `"cast"`, `WaitForChild("Audio", 5)`, `Humanoid.Died`, tween condicional de ondas) + Play (`19/19` carregados) | **corrigido e provado em Play** |
| VFX de Pesca (orquestrador) | `src/client/Features/FishingVfx/init.luau` | Correções (`MÉDIO`: `castToken`, retry `findBobber`, `ReduceEffects` ao vivo, guarda `IsStudio` em `DevPowerBarSkin`) + Play | **corrigido e provado em Play** |
| VFX da Boia / Voo / Carga / Minigame | `src/client/Features/Vfx/{BobberFx,CastFlightFx,FishingChargeFx,MinigameFx}.luau` | Correções (`MÉDIO`: localização PT/EN em `MinigameFx`/`FishingChargeFx`) + Play | **corrigido e provado em Play** |
| Linha e Boia | `src/client/Features/Fishing/Line.luau` | Leitura + Play (lagoa/coral/abyss, boia, reação na água em acerto/erro, limpeza na morte) | **ok (provado em Play)** |
| Efeitos one-shot de Pesca | `src/client/Features/Fishing/Effects.luau` | Correções (`MÉDIO`: `pillar` respeita `ReduceEffects`; `shake` sem drift em `Scriptable`) + Play 20 ciclos (0 vazamento) | **corrigido e provado em Play** |
| Câmera de Pesca | `src/client/Features/Fishing/Camera.luau` | Correções (`ALTO`: `RespectCanCollide=true`, skip transparentes, `Y>=1.2`, `oldType` seguro, morte) + Play em Lagoa, Coral (`minCamY=2.32`, `minDist=7.85`) e Abyss | **corrigido e provado em Play** |
| Cutscene de Arremesso | `src/client/Features/Fishing/CastCutscene.luau` | Correções (`MÉDIO`: raycast/piso na órbita, `stop()` na morte, guarda no delay de áudio, eixos R6) + Play (interrupção por morte -> `letterbox=false`, `camType=Custom`) | **corrigido e provado em Play** |
| Presságio Lendário/Místico | `src/client/Features/Fishing/Omen.luau` | Correção (`BAIXO`: `ReduceEffects` ao vivo + guarda `gui.Parent`) + Play (`omenCC=true`, `omenGui=true` -> restaurado limpo) | **corrigido e provado em Play** |
| Revelação de Captura | `src/client/Features/Fishing/Reveal.luau` | Correções (`ALTO`: reativação das 20 cinemáticas com `FishingRoulette=true`, `FishingCamera.stop()`, morte/teleporte, `safeRevealCamera`, `pcall`) + Play | **corrigido e provado em Play** |
| Enquadramento e Mutações | `src/client/Features/Fishing/{RevealFraming,RevealMutation}.luau` | Play: 7 mutações × 4 formatos (`mutTests=28/28`) + 5 escalas extremas `×0.4..×10000` (`frameTests=20/20`) | **ok (provado em Play)** |
| Estilos de Revelação | `src/client/Features/RevealStyles/{init,Legendary}.luau` | Play: `10/10` estilos (normal + reduced) e `3/3` assinaturas (`C10`, `C23`, `C24`), 0 falhas | **ok (provado em Play)** |
| Cinemáticas (Motor, Receitas, Beats, Místicas 3D) | `src/client/Features/Fishing/Cinematics/**` | Correções (`MÉDIO`: `safeCinemaCam`, piso `Y>=1.2`, teleporte em `alive()`, `oldType` seguro) + Play (`20/20` receitas válidas; `C93` Mística + Lendária em Coral provadas com `sawCatchCinema=true`, `skipVis=true`, restauração 100%) | **corrigido e provado em Play** |
| Aura das Criaturas | `src/client/Features/CreatureAura/{init,CosmicOrbit}.luau` | Correções (`ALTO`: arcos <=2.4 Hz, loop único, culling 150 studs, reescala dinâmica, `ReduceEffects` ao vivo, `FALLBACK.Mystic` + `C94`) + Play (`auraLightOff=true`, `leftoverAuras=0`) | **corrigido e provado em Play** |
| Movimento das Criaturas | `src/client/Features/CreatureMotion/init.luau` | Leitura + Play (cinemática `C93` skinned + 20 ciclos) | **ok** |
| Movimento do Personagem | `src/client/Features/CharacterMotion/init.luau` & `AvatarVisuals/Pose.luau` | Correções (`MÉDIO`: eixos R6 + `RootJoint` + `Left Shoulder` + `DescendantAdded` + morte) + Play (`R6_POSE_CHECK rotXYZ=0.00,0.00,0.80 restored=true`) | **corrigido e provado em Play** |
| Troféu no Pedestal | `src/client/Features/TrophyPresentation/init.luau` | Correção (`BAIXO`: esconder `TrophySign` no `CatchPhoto`) + Play (`before=true during=false after=true`) | **corrigido e provado em Play** |
| Outros Jogadores Pescando | `src/client/Features/Others/init.luau` | Correções (`MÉDIO`: race `FishingRarity` na cor da linha/boia, `UIStroke.Color`, `TextScaled`) + lint/typecheck | **corrigido (simulação real 2P na §5)** |
| Movimento no Aquário | `Collection/AquariumWorld.luau` & `AquariumTank.luau` (auditoria somente leitura) | Play: `AQUARIUM_CHECK tanks=1 modelsInTanks=10`, sem erros | **ok** |

### 1.3 Capturas Salvas (`art/preview/revisao/agente-4/`)
- `grid-mystic-legendary.jpg` — 2 Místicas + 18 Lendárias (`20/20`)
- `grid-epic.jpg` — 21 Épicas (`21/21`, pós-preload)
- `grid-rare.jpg` — 22 Raras (`22/22`)
- `grid-uncommon.jpg` — 21 Incomuns (`21/21`)
- `grid-common.jpg` — 22 Comuns (`22/22`)
- `grid-rods.jpg` — 8 Varas (`starter`..`mystic`) com pontas `LineAttachment` marcadas
- `play-mystic-c93-cinema.jpg` — Play pós-captura Mística (`C93_Ouroboros_Cosmico`) no píer da Lagoa com restauração de câmera e vara equipada
- `play-coral-legendary.jpg` — Play em Recife de Coral após captura Lendária com câmera restaurada e troféu `Ouroboros` visível

---

## 2. Tabela das 106 Criaturas Ativas (`Config.Creatures.LIST`)

> **Resumo final (`106/106` inspecionadas em Edit + 5 grades visuais):**
> - **106/106** presentes em `ReplicatedStorage.Creatures`, **0** scripts internos, **0** `CanCollide = true`, **0** `MeshId` vazios, **`CREATURE_PRELOAD total=624 ok=624 fail=0`**.
> - **103/106** visualmente OK e prontas para lançamento (inclusive `C62_Dragao_Dourado`, recuperado desde a auditoria antiga, e `C93_Ouroboros_Cosmico` skinned 20 bones).
> - **3 modelos sinalizados ao João para avaliação/ajuste opcional de malha/rotação (§4):** `C91_Hipocampo_Imperial` (parece cavaleiro de armadura), `C104_Polvo_Presente` (sem rosto em `+Z`), `C54_Peixe_Vela_Solar` (perfil lateral em `+Z`).

| # | ID | Raridade | Estilo | Tamanho (X×Y×Z) | Partes / Meshes / Neon / Bones | PrimaryPart | Pivô Offset | Flags Edit | Inspeção Visual (Grade) |
|---:|---|---|---|---|---|---|---:|---|---|
| 1 | `C01_Bolhinha_Azul` | Common | `bubbles` | 1.90x2.27x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 2 | `C02_Sardinha_Solar` | Common | `splash` | 1.17x1.42x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 3 | `C03_Siri_Pipoca` | Common | `splash` | 2.65x2.52x2.27 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 4 | `C04_Baiacu_Nuvem` | Uncommon | `bubbles` | 2.80x2.54x2.57 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 5 | `C05_Medusinha_Estelar` | Uncommon | `spark` | 2.04x2.80x1.94 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 6 | `C06_Cavalo_Marinho_Coral` | Uncommon | `prism` | 0.72x2.80x1.21 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 7 | `C07_Arraia_Prisma` | Rare | `prism` | 2.95x2.10x2.84 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 8 | `C08_Enguia_Trovao` | Rare | `storm` | 2.95x2.83x2.73 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 9 | `C09_Guardiao_Cristal` | Epic | `crystal` | 3.14x1.77x2.63 | `P=8,M=8,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 10 | `C10_Leviata_Astral` | Legendary | `cosmic` | 3.00x2.88x2.51 | `P=4,M=4,N=0,B=0` | `Body` | 0.43 | OK | OK (grade conferida) |
| 11 | `C11_Pingo_Lanterna` | Common | `spark` | 1.36x2.65x1.49 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 12 | `C12_Camarao_Confete` | Common | `splash` | 2.16x2.86x2.38 | `P=5,M=5,N=0,B=0` | `Body` | 0.01 | OK | OK (3/4 corrigido por FACE_YAW em RevealFraming) |
| 13 | `C13_Linguado_Sonolento` | Common | `bubbles` | 1.26x1.48x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 14 | `C14_Polvinho_Aquarela` | Uncommon | `prism` | 2.80x2.46x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 15 | `C15_Tartaruga_Musgo` | Uncommon | `bubbles` | 2.47x2.54x2.86 | `P=6,M=6,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 16 | `C16_Voador_Brisa` | Uncommon | `splash` | 2.78x2.80x1.33 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 17 | `C17_Martelo_Coral` | Rare | `prism` | 2.15x1.58x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 18 | `C18_Lula_Neon` | Rare | `spark` | 2.95x2.87x2.60 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 19 | `C19_Peixe_Lua_Dourado` | Rare | `cosmic` | 2.31x2.80x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 20 | `C20_Raia_Vulcanica` | Epic | `magma` | 3.20x2.66x2.98 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 21 | `C21_Baleia_Nebulosa` | Epic | `cloud` | 2.75x2.68x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 22 | `C22_Serpente_Glacial` | Epic | `frost` | 2.75x3.07x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 23 | `C23_Kraken_Trovejante` | Legendary | `storm` | 3.12x2.77x3.48 | `P=6,M=6,N=2,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 24 | `C24_Fenix_das_Mares` | Legendary | `magma` | 2.93x3.00x1.17 | `P=4,M=4,N=0,B=0` | `Body` | 0.40 | OK | OK (grade conferida) |
| 25 | `C25_Ourico_Gelatina` | Common | `bubbles` | 2.65x1.97x2.14 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 26 | `C26_Peixe_Pipa` | Common | `splash` | 1.38x1.81x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 27 | `C27_Ermitao_Cristal` | Uncommon | `crystal` | 2.86x2.71x2.19 | `P=5,M=5,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 28 | `C28_Nautilo_Aurora` | Rare | `prism` | 2.65x2.60x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 29 | `C29_Dragao_Folha` | Epic | `spark` | 3.20x3.02x0.78 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 30 | `C30_Tartaruga_Ilha` | Legendary | `crystal` | 2.77x2.60x2.81 | `P=6,M=4,N=2,B=0` | `Body` | 0.03 | OK | OK (grade conferida) |
| 31 | `C31_Carpa_Celeste` | Uncommon | `cloud` | 2.13x1.30x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 32 | `C32_Espadarte_Relampago` | Rare | `storm` | 1.57x2.95x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 33 | `C33_Orca_Aurora` | Epic | `frost` | 2.20x2.39x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 34 | `C34_Serpente_Arco_Iris` | Legendary | `prism` | 2.49x3.00x2.53 | `P=4,M=4,N=0,B=0` | `Body` | 0.24 | OK | OK (grade conferida) |
| 35 | `C60_Hidra_das_Profundezas` | Legendary | `storm` | 3.55x3.33x2.24 | `P=10,M=6,N=4,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 36 | `C61_Baleia_Celestial` | Legendary | `cosmic` | 2.71x2.55x3.55 | `P=10,M=6,N=4,B=0` | `Body` | 0.26 | OK | OK (grade conferida) |
| 37 | `C62_Dragao_Dourado` | Legendary | `storm` | 3.55x3.33x2.30 | `P=9,M=6,N=3,B=0` | `Body` | 0.76 | PIVOFF=0.76 | OK (corrigido desde auditoria antiga; dragão dourado/azul nítido) |
| 38 | `C63_Grifo_Marinho` | Legendary | `cloud` | 3.17x3.50x1.67 | `P=8,M=6,N=2,B=0` | `Body` | 0.42 | OK | OK (grade conferida) |
| 39 | `C64_Guardiao_Abissal` | Legendary | `magma` | 2.34x3.48x1.78 | `P=9,M=9,N=3,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 40 | `C50_Tubarao_Baleia_Estrelado` | Rare | `cosmic` | 2.48x1.57x2.86 | `P=6,M=6,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 41 | `C51_Lanterna_Abissal` | Rare | `spark` | 2.45x2.95x2.71 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 42 | `C52_Cavalo_Marinho_Real` | Rare | `crystal` | 1.26x2.85x1.30 | `P=5,M=5,N=0,B=0` | `Body` | 0.36 | OK | OK (grade conferida) |
| 43 | `C53_Moreia_Voltaica` | Rare | `storm` | 2.94x2.85x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 44 | `C54_Peixe_Vela_Solar` | Rare | `magma` | 3.18x2.94x1.99 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | REVER EIXO (de perfil lateral esquerdo em +Z) |
| 45 | `C55_Caranguejo_Rei_Gelo` | Rare | `frost` | 2.86x2.42x1.92 | `P=7,M=7,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 46 | `C56_Dragao_de_Coral` | Epic | `prism` | 3.20x2.90x2.77 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 47 | `C57_Manta_Galactica` | Epic | `cosmic` | 3.20x2.47x1.84 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 48 | `C58_Tubarao_Fantasma` | Epic | `frost` | 2.43x2.78x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 49 | `C59_Narval_Unicornio` | Epic | `crystal` | 2.42x3.20x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 50 | `C35_Bagre_Bigodudo` | Common | `bubbles` | 2.00x2.65x2.14 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 51 | `C36_Peixe_Bolha_Rosa` | Common | `bubbles` | 2.44x2.52x2.86 | `P=5,M=5,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 52 | `C37_Caramujo_Doce` | Common | `splash` | 1.78x1.84x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 53 | `C38_Estrela_Sonolenta` | Common | `spark` | 2.33x2.65x1.78 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 54 | `C39_Lambari_Prata` | Common | `splash` | 1.70x2.01x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 55 | `C40_Caranguejo_Bolacha` | Common | `splash` | 2.65x2.21x1.91 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 56 | `C41_Palhaco_Neon` | Common | `spark` | 1.82x2.04x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 57 | `C42_Lulinha_Gota` | Common | `bubbles` | 2.47x2.65x2.02 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 58 | `C43_Baiacu_Algodao_Doce` | Uncommon | `cloud` | 2.86x2.86x2.36 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 59 | `C44_Arraia_Pintada` | Uncommon | `prism` | 2.80x2.36x1.62 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 60 | `C45_Tartaruguinha_Coral` | Uncommon | `bubbles` | 2.59x2.73x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 61 | `C46_Peixe_Leque` | Uncommon | `splash` | 2.80x2.74x2.60 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 62 | `C47_Medusa_Lanterna` | Uncommon | `spark` | 2.02x2.80x1.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 63 | `C48_Peixe_Anjo_Real` | Uncommon | `prism` | 1.74x2.73x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 64 | `C49_Polvo_Bolinhas` | Uncommon | `bubbles` | 2.80x2.33x2.79 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 65 | `C75_Leao_Marinho_Dourado` | Rare | `magma` | 1.93x2.86x2.27 | `P=6,M=6,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 66 | `C76_Raia_Aurora` | Rare | `prism` | 2.86x1.92x1.76 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 67 | `C77_Cavalo_Marinho_Relogio` | Rare | `crystal` | 1.31x2.85x1.42 | `P=5,M=5,N=0,B=0` | `Body` | 0.15 | OK | OK (grade conferida) |
| 68 | `C78_Lagosta_Armadura` | Rare | `frost` | 2.71x2.95x1.58 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 69 | `C79_Mantarraia_Vitral` | Rare | `prism` | 2.95x2.76x0.47 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 70 | `C80_Peixe_Pavao_Eletrico` | Rare | `storm` | 2.28x2.61x2.85 | `P=6,M=6,N=0,B=0` | `Body` | 0.28 | OK | OK (3/4 lateral esquerdo em +Z) |
| 71 | `C81_Enguia_Fita_de_Seda` | Rare | `cloud` | 0.60x2.85x2.56 | `P=5,M=5,N=0,B=0` | `Body` | 0.19 | OK | OK (grade conferida) |
| 72 | `C93_Ouroboros_Cosmico` | Mystic | `cosmic` | 2.00x3.50x3.15 | `P=3,M=2,N=0,B=20` | `RootPart` | 0.12 | PP=RootPart,UNANCH=2,INVIS=1 | OK (skinned 20 bones; grade + cinemática Mística provadas em Play) |
| 73 | `C94_Mare_Primordial` | Mystic | `cosmic` | 5.54x3.42x2.21 | `P=9,M=9,N=0,B=0` | `Body` | 0.03 | SCALE=5.54 | OK (escala 5.54; grade + framing/mutações provados em Play) |
| 74 | `C65_Tilapia_Moranguinho` | Common | `bubbles` | 1.83x2.00x2.86 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 75 | `C66_Ourico_Pompom` | Common | `spark` | 2.86x2.57x2.61 | `P=2,M=2,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 76 | `C67_Lesma_do_Mar_Arco_iris` | Common | `prism` | 2.10x2.35x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 77 | `C68_Peixe_Biscoito` | Common | `splash` | 2.40x2.24x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 78 | `C69_Ermitao_Xicara` | Common | `bubbles` | 2.86x2.01x2.05 | `P=5,M=5,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 79 | `C70_Agua_viva_Lanterna` | Uncommon | `spark` | 2.00x2.86x2.00 | `P=3,M=3,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 80 | `C71_Peixe_Espada_Neon` | Uncommon | `storm` | 1.15x1.62x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 81 | `C72_Tartaruga_Pergaminho` | Uncommon | `crystal` | 2.80x2.07x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 82 | `C73_Polvo_Origami` | Uncommon | `cloud` | 2.80x2.12x2.69 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 83 | `C74_Baiacu_Balao_de_Festa` | Uncommon | `bubbles` | 2.86x2.85x2.26 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 84 | `C82_Kitsune_Aquatica` | Epic | `spark` | 2.80x2.57x2.09 | `P=6,M=6,N=0,B=0` | `Body` | 0.76 | PIVOFF=0.76 | OK (grade nítida; PIVOFF=0.76) |
| 85 | `C83_Golfinho_Trovao` | Epic | `storm` | 1.65x3.20x3.04 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 86 | `C84_Tubarao_Martelo_de_Cristal` | Epic | `crystal` | 2.72x1.87x3.14 | `P=8,M=8,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 87 | `C85_Lula_Galaxia` | Epic | `cosmic` | 3.19x3.20x2.51 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 88 | `C86_Cervo_Coral` | Epic | `splash` | 1.90x2.95x2.07 | `P=6,M=6,N=0,B=0` | `Body` | 0.27 | OK | OK (grade conferida) |
| 89 | `C87_Salamandra_de_Lava` | Epic | `magma` | 3.07x2.56x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 90 | `C88_Rei_Tritao_Colossal` | Legendary | `storm` | 2.18x3.55x1.68 | `P=11,M=6,N=5,B=0` | `Body` | 0.16 | OK | OK (grade conferida) |
| 91 | `C89_Dragao_de_Jade` | Legendary | `cloud` | 2.71x3.32x3.44 | `P=11,M=6,N=5,B=0` | `Body` | 0.55 | OK | OK (grade conferida) |
| 92 | `C90_Tartaruga_Mundo` | Legendary | `crystal` | 2.11x3.30x3.34 | `P=12,M=7,N=5,B=0` | `Body` | 1.21 | PIVOFF=1.21 | OK (grade nítida; PIVOFF=1.21 compensado por Framing) |
| 93 | `C91_Hipocampo_Imperial` | Legendary | `prism` | 2.13x3.29x3.44 | `P=11,M=7,N=4,B=0` | `Body` | 0.37 | OK | REVER MODELO (parece cavaleiro de armadura, não hipocampo) |
| 94 | `C92_Serafim_do_Mar` | Legendary | `cosmic` | 3.21x3.20x1.00 | `P=15,M=7,N=8,B=0` | `Body` | 0.18 | OK | OK (grade conferida) |
| 95 | `C95_Peixe_Vagalume_Real` | Rare | `spark` | 2.12x2.56x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 96 | `C96_Lua_Dourada` | Epic | `cosmic` | 2.42x3.20x2.41 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 97 | `C97_Raia_Tempestade` | Epic | `storm` | 3.20x2.28x2.56 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 98 | `C98_Coral_Ancestral_Vivo` | Epic | `crystal` | 2.79x2.72x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 99 | `C99_Baleia_Fantasma` | Legendary | `cloud` | 2.40x2.24x3.39 | `P=11,M=6,N=5,B=0` | `Body` | 0.09 | OK | OK (grade conferida) |
| 100 | `C100_Aurora_Boreal_Viva` | Legendary | `frost` | 3.48x3.25x2.84 | `P=7,M=7,N=2,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 101 | `C101_Rena_do_Mar` | Common | `frost` | 2.18x2.19x2.86 | `P=5,M=5,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 102 | `C102_Peixe_Arvore_de_Natal` | Uncommon | `spark` | 1.95x2.86x2.54 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 103 | `C103_Boneco_de_Gelo_Marinho` | Rare | `frost` | 2.31x2.86x1.80 | `P=6,M=6,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 104 | `C104_Polvo_Presente` | Epic | `spark` | 3.85x2.60x3.98 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | REVER FACE (sem rosto visível de frente +Z) |
| 105 | `C105_Estrela_do_Natal` | Epic | `prism` | 2.94x3.20x1.23 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | OK (grade conferida) |
| 106 | `C106_Rei_do_Gelo_Natalino` | Legendary | `frost` | 3.31x3.43x2.15 | `P=6,M=6,N=0,B=0` | `Body` | 0.02 | OK | OK (grade conferida) |

---

## 3. Lista de Bugs Encontrados, Correções e Provas em Play

> Todos os 17 arquivos alterados passaram em `stylua`, `selene` (**0 erros, 0 warnings**) e `luau-lsp analyze` (**0 erros**).

### ALTO
1. **Todas as 20 cinemáticas de Lendárias e Místicas eram puladas com `FishingRoulette=true`** (`cfcc1b9`)
   - **Arquivo:** `src/client/Features/Fishing/Reveal.luau:245`
   - **Causa:** `Fishing/init.luau:297` marca `shown.fromShow = true` após `CatchShow` curto, e `Reveal.luau` exigia `if recipe and not fromShow then`, bloqueando todas as 18 Lendárias e 2 Místicas.
   - **Correção:** Alterado para `if recipe then` com `FishingCamera.stop()` antes, mais fallback de áudio `"legendary"` para raridade `>= 5`.
   - **Prova em Play:** `MYSTIC_CINEMA_PROOF caught=C93_Ouroboros_Cosmico spins=1 sawCatchShow=true sawCatchCinema=true sawCinemaWater=true` + `CORAL_LEGENDARY_CINEMA saw=true skipBtn=true skipVis=true` + `POST_MYSTIC_RESTORE camType=Custom fov=70.0`.

2. **`SfxKit` ignorava controles de volume de Ajustes e emitia warnings no `PreloadAsync`** (`cfcc1b9`, `aaddf77`)
   - **Arquivo:** `src/shared/Vfx/SfxKit.luau`
   - **Causa:** Criava `SoundGroup`s isolados (`LegendaryCatch_SFX/Music/UI`) em vez de usar `SoundService.Music`/`Effects`; na 1ª versão do preload, passar strings `"rbxassetid://..."` causava `Asset type does not match requested type` (reportado pelo Agente 2 em `PEDIDOS.md`).
   - **Correção:** Unificado aos grupos `SoundService.Music` e `SoundService.Effects` + `PreloadAsync` via instâncias `Sound` temporárias.
   - **Prova em Play:** `AUDIO_GROUPS: Music(vol=0.60), Effects(vol=0.80)`, `AUDIO_PRELOAD_ALL ok=22 fail=0`, `AUDIO_MUTE_SYNC SFX=0.00 UI=0.00 Music=0.00`, 0 warnings dos IDs do `SfxKit`.

3. **Caixas invisíveis `FishingZone` (`CanQuery=true`) puxavam `FishingCamera` para a cabeça em Coral Reef e Star Abyss** (`cfcc1b9`)
   - **Arquivo:** `src/client/Features/Fishing/Camera.luau` (+ pedido ao Agente 3 em `PEDIDOS.md`)
   - **Correção:** `RespectCanCollide = true`, skip de partes `Transparency >= 0.8`, piso `Y >= 1.2`, `oldType` seguro (nunca salva `Scriptable`), parada na morte.
   - **Prova em Play:** `CORAL_CAMERA_CHECK gotBite=true minCamY=2.32 minDist=7.85 maxDist=20.46 camType=Scriptable` + restauração pós-morte em Star Abyss (`DEATH_INTERRUPT_RESTORE camType=Custom`).

4. **Violação de acessibilidade (>3 piscadas/s), 1 `RenderStepped` por aura, escala defasada em `fromShow` e falta de `ReduceEffects` ao vivo em `CreatureAura`** (`cfcc1b9`)
   - **Arquivo:** `src/client/Features/CreatureAura/init.luau`
   - **Correção:** Cadência segura dos arcos (`0.42–0.65 s`, <=2.4 Hz), loop único com culling a `150` studs, rastreio dinâmico de `model:GetScale()`, `ReduceEffects` ao vivo (incluindo `PointLight`), `FALLBACK.Mystic` e spec da `C94_Mare_Primordial`.
   - **Prova em Play:** `REDUCE_LIVE_CHECK auraLightOff=true`, `PERF_CLEANUP leftoverAuras=0`, `LEAK_20_CYCLES ws=13->13`.

5. **`VfxKit.cameraShake` corrompia `Humanoid.CameraOffset` e deslocava câmeras `Scriptable`; `pulseColorCorrection` vazava em `ReduceEffects`** (`cfcc1b9`)
   - **Arquivo:** `src/shared/Vfx/VfxKit.luau`
   - **Correção:** Restauração garantida de `CameraOffset`, verificação `FuzzyEq(lastAppliedCamCf)` em `Scriptable`, cancelamento de `inTw` e limpeza de `activeTempPostFx` ao ativar `ReduceEffects`, `ZIndexBehavior = Sibling`.
   - **Prova em Play:** `LEAK_20_CYCLES tasks=0->0 lights=0->0 camOff=0.0000`, `REDUCE_LIVE_CHECK tempCcCleared=true`.

6. **Briga de câmera entre `FishingCamera` e `Reveal`, falta de cancelamento por morte/teleporte e clipping em tamanhos extremos** (`cfcc1b9`)
   - **Arquivo:** `src/client/Features/Fishing/Reveal.luau`
   - **Correção:** `FishingCamera.stop()` antes da câmera do `Reveal`, `oldType` seguro, cancelamento por `Humanoid.Health <= 0` ou teleporte (`> 25` studs), `safeRevealCamera` (`RespectCanCollide=true`, `Y >= 1.2`) e `pcall` com restauração garantida.
   - **Prova em Play:** `MUTATIONS_AND_EXTREMES frameTests=20 frameFails=0` (`×0.4` até `×10000`) + `POST_MYSTIC_RESTORE` 100% limpo.

### MÉDIO
7. **Mutação permanente de volume, som dobrado `"cast"`, falta de `Humanoid.Died` e tweens eternos de ondas em `Audio/init.luau`** (`cfcc1b9`) — Provado em Play (`AUDIO_LIVE 19/19`).
8. **Cutscene de arremesso sem colisão na órbita, sem `stop()` na morte e eixos R6 invertidos (`CastCutscene.luau`)** (`cfcc1b9`) — Provado em Play (`DEATH_INTERRUPT_RESTORE letterbox=false camType=Custom`).
9. **Câmera de `Cinematics/init.luau` sem colisão/piso em `waterShot`/`showCatch` nem cancelamento por teleporte** (`cfcc1b9`) — Provado em Play (`C93` + Coral Lendária).
10. **`Effects.pillar` ignorava `ReduceEffects` e `Effects.shake` podia acumular drift (`Effects.luau`)** (`cfcc1b9`) — Provado em Play (`LEAK_20_CYCLES`).
11. **`FishingVfx/init.luau` — splash atrasado/órfão, `findBobber` sem retry, `ReduceEffects` congelado na carga e `DevPowerBarSkin` sem `IsStudio`** (`cfcc1b9`, pedido Agente 2) — Provado em Play.
12. **Textos PT-BR hardcoded em `MinigameFx.luau` e `FishingChargeFx.luau`** (`cfcc1b9`) — Localizados PT/EN via `Strings`/`StringsUi`/`LocaleId`.
13. **Eixos R6, juntas replicadas tarde e parada na morte em `CharacterMotion/init.luau` e `AvatarVisuals/Pose.luau`** (`cfcc1b9`) — Provado em Play (`R6_POSE_CHECK rotXYZ=0.00,0.00,0.80 restored=true`).
14. **Race condition de `FishingRarity` e clipping de texto em `Others/init.luau`** (`cfcc1b9`) — Validado em lint/typecheck.

### BAIXO
15. **Placa do troféu não escondia ao entrar no Modo Foto (`TrophyPresentation/init.luau`)** (`cfcc1b9`) — Provado em Play (`TROPHY_PHOTOMODE before=true during=false after=true`).
16. **Pulso de `Omen.luau` continuava se `ReduceEffects` fosse ligado durante a luta** (`aaddf77`) — Corrigido e validado em Play (`Omen` limpo).

---

## 4. Pendências que Dependem do João

1. **Lista priorizada de modelos de criaturas para possível ajuste/redesenho (nenhuma mesh nova gerada/subida):**
   - **Prioridade 1 (coerência visual):** `C91_Hipocampo_Imperial` (Lendário) — o modelo atual parece um cavaleiro bípede de armadura azul e dourada em vez de um hipocampo (cavalo-marinho).
   - **Prioridade 2 (orientação):** `C104_Polvo_Presente` (Épico) — sem rosto visível olhando para `+Z`; `C54_Peixe_Vela_Solar` (Raro) — virado de perfil lateral esquerdo em `+Z` (pode girar o modelo ou adicionar entrada em `FACE_YAW` de `RevealFraming.luau`).
   - **Prioridade 3 (opcional):** `C80_Peixe_Pavao_Eletrico` (Raro) está em 3/4 lateral, mas lê bem.
2. **`tools/RodModelsBuilder.luau`:** hoje define apenas 5 das 8 varas presentes em `ServerStorage.RodModels` (`starter..mystic`). Vale sincronizar antes de rodar o builder novamente.
3. **Warning externo observado no boot de Play:** `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` (3×) — não pertence a nenhum script/áudio do Agente 4 (provavelmente textura/decal legado em alguma parte do mapa ou avatar).

---

## 5. Não Testado (Transparência)

- **Celular físico real (iOS/Android)** — `StudioDeviceSimulatorService` está disponível, mas não rodamos em aparelho físico real; o benchmark de 3 auras Lendárias em Play (`avgMs=66.66`, `p95Ms=68.38`) ocorreu com a janela do Studio sem foco no Windows (throttling nativo de 15 FPS do Studio), indicando ~1,7 ms de jitter mas sem medição real de 60 FPS em celular fraco.
- **2 jogadores reais em rede publicada** — `Others/init.luau` foi revisado em código/typecheck, não com 2 clientes reais conectados simultaneamente.
- **Experiência publicada em produção** (não publicamos o jogo).

---

## 6. Sugestões (Não Implementadas)

1. Migrar futuramente os 6 IDs ativos de `SfxKit.luau` para `ReplicatedStorage.Audio` (catálogo único de templates).
2. Adicionar `Spec`s de aura exclusivos em `CreatureAura/init.luau` para as Épicas/Lendárias `C82..C106` que hoje usam `FALLBACK`.
3. Adicionar `C54_Peixe_Vela_Solar` (e, se aplicável, `C104_Polvo_Presente`) no mapa `FACE_YAW` de `RevealFraming.luau` se o João preferir não reexportar os modelos no Blender.

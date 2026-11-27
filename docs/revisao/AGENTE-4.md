# Relatório de Revisão Final — Agente 4 (Criaturas, Modelos, Animações, Efeitos, Cinemáticas e Som)

**Place:** `112666482424701` (Legendary Catch)
**Início:** 2026-11-26 21:30 BRT
**Status:** Etapa 1 (Inventário + auditoria de código + 16 correções em 16 arquivos com `stylua`/`selene`/`luau-lsp` limpos) concluída; auditoria técnica em Edit das 106 criaturas + 8 varas + 14 áudios concluída; **pendente reconexão do MCP do Roblox Studio** após reinicialização do PC para finalizar grades visuais das 106 criaturas + bateria completa em Play + capturas em `art/preview/revisao/agente-4/`.

---

## 1. Inventário Completo da Área

### 1.1 Modelos 3D e Assets no Place
| Item | Caminho / Local | Testado como | Resultado |
|---|---|---|---|
| 106 criaturas ativas (`C01`–`C106`) | `ReplicatedStorage.Creatures` (`Config/Creatures.LIST`) | Auditoria automatizada em Edit concluída (`106/106` presentes, 0 scripts, 0 `CanCollide=true`, 0 `MeshId` vazios, 5 flags técnicas); **pendente** captura das grades visuais + framing em Play | parcial (Edit OK, Play/visual pendente) |
| 100 criaturas planejadas (`C107`–`C206`, fora de `LIST`) | `ReplicatedStorage.Creatures` (`Config/Creatures.PLANNED`) | Conferência de presença em Edit (`206` modelos totais na pasta) | ok (fora do pool ativo) |
| 8 modelos de varas (`starter`..`mystic`) | `ServerStorage.RodModels`, `ReplicatedStorage.RodPreviews`, `tools/RodModelsBuilder.luau` | Edit: `8/8` presentes (`pivPos=0,0,0`, `tip=0,-0.29,-7.75`, 0 scripts, 0 `CanCollide`); nota: `RodModelsBuilder.luau` define apenas 5/8; **pendente** inspeção equipada na mão em Play (R15/R6) | parcial (Edit OK, Play pendente) |
| 14 templates de áudio + IDs `Audio`/`SfxKit` | `ReplicatedStorage.Audio`, `Audio/init.luau`, `SfxKit.luau`, `docs/AUDIO.md` | Edit: `14/14` presentes; `SfxKit` unificado aos `SoundGroup`s `Music`/`Effects` + preload assíncrono; `docs/AUDIO.md` atualizado; **pendente** prova `PreloadAsync` + mute ao vivo em Play | parcial (código OK, Play pendente) |
| Pipeline Blender | `tools/blender/**` | Leitura de `tools/blender/README.md` (nenhuma mesh gerada/enviada sem aprovação) | ok |

### 1.2 Módulos de Cliente e Compartilhados sob Responsabilidade do Agente 4
| Módulo | Arquivo | Testado como | Resultado |
|---|---|---|---|
| Paleta VFX | `src/shared/Vfx/Palette.luau` | Leitura + lint/typecheck | parcial (Play pendente) |
| Motor VFX (pools/budget/flash/shake) | `src/shared/Vfx/VfxKit.luau` | Leitura + correções (`ALTO`: `cameraShake`, `pulseColorCorrection`, `ReduceEffects`, `Sibling`) + lint/typecheck | corrigido (Play pendente) |
| Motor SFX (2D/3D/pools/grupos) | `src/shared/Vfx/SfxKit.luau` | Leitura + correção (`ALTO`: grupos `Music`/`Effects` unificados + `PreloadAsync`) + lint/typecheck | corrigido (Play pendente) |
| Áudio principal | `src/client/Features/Audio/init.luau` | Leitura + correções (`MÉDIO`: volume padrão preservado, anti-duplo `"cast"`, `WaitForChild("Audio", 5)`, `Humanoid.Died`, tween condicional de ondas) + lint/typecheck | corrigido (Play pendente) |
| VFX de Pesca (orquestrador) | `src/client/Features/FishingVfx/init.luau` | Leitura + correções (`MÉDIO`: `castToken`, retry `findBobber`, `ReduceEffects` ao vivo, guarda `RunService:IsStudio()` em `DevPowerBarSkin`) + lint/typecheck | corrigido (Play pendente) |
| VFX da Boia | `src/client/Features/Vfx/BobberFx.luau` | Leitura + lint/typecheck | parcial (Play pendente) |
| VFX de Voo/Splash | `src/client/Features/Vfx/CastFlightFx.luau` | Leitura + lint/typecheck | parcial (Play pendente) |
| VFX de Carga | `src/client/Features/Vfx/FishingChargeFx.luau` | Leitura + correção (`MÉDIO`: `StringsUi.perfect` localizado) + lint/typecheck | corrigido (Play pendente) |
| VFX de Minigame | `src/client/Features/Vfx/MinigameFx.luau` | Leitura + correção (`MÉDIO`: textos PT/EN localizados) + lint/typecheck | corrigido (Play pendente) |
| Linha e Boia | `src/client/Features/Fishing/Line.luau` | Leitura + lint/typecheck (**pendente** prova visual de `Line.feedback` em acerto/erro na água em Play) | parcial (Play pendente) |
| Efeitos one-shot de Pesca | `src/client/Features/Fishing/Effects.luau` | Leitura + correções (`MÉDIO`: `Effects.pillar` respeita `ReduceEffects`; `Effects.shake` sem drift em `Scriptable`) + lint/typecheck | corrigido (Play pendente) |
| Câmera de Pesca | `src/client/Features/Fishing/Camera.luau` | Leitura + correções (`ALTO`: `RespectCanCollide=true` + skip transparentes + piso `Y>=1.2` + `oldType` seguro + morte) + lint/typecheck | corrigido (Play pendente) |
| Cutscene de Arremesso | `src/client/Features/Fishing/CastCutscene.luau` | Leitura + correções (`MÉDIO`: raycast/piso na órbita, `stop()` na morte/despawn, guarda no delay de áudio, eixos R6) + lint/typecheck | corrigido (Play pendente) |
| Presságio Lendário/Místico | `src/client/Features/Fishing/Omen.luau` | Leitura + lint/typecheck | parcial (Play pendente) |
| Revelação de Captura | `src/client/Features/Fishing/Reveal.luau` | Leitura + correções (`ALTO`: reativação das 20 cinemáticas com `FishingRoulette=true`, `FishingCamera.stop()`, morte/teleporte, raycast+piso, `pcall` de restauração) + lint/typecheck | corrigido (Play pendente) |
| Enquadramento de Revelação | `src/client/Features/Fishing/RevealFraming.luau` | Leitura + lint/typecheck | parcial (Play pendente) |
| Mutações e Escala de Revelação | `src/client/Features/Fishing/RevealMutation.luau` | Leitura + lint/typecheck | parcial (Play pendente) |
| Estilos de Revelação | `src/client/Features/RevealStyles/init.luau` & `Legendary.luau` | Leitura + lint/typecheck | parcial (Play pendente) |
| Cinemáticas (Motor, Receitas, Beats, Místicas 3D) | `src/client/Features/Fishing/Cinematics/**` | Leitura + correções (`MÉDIO`: `safeCinemaCam` em `waterShot`/`showCatch`, piso `Y>=1.2`, cancelamento por teleporte, `oldType` seguro) + lint/typecheck | corrigido (Play pendente) |
| Aura das Criaturas | `src/client/Features/CreatureAura/init.luau` & `CosmicOrbit.luau` | Leitura + correções (`ALTO`: cadência segura dos arcos <=2.4 Hz, loop único sem `followConn`, reescala dinâmica em `fromShow`, culling 150 studs, `ReduceEffects` ao vivo, `FALLBACK.Mystic` + `C94`) + lint/typecheck | corrigido (Play pendente) |
| Movimento das Criaturas | `src/client/Features/CreatureMotion/init.luau` | Leitura + lint/typecheck | parcial (Play pendente) |
| Movimento do Personagem | `src/client/Features/CharacterMotion/init.luau` & `AvatarVisuals/Pose.luau` | Leitura + correções (`MÉDIO`: eixos R6 + `RootJoint` + `Left Shoulder` no cast + `DescendantAdded` + parada na morte) + lint/typecheck | corrigido (Play pendente) |
| Troféu no Pedestal | `src/client/Features/TrophyPresentation/init.luau` | Leitura + correção (`BAIXO`: esconder `TrophySign` no `CatchPhoto`) + lint/typecheck | corrigido (Play pendente) |
| Outros Jogadores Pescando | `src/client/Features/Others/init.luau` | Leitura + correções (`MÉDIO`: race de `FishingRarity` na cor da linha/boia, `UIStroke.Color` dinâmico, `TextScaled`) + lint/typecheck | corrigido (Play pendente) |
| Movimento no Aquário | `Collection/AquariumWorld.luau` & `AquariumTank.luau` (leitura/auditoria) | Leitura concluída; **pendente** verificação em Play | parcial (Play pendente) |

---

## 2. Tabela das 106 Criaturas Ativas (`Config.Creatures.LIST`)

> **Resumo da inspeção automatizada em Edit (`ReplicatedStorage.Creatures`):**
> - **106/106** criaturas ativas presentes, **0** scripts internos, **0** partes com `CanCollide = true`, **0** `MeshId` vazios.
> - **5 flags técnicas identificadas para inspeção prioritária nas grades/Play:**
>   1. `C93_Ouroboros_Cosmico` — `PP=RootPart, UNANCH=2, INVIS=1` (rig skinned com 20 `Bone`s; conferir comportamento em Reveal, Aquário, Coleção e Troféu).
>   2. `C94_Mare_Primordial` — `SCALE=5.54` (`5.54×3.42×2.21`; conferir enquadramento e tamanhos extremos).
>   3. `C90_Tartaruga_Mundo` — `PIVOFF=1.21` (conferir centralização/giro em Coleção, Aquário e Troféu).
>   4. `C62_Dragao_Dourado` — `PIVOFF=0.76` (auditoria antiga tinha 0/0/0; agora tem 9 partes/6 meshes — confirmar visual na grade).
>   5. `C82_Kitsune_Aquatica` — `PIVOFF=0.76` (conferir centralização na grade).
> - Além das 5 acima, conferir na grade visual `C104_Polvo_Presente` (`3.85×2.60×3.98`, auditoria anterior apontou frente em `+X`).

| # | ID | Raridade | Estilo | Tamanho (X×Y×Z) | Partes / Meshes / Neon / Bones | PrimaryPart | Pivô Offset | Flags Edit | Visual (Grade) |
|---:|---|---|---|---|---|---|---:|---|---|
| 1 | `C01_Bolhinha_Azul` | Common | `bubbles` | 1.90x2.27x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 2 | `C02_Sardinha_Solar` | Common | `splash` | 1.17x1.42x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 3 | `C03_Siri_Pipoca` | Common | `splash` | 2.65x2.52x2.27 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 4 | `C04_Baiacu_Nuvem` | Uncommon | `bubbles` | 2.80x2.54x2.57 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 5 | `C05_Medusinha_Estelar` | Uncommon | `spark` | 2.04x2.80x1.94 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 6 | `C06_Cavalo_Marinho_Coral` | Uncommon | `prism` | 0.72x2.80x1.21 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 7 | `C07_Arraia_Prisma` | Rare | `prism` | 2.95x2.10x2.84 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 8 | `C08_Enguia_Trovao` | Rare | `storm` | 2.95x2.83x2.73 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 9 | `C09_Guardiao_Cristal` | Epic | `crystal` | 3.14x1.77x2.63 | `P=8,M=8,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 10 | `C10_Leviata_Astral` | Legendary | `cosmic` | 3.00x2.88x2.51 | `P=4,M=4,N=0,B=0` | `Body` | 0.43 | OK | pendente |
| 11 | `C11_Pingo_Lanterna` | Common | `spark` | 1.36x2.65x1.49 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 12 | `C12_Camarao_Confete` | Common | `splash` | 2.16x2.86x2.38 | `P=5,M=5,N=0,B=0` | `Body` | 0.01 | OK | pendente |
| 13 | `C13_Linguado_Sonolento` | Common | `bubbles` | 1.26x1.48x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 14 | `C14_Polvinho_Aquarela` | Uncommon | `prism` | 2.80x2.46x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 15 | `C15_Tartaruga_Musgo` | Uncommon | `bubbles` | 2.47x2.54x2.86 | `P=6,M=6,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 16 | `C16_Voador_Brisa` | Uncommon | `splash` | 2.78x2.80x1.33 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 17 | `C17_Martelo_Coral` | Rare | `prism` | 2.15x1.58x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 18 | `C18_Lula_Neon` | Rare | `spark` | 2.95x2.87x2.60 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 19 | `C19_Peixe_Lua_Dourado` | Rare | `cosmic` | 2.31x2.80x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 20 | `C20_Raia_Vulcanica` | Epic | `magma` | 3.20x2.66x2.98 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 21 | `C21_Baleia_Nebulosa` | Epic | `cloud` | 2.75x2.68x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 22 | `C22_Serpente_Glacial` | Epic | `frost` | 2.75x3.07x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 23 | `C23_Kraken_Trovejante` | Legendary | `storm` | 3.12x2.77x3.48 | `P=6,M=6,N=2,B=0` | `Body` | 0.00 | OK | pendente |
| 24 | `C24_Fenix_das_Mares` | Legendary | `magma` | 2.93x3.00x1.17 | `P=4,M=4,N=0,B=0` | `Body` | 0.40 | OK | pendente |
| 25 | `C25_Ourico_Gelatina` | Common | `bubbles` | 2.65x1.97x2.14 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 26 | `C26_Peixe_Pipa` | Common | `splash` | 1.38x1.81x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 27 | `C27_Ermitao_Cristal` | Uncommon | `crystal` | 2.86x2.71x2.19 | `P=5,M=5,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 28 | `C28_Nautilo_Aurora` | Rare | `prism` | 2.65x2.60x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 29 | `C29_Dragao_Folha` | Epic | `spark` | 3.20x3.02x0.78 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 30 | `C30_Tartaruga_Ilha` | Legendary | `crystal` | 2.77x2.60x2.81 | `P=6,M=4,N=2,B=0` | `Body` | 0.03 | OK | pendente |
| 31 | `C31_Carpa_Celeste` | Uncommon | `cloud` | 2.13x1.30x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 32 | `C32_Espadarte_Relampago` | Rare | `storm` | 1.57x2.95x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 33 | `C33_Orca_Aurora` | Epic | `frost` | 2.20x2.39x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 34 | `C34_Serpente_Arco_Iris` | Legendary | `prism` | 2.49x3.00x2.53 | `P=4,M=4,N=0,B=0` | `Body` | 0.24 | OK | pendente |
| 35 | `C60_Hidra_das_Profundezas` | Legendary | `storm` | 3.55x3.33x2.24 | `P=10,M=6,N=4,B=0` | `Body` | 0.00 | OK | pendente |
| 36 | `C61_Baleia_Celestial` | Legendary | `cosmic` | 2.71x2.55x3.55 | `P=10,M=6,N=4,B=0` | `Body` | 0.26 | OK | pendente |
| 37 | `C62_Dragao_Dourado` | Legendary | `storm` | 3.55x3.33x2.30 | `P=9,M=6,N=3,B=0` | `Body` | 0.76 | PIVOFF=0.76 | pendente (prioridade) |
| 38 | `C63_Grifo_Marinho` | Legendary | `cloud` | 3.17x3.50x1.67 | `P=8,M=6,N=2,B=0` | `Body` | 0.42 | OK | pendente |
| 39 | `C64_Guardiao_Abissal` | Legendary | `magma` | 2.34x3.48x1.78 | `P=9,M=9,N=3,B=0` | `Body` | 0.00 | OK | pendente |
| 40 | `C50_Tubarao_Baleia_Estrelado` | Rare | `cosmic` | 2.48x1.57x2.86 | `P=6,M=6,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 41 | `C51_Lanterna_Abissal` | Rare | `spark` | 2.45x2.95x2.71 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 42 | `C52_Cavalo_Marinho_Real` | Rare | `crystal` | 1.26x2.85x1.30 | `P=5,M=5,N=0,B=0` | `Body` | 0.36 | OK | pendente |
| 43 | `C53_Moreia_Voltaica` | Rare | `storm` | 2.94x2.85x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 44 | `C54_Peixe_Vela_Solar` | Rare | `magma` | 3.18x2.94x1.99 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 45 | `C55_Caranguejo_Rei_Gelo` | Rare | `frost` | 2.86x2.42x1.92 | `P=7,M=7,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 46 | `C56_Dragao_de_Coral` | Epic | `prism` | 3.20x2.90x2.77 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 47 | `C57_Manta_Galactica` | Epic | `cosmic` | 3.20x2.47x1.84 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 48 | `C58_Tubarao_Fantasma` | Epic | `frost` | 2.43x2.78x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 49 | `C59_Narval_Unicornio` | Epic | `crystal` | 2.42x3.20x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 50 | `C35_Bagre_Bigodudo` | Common | `bubbles` | 2.00x2.65x2.14 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 51 | `C36_Peixe_Bolha_Rosa` | Common | `bubbles` | 2.44x2.52x2.86 | `P=5,M=5,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 52 | `C37_Caramujo_Doce` | Common | `splash` | 1.78x1.84x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 53 | `C38_Estrela_Sonolenta` | Common | `spark` | 2.33x2.65x1.78 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 54 | `C39_Lambari_Prata` | Common | `splash` | 1.70x2.01x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 55 | `C40_Caranguejo_Bolacha` | Common | `splash` | 2.65x2.21x1.91 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 56 | `C41_Palhaco_Neon` | Common | `spark` | 1.82x2.04x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 57 | `C42_Lulinha_Gota` | Common | `bubbles` | 2.47x2.65x2.02 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 58 | `C43_Baiacu_Algodao_Doce` | Uncommon | `cloud` | 2.86x2.86x2.36 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 59 | `C44_Arraia_Pintada` | Uncommon | `prism` | 2.80x2.36x1.62 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 60 | `C45_Tartaruguinha_Coral` | Uncommon | `bubbles` | 2.59x2.73x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 61 | `C46_Peixe_Leque` | Uncommon | `splash` | 2.80x2.74x2.60 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 62 | `C47_Medusa_Lanterna` | Uncommon | `spark` | 2.02x2.80x1.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 63 | `C48_Peixe_Anjo_Real` | Uncommon | `prism` | 1.74x2.73x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 64 | `C49_Polvo_Bolinhas` | Uncommon | `bubbles` | 2.80x2.33x2.79 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 65 | `C75_Leao_Marinho_Dourado` | Rare | `magma` | 1.93x2.86x2.27 | `P=6,M=6,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 66 | `C76_Raia_Aurora` | Rare | `prism` | 2.86x1.92x1.76 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 67 | `C77_Cavalo_Marinho_Relogio` | Rare | `crystal` | 1.31x2.85x1.42 | `P=5,M=5,N=0,B=0` | `Body` | 0.15 | OK | pendente |
| 68 | `C78_Lagosta_Armadura` | Rare | `frost` | 2.71x2.95x1.58 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 69 | `C79_Mantarraia_Vitral` | Rare | `prism` | 2.95x2.76x0.47 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 70 | `C80_Peixe_Pavao_Eletrico` | Rare | `storm` | 2.28x2.61x2.85 | `P=6,M=6,N=0,B=0` | `Body` | 0.28 | OK | pendente |
| 71 | `C81_Enguia_Fita_de_Seda` | Rare | `cloud` | 0.60x2.85x2.56 | `P=5,M=5,N=0,B=0` | `Body` | 0.19 | OK | pendente |
| 72 | `C93_Ouroboros_Cosmico` | Mystic | `cosmic` | 2.00x3.50x3.15 | `P=3,M=2,N=0,B=20` | `RootPart` | 0.12 | PP=RootPart,UNANCH=2,INVIS=1 | pendente (prioridade) |
| 73 | `C94_Mare_Primordial` | Mystic | `cosmic` | 5.54x3.42x2.21 | `P=9,M=9,N=0,B=0` | `Body` | 0.03 | SCALE=5.54 | pendente (prioridade) |
| 74 | `C65_Tilapia_Moranguinho` | Common | `bubbles` | 1.83x2.00x2.86 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 75 | `C66_Ourico_Pompom` | Common | `spark` | 2.86x2.57x2.61 | `P=2,M=2,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 76 | `C67_Lesma_do_Mar_Arco_iris` | Common | `prism` | 2.10x2.35x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 77 | `C68_Peixe_Biscoito` | Common | `splash` | 2.40x2.24x2.65 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 78 | `C69_Ermitao_Xicara` | Common | `bubbles` | 2.86x2.01x2.05 | `P=5,M=5,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 79 | `C70_Agua_viva_Lanterna` | Uncommon | `spark` | 2.00x2.86x2.00 | `P=3,M=3,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 80 | `C71_Peixe_Espada_Neon` | Uncommon | `storm` | 1.15x1.62x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 81 | `C72_Tartaruga_Pergaminho` | Uncommon | `crystal` | 2.80x2.07x2.80 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 82 | `C73_Polvo_Origami` | Uncommon | `cloud` | 2.80x2.12x2.69 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 83 | `C74_Baiacu_Balao_de_Festa` | Uncommon | `bubbles` | 2.86x2.85x2.26 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 84 | `C82_Kitsune_Aquatica` | Epic | `spark` | 2.80x2.57x2.09 | `P=6,M=6,N=0,B=0` | `Body` | 0.76 | PIVOFF=0.76 | pendente (prioridade) |
| 85 | `C83_Golfinho_Trovao` | Epic | `storm` | 1.65x3.20x3.04 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 86 | `C84_Tubarao_Martelo_de_Cristal` | Epic | `crystal` | 2.72x1.87x3.14 | `P=8,M=8,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 87 | `C85_Lula_Galaxia` | Epic | `cosmic` | 3.19x3.20x2.51 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 88 | `C86_Cervo_Coral` | Epic | `splash` | 1.90x2.95x2.07 | `P=6,M=6,N=0,B=0` | `Body` | 0.27 | OK | pendente |
| 89 | `C87_Salamandra_de_Lava` | Epic | `magma` | 3.07x2.56x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 90 | `C88_Rei_Tritao_Colossal` | Legendary | `storm` | 2.18x3.55x1.68 | `P=11,M=6,N=5,B=0` | `Body` | 0.16 | OK | pendente |
| 91 | `C89_Dragao_de_Jade` | Legendary | `cloud` | 2.71x3.32x3.44 | `P=11,M=6,N=5,B=0` | `Body` | 0.55 | OK | pendente |
| 92 | `C90_Tartaruga_Mundo` | Legendary | `crystal` | 2.11x3.30x3.34 | `P=12,M=7,N=5,B=0` | `Body` | 1.21 | PIVOFF=1.21 | pendente (prioridade) |
| 93 | `C91_Hipocampo_Imperial` | Legendary | `prism` | 2.13x3.29x3.44 | `P=11,M=7,N=4,B=0` | `Body` | 0.37 | OK | pendente |
| 94 | `C92_Serafim_do_Mar` | Legendary | `cosmic` | 3.21x3.20x1.00 | `P=15,M=7,N=8,B=0` | `Body` | 0.18 | OK | pendente |
| 95 | `C95_Peixe_Vagalume_Real` | Rare | `spark` | 2.12x2.56x2.95 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 96 | `C96_Lua_Dourada` | Epic | `cosmic` | 2.42x3.20x2.41 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 97 | `C97_Raia_Tempestade` | Epic | `storm` | 3.20x2.28x2.56 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 98 | `C98_Coral_Ancestral_Vivo` | Epic | `crystal` | 2.79x2.72x3.20 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 99 | `C99_Baleia_Fantasma` | Legendary | `cloud` | 2.40x2.24x3.39 | `P=11,M=6,N=5,B=0` | `Body` | 0.09 | OK | pendente |
| 100 | `C100_Aurora_Boreal_Viva` | Legendary | `frost` | 3.48x3.25x2.84 | `P=7,M=7,N=2,B=0` | `Body` | 0.00 | OK | pendente |
| 101 | `C101_Rena_do_Mar` | Common | `frost` | 2.18x2.19x2.86 | `P=5,M=5,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 102 | `C102_Peixe_Arvore_de_Natal` | Uncommon | `spark` | 1.95x2.86x2.54 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 103 | `C103_Boneco_de_Gelo_Marinho` | Rare | `frost` | 2.31x2.86x1.80 | `P=6,M=6,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 104 | `C104_Polvo_Presente` | Epic | `spark` | 3.85x2.60x3.98 | `P=4,M=4,N=0,B=0` | `Body` | 0.00 | OK | pendente (checar frente +Z) |
| 105 | `C105_Estrela_do_Natal` | Epic | `prism` | 2.94x3.20x1.23 | `P=1,M=1,N=0,B=0` | `Body` | 0.00 | OK | pendente |
| 106 | `C106_Rei_do_Gelo_Natalino` | Legendary | `frost` | 3.31x3.43x2.15 | `P=6,M=6,N=0,B=0` | `Body` | 0.02 | OK | pendente |

---

## 3. Lista de Bugs Encontrados e Correções

> Todos os 16 arquivos corrigidos abaixo passaram em `stylua`, `selene` (**0 erros, 0 warnings**) e `luau-lsp analyze` (**0 erros**). A prova em Play no Studio será registrada assim que o MCP do Roblox Studio reconectar após o reinício do PC.

### ALTO
1. **Todas as 20 cinemáticas de Lendárias e Místicas eram puladas com `FishingRoulette=true`**
   - **Arquivo:** `src/client/Features/Fishing/Reveal.luau:245`
   - **Causa:** `Fishing/init.luau:297` marca `shown.fromShow = true` após o `CatchShow` curto de Lendárias/Místicas, e `Reveal.luau` exigia `if recipe and not fromShow then`, pulando `Cinematics.play` para todas as 18 Lendárias e 2 Místicas.
   - **Correção:** Alterado para `if recipe then` (chamando `FishingCamera.stop()` antes) e garantindo `Audio.play("legendary")` para raridades `>= 5` mesmo sem receita.
   - **Status:** Corrigido em código (aguardando prova em Play).

2. **`SfxKit` ignorava completamente os controles de volume em Ajustes**
   - **Arquivo:** `src/shared/Vfx/SfxKit.luau:291-312`
   - **Causa:** Criava `SoundGroup`s próprios (`LegendaryCatch_SFX/Music/UI`) em vez de usar `SoundService.Music` e `SoundService.Effects` ajustados por `Settings/init.luau`.
   - **Correção:** Unificados `SFX`/`UI` -> `SoundService.Effects` (`0.7`) e `Music` -> `SoundService.Music` (`0.5`), além de adicionar `ContentProvider:PreloadAsync` assíncrono dos 6 IDs ativos.
   - **Status:** Corrigido em código (aguardando prova em Play).

3. **Caixas invisíveis `FishingZone` quebravam o raycast da `FishingCamera` em Coral Reef e Star Abyss**
   - **Arquivo:** `src/client/Features/Fishing/Camera.luau:102-119`
   - **Causa:** `CoralReefIsland.FishingZone` e `StarAbyssIsland.FishingZone` estão com `CanQuery = true, CanCollide = false, Transparency = 1`; `unblocked()` fazia raycast sem `RespectCanCollide = true` e sem pular partes transparentes, puxando a câmera para dentro do personagem. Além disso, `start()` salvava `Scriptable` como `oldType` se chamada durante outra câmera scriptable.
   - **Correção:** Ativado `RespectCanCollide = true`, loop pulando partes com `Transparency >= 0.8`, piso mínimo `Y >= 1.2`, fallback seguro para `Custom`/`70` FOV e parada automática em `Humanoid.Health <= 0`. Também aberto pedido ao Agente 3 em `docs/revisao/PEDIDOS.md` para ajustar `CanQuery = false` no place.
   - **Status:** Corrigido em código (aguardando prova em Play nas 3 zonas).

4. **Violação de acessibilidade (>3 piscadas/s), sobrecarga por aura, escala defasada em `fromShow` e falta de `ReduceEffects` ao vivo em `CreatureAura`**
   - **Arquivo:** `src/client/Features/CreatureAura/init.luau`
   - **Causa:** `arc.Enabled = math.random() < 0.35` rodava a 60 FPS (~20–30 piscadas/s); cada aura criava um `RenderStepped` extra (`followConn`); com `fromShow=true`, a aura media o modelo na escala `0.12×`; não reagia a `ReduceEffects` ao vivo e faltava `FALLBACK.Mystic` / spec da `C94_Mare_Primordial`.
   - **Correção:** Cadência segura dos arcos (`0.42–0.65 s`, <=2.4 Hz); follow unificado no loop único com culling a `150` studs; rastreio dinâmico de `model:GetScale()`; alternância ao vivo de `ReduceEffects` (inclusive `PointLight`); adicionados `FALLBACK.Mystic` e spec dedicado de `C94_Mare_Primordial`.
   - **Status:** Corrigido em código (aguardando prova em Play).

5. **`VfxKit.cameraShake` corrompia `Humanoid.CameraOffset` e deslocava câmeras `Scriptable`**
   - **Arquivo:** `src/shared/Vfx/VfxKit.luau:721-800, 1473-1534`
   - **Causa:** Trocar `Custom -> Scriptable` no meio de um shake zerava `lastHumanoidShakeOffset` sem subtrair do `Humanoid.CameraOffset`; em `Scriptable` reescrita por cutscenes, desfazer o inverse causava drift; `pulseColorCorrection` não cancelava `inTw` em `cleanup()` nem limpava ao ativar `ReduceEffects`; `flashGui` nascia sem `ZIndexBehavior = Sibling`.
   - **Correção:** Restauração garantida do `CameraOffset`, verificação `FuzzyEq(lastAppliedCamCf)` antes de desfazer offset `Scriptable`, cancelamento de `inTw` e destruição de `activeTempPostFx` ao ligar `ReduceEffects`, e `ZIndexBehavior = Enum.ZIndexBehavior.Sibling`.
   - **Status:** Corrigido em código (aguardando prova em Play).

6. **Briga de câmera entre `FishingCamera` e `Reveal`, falta de cancelamento por morte/teleporte, clipping em tamanhos extremos e risco de estado preso**
   - **Arquivo:** `src/client/Features/Fishing/Reveal.luau:277-595`
   - **Causa:** `FishingCamera.catch()` continuava rodando durante `Reveal` e `PhotoMode`, `cancelled()` não checava morte/teleporte, e escalas grandes (`×100`) puxavam a câmera para dentro do pier/ilha/água.
   - **Correção:** `FishingCamera.stop()` antes da câmera do `Reveal`, `oldType` seguro, `cancelled()` verificando `Humanoid.Health <= 0` e teleporte (`> 25` studs), `safeRevealCamera` com raycast `RespectCanCollide = true` + piso `Y >= 1.2`, e `pcall` com bloco de restauração garantida no fim.
   - **Status:** Corrigido em código (aguardando prova em Play).

### MÉDIO
7. **Mutação permanente de volume, som dobrado de arremesso e tweens contínuos em `Audio/init.luau`**
   - **Correção:** Mapa `defaultVolumes[cue]`, cooldown de `0.22 s` em `"cast"`, `WaitForChild("Audio", 5)`, parada de `tension` em `Humanoid.Died`, e tween de `Ambience_Waves` apenas quando `|gain - lastGain| > 0.015`.
8. **Cutscene de arremesso sem colisão na órbita, sem `stop()` na morte e eixos R6 invertidos (`CastCutscene.luau`)**
   - **Correção:** `unblockedPos` (`RespectCanCollide = true`, skip transparentes, `Y >= 1.2`) em `shotFor` e na órbita de `release`, `CastCutscene.stop()` na morte/despawn, guarda `current == run` no delay de áudio, `oldType` seguro e conversão de eixos R6 (`Right/Left Shoulder`, `Right/Left Hip`, `RootJoint`).
9. **Câmera de `Cinematics/init.luau` sem colisão/piso em `waterShot` e `showCatch` (`visualScale ~= 1`) nem cancelamento por teleporte**
   - **Correção:** Adicionado `safeCinemaCam` em `waterShot` e `showCatch`, piso `Y >= 1.2`, checagem de teleporte em `alive()` e `oldType` seguro.
10. **`Effects.pillar` ignorava `ReduceEffects` e `Effects.shake` podia acumular drift em `Scriptable` (`Effects.luau`)**
    - **Correção:** `Effects.pillar` omite `PointLight` e suaviza transparência em `ReduceEffects`; `Effects.shake` desfaz rotação anterior apenas quando `cam.CFrame:FuzzyEq(lastApplied)` e limpa ao terminar.
11. **`FishingVfx/init.luau` — splash atrasado/órfão, `findBobber` sem retry, `ReduceEffects` congelado na carga e `DevPowerBarSkin` sem guarda `IsStudio`**
    - **Correção:** `castToken` cancelando splash pendente (alinhado a `0.70 s` com `Line.castTo`), retry de `findBobber` até 5 s, checagem ao vivo de `reduced()` na carga, e guarda `if RunService:IsStudio() then` em `DevPowerBarSkin` (pedido do Agente 2 em `PEDIDOS.md`).
12. **Textos PT-BR hardcoded vazando em EN-US em `MinigameFx.luau` e `FishingChargeFx.luau`**
    - **Correção:** Localização PT/EN usando `Strings`, `StringsUi` e `LocalPlayer.LocaleId`.
13. **Eixos R6, juntas replicadas tarde e parada na morte em `CharacterMotion/init.luau` e `AvatarVisuals/Pose.luau`**
    - **Correção:** Conversão de eixos R6 (`Right Shoulder`, `Left Shoulder`, `RootJoint`), `Left Shoulder` no cast windup, listener `DescendantAdded` limpo em `cleanup()`, e parada automática em `Humanoid.Health <= 0`.
14. **Race condition de raridade e clipping de texto em `Others/init.luau`**
    - **Correção:** Rastreamento de `appliedRarity[player]` para atualizar `Line.setColor` mesmo quando `FishingRarity` replica depois de `FishingState = "fighting"`, atualização de `UIStroke.Color`, e `TextScaled = true` com `UITextSizeConstraint (MaxTextSize = 13)`.

### BAIXO
15. **Placa do troféu não escondia ao entrar no Modo Foto (`TrophyPresentation/init.luau:117`)**
    - **Correção:** Incluído `and child.Name ~= "CatchPhoto"` em `whenOverlayChanges`.

---

## 4. Pendências que Dependem do João

1. **Reconectar o MCP do Roblox Studio** após o desligamento do PC para concluirmos as capturas das grades visuais (106 criaturas + 8 varas) e toda a bateria de provas em Play.
2. **Lista priorizada de modelos de criaturas para refazer (Blender/meshing):** será fechada assim que capturarmos as 5 grades visuais no Studio (nenhuma mesh nova foi gerada nem enviada).
3. **`tools/RodModelsBuilder.luau` desatualizado:** hoje o script só descreve 5 das 8 varas existentes em `ServerStorage.RodModels` (`starter..mystic`). Caso o João volte a rodar o builder no futuro, vale sincronizar as 3 varas restantes para não sobrescrevê-las.

---

## 5. Não Testado (Transparência)

- **Bateria em Play no Roblox Studio + capturas visuais (`art/preview/revisao/agente-4/`):** bloqueada temporariamente porque o PC reiniciou e o servidor MCP do Roblox Studio não reconectou nesta sessão (assim que reconectar, rodamos 100% da bateria de Play, incluindo grades visuais, 6 raridades, 10 estilos, 20 cinemáticas, 7 mutações, extremos `×0.4`–`×10000`, R15/R6, 8 varas, `Others`, 20 pescas para leak check, Áudio e Device Simulator mobile).
- Celular físico real (iOS/Android).
- 2 jogadores reais em rede publicada.
- Experiência publicada em produção (não publicamos o jogo).

---

## 6. Sugestões (Não Implementadas)

1. Unificar no futuro os dois motores de áudio (`Audio/init.luau` e `SfxKit.luau`) ou migrar os 6 IDs ativos do `SfxKit` para `ReplicatedStorage.Audio` para manter um catálogo único de assets.
2. Adicionar `Spec`s de aura dedicados em `CreatureAura/init.luau` para as criaturas Épicas/Lendárias mais novas (`C82..C106`) que hoje usam `FALLBACK`, quando houver tempo de polimento pós-lançamento.

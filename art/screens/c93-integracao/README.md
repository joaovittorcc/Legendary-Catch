# Integração C93 · Ouroboros Cósmico (Mística)

Integração do rig deformável de 20 ossos da criatura `C93_Ouroboros_Cosmico` no place principal (`placeId: 112666482424701`) e nos sistemas de cliente (`CreatureMotion`, `CreatureAura`/`CosmicOrbit`, `RevealFraming`, `RevealCard` e `Cinematics`).

## 1. O que mudou

- **Modelo no place (`ReplicatedStorage.Creatures.C93_Ouroboros_Cosmico`):**
  - Substituído o modelo antigo de 12 blocos rígidos pelo rig deformável (`C93SkinnedRig = true`) com `PrimaryPart = RootPart`, `AnimationController`/`Animator` e 20 `Bone`s (`Root`, `OrbitCore`, `Spine01`..`Spine18`).
  - `Body`: `MeshPart` deformável (`HasSkinnedMesh = true`, `5.350` triângulos), `MeshId = rbxassetid://129677852347647`, `TextureID = rbxassetid://88238031398008`.
  - `Core`: `MeshPart` deformável (`HasSkinnedMesh = true`, `640` triângulos), `MeshId = rbxassetid://113296381631147`, `TextureID = rbxassetid://88238031398008`.
  - Escala validada: bounding box `(2.00, 3.50, 3.15)` studs (altura `Body.Size.Y = 3.50` studs).
  - Orientação validada: frente apontando para `+Z` (`Spine01 -> Spine02` com `direction.Z = +0.338 > 0`).
- **Enquadramento frontal (`src/client/Features/Fishing/RevealFraming.luau`):**
  - Removido o override antigo `C93_Ouroboros_Cosmico = math.pi` de `FACE_YAW` (que existia apenas para compensar a malha antiga invertida em `-Z`). Agora a nova C93 usa `+Z` nativo na revelação, no card 3D, na cinemática de portal e no modo Foto.
- **Animação de nado nos 20 ossos (`src/client/Features/CreatureMotion/init.luau` & `RevealCard.luau`):**
  - `CreatureMotion.bind` detecta automaticamente `Spine01`..`Spine18` e `OrbitCore` sem afetar as outras 105 criaturas (que continuam usando a animação por partes `Body/Head/Tail/FinL/FinR/...`).
  - `CreatureMotion.pose` e `CreatureMotion.poseBones` rodam o ciclo de 8,0 s nos ossos (desenrola o anel, ondula em S da cabeça à cauda, gira/flutua o cristal central `OrbitCore` e volta a fechar o anel), funcionando tanto no `Workspace` quanto dentro de `ViewportFrame`s (`ForegroundCreature` na cinemática, `CreaturePreview` no `RevealCard` e `Collection`/Bestiário).
- **Aura orbital (`src/client/Features/CreatureAura/CosmicOrbit.luau` & `CreatureAura/init.luau`):**
  - Integrado `CosmicOrbit.attach(model, reduced)` via `CreatureAura.attach`: cria `C93CosmicOrbit` fora do `Model` (preservando o `GetBoundingBox()` intacto), com **6 orbes com rastros** no modo normal e **3 orbes sem rastros** quando `ReduceEffects == true` (reage em tempo real à troca do atributo e limpa tudo ao destruir ou desparentear o modelo).
- **Cinemática de portal (`src/client/Features/Fishing/Cinematics/init.luau`):**
  - Ajustado `padding = 1.24` para `C93_Ouroboros_Cosmico` no `Framing.camera` do `ForegroundCreature`, garantindo margem para a abertura do nado em S e para a órbita dos 6 orbes sem cortar nas bordas.
- **Registro de assets (`art/hud-v2/ASSET_IDS.md`) e `.gitignore`:**
  - Documentados os IDs publicados na nuvem (`Body`, `Core`, `c93-color-atlas.png`).
  - Ignorada a pasta residual de cache do importador FBX (`*.fbm/`).

## 2. Números medidos

| Métrica | Valor |
|---|---|
| Triângulos totais | `5.990` (`5.350` em `Body` + `640` em `Core`) |
| Ossos (`Bone`) | `20` (`Root`, `OrbitCore`, `Spine01`..`Spine18`) |
| Atlas de textura | `512 × 512 px` (`rbxassetid://88238031398008`) |
| Bounding box | `2.00 × 3.50 × 3.15` studs (maior lado `3.50` studs) |
| Direção frontal | `+Z` (`direction.Z = +0.338`) |
| Orbes da aura (`CosmicOrbit`) | `6` com rastros (`ReduceEffects = false`) / `3` sem rastros (`ReduceEffects = true`) |
| Ciclo de nado | `8.0 s` contínuo nos 20 ossos |

## 3. Capturas neste diretório

- `01-c93-place-edit-front-34.jpg` — Novo modelo de 20 ossos instalado em `ReplicatedStorage.Creatures.C93_Ouroboros_Cosmico` no place principal (`112666482424701`), vista 3/4 frontal (`+Z`).
- `02-c93-aura-6-orbs-coiled.jpg` — Pose base em anel com os 6 orbes e rastros da aura `CosmicOrbit` (`ReduceEffects = false`).
- `03-c93-swim-wave-coiled-turn.jpg` — Deformação intermediária da coluna (`Spine01`..`Spine18`) e cristal central (`OrbitCore`).
- `04-c93-swim-uncoiled-reduce-effects.jpg` — Pico da abertura do anel em S (`t = 4.0 s` do ciclo de 8 s) + modo `ReduceEffects = true` (3 orbes estáticos sem rastros).

## 4. O que NÃO foi testado / pendência manual no Studio

- **Bloqueio do plugin MCP no Play (`Assistant_25199.rbxm`):** ao entrar em `Play` no place principal com 4 instâncias do Studio abertas, o console do Studio reportou `Failed to load plugin {type=BuiltInStandalone filepath=Assistant_25199.rbxm OTA pluginVersionId=25199} in datamodel PlayServer / PlayClient`, impedindo comandos MCP no `PlayServer`/`PlayClient` e o `save_place` pós-Play até clicar em **Stop (■)** manualmente na janela do Studio e rodar `Ctrl+S` (File > Save to Roblox).
- **Não testado:** celular físico real, 2+ jogadores simultâneos, outros avatares e jogo publicado.

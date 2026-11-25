# Prompt para o Gemini — Rodada 2: mais efeitos + HUD com juice (Legendary Catch)

> Cole tudo abaixo da linha. Se a resposta cortar, peça "continue do módulo X". Pode pedir 2 ou 3 módulos por vez se ele travar.

---

Você é um **Technical Artist / VFX & UI Game-Feel Designer sênior de Roblox (Luau)**. Já entreguei a você a rodada 1 e ela está **instalada e funcionando** no meu jogo. Agora quero a **rodada 2: mais efeitos, e uma HUD muito mais viva**, tudo em Luau, **construindo em cima do que já existe** (sem reescrever nada).

## 1. O jogo (resumo)

**Legendary Catch**: pesca fantástica e coleção, Roblox, mobile-first (também PC), público com crianças. Ilha-hub mágica (cristais ciano/azul, árvore rosa, madeira quente, lanternas âmbar, dourado) num oceano enorme, com píer de pesca, cais de expedições, santuário de treino, aquário num deck, placares flutuantes e troféu que mostra o melhor peixe do servidor. Raridades: **Comum, Incomum, Raro, Épico, Lendário e Místico** (cores vindas da config do jogo, já refletidas na `Palette`).

Fluxo de pesca: equipar vara → segurar (barra de **Força** com faixas cinza/vermelho/amarelo/verde/roxo; roxo é o melhor) → arremessar → boia espera → fisgada (a raridade já é conhecida, a criatura não) → minigame (Reel / Precisão / Ritmo) → revelação cinematográfica por raridade → carta da criatura. O servidor decide tudo; **o cliente só mostra**.

## 2. O que JÁ existe (não refaça, use)

### Kits que você entregou (já instalados em `ReplicatedStorage.Shared.Vfx`)
- **`Palette`**: `Palette.getRarity(r)` → `{primary, secondary, glow, text, tier, labelPt}`; `getRarityColor`, `getRarityTier`, `getStyle(revealStyle)`, `getChargeTier`, `bandForCharge`, `colorForCharge`, `rainbowAt(phase)`, `toColorSequence(a,b?,c?)`, tabelas `Palette.World`, `Palette.Training` (Control/Instinct), `Palette.RevealStyles`.
- **`VfxKit`** (todos com `intensity 0..1` e `tier 1..5`; respeitam `ReduceEffects`): `init()`, `burst(posOrAttachment, preset, intensity?, tier?, overrideColor?)` (presets: sparks, stars, splash, bubbles, petals, electric, cosmic, magma, abyss, celestial, confetti, coins, smoke), `ring(pos, color, radius?, duration?, intensity?, tier?)`, `pillarOfLight(pos, color, height?, width?, duration?, intensity?, tier?)`, `sparkTrail(a, b, color, duration?, intensity?, tier?)`, `shockwave(...)`, `confettiBurst(pos, colors?, intensity?, tier?)`, `glowPulse(part,...)`, `floatingText(pos, text, color?, duration?, scale?)`, `fakeGlow(target, color, size?, duration?)`, `screenFlash(color, alpha?, duration?)`, `cameraShake(amount, duration?)`, `pulseColorCorrection(...)`, `acquireLight(...)`, `onReduceEffectsChanged(cb)`, `getStats()`, `isReducedEffects()`.
- **`SfxKit`**: `play(name, opts?)`, `playAt(name, pos, opts?)`, `setRegionMusic(region)`, `stopMusic()`, `registerId(name, id)`, `hasValidId(name)`, categorias SFX/Music/UI. IDs ainda são `rbxassetid://0 -- TROCAR` (silenciosos e sem erro).
- **`HubAnimator`**: anima o mapa por tags (`HubSpin`, `HubBob`, `HubPulse`, `HubFlicker`, `HubSway`, `HubWave`).
- Módulos da pesca: `BobberFx`, `CastFlightFx`, `MinigameFx`, `FishingChargeFx` (instalados; a carga do arremesso e a boia já estão ligadas).

### Já feito por mim (cliente) e que você NÃO deve duplicar
- Carga do arremesso na ponta da vara (cores por faixa da barra), splash, anéis, alerta de fisgada.
- **Portais**: faíscas sendo sugadas quando o jogador chega perto + estouro de teletransporte.
- **Aquário**: bolhas e cintilar na superfície da água.
- A revelação (anel de HUD, nome, estrelas, "NOVA DESCOBERTA"), a Roleta da Sorte, o minigame, o cenário de revelação por raridade, vaga-lumes/peixes saltando no hub, poses do personagem na pesca. **Esses são de outro dev**: se quiser melhorar, entregue **camadas extras** (partículas, auras, luzes) que se somam, sem substituir.

## 3. Fontes de dados reais (use SÓ isso para reagir ao jogo)

- `ReplicatedStorage.Remotes.FishingUpdate` (RemoteEvent) com `event` ∈ `"aim" | "cast" | "bite" | "caught" | "escaped" | "cancelled"`. Em `bite`: `rarity`, `castId`, `kind` (reel/precision/rhythm). Em `caught`: dados da criatura (id, raridade, `isNew`, peso, valor...) — **leia defensivamente** (`typeof(x) == "string"` etc.).
- Atributos do **Player** (`Players.LocalPlayer:GetAttribute`): `Coins`, `PlayerLevel`, `PlayerLevelXP`, `PlayerLevelXPTotal`, `ReduceEffects` (bool), `CatchRevealActive` (bool), `FishingCombo`, e poder de treino (`TrainingPower…`).
- Atributos do **Character**: `FishingState` ("waiting"/"fighting"…), `FishingTarget` (Vector3 da boia), `FishingRarity`.
- Atributos em `ReplicatedStorage`: `OceanEvent`, `OceanEventEndsAt`.
- **Tags do CollectionService** no mapa: `ZonePortal` (attrs `PrimaryColor`, `AccentColor`, `Destination`, `PortalId`), `AquariumTank`, `AquariumSpot`, `TrainingSpot` (attr `TrainingStat` = "Control"/"Instinct", `TrainingIsland`), `TrophyPedestal` (attrs `TrophyCreature`, `TrophyPlayer`, `TrophyWeight`, `TrophyVariant`), `LeaderboardBoard` (modelo com `LeaderboardScreen_Catches/_Species/_Level`), `FishingZone`, `WorkshopSpot`, `GuideNPC`.
- **Não existe** nenhum RemoteEvent de efeito que você possa chamar. **Não crie RemoteEvents.**

## 4. Regras técnicas (as mesmas da rodada 1, valem aqui)

- `--!strict`, serviços no topo com `game:GetService`, `task.*` (nunca `wait()`), Parent por último, toda conexão tem dono e é desconectada, **um único Heartbeat por módulo** (e só enquanto houver algo ativo).
- **Cliente apenas.** Nada de Script dentro de modelos do mapa (o mapa é regenerado por código). Ligue por tag/atributo.
- **`ReduceEffects`**: reaja ao vivo (`GetAttributeChangedSignal`). Com ele ligado: sem tremida, sem flash, poucas partículas, sem luzes dinâmicas, animações curtas.
- **Orçamento mobile**: ~120 partículas vivas (pico ~250 por poucos segundos), no máx. 4 luzes dinâmicas, pooling, culling por distância (~120 studs), sem pós-processamento permanente.
- **Crianças/acessibilidade**: flash de tela cheia ≤ 3 por segundo, alpha ≤ 0,6, duração ≤ 0,15 s; tremida de câmera < 0,6 stud e desligável.
- **Texturas**: use as nativas (`rbxasset://textures/particles/sparkles_main.dds`, `smoke_main.dds`, `fire_main.dds`) e formas simples; se quiser textura custom, deixe `"rbxassetid://0 -- TROCAR: <descrição>"` com fallback que **funciona sem ela**. Sons: sempre via `SfxKit` com nomes novos adicionados na tabela, `0 -- TROCAR`.
- **UI (HUD)**: `ScreenGui.ZIndexBehavior = Sibling`; **escala (`UDim2.fromScale`/`UIScale`) e `UIAspectRatioConstraint`**, nada de pixel fixo; botões ≥ 44 px; nada atrás do botão de pular nem da hotbar; `UIStroke` não acompanha texto que esmaece (ajuste junto); hover só em mouse (ignore se `GetLastInputType()` for Touch).
- Comentários/nomes em **inglês**; textos para o jogador em **português do Brasil**, curtos.
- Sem dependências externas.

## 5. O que quero que você ENTREGUE (rodada 2)

Para cada arquivo: caminho sugerido, **código completo**, e acima dele um comentário de **como integrar** (qual evento/atributo/tag chama o quê). Módulos de feature têm `start()` e `order` (o carregador do cliente inicia sozinho todo módulo em `Features/` que expõe `start()`).

### A) HUD viva — `HudJuiceFx` (prioridade 1)
A HUD já existe e é **construída por código** (`ScreenGui` "AdventureHud", com elementos de nomes: `Coins` (contador de moedas), `FishingLevel` (chip de nível) com `LevelCrest`, `LevelTrack`, `LevelFill`, `TopGloss`, `MoreButton` / `QuickMenu` / `NotificationBadge`, `Perks`, `Toast`, `RecentRarity`, e a hotbar da vara). **Não recrie a HUD.** Entregue um módulo-camada que **acha esses elementos pelo nome** (com `WaitForChild` curto + `GetDescendants` defensivo, sem quebrar se algum não existir) e os **decora/anima**:
- **Moedas**: ao ganhar (`Coins` sobe) → pulo elástico do contador, brilho dourado, **moedinhas voando** (frames pequenos ou ícones simples) da captura/centro da tela até o contador, brilho passando (shine sweep) no texto; contagem animada com easing; cor mais quente em ganhos grandes.
- **Nível/XP**: barra com **brilho correndo** (UIGradient animado), partículas de UI ao encher, **subida de nível** com estouro, anel girando na `LevelCrest`, "NÍVEL X!" com entrada elástica (curto e pulável por tempo, respeitando `ReduceEffects`).
- **Botões**: hover/press com leve escala + brilho (só mouse), "respiração" suave no botão importante (ex.: `NotificationBadge` com pulso), feedback tátil visual no toque.
- **Toasts**: entrada elástica, borda colorida pela raridade, saída suave.
- **`RecentRarity`**: aura sutil na cor da raridade.
- **Barra de Força**: se houver `PowerBar` na tela (`ScreenGui` "PowerBar"), adicione partículas de UI subindo conforme o preenchimento e um brilho forte quando entrar na faixa roxa — **sem mexer na lógica**.
- Tudo com **`UIGradient`, `UIStroke`, `UICorner`, `UIScale`, `TweenService`**, sem imagens obrigatórias. Mostre também **uma "skin" opcional** (tabela de cores/gradientes) que eu possa trocar para deixar a HUD mais premium (vidro colorido, bordas douradas, gloss), aplicada por cima dos elementos existentes.
- Responda também: **o que dá para melhorar na HUD só com Luau** e o que **exige imagens/ícones** (para eu gerar e subir depois).

### B) Revelação — camadas extras `CatchRevealFx`
Camada **complementar** ao que existe (não substitui): reaja a `FishingUpdate` `caught` e ao atributo `CatchRevealActive`. Por raridade: Comum pulinho de luz (≤ 2 s) → Incomum anéis azuis → Raro raios roxos zigue-zague na água → Épico partículas rosa em espiral + onda de choque → **Lendário/Místico** evento de 6–8 s (coluna de luz gigante, chuva de estrelas/confete, aura no jogador, **pulável**, `skip()`), com variações por `revealStyle` ("electric", "cosmic", "magma", "abyss", "celestial", "default"). Selo `isNew`: brilho + confete extra. Orçamento de partículas respeitado.

### C) Mundo
1. **`AquariumFx` v2**: brilho/cauda de partículas nos peixes por raridade, **moedas saltando** quando o aquário gera renda, brilho dourado em gigante/gold, **onda de luz ao subir de nível do tanque**, raios de luz falsos (God rays com `Beam`). Tag `AquariumTank`.
2. **`TrainingFx`**: pontos de treino (`TrainingSpot`, attr `TrainingStat`): aura de energia diferente para Controle (ciano) e Instinto (roxo/dourado), anéis de ritmo, números flutuantes de ganho, **efeito ao subir de nível de treino** (coluna de luz + estrelas).
3. **`OceanEventFx`**: lê `OceanEvent`/`OceanEventEndsAt`: tinta de céu/água, chuva/aurora/bruma, relâmpagos suaves, **banner com contagem regressiva animada** (use `HudJuiceFx` helpers se quiser), tudo com fade-in/out e desfeito no fim.
4. **`WorldAmbientFx`**: complementos para o hub (sem duplicar vaga-lumes e peixes saltando que já existem): folhas/pétalas da árvore rosa, **estrelas cadentes** à noite, brilho nas lanternas ao anoitecer, partículas nos cristais, névoa/respingos na cachoeira.
5. **`TrophyFx`**: halo/aura do troféu muda com a raridade do peixe exibido (`TrophyCreature`, `TrophyVariant`), faíscas e raios de luz; **`LeaderboardFx`**: brilho sutil e leve rotação nas telas.
6. **`PortalFx` v2**: vórtice com runas girando e partículas em espiral por portal (cores `PrimaryColor`/`AccentColor`), pulso quando o jogador se aproxima, e uma chegada mais bonita (sem repetir o estouro que já existe — **substitua só o seu visual**, descrevendo como desativar o meu).
7. **`CollectionFx`**: brilho nas criaturas descobertas, silhueta que "revela" ao descobrir, carrossel de varas com partícula do bônus, efeito de **compra** (confete + `shop_buy`).
8. **`OtherPlayersFishingFx`**: outros jogadores pescando (`FishingState`, `FishingTarget`, `FishingRarity` no Character deles): linha + boia + brilho na luta na cor da raridade, com **LOD** (a mais de 80 studs só a boia).

### D) Sons
Para **cada módulo novo**, adicione à tabela do `SfxKit` os nomes de som com descrição do som ideal (`"rbxassetid://0 -- TROCAR: ..."`), e chame `SfxKit.play/playAt` nos pontos certos. No fim, entregue uma **lista única "sons que preciso encontrar"** (nome → descrição → duração aproximada → loop?) para eu buscar no Creator Store.

## 6. Como quero a resposta

1. **Plano de integração curto**: arquivos, onde cada um vai, ordem do que mais impacta (comece pela **HUD**).
2. **Código completo** e funcional por arquivo (sem `...`, sem pseudo-código, sem `-- TODO` no essencial). Se não couber tudo, entregue **`HudJuiceFx` + `CatchRevealFx` primeiro** e avise o que fica para a próxima mensagem.
3. **No fim**: como **testar cada efeito sem jogar** (ex.: forçar `player:SetAttribute("Coins", ...)` ou disparar funções), e **tabela de custos** (partículas/instâncias/luzes por efeito).
4. **Não faça perguntas**: assuma o mais razoável e escreva a suposição num comentário.
5. Aponte o que você **não tem certeza** de que existe na API do Roblox em vez de inventar.

## 7. Proibido

- Criar RemoteEvents, mexer em moedas/captura/raridade/servidor ou em dados do jogador.
- Scripts dentro de modelos do mapa; recriar a HUD do zero; reescrever módulos da rodada 1.
- IDs de asset/som inventados (use `0 -- TROCAR`).
- Flashes agressivos, tremida forte, efeito que não pode ser desligado.
- `wait()`, loops `while true` soltos, criar centenas de instâncias por frame, deixar efeitos vivos depois de terminar.

Comece pelo plano de integração e já entregue o `HudJuiceFx` completo.

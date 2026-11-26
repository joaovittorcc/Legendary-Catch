# Prompt: animações dos lagos de treino (para o Gemini)

**Anexe junto:** `RESUMO-DO-JOGO.md` e os 6 prints da pasta `prints`. Depois cole tudo abaixo da linha.

---

Você é um programador Luau sênior e artista de efeitos para Roblox. No meu jogo **Legendary Catch** (leia o `RESUMO-DO-JOGO.md` anexo) existem 3 ilhas de treino prontas, cada uma com dois lagos: **Lagoa do Foco** (treina Controle) e **Lagoa do Instinto** (treina Instinto). Anexei um print de cada um dos 6 lagos. **Hoje eles estão completamente parados.** Quero que fiquem **vivos, mágicos e fofos**, com cada ilha tendo personalidade própria e ficando mais impressionante da ilha 1 para a 3.

Você não vê meu computador nem meu Roblox Studio. Tudo o que você precisa está neste texto e nos anexos. Os prints são a verdade visual: **não mude o visual parado** (cores, posições, tamanhos). Você só dá movimento e efeitos.

# ENTREGA
**Um único arquivo `PondAnimator.luau`**, completo, `--!strict`. É um módulo do cliente carregado pelo meu carregador de features: ele deve retornar uma tabela com `order = 115` e uma função `start()`. Caminho no projeto: `src/client/Features/PondAnimator.luau`.
- **Só cliente.** Nada de servidor, `RemoteEvent`, `Script` dentro do mapa, nem mudança no mapa.
- Só um `RunService.Heartbeat` (ou `RenderStepped`) para o módulo inteiro. Nada de um loop por peça.
- Sem bibliotecas externas e sem baixar assets. Use partes, `Beam`, `ParticleEmitter`, `PointLight`, `TweenService` e matemática. Para partículas, use só texturas que já existem nas peças do mapa ou o padrão do Roblox. Não invente `rbxassetid`.
- Se não tiver certeza de uma API do Roblox, use a alternativa mais simples e segura.

# ONDE ESTÃO AS COISAS
`Workspace.TrainingIslands.<Ilha>.<Lagoa>`, com `<Ilha>` = `TrainingIsland_Apprentice`, `TrainingIsland_Reef`, `TrainingIsland_Abyss` e `<Lagoa>` = Model `FocusPond` ou `InstinctPond`. Em cada lagoa há uma Part `WaterSurface` (use a posição X/Z dela como **centro da lagoa**; os lagos são elípticos, perto de 29 a 33 studs por 25 a 27).

**Muito importante, streaming ligado:** o jogo usa `StreamingEnabled`. As ilhas são longe e as peças chegam e somem aos poucos. Nunca assuma que uma lagoa ou um Model está completo. Registre o que existir, use `DescendantAdded`/`DescendantRemoving` (ou re-varredura leve a cada 1 a 2 segundos), tolere partes faltando sem erro e limpe referências quando sumirem. Nada de `WaitForChild` que trave para sempre.

## Ilha 1 (Aprendiz): luz, água cristalina, clima gostoso de começo
**FocusPond** (água em Y ≈ 11,68): subpasta `FocusLightRings` com os Models `FocusRing_1`, `FocusRing_2`, `FocusRing_3` (anéis flutuantes empilhados), `FocusRing_Ripple` e `FocusRing_OuterWave` (na água). Cada um tem `PrimaryPart = "Center"` e atributos `RingIndex` (1 a 5) e `BaseY` (altura de repouso). Há também `FocusRing_1_Halo`..`_3_Halo`, que precisam se mover **junto** do anel correspondente. Também: `FocusVerticalColumn` (Beam), `FocusBuoys` com `FocusBuoy_1..3` (`PrimaryPart = "FloatBase"`, atributo `BuoyIndex`) e ondinhas `RippleInner`/`RippleOuter` junto das boias; `WaterCellPattern` (padrão de hexágonos de Neon no fundo: bom para um brilho que percorre as células); `CrystalPillars` (cristais com `Beam` e `ParticleEmitter`).
Ideias: anéis subindo e descendo em onda com defasagem por `RingIndex` e girando devagar; ondas se expandindo e sumindo; boias balançando; pulso de luz percorrendo os hexágonos; cristais "respirando".

**InstinctPond:** Models `InstinctFish_Whale`, `InstinctFish_Gold`, `InstinctFish_Rainbow` (`PrimaryPart = "Body"`, atributos `OrbitRadius`, `OrbitSpeed` em radianos/s com sinal = sentido, `OrbitPhase`, `DepthY`, aqui **altura Y absoluta**, ≈ 11,3). Dentro dos peixes há peças `TailL`/`TailR`/`FinL`/`FinR` para bater cauda e nadadeiras. Também: `InstinctRainbowArc` (arco-íris na água, com `WaterStar`, `StarCrossA/B`, `WaterPetal`), `InstinctSparkles` e `FallingPetals` (emissores já existentes), `PinkLilacBlossomTree` (copa balançando de leve), `LanternPost_Left/Right` com `HangingLantern`, `RuneStones` com peças `RuneStroke` de Neon, `GoldenFireflies`.
Ideias: peixes nadando em órbita olhando para a frente, com corpo e cauda ondulando; um salto raro e curto de um peixe com respingo; pétalas girando na água; estrelas piscando; runas acendendo em sequência.

## Ilha 2 (Recife): tropical, fofo, vida marinha
**FocusPond:** `FocusLightRings` com `FocusRing_1..3` (`PrimaryPart = "Center"`, `RingIndex`, `BaseY` 14 / 17,4 / 20,8) e `FocusRingHalo_1..3`; `WaterRipple_1..3`; cristais grandes `TallCrystalLeft`, `TallCrystalMid`, `TallCrystalRight` (com `Beam`); ilhotas `IsletAnemone_1..3` (peças `Tent` = tentáculos), `IsletCoral_1..3`, `IsletFan_1..3`; conchas `TargetShell_1..4`.
Ideias: anéis em espiral subindo; cristais flutuando em alturas defasadas, com os feixes acompanhando; tentáculos de anêmona ondulando; corais e leques balançando como em água; conchas piscando em sequência, como "alvos de foco".

**InstinctPond:** `Jellyfish_1..3` (`PrimaryPart = "BellOuter"`, atributos `OrbitRadius`, `OrbitSpeed`, `OrbitPhase`; sem `DepthY`, mantenha a altura atual delas; tentáculos são as peças `Tent_1`..`Tent_7`); `PondFish_1..2` (`PrimaryPart = "Body"`, com `DepthY` **absoluto**, ≈ 11,45); `GiantClam` (peças `Top_Outer`/`Top_Inner` são a tampa; `GiantPearl`, `PearlInnerGlow`, `PearlHalo`); `WaterStar`, `StarCrossA/B`; `RuneStone_FrontL`, `RuneStone_FrontR`, `RuneStone_Back`.
Ideias: águas-vivas pulsando (a cúpula contrai e elas sobem um pouco) com tentáculos arrastando; concha gigante abrindo e fechando devagar e revelando a pérola brilhando; bolhinhas subindo.

## Ilha 3 (Abismo Estelar): cósmico, profundo, a mais impressionante
**FocusPond:** não há atributos aqui, use os nomes: anéis na água `FocusWaterRingOuter_Core/_Halo`, `FocusWaterRingMid_Core/_Halo`, `FocusWaterRingInner_Core/_Halo`; anéis flutuantes `FocusFloatRingLower_Core/_Halo` e `FocusFloatRingUpper_Core/_Halo` (cada `_Core` anda junto com o seu `_Halo`; esses Models **não têm** `PrimaryPart`, calcule o centro pelas peças `Seg_` e guarde); `FocusConstellation` (`NodeCore`, `NodeHalo` e `ConstLine`: pode acender estrela por estrela; se mover nós, as linhas têm que continuar ligadas, então prefira brilho e pulso a deslocamento); `FocusCrystalPillar_1..4` (com `BeamCore`/`BeamHalo`); `MirrorStar` (92 estrelinhas no espelho d'água), `MirrorCenterGlow`, `StarCrossA/B`; `FocusDeckCrystal_1..3`.
Ideias: anéis girando em sentidos opostos; constelação se desenhando em sequência; estrelas cintilando fora de fase; uma estrela cadente rara riscando o espelho.

**InstinctPond:** peixes cósmicos `CosmicFish_Gold`, `CosmicFish_Rainbow`, `CosmicFish_Nebula`, `CosmicFish_Azure` (`PrimaryPart = "Body"`, `OrbitRadius`, `OrbitSpeed`, `OrbitPhase`, `DepthY`; **atenção: aqui `DepthY` é negativo (≈ -0,5), ou seja, relativo à superfície da água**, diferente das outras ilhas); galáxia no fundo: peças `SpiralArm_0_`..`SpiralArm_3_` (24 por braço), `GalaxyCoreOuter/Mid/Eye`, `NebulaOuter/Mid`, `GalaxyStar` (75); `CrystalTree` (copas `CanopyCrystal_*`, `FallenPetal`); `RuneMonolith_1..3` (peças `MonolithRune_*`).
Ideias: **a galáxia girando devagar** (rotacione as peças dos braços em torno do centro, guardando o CFrame original), núcleo pulsando, peixes deixando rastro, copa de cristal cintilando em ondas.

Para classificar um valor de `DepthY` sem erro: se for menor que 5, é relativo à altura da `WaterSurface`; senão, é Y absoluto. Antes de animar um peixe, confira se a distância atual dele até o centro da lagoa combina com `OrbitRadius`; nada pode sair da água nem atravessar o deck.

# REAGIR A QUEM ESTÁ TREINANDO (a parte que dá "juice")
- Cada jogador tem o atributo replicado `TrainingStat`: `"Control"`, `"Instinct"` ou `""` (parado). Há também `TrainingCombo` (número).
- As Parts com a tag `TrainingSpot` (CollectionService) têm os atributos `TrainingIsland` (número) e `TrainingStat`. Um jogador está treinando numa lagoa quando o `TrainingStat` dele bate com o do spot e o personagem está a até 16 studs.
- Quando **alguém** treina numa lagoa: ela "acorda" (movimentos um pouco mais rápidos e brilhantes, com transição suave de 1 a 2 s) e volta ao normal quando para. `Control` acorda o `FocusPond`, `Instinct` acorda o `InstinctPond`.
- Quando o `TrainingCombo` do **jogador local** subir, faça um pulso curto na lagoa dele (um anel expandindo, os peixes dando uma disparada). Sem flash de tela e sem tremer a câmera.

# VELOCIDADE E ESTILO (erro que já tive)
Movimentos **calmos e elegantes**. Giros de anel entre **8 e 36 graus por segundo** no repouso (até ~50 com a lagoa acordada). Já tive uma versão em que tudo girava rápido demais por confundir graus com radianos: **use `math.rad` em tudo que estiver em graus**. Subir e descer: amplitude pequena (0,1 a 0,6 stud) e ciclo de 2 a 5 s. Defasagem entre elementos para nunca ficar tudo sincronizado.

# DESEMPENHO (o jogo roda em celular e o público inclui crianças)
- Anime **só** lagoas a até **160 studs** da câmera; fora disso, não mexa em nada.
- Para mover muitas peças use `workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)`. Meta: no máximo ~450 peças movidas por quadro, por lagoa visível. Os anéis têm dezenas de peças `Seg_` e a galáxia quase 100: se precisar, atualize detalhes a 30 Hz e alterne quadros.
- Guarde o **CFrame, a transparência, o tamanho e o brilho originais** na primeira vez que vir cada peça e calcule sempre a partir deles (nunca acumule erro). Se a peça sair e voltar pelo streaming, não pode registrar uma posição já deslocada como original.
- Partículas: poucas, taxa baixa. Não crie mais de ~6 emissores novos por lagoa. Não crie instâncias a cada quadro (reaproveite um pequeno pool).
- **Acessibilidade:** o jogador local tem o atributo `ReduceEffects` (boolean, pode mudar a qualquer momento). Com ele ligado: amplitudes a 35%, sem saltos, estrela cadente nem pulsos de combo, sem cintilação rápida, partículas novas desligadas.
- Nada pisca mais de 3 vezes por segundo.

# REGRA DE OURO
Não entregue nada pela metade: sem `TODO`, sem "resto igual", sem função vazia. Antes de responder, revise em ciclos: (1) compila em `--!strict` (sem variável não declarada, `nil` não tratado, API inventada); (2) cada um dos 6 lagos tem animação própria; (3) funciona com peças faltando ou chegando atrasadas; (4) nenhuma peça se desloca para sempre do lugar; (5) `ReduceEffects` respeitado; (6) velocidades calmas. Entregue o arquivo completo para download (ou em um único bloco de código). Se parar no meio e eu escrever "continue", retome exatamente de onde parou.

No fim, em até 8 linhas: o que cada lagoa ganhou, quantas peças são animadas, o que só dá para confirmar rodando no Studio e os riscos que você enxerga.

A Ilha 4 (Celestial) ainda vai ser construída: **organize o código por "perfil de lagoa"** (uma tabela por ilha e lagoa), para eu poder adicionar a Celestial depois sem reescrever o módulo.

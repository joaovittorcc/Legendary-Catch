# Lucy · Iscas

Lucy é a vendedora de iscas em Legendary Catch. É animada, esperta e empreendedora. A presença dela dá vida ao porto e associa o píer ao comércio de pesca. Hoje a NPC conversa com quem passa: explica a Sorte das varas, diz que as lanternas acendem à noite, comenta os Eventos do Oceano e avisa: “Se a boia afundar rápido, prepara o dedo!”. A venda de iscas pertence ao conceito da personagem.

[Galeria, capturas do Studio e prompts](../../art/npcs/lucy/README.md)

## Modelo atual no Studio

`LivingWorld.buildCustomNpc` cria `Workspace.LivingWorldNPCs.NPC_BaitVendor` no cliente durante o Play, por isso o inventário foi extraído ali. Base do modelo em **(34; 10,15; 3,2)** studs, com a frente em **+Z**. Caixa medida em Play de **3,86 × 5,39 × 1,38 studs** incluindo balde, caixa e iscas. A cabeça mede **1,25 stud** de altura, cerca de **23% da altura total**, e tem **84% da largura do torso**. Cabeça e torso medem **1:1,4** na vertical.

A silhueta combina chapéu ciano de abas largas e faixa dourada, cabeça esférica e corpo retangular com calça azul e botas escuras. A cabeça tem cabelo castanho atrás, dois olhos escuros com pontos neon e blush rosa. O colete rosa cobre o torso creme. Um balde de madeira com brilho ciano acompanha a mão. Ao lado há uma caixa de madeira com dois volumes neon, menta e laranja. A fala abre perto do jogador, e o rosto acompanha quem entra no raio de olhar. A animação do torso inclui o balde. O `SpeechPoint` fica na cabeça.

Paleta base extraída: chapéu e balde ciano `#75EAFF`, faixa dourada `#FFC169`, colete rosa `#FF9DD9`, camisa creme `#F8F0E0`, calça marinho `#304C72`, pele `#FCD4B6`, cabelo castanho `#623A2A`, botas `#402E28`, madeira `#945A34`, iscas menta `#5AFFDC` e laranja `#FFB260`.

## Evolução visual

A folha de personagem conserva o chapéu ciano e dourado, o colete rosa e o corpo compacto. A proposta polida costura o colete como avental e usa coral quente em bolsos e debruns, com verde-água e dourado nos acessórios. Um coque baixo mantém o rosto visível. Dar relevo a um sorriso de canto e aos bolsos, usar cinto com uma bolsa de ferramentas e arredondar levemente punhos e botas. Trocar os volumes neon da caixa por frascos de vidro grosso com centros ciano, rosa e dourado. Deixar o brilho localizado dentro do vidro e no balde. Na pose de espera, ela segura um pote, apoia o peso numa perna e aponta para o mar com a outra mão. A caixa, a madeira, a rede e a lanterna amarram o ponto de venda ao restante do píer.

## Inventário de peças

Size em studs na ordem X × Y × Z. Valores de cor medidos diretamente nas instâncias.

| Peça | Forma | Size | RGB e HEX | Material |
| --- | --- | --- | --- | --- |
| `BootL` | Block | 0.60 × 0.45 × 0.80 | 64, 46, 40 · `#402E28` | SmoothPlastic |
| `BootR` | Block | 0.60 × 0.45 × 0.80 | 64, 46, 40 · `#402E28` | SmoothPlastic |
| `LegL` | Block | 0.54 × 1.35 × 0.54 | 48, 76, 114 · `#304C72` | SmoothPlastic |
| `LegR` | Block | 0.54 × 1.35 × 0.54 | 48, 76, 114 · `#304C72` | SmoothPlastic |
| `Torso` | Block | 1.55 × 1.75 × 0.95 | 248, 240, 224 · `#F8F0E0` | SmoothPlastic |
| `Vest` | Block | 1.64 × 1.35 × 1.02 | 255, 157, 217 · `#FF9DD9` | SmoothPlastic |
| `ArmL` | Block | 0.48 × 1.45 × 0.48 | 252, 212, 182 · `#FCD4B6` | SmoothPlastic |
| `ArmR` | Block | 0.48 × 1.45 × 0.48 | 252, 212, 182 · `#FCD4B6` | SmoothPlastic |
| `PropBucket` | Cylinder | 0.70 × 0.65 × 0.70 | 164, 104, 62 · `#A4683E` | Wood |
| `PropGlow` | Ball | 0.45 × 0.25 × 0.45 | 117, 234, 255 · `#75EAFF` | Neon |
| `Head` | Ball | 1.30 × 1.25 × 1.25 | 252, 212, 182 · `#FCD4B6` | SmoothPlastic |
| `HairBack` | Ball | 1.38 × 1.10 × 0.85 | 98, 58, 42 · `#623A2A` | SmoothPlastic |
| `EyeL` | Ball | 0.18 × 0.24 × 0.14 | 28, 28, 38 · `#1C1C26` | SmoothPlastic |
| `EyeR` | Ball | 0.18 × 0.24 × 0.14 | 28, 28, 38 · `#1C1C26` | SmoothPlastic |
| `EyeShineL` | Ball | 0.07 × 0.07 × 0.07 | 255, 255, 255 · `#FFFFFF` | Neon |
| `EyeShineR` | Ball | 0.07 × 0.07 × 0.07 | 255, 255, 255 · `#FFFFFF` | Neon |
| `BlushL` | Block | 0.18 × 0.10 × 0.08 | 255, 145, 165 · `#FF91A5` | SmoothPlastic |
| `BlushR` | Block | 0.18 × 0.10 × 0.08 | 255, 145, 165 · `#FF91A5` | SmoothPlastic |
| `HatBrim` | Cylinder | 2.05 × 0.14 × 2.05 | 117, 234, 255 · `#75EAFF` | SmoothPlastic |
| `HatCrown` | Block | 1.22 × 0.52 × 1.22 | 117, 234, 255 · `#75EAFF` | SmoothPlastic |
| `HatBand` | Block | 1.30 × 0.16 × 1.30 | 255, 193, 105 · `#FFC169` | SmoothPlastic |
| `BaitCrate` | Block | 1.60 × 1.20 × 1.20 | 148, 90, 52 · `#945A34` | WoodPlanks |
| `BaitJar1` | Block | 0.40 × 0.55 × 0.40 | 90, 255, 220 · `#5AFFDC` | Neon |
| `BaitJar2` | Block | 0.36 × 0.48 × 0.36 | 255, 178, 96 · `#FFB260` | Neon |

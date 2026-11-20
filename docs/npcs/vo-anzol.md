# Vô Anzol

Guia da primeira pescaria em Legendary Catch. Recebe quem chega, aponta o píer, explica a mordida e a luta e convida a abrir a Coleção. Depois, recomenda a Oficina e o treino na lagoa e divide dicas e causos do mar. Fala com humor tranquilo e confiança de quem vive na ilha: “Dizem que um Kraken mora depois da arrebentação. Eu acredito.”

[Artes, referências e capturas do Studio](../../art/npcs/vo-anzol/README.md)

## Modelo atual no Studio

`Workspace.Island.GuideNPC`, na entrada do píer, pivô em **(13,8; 13,34; 1,8)** studs. Direção frontal **(−0,908; 0; +0,418)**. Caixa completa **5,02 × 6,72 × 3,06 studs**, incluindo a ponta da vara carregada nas costas. Das solas ao topo do chapéu são cerca de **6,46 studs**. A peça da cabeça mede **1,28 stud** de altura, ou cerca de **20% da altura vestida**, e tem **65% da largura** do torso. Cabeça e torso em altura têm proporção **1:1,63**.

A aba larga, a barba branca em volumes arredondados e a vara diagonal definem a silhueta. O corpo é feito de blocos curtos, com ombros redondos, mãos simples e botas largas. O chapéu texturizado é palha dourada com faixa marinho e um enfeite azul. A barba texturizada tem cachos brancos, bigode curvado e volume no queixo. O rosto tem olhos escuros com reflexo branco, nariz pêssego arredondado e sobrancelhas grossas. A vara texturizada marrom/cinza tem amarrações claras, ponta azul luminosa e uma tira de couro diagonal. O cinto tem fivela dourada. Uma peça laranja aparece atrás do quadril na vista do píer e não está identificada como lanterna no inventário do modelo.

Paleta principal extraída das peças: creme `#F8EED6`, petróleo `#2E5E6C`, calça azul ardósia `#3A4E60`, couro escuro `#3A2A22`, couro caramelo `#B87E4C`, dourado `#FFC860`, pele `#EEBA94`, branco `#F5F5F5` e cristal ciano `#4AE4FF`. O RGB `#A3A2A5` das três MeshParts é a cor-base da instância. Os materiais e cores do chapéu, da barba e da vara são lidos na textura nas capturas.

`LivingWorld` usa o modelo existente no mapa e cria respiração e olhar procedural. `buildCustomNpc` constrói Marina e a NPC da praia. `Guide` controla o balão e seleciona as falas por etapa, evento e dicas em `Strings.luau`. O ícone atual do balão ocupa 38 × 38 px, então o retrato deve privilegiar chapéu, sobrancelhas, olhos e barba.

## Evolução visual

Preservar chapéu de palha com faixa marinho, barba em cachos, colete petróleo com dois bolsos, tira diagonal, botas escuras e broche ciano. Dar uma curva gentil à boca e pequenos vincos junto aos olhos. Dar desgaste às bordas e à vara, com duas amarrações claras e uma emenda legível. Usar poucos anzóis e iscas nos bolsos e uma pequena lanterna âmbar no cinto. O brilho do cristal fica concentrado no broche para o rosto seguir como primeiro foco. Para a pose de espera, apoiar a vara fora da silhueta do corpo, deixar a outra mão no quadril e deslocar o peso para uma bota. Conferir a leitura de frente e pela câmera do píer. Sem cachimbo.

## Inventário de peças (50 BaseParts)

Size em studs, na ordem X × Y × Z. Para peças com SpecialMesh, a forma abaixo é a propriedade da peça base. Head, BackHair, BackHairTuft e as duas costeletas têm SpecialMesh. O Attachment `SpeechPoint` fica na cabeça.

| Peça | Forma | Size | RGB e HEX | Material |
| --- | --- | --- | --- | --- |
| `BootL` | Block | 0.86 × 0.72 × 1.12 | 58, 42, 34 · `#3A2A22` | Leather |
| `BootSoleL` | Block | 0.90 × 0.14 × 1.16 | 38, 28, 22 · `#261C16` | Rubber |
| `BootCuffL` | Block | 0.94 × 0.24 × 0.96 | 184, 126, 76 · `#B87E4C` | Fabric |
| `LegL` | Block | 0.84 × 1.28 × 0.86 | 58, 78, 96 · `#3A4E60` | Fabric |
| `BootR` | Block | 0.86 × 0.72 × 1.12 | 58, 42, 34 · `#3A2A22` | Leather |
| `BootSoleR` | Block | 0.90 × 0.14 × 1.16 | 38, 28, 22 · `#261C16` | Rubber |
| `BootCuffR` | Block | 0.94 × 0.24 × 0.96 | 184, 126, 76 · `#B87E4C` | Fabric |
| `LegR` | Block | 0.84 × 1.28 × 0.86 | 58, 78, 96 · `#3A4E60` | Fabric |
| `Torso` | Block | 2.04 × 2.08 × 1.12 | 248, 238, 214 · `#F8EED6` | Fabric |
| `Belt` | Block | 2.14 × 0.28 × 1.22 | 58, 42, 34 · `#3A2A22` | Leather |
| `BeltBuckle` | Block | 0.42 × 0.34 × 0.18 | 255, 200, 96 · `#FFC860` | Metal |
| `VestBack` | Block | 2.16 × 1.88 × 0.46 | 46, 94, 108 · `#2E5E6C` | Fabric |
| `VestFrontL` | Block | 0.78 × 1.86 × 0.78 | 46, 94, 108 · `#2E5E6C` | Fabric |
| `VestPocketL` | Block | 0.46 × 0.44 × 0.16 | 184, 126, 76 · `#B87E4C` | Leather |
| `VestButtonL` | Ball | 0.12 × 0.12 × 0.10 | 176, 132, 68 · `#B08444` | Metal |
| `VestFrontR` | Block | 0.78 × 1.86 × 0.78 | 46, 94, 108 · `#2E5E6C` | Fabric |
| `VestPocketR` | Block | 0.46 × 0.44 × 0.16 | 184, 126, 76 · `#B87E4C` | Leather |
| `VestButtonR` | Ball | 0.12 × 0.12 × 0.10 | 176, 132, 68 · `#B08444` | Metal |
| `VestCrystalPin` | Block | 0.16 × 0.26 × 0.14 | 74, 228, 255 · `#4AE4FF` | Neon |
| `RodStrapFront` | Block | 0.24 × 2.38 × 0.12 | 58, 42, 34 · `#3A2A22` | Leather |
| `RodStrapBack` | Block | 0.24 × 2.38 × 0.12 | 58, 42, 34 · `#3A2A22` | Leather |
| `ShoulderR` | Ball | 0.68 × 0.68 × 0.68 | 248, 238, 214 · `#F8EED6` | Fabric |
| `ArmR` | Block | 0.58 × 0.88 × 0.58 | 248, 238, 214 · `#F8EED6` | Fabric |
| `CuffR` | Block | 0.64 × 0.18 × 0.64 | 248, 238, 214 · `#F8EED6` | Fabric |
| `ForearmR` | Block | 0.48 × 0.82 × 0.48 | 238, 186, 148 · `#EEBA94` | SmoothPlastic |
| `HandR` | Ball | 0.48 × 0.48 × 0.48 | 238, 186, 148 · `#EEBA94` | SmoothPlastic |
| `ShoulderL` | Ball | 0.68 × 0.68 × 0.68 | 248, 238, 214 · `#F8EED6` | Fabric |
| `ArmL` | Block | 0.58 × 0.86 × 0.58 | 248, 238, 214 · `#F8EED6` | Fabric |
| `CuffL` | Block | 0.64 × 0.18 × 0.64 | 248, 238, 214 · `#F8EED6` | Fabric |
| `ForearmL` | Block | 0.48 × 0.82 × 0.48 | 238, 186, 148 · `#EEBA94` | SmoothPlastic |
| `HandL` | Ball | 0.48 × 0.48 × 0.48 | 238, 186, 148 · `#EEBA94` | SmoothPlastic |
| `Neck` | Cylinder | 0.64 × 0.36 × 0.64 | 238, 186, 148 · `#EEBA94` | SmoothPlastic |
| `Head` | Block | 1.36 × 1.28 × 1.28 | 238, 186, 148 · `#EEBA94` | SmoothPlastic |
| `Nose` | Ball | 0.28 × 0.24 × 0.32 | 224, 152, 120 · `#E09878` | SmoothPlastic |
| `BackHair` | Block | 1.38 × 0.78 × 0.68 | 245, 245, 245 · `#F5F5F5` | SmoothPlastic |
| `BackHairTuft` | Block | 0.86 × 0.44 × 0.48 | 245, 245, 245 · `#F5F5F5` | SmoothPlastic |
| `Sideburn-1` | Block | 0.32 × 0.60 × 0.54 | 245, 245, 245 · `#F5F5F5` | SmoothPlastic |
| `Ear-1` | Ball | 0.20 × 0.32 × 0.26 | 238, 186, 148 · `#EEBA94` | SmoothPlastic |
| `Eye-1` | Ball | 0.16 × 0.20 × 0.12 | 30, 34, 46 · `#1E222E` | SmoothPlastic |
| `EyeShine-1` | Ball | 0.06 × 0.06 × 0.05 | 245, 245, 245 · `#F5F5F5` | Neon |
| `Brow-1` | Block | 0.32 × 0.12 × 0.14 | 245, 245, 245 · `#F5F5F5` | SmoothPlastic |
| `Sideburn1` | Block | 0.32 × 0.60 × 0.54 | 245, 245, 245 · `#F5F5F5` | SmoothPlastic |
| `Ear1` | Ball | 0.20 × 0.32 × 0.26 | 238, 186, 148 · `#EEBA94` | SmoothPlastic |
| `Eye1` | Ball | 0.16 × 0.20 × 0.12 | 30, 34, 46 · `#1E222E` | SmoothPlastic |
| `EyeShine1` | Ball | 0.06 × 0.06 × 0.05 | 245, 245, 245 · `#F5F5F5` | Neon |
| `Brow1` | Block | 0.32 × 0.12 × 0.14 | 245, 245, 245 · `#F5F5F5` | SmoothPlastic |
| `FishermanHat/body_geom` | MeshPart | 2.11 × 1.06 × 2.11 | 163, 162, 165 · `#A3A2A5` | Plastic |
| `FishermanBeard/body_geom` | MeshPart | 1.18 × 1.00 × 0.83 | 163, 162, 165 · `#A3A2A5` | Plastic |
| `BackFishingRod/body_geom` | MeshPart | 0.54 × 5.40 × 1.41 | 163, 162, 165 · `#A3A2A5` | Plastic |
| `Tip` | Ball | 0.13 × 0.13 × 0.13 | 150, 230, 255 · `#96E6FF` | Neon |

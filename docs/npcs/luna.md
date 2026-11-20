# Luna · Conchas

Luna vive à beira-mar, ao pé da escadaria, e divide com quem passa o que ouviu e encontrou na areia. Fala das conchas que guardam sons diferentes, da pesca na hora dourada, dos cristais que parecem estrelas à noite e da estrela-do-mar sonolenta. A fala sobre “100 criaturas no álbum inteiro” é a contagem que a personagem ouviu. Seu tom é curioso, doce e sonhador.

[Galeria, capturas e prompts](../../art/npcs/luna/README.md)

## Modelo atual no Studio

`LivingWorld.buildCustomNpc` cria `Workspace.LivingWorldNPCs.NPC_ShellGirl` no cliente em Play. Base em **(−10,8 | 1,35 | 53,5)** studs, ao pé de `FrontStairs.Landing`. Olha para o ponto **(−4 | 1,35 | 48)**. A caixa medida em Play é **3,08 × 5,37 × 1,46 studs**, incluindo balde e conchas. A cabeça mede **1,25 stud**, cerca de **23% da altura total**. A razão cabeça:torso na vertical é **1:1,4**.

A silhueta tem aba larga, rosto esférico, cabelo arredondado nas costas, torso de bloco e pernas retas. Olhos escuros com brilho branco e blush rosa dão a expressão atual. Ela carrega um balde de madeira com brilho rosa. Três pequenas formas de concha já decoram a areia. A pose e o olhar balançam com a animação de `LivingWorld`, e o balão usa `SpeechPoint` na cabeça.

Paleta: lilás `#D8BAFF`, amarelo claro `#FFDC94`, azul `#5698C6`, roxo escuro `#362A42`, palha `#F4DAA8`, faixa e brilho rosa `#FF9DD9`, pele `#F6C8AA` e madeira `#C28E5C`. As conchas atuais usam rosa `#FFB6CE`, turquesa claro `#91E8FF` e dourado `#FFE08C`.

## Evolução visual

Preservar o chapéu de palha com faixa rosa, o colete amarelo sobre o lilás, a calça azul e o volume do cabelo roxo. Arredondar um pouco a aba, dar um sorriso pequeno e aumentar os olhos com parcimônia. Acrescentar um cesto raso de conchas, deixar o rosa brilhar lá dentro e usar pés descalços na versão polida. Na pose principal, a concha ocupa o espaço entre a mão e a orelha, com cotovelo destacado, cabeça inclinada e apoio em uma perna. A estrela-do-mar dorme na areia ao lado. Para as conchas decorativas, usar quatro silhuetas distintas: vieira, espiral, búzio e náutilo.

## Inventário de peças

24 BaseParts. Size em studs, na ordem X × Y × Z. O modelo também tem o Attachment `SpeechPoint`.

| Peça | Forma | Size | RGB e HEX | Material |
| --- | --- | --- | --- | --- |
| `BootL` | Block | 0.60 × 0.45 × 0.80 | 64, 46, 40 · `#402E28` | SmoothPlastic |
| `BootR` | Block | 0.60 × 0.45 × 0.80 | 64, 46, 40 · `#402E28` | SmoothPlastic |
| `LegL` | Block | 0.54 × 1.35 × 0.54 | 86, 152, 198 · `#5698C6` | SmoothPlastic |
| `LegR` | Block | 0.54 × 1.35 × 0.54 | 86, 152, 198 · `#5698C6` | SmoothPlastic |
| `Torso` | Block | 1.55 × 1.75 × 0.95 | 216, 186, 255 · `#D8BAFF` | SmoothPlastic |
| `Vest` | Block | 1.64 × 1.35 × 1.02 | 255, 220, 148 · `#FFDC94` | SmoothPlastic |
| `ArmL` | Block | 0.48 × 1.45 × 0.48 | 246, 200, 170 · `#F6C8AA` | SmoothPlastic |
| `ArmR` | Block | 0.48 × 1.45 × 0.48 | 246, 200, 170 · `#F6C8AA` | SmoothPlastic |
| `PropBucket` | Cylinder | 0.70 × 0.65 × 0.70 | 194, 142, 92 · `#C28E5C` | Wood |
| `PropGlow` | Ball | 0.45 × 0.25 × 0.45 | 255, 157, 217 · `#FF9DD9` | Neon |
| `Head` | Ball | 1.30 × 1.25 × 1.25 | 246, 200, 170 · `#F6C8AA` | SmoothPlastic |
| `HairBack` | Ball | 1.38 × 1.10 × 0.85 | 54, 42, 66 · `#362A42` | SmoothPlastic |
| `EyeL` | Ball | 0.18 × 0.24 × 0.14 | 28, 28, 38 · `#1C1C26` | SmoothPlastic |
| `EyeR` | Ball | 0.18 × 0.24 × 0.14 | 28, 28, 38 · `#1C1C26` | SmoothPlastic |
| `EyeShineL` | Ball | 0.07 × 0.07 × 0.07 | 255, 255, 255 · `#FFFFFF` | Neon |
| `EyeShineR` | Ball | 0.07 × 0.07 × 0.07 | 255, 255, 255 · `#FFFFFF` | Neon |
| `BlushL` | Block | 0.18 × 0.10 × 0.08 | 255, 145, 165 · `#FF91A5` | SmoothPlastic |
| `BlushR` | Block | 0.18 × 0.10 × 0.08 | 255, 145, 165 · `#FF91A5` | SmoothPlastic |
| `HatBrim` | Cylinder | 2.05 × 0.14 × 2.05 | 244, 218, 168 · `#F4DAA8` | SmoothPlastic |
| `HatCrown` | Block | 1.22 × 0.52 × 1.22 | 244, 218, 168 · `#F4DAA8` | SmoothPlastic |
| `HatBand` | Block | 1.30 × 0.16 × 1.30 | 255, 157, 217 · `#FF9DD9` | SmoothPlastic |
| `Shell1` | Ball | 0.65 × 0.24 × 0.65 | 255, 182, 206 · `#FFB6CE` | SmoothPlastic |
| `Shell2` | Ball | 0.55 × 0.22 × 0.55 | 145, 232, 255 · `#91E8FF` | SmoothPlastic |
| `Shell3` | Ball | 0.50 × 0.20 × 0.50 | 255, 224, 140 · `#FFE08C` | SmoothPlastic |

# Ilha de Treino 2 (Recife): prompt para o chat do Gemini (navegador)

Como usar: abra o Gemini no navegador, anexe a imagem `art/concept/escolhidas/ilha-2-recife.jpg`, cole TODO o bloco abaixo (de "Você é um..." até o fim) e envie. O prompt é autocontido: o Gemini do navegador não enxerga o repositório.
Quando ele responder com o código, salve o resultado num arquivo `.lua` e me mande (eu converto em `tools/TrainingIsland2Builder.luau`, ligo no jogo e testo).
Se a resposta vier cortada, mande: "continue exatamente de onde parou, sem repetir nada".

---

Você é um programador Luau sênior e artista técnico de Roblox. Vou anexar uma imagem de concept art. Escreva UM script Luau completo (um único arquivo, em um único bloco de código, sem explicações no meio) que construa essa ilha em Roblox Studio por código, o mais fiel possível à imagem. Depois do código escreva só 5 linhas de resumo.

# CONTEXTO
Jogo: Legendary Catch (pesca e coleção). Esta é a "Ilha de Treino 2: Recife", uma ilha tropical flutuante num mar turquesa. Tem duas lagoas de treino (Foco, azul cristalina; Instinto, roxa bioluminescente), um portal de pedra com corais ao fundo, ponte de tábuas no centro, palmeiras, cabana de palha, rede de dormir, e uma lateral de rocha escura coberta de corais coloridos. Visual estilizado, cartoon premium, cores vivas, brilhos.
Um script igual a este já foi feito para a Ilha 1 (grama + lagoas) e o resultado serviu muito bem, então siga o mesmo padrão de entrega.

# ENTREGA (formato obrigatório)
- Arquivo `TrainingIsland2Builder.luau`, começando com `--!strict`. Um `local Builder = {}` e `return Builder` no fim.
- `function Builder.build(origin: Vector3?): Model`: IDEMPOTENTE (apaga a versão anterior e recria). Origem padrão `Vector3.new(480, 12, 420)`. O Model final se chama `TrainingIsland_Reef` e fica dentro de `Workspace.TrainingIslands` (crie a Folder `TrainingIslands` se não existir; se já existir um Model com esse nome, destrua-o antes). Ao final, imprima `print` com a contagem de BaseParts.
- Opcional: `function Builder.applyReferenceLighting()` e `function Builder.restoreLighting()` para um preset de iluminação ensolarada SÓ para prints (guarde os valores originais e restaure). NÃO chame isso dentro de `build()`. NUNCA altere o Lighting dentro de `build()`.
- Tudo em um arquivo, com suas próprias funções auxiliares: `makeFolder`, `makeModel`, `makePart(parent, name, cf, size, color, material, canCollide, transparency)`, `makeWedge`, `makeCylinderY` (cilindro com o eixo circular alinhado ao Y), `makeEllipsoid` (Part + SpecialMesh Sphere), `makeSegment(p1, p2, espessura...)` e `makeNeonRing` (anel feito de segmentos Neon). Todas as peças `Anchored = true`.
- Código limpo: `--!strict`, `local Workspace = game:GetService("Workspace")` etc. no topo, nunca `wait()` (se precisar, `task.wait`), sem `Script`/`LocalScript` dentro do modelo, `Parent` por último quando possível, `Random.new(SEED)` fixo para ser determinístico, constantes de paleta em uma tabela `PALETTE`. Rode mentalmente o código procurando erros de tipo e `nil` antes de responder. Evite `Enum` que não exista. Se não tiver certeza de uma API do Roblox, use a alternativa mais simples e segura.
- Se o código ficar muito grande, divida em seções comentadas, mas entregue TUDO em um único bloco. Se a resposta for cortar, termine numa linha completa e eu peço para continuar.

# SISTEMA DE COORDENADAS
Todas as posições locais são relativas à origem da ilha. Eixo +Y para cima. A câmera da concept art olha de +Z (frente, perto) para -Z (fundo, longe). Então:
- FUNDO (-Z): o portal de pedra com corais, a cabana de palha, a árvore de coral rosa, palmeiras.
- FRENTE (+Z): a ilha se abre, areia larga na frente, lateral de rocha com corais visível para a câmera.
- ESQUERDA (-X): Lagoa do Foco (azul cristalina). DIREITA (+X): Lagoa do Instinto (roxa).
- CENTRO: caminho de areia e conchas vindo do portal, uma ponte de tábuas com corda entre as duas lagoas.
O chão jogável da ilha fica em Y = 0 local (= Y 12 do mundo). Raio da ilha ≈ 46 studs (silhueta orgânica, levemente irregular com seno/cosseno, NÃO um círculo perfeito). Escala: um avatar tem ~5 studs de altura.

# O QUE CONSTRUIR (fiel à imagem)

1. SILHUETA E BASE (o ponto mais importante)
- A ilha é UMA massa contínua: topo de grama com bordas de areia em volta (areia clara e larga, mais larga na frente), uma borda de areia que acompanha o contorno sem sobrar como um prato por cima, e a rocha escura descendo logo abaixo, no mesmo raio da borda, afinando em 3 a 4 camadas de blocos arredondados até uma ponta irregular. A rocha é cinza-azulada escura com musgo verde-escuro nos vãos.
- A lateral da rocha (visível para a câmera, na frente) é COBERTA DE CORAIS: galhos de coral rosa, laranja, roxo e amarelo (use cilindros finos ramificados, cada galho levemente inclinado), corais-leque grandes (discos achatados e arredondados em rosa/laranja/roxo com um padrão de nervuras: várias fatias finas), anêmonas (cones baixos com tentáculos de bolinhas coloridas), pequenas flores-do-mar, e cristais aqua brilhando (Neon + PointLight fraca nos maiores). Muitos desses. Isso dá a "cara" da ilha.
- Água do mar em volta não faz parte da ilha (já existe no jogo): não crie oceano.

2. TOPO
- Grama verde viva, com tufos (peças finas cruzadas) e pedrinhas; manchas de areia; margens de areia em volta de cada lagoa.
- Caminho central do portal até a ponte, feito de pedrinhas e conchas na areia (pequenas elipses achatadas em tons de cinza, rosa-claro e creme).

3. PORTAL (fundo, centro) — arco de pedra cinza
- Arco de blocos de pedra cinza empilhados (pilares de 4 a 5 blocos levemente desalinhados, com juntas escuras e rachaduras), coberto de corais e conchas, com cristais aqua encravados nas laterais. Pedra central no topo com cristal aqua. Interior branco-aqua BRILHANTE: uma peça Neon com anéis/espiral luminosos e `ParticleEmitter` leve (poucas partículas). Escadinha de 3 degraus de pedra na frente. Pequenos cristais e corais nos pés do arco.
- A pedra do arco não pode ficar tingida de ciano pela luz: use uma `PointLight` fraca.

4. LAGOA DO FOCO (esquerda) — água cristalina
- Água rasa azul-clara bem transparente com fundo de areia branca. Use uma peça de água (cilindro/elipse achatada) com `Material = Glass` ou `SmoothPlastic` com Transparency ~0.35 e cor azul-turquesa clara, e um fundo de areia mais abaixo.
- Ilhotas de anêmona/coral dentro da água (3 pequenas ilhas de musgo verde com corais roxos e rosas), anéis de coral e pedra dentro da água.
- 3 ANÉIS DE LUZ grandes empilhados sobre a água (anéis Neon ciano finos, um maior embaixo e menores acima), com brilho (`PointLight` suave, bloom virá do Lighting do jogo).
- Conchas flutuando como alvos (3 a 4 conchas grandes rosa e creme sobre a água).
- 3 cristais aqua altos (prismas hexagonais translúcidos, o do meio maior) atrás da lagoa, com um feixe de luz vertical difuso (peça fina e alta, Transparency alta, Neon).
- Deck de madeira comprido na borda de cima, com 2 banquinhos redondos de 3 pernas e um barril; estacas na água com corda enrolada.
- Uma rede de dormir (hammock) pendurada entre 2 palmeiras na borda esquerda.

5. LAGOA DO INSTINTO (direita) — água roxa bioluminescente
- Água roxa/violeta profunda com gradiente para turquesa no centro, brilho roxo nas bordas, estrelinhas flutuando (partículas leves). Peças de água com Transparency ~0.4.
- 3 águas-vivas brilhando (cúpula arredondada rosa ou ciano translúcida com tentáculos finos pendurados; duas rosas, uma ciano), e 2 peixes coloridos pequenos (laranja e azul) nadando.
- 2 decks de madeira com banquinho (um acima e um à direita), pedras com runas ciano brilhando (3 pedras cinza com glifos Neon ou `SurfaceGui` com texto de runa).
- CONCHA GIGANTE ABERTA com uma PÉROLA brilhando, na borda direita da lagoa (duas metades de concha rosa/lilás, com nervuras, e uma esfera Neon branca-rosada).
- Árvore de coral rosa atrás: tronco torcido e galhos grossos em rosa, copa de coral com muitos galhos, pétalas caindo (um `ParticleEmitter` leve).
- Varal de luzinhas e lanternas âmbar em postes de madeira com braço curvo; suporte de madeira com boias coloridas penduradas (vermelha, azul, amarela, branca); pilha de 4 a 5 caixotes de madeira.

6. VEGETAÇÃO E PROPS
- 6 a 7 PALMEIRAS: tronco curvo feito de 5 a 6 cilindros inclinados e levemente afinando, copa com 7 a 9 folhas longas e arqueadas (cada folha 3 a 4 segmentos achatados verde-vivo, com tom mais claro e mais escuro), cocos pequenos. Distribua em volta da ilha, principalmente no fundo e nos lados.
- CABANA DE PALHA pequena no fundo-esquerdo: 4 postes, plataforma elevada, telhado de palha (peças inclinadas amarelo-palha), escadinha.
- Placas de madeira com peixe entalhado em creme (2 a 3 pelo caminho).
- Conchas e estrelas-do-mar na areia, pedrinhas, tufos, flores pequenas.
- Luzes: no máximo 17 `PointLight`/`SpotLight` no total, tudo leve; partículas: no máximo 8 `ParticleEmitter` com `Rate` baixa.

# CONTRATO COM O SERVIDOR (OBRIGATÓRIO, nomes e atributos exatos)
Estes são filhos DIRETOS do Model `TrainingIsland_Reef` (Parts ancoradas, `Transparency = 1`, `CanCollide = false`, `CanQuery = false` exceto onde indicado, `CastShadow = false`):
1. `ArrivalSpawn` (4x1x4): na areia à frente do portal, no chão, virada para o centro da ilha. Tag `ZoneSpawn` (CollectionService) e atributo `Destination = "training_2"` (string).
2. `ReturnPortal` (~6x8x2.4): dentro do arco do portal (CanTouch e CanQuery = true). Tag `ZonePortal`. Atributos: `PortalId = "training_2_return"`, `ZoneId = "lagoon"`, `Destination = "main"`.
3. `FocusSpot` (~5.5x2x5.5): sobre o deck da lagoa do Foco, junto ao banquinho. Tag `TrainingSpot`. Atributos: `TrainingIsland = 2` (number), `TrainingStat = "Control"`.
4. `InstinctSpot` (~5.5x2x5.5): sobre um deck da lagoa do Instinto. Tag `TrainingSpot`. Atributos: `TrainingIsland = 2` (number), `TrainingStat = "Instinct"`.
5. `FocusPond` e `InstinctPond`: dois Models (filhos diretos) que agrupam as peças da água e dos efeitos de cada lagoa.
6. `CameraShot` (1x1x1, invisível): na posição `origin + Vector3.new(0, 48, 100)` olhando para a origem, com atributo `FieldOfView = 55` (esse é o ângulo da concept art).
Também crie `IslandCenter` (Part 2x2x2 invisível, na origem) e defina como `PrimaryPart` do Model.
Regras de colisão: piso, caminhos, ponte e decks com `CanCollide = true`; decoração (corais, palmeiras, conchas, cristais, folhas, etc.) com `CanCollide = false` para o jogador não travar. Nada pode bloquear o caminho a pé do `ArrivalSpawn` até os decks do Foco e do Instinto, nem do `ArrivalSpawn` até o portal. A ponte central deve ser caminhável.
Não crie `Script`/`LocalScript`, `ProximityPrompt` nem `Seat` dentro do modelo (o servidor cuida da lógica). Se precisar de animação, deixe atributos (por exemplo `OrbitRadius`, `OrbitSpeed`, `OrbitPhase` nas águas-vivas e peixes) para ser animado depois.

# QUALIDADE (aprendizados da ilha anterior)
- NÃO há limite de peças: use quantas precisar para ficar bonito e fiel. Prefira muitas peças pequenas bem colocadas a poucas peças lisas. A otimização será feita depois. Só não deixe o `build()` demorar mais que ~2 s (evite loops gigantes e aninhados).
- Nada de blocos retos e lisos: use `Rotation` variada, elipsoides achatados, cunhas, pequenas variações de cor e de tamanho (com o `Random` fixo) para parecer orgânico e esculpido.
- Cores vivas e saturadas, mas com variação (verdes de 3 tons, rosa/laranja/roxo nos corais, areia dourada-clara, rocha cinza-azulada escura com musgo).
- Evite z-fighting: nunca deixe duas faces coplanares sobrepostas; ajuste a altura em 0,02 a 0,05 stud.
- Brilho só onde precisa: Neon nos anéis, cristais, pérola, runas, interior do portal, águas-vivas e luzinhas. O resto é `SmoothPlastic`, `Sand`, `Grass`, `Wood`, `WoodPlanks`, `Slate`, `Limestone`, `Fabric`.
- Compare mentalmente com a imagem anexada em cada parte e corrija antes de responder: a ilha deve ter a mesma composição da imagem (portal ao fundo, Foco à esquerda, Instinto à direita, ponte no centro, rocha coberta de corais na frente).

Depois do código, escreva um resumo de 5 linhas: (1) o que foi construído, (2) contagem aproximada de peças, luzes e emissores, (3) como rodar (`require(game.ServerStorage.DevTools.TrainingIsland2Builder).build()` ou colando na Command Bar), (4) qualquer parte da imagem que ficou simplificada, (5) qualquer risco que você enxerga.

# Ilha de Treino 4 (Celestial): prompt para o Claude Chat (claude.ai)

Prompt autocontido: o Claude Chat não vê o seu computador.

**1. Anexe no chat** (todos estão em `art/preview/ilha-4/`):
- `referencia.jpg` (a ilha que queremos)
- `atual-1-frente.jpg`, `atual-2-diagonal.jpg`, `atual-3-cima.jpg` (como está hoje)

**2. Opcional, ajuda no acabamento:** anexe `tools/TrainingIsland3Builder.luau` (126 KB). Se o chat reclamar do tamanho, mande sem.

**3. Cole tudo que está abaixo da linha.** Use o modelo mais forte disponível. Se parar no meio, escreva `continue`.

**4.** Baixe o arquivo, salve como `tools/TrainingIsland4Builder.luau` e me chame: eu monto no Studio, apago o provisório, testo e mando de volta as correções.

---

Você é um programador Luau sênior e artista técnico de Roblox, especialista em construir ilhas estilizadas bonitas por código. Anexei: (1) a **imagem de referência** (`referencia.jpg`) da "Ilha de Treino 4: Celestial (treino x50, exige 1 trilhão de Poder de Pesca)" do meu jogo "Legendary Catch"; (2) **prints de como ela está HOJE no jogo** (`atual-1-frente.jpg`, `atual-2-diagonal.jpg`, `atual-3-cima.jpg`); e, se foi possível, (3) o código de **outra ilha de treino do jogo** (`TrainingIsland3Builder.luau`) como exemplo do padrão de código e de acabamento. Você não tem acesso ao meu computador nem ao Roblox Studio: tudo o que precisa está neste texto e nos anexos.

# COMO ESTÁ HOJE (os prints "atual-*")
É só um **provisório** de 195 peças: um disco liso e branco com borda amarela, colunas finas, bolas brancas no lugar das nuvens, placas retangulares coloridas no lugar da aurora e um anel de traços. **Não aproveite nada do visual: vai ser tudo substituído.** Os prints servem para você ver o que **não** fazer (chapado, estourado de branco, formas básicas soltas, nada de natureza) e a escala atual. O alvo é a imagem de referência.

# MISSÃO
Escreva **um único arquivo Luau, `TrainingIsland4Builder.luau`**, que constrói por código a ilha da imagem de referência, o mais **idêntica** possível. É a ilha final, **flutuando no céu acima de um mar de nuvens**, com aurora pastel e raios de luz: grama verde com borda de **mármore branco e frisos dourados**, rocha clara com cristais dourados e ciano, cachoeiras de luz caindo para as nuvens, um anel de luz dourado enorme em volta, ilhotas flutuantes, portal de mármore e ouro com asas, e duas lagoas de luz. Estilo cartoon "candy" premium: cores vivas, brilhos nos lugares certos, muito detalhe pequeno.
**Capriche de verdade.** O jogo precisa rodar em celular e o mapa já tem cerca de 25 mil peças, então **mire em 5.000 a 8.000 BaseParts (teto 9.000)**: gaste peças onde o jogador vê de perto (topo, portal, lagoas, borda, árvore) e use poucas peças grandes no mar de nuvens e no fundo da rocha. Mantenha o `build()` abaixo de ~10 segundos (evite loops gigantes aninhados; use `task.wait()` entre blocos grandes se precisar).

# REGRA DE OURO: SÓ TERMINE QUANDO ESTIVER PRONTO DE VERDADE
Você **não pode parar, resumir, escrever "etc.", deixar `-- TODO`, "resto igual", placeholders ou funções vazias**. O código tem que estar **completo e funcionando**. Antes da resposta final, revise em ciclos:
1. **Rascunhe** a ilha por regiões.
2. **Compare cada região com a imagem de referência** e com o checklist abaixo.
3. **Corrija** erros de sintaxe e de tipo, APIs inexistentes, variáveis `nil`, escopo, posições erradas, z-fighting, falta de detalhe.
4. **Repita** até **todos** os itens do checklist passarem e a ilha, na sua avaliação honesta, estar "idêntica à referência e pronta para lançar". Só então responda.
Entregue o `TrainingIsland4Builder.luau` **como um artifact de código (um único arquivo, completo, para baixar)** e releia-o antes de terminar (balanceamento de `function`/`end`, escopo, tipos, nomes de enums). Se a geração parar no meio, quando eu escrever "continue" retome **exatamente de onde parou**, no mesmo arquivo, sem repetir nem resumir. **Nunca troque código por comentário** tipo "mesma lógica de antes".

# LIÇÕES DA ILHA ANTERIOR (evite estes erros)
- **Água escondida:** uma lagoa feita de disco fino de água abaixo do topo do chão não aparece. Se a grama/chão é um disco sólido, a água tem que ficar **acima** do topo do chão (ou o chão precisa ter um buraco de verdade). Confira a altura Y de cada peça de água contra o chão ao redor.
- **Disco achatado:** a ilha não pode ser um disco liso com borda. Faça a massa de rocha **cheia e esculpida**, com camadas de blocos arredondados e rachados, o **mesmo raio da borda** de cima (sem "prato" de borda sobrando), afinando para baixo.
- **Superfícies quase brancas enormes e feixes de luz gigantes estouram a imagem.** Use cores com tom e variação, e feixes finos e translúcidos.
- **Cilindros lisos como cristais ficam feios:** faça cristais como **prismas hexagonais pontudos** (várias peças inclinadas), em tufos, com cristais menores na base.
- **Interior de portal liso:** faça espiral/anéis luminosos com Neon e partículas leves, não um oval chapado.

# ITENS DA IMAGEM QUE NÃO PODEM FALTAR (confira um por um)
- **Cerca de corda** com **postes de mármore branco** baixos na borda da frente (a corda é dourada/bege, caída entre os postes), sem bloquear caminho nenhum.
- **Placas de madeira com desenho de peixe**, **lanternas laranja** penduradas em postes, **barris dourados**.
- **Dois canais de água de luz** cruzando a grama na frente, que viram as **duas cachoeiras** principais na borda.
- **Borda em camadas:** mármore creme com **dois frisos dourados** contornando a ilha inteira.
- **Portal** com pedestal em degraus, ombreiras com detalhes dourados e **asas com penas em leque**, bem maiores que o avatar.
- **Ponte de mármore arqueada** com guarda-corpo trabalhado, entre as duas lagoas.
- **Anel de luz duplo** (duas linhas finas concêntricas) envolvendo a ilha por baixo da borda.

# ANIMAÇÕES (o jogo já tem o código que anima: você só marca as peças)
Não crie scripts. Use `CollectionService` para pôr tags em Parts ou Models (Model precisa de `PrimaryPart` ou pivô correto no eixo do giro):
- `HubSpin`: atributos `Speed` (**graus por segundo**, use valores calmos entre 8 e 36; acima disso fica frenético), `Axis` ("X", "Y" ou "Z"), `Phase` (opcional). Use no redemoinho do portal, no anel de luz e nas constelações.
- `HubBob` (sobe e desce): `Amplitude` (studs), `Speed` (radianos/s, 1 a 2), `Phase`. Use em ilhotas, cristais e esferas flutuantes.
- `HubPulse`: `Min`, `Max`, `Speed` (radianos/s), `Target` ("Transparency", "Brightness", "Size" ou "Range").
- `HubFlicker` (`Intensity` 0 a 1) nas lanternas; `HubSway` (`Angle` em graus, `Speed` radianos/s) nos estandartes e na copa da árvore.
Marque com moderação (menos de 150 itens).

# FORMATO DE ENTREGA
- Primeira linha `--!strict`. `local Builder = {}` ... `return Builder`.
- `function Builder.build(origin: Vector3?): Model`: **idempotente** (se já existir o modelo, destrói e recria). Origem padrão `Vector3.new(0, 160, -680)`. **Todas as posições internas são relativas à origem.** Cria o Model `TrainingIsland_Celestial` dentro de uma Folder `Workspace.TrainingIslands` (crie a pasta se não existir). Ao final, `print` com a contagem de BaseParts. Não crie `Script`/`LocalScript` dentro do modelo.
- `function Builder.selfTest(origin: Vector3?): { string }`: devolve a lista de falhas (vazia = tudo certo). Verifica por código: que todo o contrato abaixo existe (nomes, tags, atributos, valores), que `ArrivalSpawn` está sobre chão sólido **(ignore a própria peça do spawn no raio)**, que os decks e a ponte têm colisão, que o caminho do `ArrivalSpawn` até cada deck e até o portal não está bloqueado, que a água está **acima** do chão onde deve aparecer, e que decoração não tem colisão.
- Opcional: `Builder.applyReferenceLighting()` e `Builder.restoreLighting()` com iluminação só para prints (guarde e restaure os valores). **Nunca altere o `Lighting` dentro de `build()`.**
- Funções auxiliares próprias no mesmo arquivo: `makeFolder`, `makeModel`, `makePart(parent, name, cf, size, color, material, canCollide, transparency)`, `makeWedge`, `makeCylinderY` (cilindro com o eixo circular no Y), `makeEllipsoid` (Part + SpecialMesh Sphere), `makeSegment(p1, p2, espessura...)`, `makeNeonRing`, `makeRope`, `makeCrystal` (prisma hexagonal translúcido com brilho), `makeSign` (placa com `SurfaceGui`/`TextLabel`, fonte `Enum.Font.FredokaOne`), `makeWing` (asa de mármore/ouro com penas), `makeCloud` (nuvem fofa de muitas esferas), `makeCrown` (monumento-coroa de cristal dourado), `makeCushion` (almofada), `makeConstellation` (esferas ligadas por linhas finas). Reaproveite-as.
- Código: `local Workspace = game:GetService("Workspace")` e `CollectionService` no topo, tipos, `task.wait` (nunca `wait`), `Random.new(SEED)` fixo (resultado sempre igual), tabela `PALETTE` no topo, comentários curtos em inglês, `CastShadow = false` em decoração pequena, `Parent` por último quando possível. Se não tiver certeza de uma API do Roblox, use a alternativa mais simples e segura.

# SISTEMA DE COORDENADAS
Posições locais relativas à origem. +Y para cima. A câmera da concept art olha de +Z (frente, perto) para -Z (fundo, longe):
- **FUNDO (-Z):** o **portal** de mármore e ouro com asas (fundo, centro) e a escadinha.
- **FRENTE (+Z):** a chegada e a lateral da rocha clara com cristais e cachoeiras de luz, visível para a câmera.
- **ESQUERDA (-X):** Lagoa do Foco (luz líquida). **DIREITA (+X):** Lagoa do Instinto (roxa-rosa-dourada).
- **CENTRO:** caminho de **ladrilhos dourados com runas** do portal até uma **ponte de mármore com corrimão**, e o monumento-coroa de cristal dourada perto do caminho.
Raio da ilha ≈ 46 studs, silhueta orgânica. A origem padrão está no céu (Y = 160): o mar de nuvens fica **abaixo** da ilha (em torno de Y = -30 a -60 local) e faz parte da sua construção (pode ser feito de peças de nuvem), pois ali não existe água.
O chão jogável da ilha fica em **Y = 0 local**. Um avatar tem ~5 studs de altura.

# O QUE CONSTRUIR (fiel à imagem de referência)
1. **Silhueta e base (o ponto mais importante).** Ilha **cheia e esculpida**: topo de grama verde com **borda de mármore branco e frisos dourados**, e **rocha clara** (creme/cinza-claro, **não branca estourada**) descendo no **mesmo raio da borda** em camadas de blocos arredondados e rachados, afinando para baixo, com **cristais dourados e ciano** brilhando encravados. **Cachoeiras de luz** brancas caindo para as nuvens (2 a 3, faixas finas de Neon com transparência), **2 ilhotas pequenas flutuando** com cristais, e um **anel de luz dourado enorme** orbitando a ilha (peça fina de Neon em anel; só construa, a rotação é feita depois). Embaixo, o **mar de nuvens** (muitas esferas achatadas creme/rosa/azul-claro, em camadas, com variação) cobrindo uma área ampla.
2. **Topo.** Grama verde com tufos, canteiros, pedrinhas; **caminho de ladrilhos dourados com runas** (lajes de mármore creme com traço de runa em ouro) do portal até a ponte de mármore.
3. **Portal (fundo, centro): arco de mármore branco-creme e ouro com asas** dos lados (penas escalonadas de mármore/ouro) e **cristal no topo**; dentro, **redemoinho arco-íris pastel** (anéis/espiral Neon em cores pastel girando + `ParticleEmitter` leve de brilhos dourados), escadinha de mármore, cristais e detalhes dourados nos pés. Sem estourar de branco: use tom creme, juntas douradas e sombras.
4. **Lagoa do Foco (esquerda):** água **branca-aqua de luz líquida** (acima do chão), **anéis de luz dourados empilhados**, **esferas douradas flutuantes ligadas por linhas finas** (constelação), **pilares de cristal e ouro** com **feixes de luz** finos e translúcidos até o céu, **deck de mármore** com banquinho e **almofadas**, barril dourado, lanterna.
5. **Lagoa do Instinto (direita):** água **roxa-rosa-dourada** com reflexos arco-íris (anéis concêntricos de cor), **peixes lendários** dourados e arco-íris (guarde `OrbitRadius`, `OrbitSpeed`, `OrbitPhase` como atributos), **deck de mármore** com banquinho, **árvore de flores rosa com tronco dourado e auréola de luz**, vaga-lumes dourados, lanternas, **pedras com runas douradas**.
6. **Centro e props:** **monumento-coroa de cristal dourada** perto do caminho, **estátua de peixe em mármore**, **estandartes brancos com frisos dourados**, **placas douradas com peixe**, lanternas. **Ar celestial:** penas e brilhos dourados (emissores leves, taxa baixa).

Detalhes que dão vida e variação: **nada de blocos retos e lisos**. Use rotação variada, elipsoides achatados, cunhas, pequenas variações de cor e tamanho (com o `Random` fixo). Brilho (Neon, `PointLight`, partículas) só onde faz sentido; o resto é fosco (`SmoothPlastic`, `Slate`, `Wood`, `WoodPlanks`, `Fabric`, `Marble`, etc.). Evite z-fighting (offset de 0,02 a 0,05 entre faces coplanares). Mantenha luzes e partículas leves (poucas `PointLight`, taxas baixas de `ParticleEmitter`).

# CONTRATO COM O SERVIDOR (obrigatório, nomes, tags e valores exatos)
Filhos **diretos** do Model `TrainingIsland_Celestial` (Parts ancoradas, `Transparency = 1`, `CanCollide = false`, `CastShadow = false`):
1. **`ArrivalSpawn`** (4 x 1 x 4): no chão, à frente do portal, virada para o centro da ilha. Tag `ZoneSpawn` (CollectionService) e atributo `Destination = "training_celestial"` (string).
2. **`ReturnPortal`** (~6 x 8 x 2,4): dentro do arco do portal, com `CanTouch = true` e `CanQuery = true`. Tag `ZonePortal` e atributos `PortalId = "training_celestial_to_main"`, `ZoneId = "lagoon"`, `Destination = "main"`.
3. **`FocusSpot`** (~5,5 x 2 x 5,5): sobre o deck da lagoa do Foco, junto ao banquinho. Tag `TrainingSpot`, atributos `TrainingIsland = 4` (**number**) e `TrainingStat = "Control"`.
4. **`InstinctSpot`** (~5,5 x 2 x 5,5): sobre o deck da lagoa do Instinto. Tag `TrainingSpot`, atributos `TrainingIsland = 4` (**number**) e `TrainingStat = "Instinct"`.
5. **`FocusPond`** e **`InstinctPond`**: dois Models (filhos diretos) que agrupam a água e os efeitos de cada lagoa.
6. **`CameraShot`** (1 x 1 x 1, invisível): em `origin + Vector3.new(0, 48, 100)` olhando para a origem, com atributo `FieldOfView = 55` (o ângulo da concept art).
7. **`IslandCenter`** (Part 2 x 2 x 2, invisível, na origem), definido como `PrimaryPart` do Model.
Colisão: piso, caminhos, ponte e decks com `CanCollide = true`; decoração (cristais, folhas, peixes, brilhos, etc.) com `CanCollide = false`. Nada pode bloquear o caminho a pé do `ArrivalSpawn` até os decks e até o portal; a ponte é caminhável (sem degrau maior que 3 studs). **Não crie `Script`, `LocalScript`, `ProximityPrompt` nem `Seat`.** O treino fica a até 16 studs do `FocusSpot`/`InstinctSpot`, então o deck deve ficar dentro dessa distância do banquinho.

# CHECKLIST FINAL (audite item por item antes de responder)
1. O código compila (sem erro de sintaxe, variável não declarada, `nil`, API inventada); você revisou cada função linha a linha.
2. `--!strict`, serviços no topo, sem `wait()`, sem scripts no modelo; `build()` idempotente com origem relativa; `selfTest()` implementado de verdade.
3. Todo o contrato existe com nomes, tags, atributos e tipos EXATOS (`TrainingIsland` é número).
4. Caminhos a pé contínuos e com colisão: spawn → portal, spawn → deck do Foco, spawn → deck do Instinto, e a ponte; sem degrau > 3 studs.
5. **A água das duas lagoas fica visível** (acima do chão) e a massa da ilha não é um disco achatado: a rocha é cheia e esculpida, com o mesmo raio da borda.
6. Todas as regiões da imagem existem: rocha clara com cristais dourados e ciano, borda de mármore e frisos dourados, cachoeiras de luz, ilhotas flutuantes, anel dourado, mar de nuvens, portal de mármore e ouro com asas e redemoinho arco-íris, caminho de ladrilhos dourados, ponte de mármore, lagoa do Foco (luz líquida, anéis dourados, constelação, pilares, deck com almofadas), lagoa do Instinto (roxa-rosa-dourada, peixes lendários, árvore rosa com auréola, runas douradas), monumento-coroa, estátua de peixe, estandartes, placas.
7. Cada região tem detalhes pequenos e variação de cor/tamanho/rotação; sem blocos lisos; cristais em prismas e tufos.
8. Sem z-fighting evidente, sem peças flutuando sem motivo; sem superfícies brancas enormes nem feixes gigantes.
9. O código está completo: nenhuma função vazia, nenhum TODO, nenhum "resto igual".
Se algum item falhar, corrija e reaudite. **Não responda enquanto não passar em todos.**

# RESPOSTA FINAL
O artifact com o código completo e depois um resumo de 7 linhas: (1) o que foi construído por região, (2) contagem aproximada de peças, luzes e emissores, (3) tempo estimado do `build()`, (4) como rodar (`local m = game.ServerStorage.DevTools.TrainingIsland4Builder:Clone(); require(m).build(); print(table.concat(require(m).selfTest(), "\n"))`), (5) o que ficou mais simples que a imagem, (6) riscos que você enxerga, (7) o resultado honesto do checklist (cada item OK ou com ressalva). Como você não consegue rodar o Roblox, diga claramente o que só dá para confirmar rodando no Studio.

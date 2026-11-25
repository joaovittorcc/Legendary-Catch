# Ilha de Treino 3 (Abismo Estelar): prompt para o chat do Gemini (navegador)

Prompt autocontido (nada de caminho de pasta dentro do texto que você cola: o Gemini não vê o seu computador).

**O que anexar no chat do Gemini (arquivos, não caminhos):**
1. A imagem de referência da ilha: `ilha-3-abismo-estelar.jpg` (pasta `art/concept/escolhidas`).
2. **Opcional, mas ajuda muito:** o arquivo `TrainingIsland1Builder.luau` (pasta `tools`), a Ilha 1, como exemplo do padrão de código e de acabamento. Se o Gemini reclamar do tamanho, mande sem ele: o prompt já descreve o padrão.

Depois cole o bloco abaixo (de "Você é um programador Luau sênior..." até o fim). Quando ele terminar, salve o código num `.lua` e mande para o Claude. Se a resposta for cortada, escreva: "continue exatamente de onde parou, sem repetir nada e sem resumir".

---

Você é um programador Luau sênior e artista técnico de Roblox, especialista em construir ilhas estilizadas bonitas por código. Anexei a **imagem de referência** da "Ilha de Treino 3: Abismo Estelar (treino x12, exige 100 milhões de Poder de Pesca)" do meu jogo "Legendary Catch" e, se foi possível, o código da **Ilha de Treino 1**, que você já ajudou a fazer, como exemplo do padrão que eu quero.

# MISSÃO
Escreva **um único arquivo Luau, `TrainingIsland3Builder.luau`**, que constrói por código a ilha da imagem de referência, o mais **idêntica** possível. É uma ilha mística **de noite**, mas colorida, nunca sombria: rocha azul-escura e violeta, grama azul-escura, cachoeiras de luz, cristais azuis brilhando, fragmentos de rocha flutuando, observatório com telescópio dourado, lagoa-espelho com estrelas e lagoa roxa com galáxia. A ilha deve **parecer noite com materiais escuros e brilhos**, sem mudar o `Lighting` global. Estilo cartoon "candy" premium: cores vivas, brilhos nos lugares certos, muito detalhe pequeno.
**Capriche de verdade. Não há limite de peças por enquanto** (a otimização vem depois): use quantas precisar. Só mantenha o `build()` abaixo de ~10 segundos (evite loops gigantes aninhados; use `task.wait()` entre blocos grandes se precisar).

# REGRA DE OURO: SÓ TERMINE QUANDO ESTIVER PRONTO DE VERDADE
Você **não pode parar, resumir, escrever "etc.", deixar `-- TODO`, "resto igual", placeholders ou funções vazias**. O código tem que estar **completo e funcionando**. Antes da resposta final, trabalhe em ciclos internos:
1. **Rascunhe** a ilha por regiões.
2. **Compare cada região com a imagem de referência** e com o checklist abaixo.
3. **Corrija** erros de sintaxe e de tipo, APIs inexistentes, variáveis `nil`, escopo, posições erradas, z-fighting, falta de detalhe.
4. **Repita** até **todos** os itens do checklist passarem e a ilha, na sua avaliação honesta, estar "idêntica à referência e pronta para lançar". Só então responda.
Se não couber numa mensagem, entregue em partes numeradas ("PARTE 1/N", ...), cada uma terminando numa linha completa, e **continue sozinho** até acabar. Escreva "FIM" só na última, depois do resumo. Se você tiver ferramenta de arquivos (download), entregue o `TrainingIsland3Builder.luau` **como arquivo completo** e releia-o antes (balanceamento de `function`/`end`, escopo, tipos, nomes de enums). **Nunca troque código por comentário** tipo "mesma lógica de antes".

# LIÇÕES DA ILHA ANTERIOR (evite estes erros)
- **Água escondida:** uma lagoa feita de disco fino de água abaixo do topo do chão não aparece. Se a grama/chão é um disco sólido, a água tem que ficar **acima** do topo do chão (ou o chão precisa ter um buraco de verdade). Confira a altura Y de cada peça de água contra o chão ao redor.
- **Disco achatado:** a ilha não pode ser um disco liso com borda. Faça a massa de rocha **cheia e esculpida**, com camadas de blocos arredondados e rachados, o **mesmo raio da borda** de cima (sem "prato" de borda sobrando), afinando para baixo.
- **Superfícies quase brancas enormes e feixes de luz gigantes estouram a imagem.** Use cores com tom e variação, e feixes finos e translúcidos.
- **Cilindros lisos como cristais ficam feios:** faça cristais como **prismas hexagonais pontudos** (várias peças inclinadas), em tufos, com cristais menores na base.
- **Interior de portal liso:** faça espiral/anéis luminosos com Neon e partículas leves, não um oval chapado.

# FORMATO DE ENTREGA
- Primeira linha `--!strict`. `local Builder = {}` ... `return Builder`.
- `function Builder.build(origin: Vector3?): Model`: **idempotente** (se já existir o modelo, destrói e recria). Origem padrão `Vector3.new(-520, 12, 420)`. **Todas as posições internas são relativas à origem.** Cria o Model `TrainingIsland_Abyss` dentro de uma Folder `Workspace.TrainingIslands` (crie a pasta se não existir). Ao final, `print` com a contagem de BaseParts. Não crie `Script`/`LocalScript` dentro do modelo.
- `function Builder.selfTest(origin: Vector3?): { string }`: devolve a lista de falhas (vazia = tudo certo). Verifica por código: que todo o contrato abaixo existe (nomes, tags, atributos, valores), que `ArrivalSpawn` está sobre chão sólido **(ignore a própria peça do spawn no raio)**, que os decks e a ponte têm colisão, que o caminho do `ArrivalSpawn` até cada deck e até o portal não está bloqueado, que a água está **acima** do chão onde deve aparecer, e que decoração não tem colisão.
- Opcional: `Builder.applyReferenceLighting()` e `Builder.restoreLighting()` com iluminação só para prints (guarde e restaure os valores). **Nunca altere o `Lighting` dentro de `build()`.**
- Funções auxiliares próprias no mesmo arquivo: `makeFolder`, `makeModel`, `makePart(parent, name, cf, size, color, material, canCollide, transparency)`, `makeWedge`, `makeCylinderY` (cilindro com o eixo circular no Y), `makeEllipsoid` (Part + SpecialMesh Sphere), `makeSegment(p1, p2, espessura...)`, `makeNeonRing`, `makeRope`, `makeCrystal` (prisma hexagonal translúcido com brilho), `makeSign` (placa com `SurfaceGui`/`TextLabel`, fonte `Enum.Font.FredokaOne`), `makeFloatingRock` (fragmento de rocha com cristais), `makeConstellation` (esferas Neon ligadas por linhas finas), `makeTelescope`. Reaproveite-as.
- Código: `local Workspace = game:GetService("Workspace")` e `CollectionService` no topo, tipos, `task.wait` (nunca `wait`), `Random.new(SEED)` fixo (resultado sempre igual), tabela `PALETTE` no topo, comentários curtos em inglês, `CastShadow = false` em decoração pequena, `Parent` por último quando possível. Se não tiver certeza de uma API do Roblox, use a alternativa mais simples e segura.

# SISTEMA DE COORDENADAS
Posições locais relativas à origem. +Y para cima. A câmera da concept art olha de +Z (frente, perto) para -Z (fundo, longe):
- **FUNDO (-Z):** o **portal** (fundo, mais à direita), a **plataforma do observatório** com o telescópio dourado (fundo, centro) e a rocha alta.
- **FRENTE (+Z):** a areia/pedra de chegada e a lateral da rocha com cristais e cachoeiras de luz, visível para a câmera.
- **ESQUERDA (-X):** Lagoa do Foco (espelho de estrelas). **DIREITA (+X):** Lagoa do Instinto (galáxia roxa).
- **CENTRO:** caminho de pedras escuras com runas azuis até uma ponte de madeira escura com corda entre as duas lagoas.
Raio da ilha ≈ 46 studs, silhueta orgânica (seno/cosseno), não um círculo perfeito.
O chão jogável da ilha fica em **Y = 0 local**. Um avatar tem ~5 studs de altura.

# O QUE CONSTRUIR (fiel à imagem de referência)
1. **Silhueta e base (o ponto mais importante).** Ilha **cheia e esculpida**: topo de grama azul-escura, borda de pedra, e **rocha alta azul-escura/violeta** descendo no **mesmo raio da borda**, em camadas de blocos arredondados e rachados, afinando para baixo. **Cachoeiras de luz** azul-ciano caindo pelas bordas (2 a 3, faixas finas de Neon com transparência, espuma de luz na base), **muitos cristais azuis** brilhando nas paredes e na borda (prismas em tufos, `PointLight` fraca nos maiores) e **fragmentos de rocha flutuando** em volta, cada um com cristais. Não crie oceano: já existe.
2. **Topo.** Grama azul-escura com tufos, pedras escuras, **caminho de pedras escuras com runas azuis brilhando** do portal até a ponte (traço fino de Neon sobre pedra escura, nada de blocos chapados brilhantes).
3. **Portal (fundo, direita): arco de pedra escura com runas azuis** em blocos empilhados com juntas, **cristal grande no topo**, e dentro um **vórtice estrelado** azul-violeta (anéis/espiral Neon girando + `ParticleEmitter` leve de estrelinhas), escadinha de pedra, cristais nos pés. A pedra não pode ficar tingida de azul pela luz: `PointLight` fraca.
4. **Plataforma do observatório (fundo, centro):** círculo de pedra com degraus e um **telescópio dourado** apontando para o céu (tubo de vários cilindros, suporte em tripé, detalhes dourados).
5. **Lagoa do Foco (esquerda):** água escura tipo **espelho com estrelas** (peças de água acima do chão, com pontinhos de Neon), **2 anéis concêntricos grandes** de luz azul, **linhas de constelação** (peças Neon finas) ligando **esferas-alvo flutuantes**, **4 pilares de cristal** em volta com **feixes de luz** subindo alto (finos e translúcidos). **Deck de madeira escura** com banquinho redondo de 3 pernas e barril, cristais pequenos no deck.
6. **Lagoa do Instinto (direita):** água **roxa com galáxia em espiral** (anéis concêntricos Neon de cor/transparência formando uma espiral), **peixes cósmicos** brilhando (dourado, arco-íris, nebulosa; guarde `OrbitRadius`, `OrbitSpeed`, `OrbitPhase` como atributos para animar depois), **árvore de cristal violeta-rosa** com pétalas brilhando caindo (`ParticleEmitter` leve), **vaga-lumes dourados** (partículas), lanternas pequenas, **monólitos com runas** brilhantes, **deck de madeira escura** com banquinho.
7. **Props:** placas ornamentadas com peixe entalhado, postes com cristal na ponta, bandeirolas escuras com friso dourado, cordas, caixotes, lanternas âmbar. A lua grande no céu é opcional e só se ficar leve (por exemplo um `BillboardGui` ou uma esfera Neon suave).

Detalhes que dão vida e variação: **nada de blocos retos e lisos**. Use rotação variada, elipsoides achatados, cunhas, pequenas variações de cor e tamanho (com o `Random` fixo). Brilho (Neon, `PointLight`, partículas) só onde faz sentido; o resto é fosco (`SmoothPlastic`, `Slate`, `Wood`, `WoodPlanks`, `Fabric`, `Marble`, etc.). Evite z-fighting (offset de 0,02 a 0,05 entre faces coplanares). Mantenha luzes e partículas leves (poucas `PointLight`, taxas baixas de `ParticleEmitter`).

# CONTRATO COM O SERVIDOR (obrigatório, nomes, tags e valores exatos)
Filhos **diretos** do Model `TrainingIsland_Abyss` (Parts ancoradas, `Transparency = 1`, `CanCollide = false`, `CastShadow = false`):
1. **`ArrivalSpawn`** (4 x 1 x 4): no chão, à frente do portal, virada para o centro da ilha. Tag `ZoneSpawn` (CollectionService) e atributo `Destination = "training_abyss"` (string).
2. **`ReturnPortal`** (~6 x 8 x 2,4): dentro do arco do portal, com `CanTouch = true` e `CanQuery = true`. Tag `ZonePortal` e atributos `PortalId = "training_abyss_to_main"`, `ZoneId = "lagoon"`, `Destination = "main"`.
3. **`FocusSpot`** (~5,5 x 2 x 5,5): sobre o deck da lagoa do Foco, junto ao banquinho. Tag `TrainingSpot`, atributos `TrainingIsland = 3` (**number**) e `TrainingStat = "Control"`.
4. **`InstinctSpot`** (~5,5 x 2 x 5,5): sobre o deck da lagoa do Instinto. Tag `TrainingSpot`, atributos `TrainingIsland = 3` (**number**) e `TrainingStat = "Instinct"`.
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
6. Todas as regiões da imagem existem: rocha alta com cachoeiras de luz e cristais, fragmentos flutuantes, portal com vórtice estrelado, observatório com telescópio dourado, caminho de runas azuis, ponte de madeira escura, lagoa do Foco (espelho de estrelas, 2 anéis, constelação, 4 pilares de cristal, deck), lagoa do Instinto (galáxia, peixes cósmicos, árvore de cristal, vaga-lumes, monólitos, deck), placas e lanternas.
7. Cada região tem detalhes pequenos e variação de cor/tamanho/rotação; sem blocos lisos; cristais em prismas e tufos.
8. Sem z-fighting evidente, sem peças flutuando sem motivo; sem superfícies brancas enormes nem feixes gigantes.
9. O código está completo: nenhuma função vazia, nenhum TODO, nenhum "resto igual".
Se algum item falhar, corrija e reaudite. **Não responda enquanto não passar em todos.**

# RESPOSTA FINAL
O código completo (arquivo para baixar, ou em partes numeradas), e depois um resumo de 7 linhas: (1) o que foi construído por região, (2) contagem aproximada de peças, luzes e emissores, (3) tempo estimado do `build()`, (4) como rodar (`local m = game.ServerStorage.DevTools.TrainingIsland3Builder:Clone(); require(m).build(); print(table.concat(require(m).selfTest(), "\n"))`), (5) o que ficou mais simples que a imagem, (6) riscos que você enxerga, (7) o resultado honesto do checklist (cada item OK ou com ressalva).

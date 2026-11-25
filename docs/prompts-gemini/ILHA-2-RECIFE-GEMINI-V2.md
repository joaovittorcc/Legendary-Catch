# Ilha de Treino 2 (Recife): prompt para o chat do Gemini (navegador)

Versão 2, autocontida (nada de caminho de pasta: o Gemini não vê o seu computador). Substitui `ILHA-2-RECIFE-GEMINI-CHAT.md`.

**O que anexar no chat do Gemini (arquivos, não caminhos):**
1. A imagem de referência da ilha: `ilha-2-recife.jpg` (pasta `art/concept/escolhidas`).
2. O print da ilha atual provisória (só para ele ver o que está fraco): `13-treino-2-recife.jpg` (pasta `art/preview/hub-tour`).
3. **Opcional, mas ajuda muito:** o arquivo `TrainingIsland1Builder.luau` (pasta `tools`), a Ilha 1 que ele já ajudou a fazer, como exemplo do padrão de código e de acabamento. Se o Gemini reclamar do tamanho, mande sem ele: o prompt já descreve o padrão.

Depois, cole o bloco abaixo (de "Você é um programador Luau sênior..." até o fim). Quando ele terminar, salve o código num `.lua` e mande para o Claude. Se a resposta for cortada, escreva: "continue exatamente de onde parou, sem repetir nada e sem resumir".

---

Você é um programador Luau sênior e artista técnico de Roblox, especialista em construir ilhas estilizadas bonitas por código. Anexei: (1) a **imagem de referência** da "Ilha de Treino 2: Recife" do meu jogo "Legendary Catch", (2) um **print da versão provisória atual** (que está fraca e vai ser substituída) e, se foi possível, (3) o código da **Ilha de Treino 1**, que você já ajudou a fazer, como exemplo do padrão que eu quero.

# MISSÃO
Escreva **um único arquivo Luau, `TrainingIsland2Builder.luau`**, que constrói por código a ilha da imagem de referência, o mais **idêntica** possível: tropical, redonda, num mar turquesa raso, com duas lagoas de treino, portal de pedra com corais ao fundo, ponte de tábuas no centro, palmeiras, cabana de palha, rede de dormir, cristais aqua, e a lateral de rocha escura coberta de corais coloridos. Estilo cartoon "candy" premium: cores vivas, brilhos nos lugares certos, muito detalhe pequeno.
**Capriche de verdade. Não há limite de peças por enquanto** (a otimização vem depois): use quantas precisar. Só mantenha o `build()` abaixo de ~10 segundos (evite loops gigantes aninhados; use `task.wait()` entre blocos grandes se precisar).

# REGRA DE OURO: SÓ TERMINE QUANDO ESTIVER PRONTO DE VERDADE
Você **não pode parar, resumir, escrever "etc.", deixar `-- TODO`, "resto igual", placeholders ou funções vazias**. O código tem que estar **completo e funcionando**. Antes da resposta final, trabalhe em ciclos internos:
1. **Rascunhe** a ilha por regiões.
2. **Compare cada região com a imagem de referência** e com o checklist abaixo.
3. **Corrija** erros de sintaxe e de tipo, APIs inexistentes, variáveis `nil`, escopo, posições erradas, z-fighting, falta de detalhe.
4. **Repita** até **todos** os itens do checklist passarem e a ilha, na sua avaliação honesta, estar "idêntica à referência e pronta para lançar". Só então responda.
Se não couber numa mensagem, entregue em partes numeradas ("PARTE 1/N", ...), cada uma terminando numa linha completa, e **continue sozinho** até acabar. Escreva "FIM" só na última, depois do resumo. Se você tiver ferramenta de arquivos (download), entregue o `TrainingIsland2Builder.luau` **como arquivo completo** e releia-o antes (balanceamento de `function`/`end`, escopo, tipos, nomes de enums). **Nunca troque código por comentário** tipo "mesma lógica de antes".

# FORMATO DE ENTREGA
- Primeira linha `--!strict`. `local Builder = {}` ... `return Builder`.
- `function Builder.build(origin: Vector3?): Model`: **idempotente** (se já existir o modelo, destrói e recria). Origem padrão `Vector3.new(480, 12, 420)`. **Todas as posições internas são relativas à origem.** Cria o Model `TrainingIsland_Reef` dentro de uma Folder `Workspace.TrainingIslands` (crie a pasta se não existir). Ao final, `print` com a contagem de BaseParts. Não crie `Script`/`LocalScript` dentro do modelo.
- `function Builder.selfTest(origin: Vector3?): { string }`: devolve a lista de falhas (vazia = tudo certo). Verifica por código: que todo o contrato abaixo existe (nomes, tags, atributos, valores), que `ArrivalSpawn` está sobre chão sólido, que os decks e a ponte têm colisão, que o caminho do `ArrivalSpawn` até cada deck e até o portal não está bloqueado (use `Workspace:Raycast`/`GetPartBoundsInBox` simples) e que decoração não tem colisão.
- Opcional: `Builder.applyReferenceLighting()` e `Builder.restoreLighting()` com iluminação ensolarada só para prints (guarde e restaure os valores). **Nunca altere o `Lighting` dentro de `build()`.**
- Funções auxiliares próprias no mesmo arquivo: `makeFolder`, `makeModel`, `makePart(parent, name, cf, size, color, material, canCollide, transparency)`, `makeWedge`, `makeCylinderY` (cilindro com o eixo circular no Y), `makeEllipsoid` (Part + SpecialMesh Sphere), `makeSegment(p1, p2, espessura...)`, `makeNeonRing`, `makeRope`, `makeCoral` (galhos ramificados), `makeFanCoral`, `makeAnemone`, `makePalm`, `makeCrystal` (prisma hexagonal translúcido com brilho), `makeShell`, `makeSign` (placa com `SurfaceGui`/`TextLabel`, fonte `Enum.Font.FredokaOne`). Reaproveite-as.
- Código: `local Workspace = game:GetService("Workspace")` e `CollectionService` no topo, tipos, `task.wait` (nunca `wait`), `Random.new(SEED)` fixo (resultado sempre igual), tabela `PALETTE` no topo, comentários curtos em inglês, `CastShadow = false` em decoração pequena, `Parent` por último quando possível. Se não tiver certeza de uma API do Roblox, use a alternativa mais simples e segura.

# SISTEMA DE COORDENADAS
Posições locais relativas à origem. +Y para cima. A câmera da concept art olha de +Z (frente, perto) para -Z (fundo, longe):
- **FUNDO (-Z):** portal de pedra com corais, cabana de palha, árvore de coral rosa, palmeiras.
- **FRENTE (+Z):** areia larga e a lateral da rocha coberta de corais, visível para a câmera.
- **ESQUERDA (-X):** Lagoa do Foco (azul cristalina). **DIREITA (+X):** Lagoa do Instinto (roxa).
- **CENTRO:** caminho de areia e conchas do portal até a ponte de tábuas com corda entre as duas lagoas.
O chão jogável da ilha fica em **Y = 0 local**. Raio ≈ 46 studs, silhueta orgânica (seno/cosseno), não um círculo perfeito. Um avatar tem ~5 studs de altura.

# O QUE CONSTRUIR (fiel à imagem de referência)
1. **Silhueta e base (o ponto mais importante).** A ilha é **uma massa contínua**: grama em cima, **borda grossa de areia clara** em volta (mais larga na frente), e a **rocha escura descendo logo abaixo, no mesmo raio da borda** (sem prato de areia sobrando para fora e sem degrau), afinando em 3 a 4 camadas de blocos arredondados e rachados até uma ponta irregular. Rocha cinza-azulada escura com musgo nos vãos. A lateral visível (frente) é **coberta de corais**: galhos rosa, laranja, roxo e amarelo (cilindros finos ramificados, cada galho inclinado), corais-leque grandes (discos arredondados com nervuras: várias fatias finas), anêmonas (cones baixos com tentáculos de bolinhas coloridas) e **cristais aqua** brilhando (Neon, `PointLight` fraca nos maiores). Muitos. Não crie oceano: já existe.
2. **Topo.** Grama verde viva com tufos (peças finas cruzadas), pedrinhas, manchas de areia, margens de areia em volta das lagoas. **Caminho central** do portal até a ponte, feito de pedrinhas e conchas na areia (elipses achatadas cinza, rosa-claro e creme).
3. **Portal (fundo, centro): arco de pedra cinza** de blocos empilhados (pilares de 4 a 5 blocos levemente desalinhados, juntas escuras, rachaduras), **coberto de corais e conchas** e com cristais aqua encravados; pedra central no topo com cristal aqua; **interior branco-aqua brilhante** (peça Neon, anéis/espiral luminosos e `ParticleEmitter` leve); **escadinha de 3 degraus** de pedra na frente; cristais e corais nos pés. A pedra **não** pode ficar tingida de ciano: `PointLight` fraca.
4. **Lagoa do Foco (esquerda): água cristalina.** Água rasa azul-clara bem transparente (peça achatada `Glass` ou `SmoothPlastic`, Transparency ~0,35) sobre fundo de **areia branca**. Ilhotas de anêmona/coral dentro da água (3 pequenas ilhas de musgo com corais), anéis de coral e pedra na água, **3 anéis de luz grandes empilhados** (anéis Neon ciano, o maior embaixo), **conchas flutuando** como alvos (3 a 4 conchas rosa e creme), **3 cristais aqua altos** atrás (prismas hexagonais translúcidos, o do meio maior) com **feixe de luz vertical difuso** (peça fina e alta, Transparency alta, Neon). **Deck de madeira comprido** na borda de cima com **2 banquinhos redondos de 3 pernas** e um barril, estacas com corda enrolada. **Rede de dormir** pendurada entre 2 palmeiras na borda esquerda.
5. **Lagoa do Instinto (direita): água roxa bioluminescente.** Água roxa/violeta profunda com **gradiente para turquesa no centro** (anéis concêntricos de cor/transparência), brilho roxo nas bordas, estrelinhas flutuando (partículas leves). **3 águas-vivas** brilhando (cúpula arredondada translúcida com tentáculos finos; duas rosa e uma ciano) e **2 peixes coloridos** (laranja e azul) nadando; guarde `OrbitRadius`, `OrbitSpeed`, `OrbitPhase` como atributos (a animação é feita depois, por fora). **2 decks de madeira com banquinho**, **3 pedras com runas ciano** brilhando (glifos Neon ou `SurfaceGui`), **concha gigante aberta com pérola brilhando** na borda direita (duas metades rosa/lilás com nervuras e esfera Neon), **árvore de coral rosa** atrás (tronco torcido, galhos grossos, copa de coral, pétalas caindo com `ParticleEmitter` leve), **varal de luzinhas e lanternas âmbar** em postes com braço curvo, suporte de madeira com **boias coloridas** penduradas (vermelha, azul, amarela, branca) e **pilha de 4 a 5 caixotes**.
6. **Vegetação e props.** **6 a 7 palmeiras** (tronco curvo de 5 a 6 cilindros inclinados afinando, copa com 7 a 9 folhas longas e arqueadas, 3 tons de verde, cocos pequenos), principalmente no fundo e nos lados. **Cabana de palha** no fundo-esquerdo (4 postes, plataforma elevada, telhado de palha inclinado amarelo-palha, escadinha). 2 a 3 **placas de madeira** com peixe entalhado em creme. Conchas e estrelas-do-mar na areia, pedrinhas, tufos, flores pequenas, cordas caídas, redes de pesca.
7. Detalhes que dão vida e variação: **nada de blocos retos e lisos**. Use rotação variada, elipsoides achatados, cunhas, pequenas variações de cor e tamanho (com o `Random` fixo). Brilho (Neon, `PointLight`, partículas) só onde faz sentido: anéis, cristais, pérola, runas, interior do portal, águas-vivas, luzinhas, pétalas. O resto é fosco (`SmoothPlastic`, `Sand`, `Grass`, `Wood`, `WoodPlanks`, `Slate`, `Limestone`, `Fabric`). Evite z-fighting (offset de 0,02 a 0,05 entre faces coplanares). Mantenha luzes e partículas leves (poucas `PointLight`, taxas baixas de `ParticleEmitter`): a otimização vem depois, mas não exagere.

# CONTRATO COM O SERVIDOR (obrigatório, nomes, tags e valores exatos)
Filhos **diretos** do Model `TrainingIsland_Reef` (Parts ancoradas, `Transparency = 1`, `CanCollide = false`, `CastShadow = false`):
1. **`ArrivalSpawn`** (4 x 1 x 4): na areia, à frente do portal, no chão, virada para o centro da ilha. Tag `ZoneSpawn` (CollectionService) e atributo `Destination = "training_reef"` (string).
2. **`ReturnPortal`** (~6 x 8 x 2,4): dentro do arco do portal, com `CanTouch = true` e `CanQuery = true`. Tag `ZonePortal` e atributos `PortalId = "training_reef_to_main"`, `ZoneId = "lagoon"`, `Destination = "main"`.
3. **`FocusSpot`** (~5,5 x 2 x 5,5): sobre o deck da lagoa do Foco, junto ao banquinho. Tag `TrainingSpot`, atributos `TrainingIsland = 2` (**number**) e `TrainingStat = "Control"`.
4. **`InstinctSpot`** (~5,5 x 2 x 5,5): sobre um deck da lagoa do Instinto. Tag `TrainingSpot`, atributos `TrainingIsland = 2` (**number**) e `TrainingStat = "Instinct"`.
5. **`FocusPond`** e **`InstinctPond`**: dois Models (filhos diretos) que agrupam a água e os efeitos de cada lagoa.
6. **`CameraShot`** (1 x 1 x 1, invisível): em `origin + Vector3.new(0, 48, 100)` olhando para a origem, com atributo `FieldOfView = 55` (o ângulo da concept art).
7. **`IslandCenter`** (Part 2 x 2 x 2, invisível, na origem), definido como `PrimaryPart` do Model.
Colisão: piso, caminhos, ponte e decks com `CanCollide = true`; decoração (corais, palmeiras, conchas, cristais, folhas, água-viva etc.) com `CanCollide = false`. Nada pode bloquear o caminho a pé do `ArrivalSpawn` até os decks e até o portal; a ponte central é caminhável (sem degrau maior que 3 studs). **Não crie `Script`, `LocalScript`, `ProximityPrompt` nem `Seat`.** O treino fica a até 16 studs do `FocusSpot`/`InstinctSpot`, então o deck deve ficar dentro dessa distância do banquinho.

# CHECKLIST FINAL (audite item por item antes de responder)
1. O código compila (sem erro de sintaxe, variável não declarada, `nil`, API inventada); você revisou cada função linha a linha.
2. `--!strict`, serviços no topo, sem `wait()`, sem scripts no modelo; `build()` idempotente com origem relativa; `selfTest()` implementado de verdade.
3. Todo o contrato existe com nomes, tags, atributos e tipos EXATOS (`TrainingIsland` é número).
4. Caminhos a pé contínuos e com colisão: spawn → portal, spawn → deck do Foco, spawn → decks do Instinto, e a ponte central; sem degrau > 3 studs.
5. A rocha e a borda de areia têm o mesmo raio (silhueta contínua, sem prato nem degrau).
6. Todas as regiões da imagem existem: rocha com corais e cristais, areia, portal de pedra com corais, escadinha, caminho de conchas, ponte de corda, lagoa do Foco (anéis, conchas, cristais, deck de 2 banquinhos, rede de dormir, cabana), lagoa do Instinto (águas-vivas, peixes, 2 decks, runas, concha com pérola, árvore de coral, varal, boias, caixotes), palmeiras, placas.
7. Cada região tem detalhes pequenos e variação de cor/tamanho/rotação; sem blocos lisos.
8. Sem z-fighting evidente, sem peças flutuando sem motivo.
9. O código está completo: nenhuma função vazia, nenhum TODO, nenhum "resto igual".
Se algum item falhar, corrija e reaudite. **Não responda enquanto não passar em todos.**

# RESPOSTA FINAL
O código completo (arquivo para baixar, ou em partes numeradas), e depois um resumo de 7 linhas: (1) o que foi construído por região, (2) contagem aproximada de peças, luzes e emissores, (3) tempo estimado do `build()`, (4) como rodar (`local m = game.ServerStorage.DevTools.TrainingIsland2Builder:Clone(); require(m).build(); print(table.concat(require(m).selfTest(), "\n"))`), (5) o que ficou mais simples que a imagem, (6) riscos que você enxerga, (7) o resultado honesto do checklist (cada item OK ou com ressalva).

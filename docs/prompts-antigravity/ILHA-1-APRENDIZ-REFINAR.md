# Ilha 1 (Aprendiz): refinar para ficar IDÊNTICA à concept art

Cole este prompt no Antigravity (ou Gemini). Ele já tem o contexto todo.

---

Você vai **refinar uma ilha que já existe** no projeto Legendary Catch (Roblox). Não recomece do zero: edite o builder existente e deixe a ilha o mais parecida possível com as duas imagens de referência.

## Arquivos

- **Builder (edite este):** `tools/TrainingIsland1Builder.luau`. É uma função `build(origin?)` idempotente: apaga e recria `Workspace.TrainingIslands.TrainingIsland_Apprentice`. Centro padrão `(520, 12, -380)`. Rode no Studio (Edit) com `require(game.ServerStorage.DevTools.TrainingIsland1Builder).build()` (o Rojo sincroniza `tools/` em `ServerStorage.DevTools`; se pedir, clone o ModuleScript antes do `require` para não pegar cache).
- **Referência A:** `art/concept/escolhidas/ilha-1-aprendiz.jpg` (ilha vista de frente e de cima, portal na frente-esquerda, píer diagonal no meio).
- **Referência B:** `art/concept/escolhidas/ilha-1-aprendiz-v2.jpg` (mesma ilha, ângulo mais alto; **use esta como guia de acabamento**: água, peixes, grama, árvore, cordas, pedras de runa, vaga-lumes).
- **Prints de como está hoje (Studio):** `art/preview/ilha-1/atual-1-frente.jpg`, `atual-2-portal.jpg`, `atual-3-lagoa-instinto.jpg`, `atual-4-lagoa-foco.jpg`. Compare cada print com as referências e corrija a diferença.
- Leia antes: `AGENTS.md`, `docs/COORDENACAO.md`, `docs/prompts-antigravity/ILHA-CONSTRUIR-1-APRENDIZ.md` (contrato com o servidor).

## O que NÃO pode mudar (contrato com o servidor)

Filhos diretos de `TrainingIsland_Apprentice` e seus nomes/tags/atributos ficam **exatamente** como estão em `buildGameplayZones`:
`ArrivalSpawn` (tag `ZoneSpawn`, `Destination="training_1"`), `ReturnPortal` (tag `ZonePortal`, `PortalId="training_1_return"`, `ZoneId="lagoon"`, `Destination="main"`), `FocusSpot` (tag `TrainingSpot`, `TrainingIsland=1`, `TrainingStat="Control"`), `InstinctSpot` (`TrainingStat="Instinct"`), models `FocusPond` e `InstinctPond`, `CameraShot`.
Mantenha o piso jogável em Y ≈ 12, decks e píer com colisão, decoração sem colisão, nada de `Script` dentro do modelo, `--!strict`, sem `wait()`.
Não mexa em `src/**`, no hub, nem nas outras ilhas.

## Limite de peças: IGNORAR por enquanto

Pode adicionar quantas peças, luzes e partículas precisar para ficar fiel. Depois fazemos uma passada de desempenho. Só evite lag absurdo no Studio (mantenha loops razoáveis).

## Diferenças que vi (do mais para o menos importante)

### 1. Lateral de rocha e cachoeiras (maior diferença)
- Hoje: bloco de rocha liso, cinza-arroxeado, sem textura, e as "cachoeiras" são colunas brancas retas.
- Referência: rocha **marrom quente** em blocos arredondados e grossos (pedras empilhadas, com rachaduras e relevo), contorno irregular, sombra mais escura embaixo. **Cristais ciano** encravados na rocha, em tamanhos variados, **brilhando** (Neon + `PointLight` fraca nos maiores). **Raízes finas e escuras** saindo por baixo e pelas bordas. **Duas cachoeiras finas** caindo da borda da frente (uma no centro-esquerdo, outra no centro-direito), **água azul-clara translúcida com espuma na base e névoa**, não coluna branca opaca.
- Faça a borda da grama/areia ter um **lábio de terra marrom** visível entre a grama e a rocha, como na referência B.
- Use pedras de forma orgânica (mistura de `Part` esfera/cilindro achatado e `WedgePart`, cada uma ligeiramente girada), cores variando entre `(132,102,84)`, `(116,88,74)` e `(98,74,64)`. Evite arestas retas e planos grandes iguais.

### 2. Topo: grama e areia
- Hoje: grama lisa verde-limão forte, borda de "bolinhas" arredondadas em volta das lagoas, areia branca-amarelada lavada.
- Referência: grama **verde-oliva/dourada** (mais quente: `(124,160,60)` a `(150,170,70)`), com **tufos** e tons mais claros e mais escuros em manchas, areia **dourada quente** `(232,196,120)` com **caminho de areia** que sai do portal. Trocar o aspecto de "recorte em escadinha" por bordas suaves e curvas.
- Adicione tufos de grama (pequenas peças finas cruzadas), algumas florzinhas e pedrinhas.
- As lagoas devem ter **margem de terra/areia fina** e pedrinhas na borda, não a faixa de bolinhas verdes.

### 3. Lagoa do Foco (esquerda, fundo)
- Hoje: água ciano chapada, anéis brancos finos, 3 cones.
- Referência: água **azul-clara translúcida** com **padrão de células/hexágonos** no fundo, **ondulações** claras e **3 anéis de luz empilhados** brilhantes (leve bloom), com um **feixe de luz** vertical difuso subindo ao lado dos cristais. Os 2 **cristais azuis altos** têm formato de prisma hexagonal pontudo, azul-gelo translúcido, com cristais menores na base; o feixe sai do alto do cristal esquerdo.
- **Deck:** madeira com tábuas envelhecidas, banquinho redondo de 3 pernas, **estacas com corda enrolada** nas pontas.
- **Boias:** cones laranja com listras brancas, ondinha em volta.
- **Cerca de postes e corda** atrás da lagoa, com nós de corda nos postes.

### 4. Lagoa do Instinto (direita)
- Hoje: água **azul-escura lisa**, praticamente sem efeito. Falta o principal.
- Referência: água **roxa/violeta profunda** com **gradiente para turquesa/verde no centro**, **brilho roxo na borda**, **partículas/estrelinhas** flutuando, **arco-íris leve** na superfície (use `Beam`/faixas finas coloridas ou texturas), **silhuetas de 3 peixes** nadando (uma grande tipo baleia/tubarão escura, duas menores, uma delas com brilho arco-íris; use meshes simples ou conjuntos de partes arredondadas com cauda e barbatana). Faça os peixes **girarem lentamente** (atributos de órbita já existem no código: `OrbitRadius`, `OrbitSpeed`, `OrbitPhase`; implemente a animação num `RunService` só se for **fora do modelo** ou deixe os atributos prontos e avise).
- **Deck** com banquinho na frente-esquerda, lanterna âmbar no chão ao lado.
- **Árvore de flores** atrás: hoje são esferas rosa lisas e galhos laranja. Troque por **tronco roxo-acastanhado retorcido** com galhos curvos e **copa em 3 nuvens** de pétalas rosa/lilás (muitas peças pequenas achatadas ou esferas pequenas sobrepostas para parecer flor, com variação de rosa e lilás), **pétalas caindo** (emissor leve) e algumas pétalas no chão.
- **Duas lanternas âmbar** em postes de madeira com braço curvo (corrente), com luz âmbar quente.
- **Pedras de runa** (4 a 5): pedras cinza-azuladas com **runas brilhando** (use `SurfaceGui` com texto ou peças Neon pequenas em forma de letra).
- **Vaga-lumes** amarelos pequenos pelo ar (referência B).

### 5. Portal
- Hoje: bloco de gelo ciano quadrado com anel flutuando no topo. A pedra está lavada de ciano e fica parecendo um cubo.
- Referência: **arco de pedra cinza** feito de **blocos de pedra empilhados** (pilares de 4 a 5 blocos, levemente desalinhados, com rachaduras), **viga de madeira marrom** em cima com **pedra central com espiral ciano** gravada. Dentro do arco, um **redemoinho em espiral ciano/branco** brilhante (não um quadrado liso): use várias faixas finas em espiral, com `Beam`/anéis girando e `ParticleEmitter` leve. Pedrinhas de caminho na areia na frente. **Pequenos cristais ciano** nos pés do arco. Na referência B o arco é mais arredondado e todo de pedra clara com junta escura entre os blocos e brilho ciano suave por dentro.
- Importante: a pedra **não deve ficar tingida de ciano**. Reduza o brilho/luz do portal sobre as pedras (a `PointLight` está forte) e use cores de pedra reais.

### 6. Píer central
- Hoje: bom, mas tábuas lisas e uniformes.
- Referência: **tábuas com variação de comprimento e tom**, pequenas folgas, **postes de madeira grossos nas bordas com corda**, levemente curvado na diagonal ligando o portal à lagoa. Adicione veios de madeira (textura `WoodPlanks` já está, varie as cores e tamanhos).

### 7. Props
- **Placas de madeira** com peixe entalhado: hoje o peixe é branco chapado. Faça o peixe **entalhado em tom mais claro de madeira** (creme), placa com borda e pequenas imperfeições, poste com topo arredondado.
- **Barril de iscas** com **aros de ferro azuis** e **peixes coloridos dentro** (vermelho, azul, roxo) aparecendo na boca do barril.
- **Cerca de corda**: postes grossos de madeira com **nó de corda enrolado em volta** e **corda caída em curva**, não reta.

### 8. Céu, água e nuvens
- Hoje: nuvens são elipsoides brancos lisos, e o oceano é azul-elétrico saturado, com outras ilhas ao fundo.
- Referência: nuvens **cremosas e fofas** (cor `(255,240,215)`, formadas por **muitas esferas de tamanhos diferentes** coladas, base achatada, com leve sombra mais escura embaixo), oceano **turquesa translúcido** `(48,170,200)` com ondulação suave e **sombra grande da ilha** projetada na água. Luz **dourada** vindo do canto superior esquerdo (`ClockTime` ≈ 9 a 10, `ColorCorrection` quente leve, `SunRays` fraco, `Bloom` suave).
- O ambiente (Lighting/oceano) é global do jogo: **não altere `Lighting` do place**. Se quiser mostrar a luz da referência, deixe numa função opcional `applyReferenceLighting()` que o João roda só para tirar prints, e documente.

### 9. Efeitos gerais
- Brilhos e partículas **leves**, sem poluir: cristais pulsando, poeira dourada perto da luz do portal, pétalas, vaga-lumes, névoa nas cachoeiras.
- Detalhes pequenos que dão vida: pedrinhas, conchas na areia, tufos de grama, algumas flores, musgo nas pedras da base.

## Como trabalhar

1. Abra as duas referências e os 4 prints. Anote diferença por diferença.
2. Edite `tools/TrainingIsland1Builder.luau` por partes (rocha, topo, lagoa foco, lagoa instinto, árvore, portal, props, nuvens). Rode `build()` depois de cada parte e tire print no **mesmo ângulo da referência A**: câmera em `origin + (0, 48, 100)` olhando para `origin`, FOV 55. Compare lado a lado.
3. Rode `stylua tools/TrainingIsland1Builder.luau` e `selene tools/TrainingIsland1Builder.luau` (zero warnings).
4. Teste em Play: ir pelo portal, chegar na areia, treinar nos dois decks, voltar. Nada pode bloquear o caminho do portal até as lagoas.
5. Tire os prints finais nos mesmos 4 ângulos de `art/preview/ilha-1/` com o nome `novo-*.jpg` e escreva no Mural (`docs/COORDENACAO.md`, só adicionando no fim): o que mudou, contagem de peças e o que ficou diferente da referência.
6. **Studio compartilhado:** crie `.studio-lock` (`antigravity ilha-1-refinar <hora>`) antes de usar o Studio e apague ao terminar. Se já existir lock de outro, espere.
7. Não salve o place (`save_place`) nem faça commit: o João decide. Avise quando terminar.

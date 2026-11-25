# Ilha 1 (Aprendiz): polimento final (mais bonita e mais chamativa)

Cole o bloco abaixo no Antigravity junto com: (1) a imagem de referência, (2) prints do estado atual da ilha.

---

Você vai dar o POLIMENTO FINAL na Ilha de Treino 1 ("Ilha do Aprendiz") do Legendary Catch (Roblox). A ilha já está construída e funcionando. Seu trabalho é deixá-la mais bonita, mais chamativa e o mais parecida possível com a imagem de referência anexada, editando o builder existente. Não recomece do zero e não quebre o que funciona.

ARQUIVOS
- Builder (edite este): tools/TrainingIsland1Builder.luau. build(origin?) é idempotente: apaga e recria Workspace.TrainingIslands.TrainingIsland_Apprentice. Centro padrão (520, 12, -380). Para rodar no Studio (Edit):
  local m = game.ServerStorage.DevTools.TrainingIsland1Builder:Clone(); require(m).build()
  (o Rojo sincroniza tools/ em ServerStorage.DevTools; sempre clone antes do require para não pegar cache).
- Também existe Builder.buildHubPortal(parent, worldBase): constrói o portal da ilha dentro de Workspace.TrainingPortalsHub. Não quebre essa função (ela reusa buildArrivalPortal).
- Referências: art/concept/escolhidas/ilha-1-aprendiz.jpg (A) e art/concept/escolhidas/ilha-1-aprendiz-v2.jpg (B, guia de acabamento). Prints do estado atual: art/preview/ilha-1/ (podem estar um pouco antigos, rode build() e tire prints novos).
- Leia antes: AGENTS.md, docs/COORDENACAO.md, docs/prompts-antigravity/ILHA-CONSTRUIR-1-APRENDIZ.md.

NÃO PODE MUDAR (contrato com o servidor, já testado em Play)
Filhos diretos de TrainingIsland_Apprentice: ArrivalSpawn (tag ZoneSpawn, Destination="training_1"), ReturnPortal (tag ZonePortal, PortalId="training_1_return", ZoneId="lagoon", Destination="main"), FocusSpot (tag TrainingSpot, TrainingIsland=1, TrainingStat="Control"), InstinctSpot (TrainingStat="Instinct"), models FocusPond e InstinctPond, CameraShot. Os decks continuam alcançáveis a pé a partir do ArrivalSpawn sem passar pelo ReturnPortal. Piso jogável em Y ≈ 12. Decks e píer com colisão, decoração sem colisão. Nenhum Script dentro do modelo. --!strict, sem wait(). Não mexa em src/**, no resto do hub, nas outras ilhas, nem no Lighting do place (use só a função opcional applyReferenceLighting(), que não é chamada no build()).

LIMITE DE PEÇAS: IGNORAR por enquanto (hoje são ~2800 peças). Pode adicionar quantas precisar. A otimização vem depois. Só evite deixar o build() lento demais (hoje roda em ~0,2 s; até 2 s é ok).

O QUE JÁ FOI FEITO (mantenha)
Portal em arco de pedra com espiral, árvore de flores, decks com banquinho e corda enrolada, lanternas, pedras de runa, cones, anéis de luz, cristais com feixe, nuvens fofas, cercas, placas, barril, píer diagonal.

O QUE AINDA ESTÁ FRACO (corrigir, nesta ordem)

1. ROCHA E BORDA (maior problema)
- O anel de areia da borda está como um disco achatado que sobra para fora, e as pedras da rocha aparecem soltas e encostadas por baixo, parecendo outra coisa. Compare com a referência: a ilha é UMA massa só. Grama em cima, areia na frente, uma borda de terra marrom, e a rocha marrom grossa descendo em blocos arredondados e rachados que terminam numa ponta irregular (a ilha afina embaixo, como um pião achatado).
- Faça a silhueta lateral contínua: o raio da rocha logo abaixo da terra deve ser IGUAL ao raio da borda (sem degrau nem prato), depois afinando em 3 a 4 camadas de blocos com juntas visíveis e rachaduras. Pequenas pedras soltas e cascalho só como detalhe.
- Cor: marrom quente (a rocha hoje às vezes lê cinza/verde por causa do material Slate e da sombra). Teste materiais (Rock, Cobblestone, Concrete) e use variação de tom entre blocos.
- Cristais ciano encravados na rocha, MAIORES e mais numerosos (6 a 10), brilhando (Neon + PointLight fraca nos maiores). Raízes finas escuras saindo por baixo.
- Cachoeiras: hoje são faixas azul/branco retas e chapadas. Faça 2 cachoeiras finas (centro-esquerdo e centro-direito da frente) com água azul clara translúcida, fluxo levemente ondulado (várias faixas finas com Transparency diferente), espuma branca na base, névoa (ParticleEmitter leve) e uma pequena ondulação no mar onde cai.

2. LAGOA DO INSTINTO (roxa)
- De perto a água parece só um roxo escuro liso. Na referência: roxo/violeta profundo com centro turquesa/verde luminoso, brilho roxo na borda, estrelinhas flutuando, arco-íris suave na superfície e 3 peixes nadando (uma silhueta grande tipo baleia/tubarão escura e duas menores, uma com brilho arco-íris).
- Deixe a água com gradiente (anéis concêntricos de transparência/cor), um brilho (Neon fraco ou luz) no centro, os peixes visíveis de cima (corpo arredondado + cauda + barbatana, com cor e brilho), e partículas de brilho. O arco-íris deve ser uma faixa curva com as 7 cores em transparência suave, não uma faixa branca única.
- Mantenha os atributos de órbita dos peixes (OrbitRadius, OrbitSpeed, OrbitPhase) para o servidor/cliente animar depois.

3. LAGOA DO FOCO (azul)
- Água azul-clara translúcida com padrão de células/hexágonos no fundo, ondulações claras, 3 anéis de luz empilhados mais brilhantes e grossos, feixe de luz vertical difuso, 3 cones laranja com ondinhas. Os 2 cristais altos azuis devem parecer prismas hexagonais translúcidos com cristais menores na base e brilho.

4. "CHAMATIVA": ELEMENTOS QUE FAZEM O OLHO PARAR
- Portal da ilha: mais brilho e presença (anel de luz girando, partículas subindo, raios de luz atrás do arco, cristais maiores nos pés). A pedra não pode ficar tingida de ciano: use PointLight fraca.
- Um ponto de luz dourada/âmbar quente nas lanternas e nos decks para contrastar com o azul/ciano da água.
- Pétalas rosa caindo da árvore e ficando no chão, vaga-lumes amarelos, poeira dourada no ar perto do portal, cristais pulsando. Tudo leve (taxas baixas).
- Mais detalhes de vida no topo: tufos de grama, flores pequenas, pedrinhas, conchas na areia, musgo, pegadas/caminho de areia do portal até o píer, cestos/redes de pesca perto dos decks, 2 ou 3 caixotes e um barco pequeno ou boia grande ancorada perto da borda (coisas pequenas que contam história).
- Placas de madeira com peixe entalhado em creme (hoje brancas e chapadas), barril de iscas com aros azuis e peixes coloridos aparecendo.

5. PORTAL NO HUB (Workspace.TrainingPortalsHub.Portal_Training_Apprentice)
- Ele é mais baixo que os portais vizinhos (Recife, Abismo, Celestial, ~10,6 de altura) e a placa fica alta e sem as hastes rosa deles. Aumente a escala do arco (ou os blocos) para ficar da altura dos vizinhos, aproxime a placa do topo, e dê uma haste/suporte. Mantenha atributos do PortalTrigger (PortalId="main_to_training_1", ZoneId="lagoon", Destination="training_1", tag ZonePortal) e a extensão de deck TrainingPortalDeckExt1. Essa parte vive em Builder.buildHubPortal.

6. ILUMINAÇÃO E CÂMERA
- Use Builder.applyReferenceLighting() só para tirar os prints finais, depois restoreLighting(). Ângulo da referência A: câmera em origin + (0, 48, 100) olhando para origin, FOV 55. A ilha deve ficar com a mesma "cara" da imagem de referência: ensolarada, dourada, saturada, com brilhos.

COMO TRABALHAR
1. Compare a referência com o estado atual, anote cada diferença e trabalhe por partes (rocha, cachoeiras, lagoa do instinto, lagoa do foco, efeitos, portal do hub). Rode build() depois de cada parte e tire print no ângulo da referência A e em mais 3 ângulos: portal de perto, cada lagoa de perto e a lateral da rocha (câmera acima da água, evite ficar debaixo d'água).
2. stylua e selene em tools/TrainingIsland1Builder.luau (zero warnings).
3. Teste em Play: usar o portal do hub, chegar na areia, caminhar até os dois decks, treinar (prompt do deck), voltar pelo ReturnPortal. Nada pode bloquear o caminho.
4. Prints finais em art/preview/ilha-1/novo-*.jpg. Escreva no Mural (docs/COORDENACAO.md, só adicionando no fim): o que mudou, contagem de peças e o que ficou diferente da referência.
5. Studio compartilhado: crie .studio-lock ("antigravity ilha-1-polimento <hora>") antes de usar o Studio e apague ao terminar. Se já existir lock de outro, espere.
6. Não salve o place e não faça commit: o João decide. Avise quando terminar.

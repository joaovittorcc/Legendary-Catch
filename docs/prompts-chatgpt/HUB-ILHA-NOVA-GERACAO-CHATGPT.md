# Hub novo: gerar a ilha inteira por código (prompt para o ChatGPT)

Mesmo pedido do prompt do Gemini, ajustado para o ChatGPT, para comparar qual gera a ilha melhor.

Como usar (ChatGPT no navegador, de preferência um modelo com raciocínio e com envio de arquivos): anexe 1) `art/concept/hub-portais/gemini-v1-aprovado-com-marcacoes.webp` (o concept aprovado), 2) `docs/gemini-hub/HUB-TERRENO-PARA-GEMINI.md` (dados reais do terreno e do que existe hoje) e, se quiser, 3) os prints `art/preview/hub-tour/01..08`. Cole o bloco abaixo. Quando terminar, mande o arquivo (ou o código) para o Claude. Se a resposta for cortada: "continue exatamente de onde parou, sem repetir nada e sem resumir".
Dica: peça ao ChatGPT para entregar como **arquivo para baixar** (`HubBuilder.luau`), que é mais seguro que colar um código gigante.

Para a comparação justa: use as mesmas imagens e o mesmo contrato nos dois, e guarde o resultado de cada um com um nome diferente (`HubBuilder_gemini.luau` e `HubBuilder_chatgpt.luau`). O Claude roda os dois em origens diferentes e tira os mesmos prints.

---

Você é um programador Luau sênior e artista técnico de Roblox. Pense com calma e use todo o raciocínio necessário, especialista em construir mundos estilizados bonitos por código (terreno nativo + peças). Anexei: (1) o **concept aprovado** da ilha-hub do meu jogo "Legendary Catch" (imagem gerada por outra IA e aprovada por mim, com 3 círculos de cor que são só indicações de melhoria visual), e (2) um arquivo com os **dados reais do terreno atual e o contrato** com o que existe no jogo.

# MISSÃO
Escreva **o código que gera uma NOVA ilha-hub inteira**, fiel ao concept aprovado: terreno, praça central, Oficina de Varas, escadaria de entrada, fogueira, Píer de Pesca, o cais com os portais das ilhas de pesca, o santuário de treino com os 4 portais e o círculo de runas, a lagoa com cachoeira e o portal do Aprendiz (bem fácil de acessar), a árvore de flores, o aquário, cristais, palmeiras, lanternas, placas, bandeirolas, cordas e todos os detalhes do concept. O plano visual está **aprovado**: não invente outro. Siga a imagem. Onde eu disse "melhorar" (as 3 entradas), faça mais bonito e detalhado do que na imagem:
1. **Cais das Expedições** (pórtico de madeira "CAIS DAS EXPEDIÇÕES", redes, caixotes, barris, boias, lanternas, 2 portais de pesca com base de pedra, cristais e coluna de luz, espaço visível para mais 2 portais).
2. **Portal do Aprendiz na cachoeira**: de frente para a praça, com **caminho largo e claro** da praça até ele (ponte/rampa de madeira com corrimão de corda e lanternas), cachoeira como cenário de fundo, vitórias-régias, placa grande e placa direcional na praça.
3. **Entrada do Santuário do Treino** (escada ao lado da fogueira): portão de pedra e madeira "SANTUÁRIO DO TREINO", degraus largos com runas brilhando, lanternas, cristais; o deck da fogueira vira um ponto de descanso bem acabado.

**Capriche de verdade.** Este é o cartão de visita do jogo. Quero acabamento de jogo premium: detalhes pequenos, variação de cor/tamanho/rotação, nada de blocos retos e lisos, brilhos e partículas leves nos lugares certos, tudo coerente com o estilo "cartoon candy" (cores vivas, cristais ciano, rosa/lilás, dourado, madeira quente, lanternas âmbar, luz de dia). **Não há limite de peças por enquanto** (a otimização vem depois): use quantas precisar para ficar lindo. Só mantenha o `build()` abaixo de ~60 segundos no total (use `task.wait()` entre blocos grandes) e cada etapa legível.

# REGRA DE OURO: SÓ TERMINE QUANDO ESTIVER PRONTO DE VERDADE
Você **não pode parar, resumir, escrever "etc.", deixar `-- TODO`, `-- ... resto igual`, placeholders ou funções vazias**. O código tem que estar **completo e funcionando**. Trabalhe em ciclos, internamente, antes de entregar a resposta final:
1. **Rascunhe** a construção por etapas.
2. **Audite** o rascunho contra a lista de verificação da seção "CHECKLIST FINAL" abaixo, item por item, e contra o concept (compare cada região da imagem com o que o código faz).
3. **Corrija** tudo que falhar (erros de sintaxe e de tipo, APIs inexistentes, variáveis `nil`, posições que não batem com o contrato, partes sem colisão onde precisa ter, coisas sobrepostas, z-fighting, falta de detalhe).
4. **Repita** o ciclo até **todos** os itens do checklist passarem e a ilha ficar, na sua avaliação honesta, "pronta para lançar". Só então escreva a resposta final.
Se o código não couber em uma mensagem, entregue em partes numeradas ("PARTE 1/N", "PARTE 2/N"...), cada parte terminando numa linha completa, e **continue sozinho nas partes seguintes** até acabar tudo. Só escreva "FIM" na última parte, depois do resumo.

**ENTREGA POR ARQUIVO (importante no ChatGPT):** se você tiver ferramenta de código/arquivos (Python, Canvas ou download), **escreva o arquivo `HubBuilder.luau` completo em disco e me dê o link para baixar**, em vez de colar tudo no chat. Antes de entregar, **releia o arquivo gerado** e confira: contagem de `function`/`end`, parênteses e chaves balanceados, nenhuma função vazia, nenhum `TODO`, nenhuma reticência (`...`) onde deveria ter código. Se não tiver como gerar arquivo, cole o código em blocos numerados como descrito acima, sem encurtar nada. **Nunca troque código por comentário do tipo "mesma lógica de antes".**
Se algo do concept for ambíguo, escolha o que fica mais bonito e **mais fácil de jogar** e anote em uma linha no resumo.

# FORMATO DE ENTREGA
Um único arquivo `HubBuilder.luau` (pode vir em partes na conversa, mas é um arquivo só ao colar em sequência):
- Primeira linha `--!strict`. `local Builder = {}` ... `return Builder`.
- `function Builder.build(origin: Vector3?): Model`: **idempotente**. Origem padrão `Vector3.new(0, 0, 700)` (uma área livre do mar, para eu comparar com o hub atual sem apagar nada). **Todas as posições internas são relativas à origem**, escritas com as coordenadas do contrato como se a origem fosse `(0,0,0)`. Assim, quando eu rodar com origem `(0,0,0)`, tudo cai nos valores reais que o servidor espera.
- Cria o modelo `Workspace.HubNew` (nome fixo; se existir, destrói e recria) com subpastas/modelos organizados por região (por exemplo `Terrainless`, `Plaza`, `Workshop`, `Stairs`, `FishingPier`, `ExpeditionWharf`, `TrainingSanctuary`, `LagoonGate`, `Aquarium`, `Decor`, `Contract`). O **terreno nativo** (`workspace.Terrain`) é gerado dentro de uma caixa ao redor da origem; antes de gerar, limpe **só essa caixa** (não use `Terrain:Clear()` global). Guarde a caixa em constantes.
- Funções auxiliares próprias no mesmo arquivo: `makeFolder`, `makeModel`, `makePart(parent, name, cf, size, color, material, canCollide, transparency)`, `makeWedge`, `makeCylinderY`, `makeEllipsoid`, `makeSegment`, `makeNeonRing`, `makeSign` (placa com `SurfaceGui` e `TextLabel`, fonte `Enum.Font.FredokaOne`, texto curto e legível), `makeRope` (corda com leve curva), `makeLantern` (poste/lanterna âmbar com `PointLight` leve), `makeCrystal` (prisma hexagonal translúcido com brilho), `makePalm`, `makeStairs`, `makeBridge`. Reaproveite-as em tudo.
- `function Builder.selfTest(origin: Vector3?): { string }`: devolve uma lista de falhas (lista vazia = tudo certo). Ele verifica por código: que existem todas as partes do contrato (nomes, tags, atributos), que o `PlayerSpawn` está no lugar, que `FishingZone` cobre a ponta do píer, que as 4 áreas caminháveis têm colisão, que o terreno nos pontos de verificação está nas alturas esperadas e que não há terreno sólido dentro da casa da Oficina. Eu vou rodar isso no Studio.
- Opcional: `function Builder.applyReferenceLighting()` e `restoreLighting()` com iluminação ensolarada dourada só para prints (nunca chamados dentro do `build()`). **Não altere o `Lighting` no `build()`.**
- Código: tipos, serviços no topo com `game:GetService`, `task.wait` (nunca `wait`), `Random.new(SEED)` fixo, tabela `PALETTE` no topo, comentários curtos em inglês, **sem `Script`/`LocalScript` dentro do modelo**, `CastShadow = false` em decoração pequena, `Parent` por último quando possível, nada de APIs que você não tem certeza que existem (use alternativas simples).

# CONTRATO COM O SERVIDOR (obrigatório: nomes, tags e valores exatos)
Coordenadas com origem `(0,0,0)`. Todos estes são filhos do modelo `Contract` (ou diretos de `HubNew`), partes ancoradas, `CanCollide = false`, `CanQuery = false`, invisíveis (`Transparency = 1`) salvo quando indicado:
- **Spawn:** `PlayerSpawn` (SpawnLocation ou Part com tag, 8x0,2x8) em `(-6, 10.4, 11.5)`, chão da praça em **Y = 10.3**. O jogador nasce voltado para a Oficina (-Z).
- **Zona de pesca:** Part `FishingZone`, tag `FishingZone` (CollectionService), atributo `ZoneId = "lagoon"`, centro `(63, 14.1, 8)`, tamanho `(46, 10, 14)`, cobrindo o píer. O píer de pesca tem piso em **Y = 10.1**, X de 17 a 85, Z de 1 a 15, e **a ponta do píer fica em X = 81, Z = 8** (o servidor só deixa lançar em um círculo de raio 5,5 em torno de `(81, 10.1, 8)`, virado para +X). **Não mude essa geometria.** Mantenha o píer de pesca como no concept (comprido, curvando para o sul no fim, com cordas, boias, caixotes, barris, redes, lanternas).
- **Oficina:** Part `WorkshopSpot`, tag `WorkshopSpot`, no balcão da Oficina, em `(-6, 15.5, -38)` (o servidor cria o prompt `OpenWorkshop` nela). O terraço da Oficina fica em **Y = 14.3**, X de -26 a 14, Z de -48 a -22, e **por dentro da casa o terreno tem que estar vazio**.
- **Portais de pesca** (na plataforma do Cais das Expedições): para cada um, uma Part `PortalTrigger` (7,2 x 9,4 x 4,8, invisível, `CanTouch = true`) com tag `ZonePortal` e atributos `PortalId`, `ZoneId`, `Destination`, `PrimaryColor`, `AccentColor`: Recife de Coral = `PortalId "main_to_coral"`, `ZoneId "coral"`, `Destination "coral"`; Abismo Estelar = `PortalId "main_to_abyss"`, `ZoneId "abyss"`, `Destination "abyss"`.
- **Portais de treino** (no Santuário do Treino): `PortalTrigger` com tag `ZonePortal`, `ZoneId = "lagoon"` e `Destination` + `PortalId` + `TrainingIsland`: Aprendiz `"training_1"` / `"main_to_training_1"` / 1; Recife `"training_reef"` / `"main_to_training_reef"` / 2; Abismo Estelar `"training_abyss"` / `"main_to_training_abyss"` / 3; Celestial `"training_celestial"` / `"main_to_training_celestial"` / 4. Cada um com placa: "ILHA DO APRENDIZ · Treino x1 · Grátis", "ILHA DO RECIFE · Treino x3 · 100K Poder", "ABISMO ESTELAR · Treino x12 · 100M Poder", "ILHA CELESTIAL · Treino x50 · 1T Poder".
- **Portal do Aprendiz na lagoa** (o primeiro portal, onde o tutorial vai levar o jogador): `PortalTrigger` com tag `ZonePortal` **e também tag `TrainingPortalGuide`**, `PortalId "lagoon_to_training_1"`, `ZoneId "lagoon"`, `Destination "training_1"`, `TrainingIsland 1`. Fica de frente para a praça, a cerca de (-46, 10.3, -5.5) com a cachoeira ao fundo.
- **Placar:** 3 Parts grandes (telas) com tag `LeaderboardBoard` flutuando sobre o mar a oeste, em torno de `(-70, 36, 27)` (cada uma ~14 x 9 x 0,6, `SurfaceGui` fica por conta do jogo, deixe a face frontal lisa e escura).
- **Lagoa:** bacia de raio 15 centrada em `(-44, ·, 2)`, água em **Y = 8** (terreno nativo Water), fundo de areia em Y ≈ 4. Não deixe terreno sólido acima de Y 10 dentro da bacia.
- **Escadaria de entrada:** desce da praça (Y 10,3) ao sul, X de -14 a 2, Z de 24 a 52, até a água rasa turquesa. Degraus com colisão e altura de ~0,55 stud, caminháveis, sem lacunas.
- **Praça central:** piso de pedra clara, X de -30 a 18, Z de -22 a 24, **Y = 10,3**, com fogueira (perto de `(-16, 10.3, 11)`) e cristal central.
- Tudo que o jogador pisa (praça, escadas, píer, pontes, decks, caminhos, plataformas dos portais) tem `CanCollide = true`. Decoração (cristais, folhas, cordas, conchas, bandeirolas, partículas) tem `CanCollide = false`. **Ninguém pode ficar preso nem sem caminho** entre: spawn → praça → terraço da Oficina; praça → escadaria; praça → píer de pesca até a ponta; praça → Cais das Expedições; praça → escada do Santuário do Treino → portais de treino; praça → ponte do portal do Aprendiz. Desnível máximo entre degraus/rampas: 3 studs.
- Outras construções do jogo ficam como estão e **não fazem parte do seu código**: as ilhas de pesca e de treino distantes, o troféu flutuante, os NPCs e o aquário (você só cria a plataforma de madeira do aquário com uma vitrine de vidro, sem lógica).

# TERRENO
Use o arquivo anexo (`HUB-TERRENO-PARA-GEMINI.md`) como fonte dos mapas de altura e do que deve ficar nas alturas certas. Gere terreno **mais bonito que o atual**, como descrito lá: contorno orgânico, praias de areia, falésias de rocha em camadas, colina atrás da Oficina, cachoeira, recife raso turquesa na escada, arcos e pilares de rocha ao redor, relevo suave na grama, rocha afinando para baixo (a ilha "emerge" do mar). Materiais: Grass, Rock, Sand, Basalt, Water (e Slate no fundo). Respeite a caixa do hub, e **nunca deixe terreno sólido acima de Y 10 sob a praça nem dentro da casa da Oficina**.

# CHECKLIST FINAL (audite item por item antes de responder)
1. O código compila (sem erro de sintaxe, sem variável não declarada, sem uso de `nil`, sem API inventada). Revisou cada função linha a linha.
2. `--!strict`, serviços no topo, sem `wait()`, sem `Script`/`LocalScript` no modelo.
3. `build()` idempotente com origem relativa; `selfTest()` implementado de verdade.
4. Todo o contrato acima existe com nomes, tags e atributos EXATOS.
5. Spawn em `(-6, 10.4, 11.5)`, `FishingZone` e ponta do píer em `(81, 10.1, 8)`, `WorkshopSpot` no balcão.
6. Caminhos a pé contínuos e com colisão entre todos os pontos listados; nenhum degrau > 3 studs; nenhum espaço preso.
7. Nenhum terreno sólido acima de Y 10 sob a praça e nenhum dentro da casa da Oficina; lagoa com água em Y 8.
8. Todas as regiões do concept existem: terreno + colina, Oficina com telhado azul e placa "OFICINA DE VARAS", praça com fogueira, bancos e cristal, escadaria com arco "Legendary Catch", píer de pesca curvo, Cais das Expedições (pórtico, 2 portais + espaço para mais 2), Santuário do Treino (escada, portão, círculo de runas, 4 portais em progressão), lagoa com cachoeira e portal do Aprendiz acessível, árvore de flores, aquário, palmeiras, cristais, lanternas, bandeirolas, placas.
9. As 3 entradas melhoradas estão mais detalhadas que na imagem.
10. Cada região tem **detalhes pequenos** (corda, nós, tábuas variadas, pedrinhas, tufos, conchas, flores, runas) e variação de cor/tamanho/rotação.
11. Sem z-fighting evidente (superfícies coplanares com offset de 0,02 a 0,05), sem peças flutuando sem motivo, sem peças enterradas escondendo detalhe.
12. Brilho (Neon, `PointLight`, partículas) usado com critério: cristais, portais, runas, lanternas, cachoeira, pétalas; o resto é fosco.
13. O código está completo: nenhuma função vazia, nenhum TODO, nenhum "resto igual".
Se algum item falhar, corrija e reaudite. **Não responda enquanto não passar em todos.**

# RESPOSTA FINAL
O código completo (em um bloco, ou em partes numeradas se for longo), e depois um resumo de 8 linhas: (1) o que foi construído por região, (2) contagem aproximada de peças, luzes e emissores, (3) tempo estimado do `build()`, (4) como rodar (`local m = game.ServerStorage.DevTools.HubBuilder:Clone(); require(m).build()` e `require(m).selfTest()`), (5) decisões que você tomou onde o concept era ambíguo, (6) o que ficou mais simples que o concept, (7) riscos que você enxerga, (8) o resultado honesto do seu checklist (cada item OK ou com ressalva).

# Hub V2 (Claude): polimento visual completo (Antigravity)

Prompt para o Antigravity. Ele tem acesso ao repositório (os caminhos abaixo existem nele). Anexe também, se puder, os prints citados, para ele ver as imagens direto.

---

Você vai dar o **POLIMENTO VISUAL COMPLETO no hub V2** do Legendary Catch (Roblox): a ilha principal onde o jogador nasce. Esse hub vai **substituir** o hub antigo e virar a ilha principal do jogo (isso é feito depois, por outro agente, não por você). Seu trabalho agora é só **deixar o hub bonito, espaçoso, bem acabado e fiel às imagens de referência**, editando o builder que já existe. **Não recomece do zero**: a base está boa, a composição foi aprovada pelo João, e o contrato com o servidor passa no teste.

## 1. Arquivos
- **Builder (edite este):** `tools/HubBuilder_claude.luau` (~7.500 linhas). `Builder.build(origin)` é idempotente e cria `Workspace.HubNew` (subgrupos: `Contract`, `Plaza`, `Workshop`, `Stairs`, `FishingPier`, `ExpeditionWharf`, `TrainingSanctuary`, `LagoonGate`, `Aquarium`, `Decor`). Também tem `Builder.selfTest(origin)` (deve voltar **vazio**) e `Builder.applyReferenceLighting()`/`restoreLighting()` (só para prints, nunca no `build()`). Hoje o hub de teste está em **origem `(-700, 0, 700)`**; o hub antigo continua em `(0, 0, 0)` e você **não toca nele**. Para rodar no Studio (Edit), sempre com `:Clone()` (evita cache):
  `local m = game.ServerStorage.DevTools.HubBuilder_claude:Clone(); local B = require(m); B.build(Vector3.new(-700, 0, 700)); print(table.concat(B.selfTest(Vector3.new(-700, 0, 700)), "\n"))`
  O Rojo sincroniza `tools/` em `ServerStorage.DevTools`.
- **Referências visuais (alvo):** `art/concept/hub-v2/` (ref-1 a ref-5: entrada do santuário, visão geral A e B, entrada do píer, lagoa com portal do Aprendiz) e `art/concept/hub-portais/gemini-v1-aprovado-com-marcacoes.webp`. São imagens geradas por IA (têm textos tortos nas placas): **vale o conceito, a composição e o acabamento, não os textos**.
- **Prints do estado atual (V2):** `art/preview/hub-claude-v2/` (10 prints do Studio, de dia) e `art/preview/hub-v2-joao/` (5 prints tirados pelo João jogando, de noite, com os defeitos que ele quer corrigidos).
- **Análise anterior (leia):** `docs/hub-v2/ANALISE-HUB-CLAUDE-V1-VS-REFERENCIA.md` (causas da luz estourada, forma da ilha, praça, santuário, cais etc.). Parte já foi feita na V2; o que ainda vale está repetido abaixo.
- **Contrato com o servidor:** `docs/gemini-hub/HUB-ILHA-NOVA-GERACAO-GEMINI.md` (seção "CONTRATO COM O SERVIDOR") e `docs/gemini-hub/HUB-TERRENO-PARA-GEMINI.md`. Leia também `AGENTS.md` e `docs/COORDENACAO.md`.

## 2. O QUE NÃO PODE MUDAR (contrato do servidor, será testado em Play)
Coordenadas com origem `(0,0,0)`; no hub de teste somam-se `(-700, 0, 700)`.
- `PlayerSpawn` em `(-6, 10.4, 11.5)`, **piso da praça em Y = 10,3**.
- `FishingZone` (tag `FishingZone`, `ZoneId "lagoon"`), centro `(63, 14.1, 8)`, tamanho `(46, 10, 14)`. **Píer de pesca com piso em Y = 10,1, X de 17 a 85, Z de 1 a 15, ponta em `(81, 10.1, 8)`** (círculo de lançamento raio 5,5 virado para +X). A geometria e a posição da ponta do píer **não mudam**.
- `WorkshopSpot` no balcão em `(-6, 15.5, -38)`; terraço da oficina em **Y = 14,3**; dentro da casa o terreno é vazio.
- Portais com tag `ZonePortal` + atributos `PortalId`, `ZoneId`, `Destination`, `TrainingIsland`, `PrimaryColor`, `AccentColor`: pesca `coral` e `abyss`; treino `training_1` (Aprendiz), `training_reef`, `training_abyss`, `training_celestial`; o portal da lagoa também tem a tag `TrainingPortalGuide` e `PortalId "lagoon_to_training_1"`. Placares com tag `LeaderboardBoard`. Lagoa com água em **Y = 8**. Escadaria de entrada descendo à água em X -14 a 2, Z 24 a 52.
- Tudo que o jogador pisa tem `CanCollide = true`; decoração não. **Nenhum degrau > 3 studs** e caminhos contínuos entre spawn, praça, oficina, escadaria, píer, cais, santuário e portal da lagoa. Nada de `Script` dentro do modelo. `--!strict`, sem `wait()`.
- **Os valores de contrato acima são fixos, mas o resto pode (e deve) se espalhar.** Para ganhar espaço, mova decoração, props, zonas e a borda da ilha para fora; **não mova** spawn, `FishingZone`, píer, `WorkshopSpot` nem os pisos Y 10,3/10,1/14,3/8.
- **Não altere o `Lighting` do place** (só a função opcional de prints). Não mexa em `src/**`, nas ilhas de pesca/treino, nem no hub antigo.

## 3. Limite de peças: IGNORAR por enquanto
Pode usar quantas peças, luzes e partículas precisar (hoje ~7.300 peças). A otimização vem depois. Mantenha `build()` abaixo de ~15 s (use `task.wait()` entre blocos grandes).

## 4. PEDIDOS DO JOÃO (principais), com o que eu vi nos prints

### 4.1 Mais espaço: as coisas estão apertadas
Tudo está muito junto e baixo. **Aumente a ilha um pouco** (praça, santuário, lagoa, cais) e **dê espaçamento maior entre as coisas**: mais respiro entre a oficina, a praça, as escadas, o santuário, a lagoa, o aquário e o cais. Distribua canteiros, bancos, lanternas e plantas com intervalos maiores; evite objetos colados ou sobrepostos (vi corrimões, lanternas, bandeirolas e placas se atravessando). Ao expandir, mantenha a ilha como **uma massa de rocha única e cheia** (nada de pedaços soltos flutuando no mar). Os caminhos entre as zonas devem ficar **largos e claros**.

### 4.2 Lugares para os 3 NPCs (o João esqueceu o nome da que "desce a escada": é a **Luna**)
Os NPCs são criados no cliente (`src/client/Features/LivingWorld/init.luau` e `Guide/init.luau`) em posições fixas **que o hub precisa respeitar** (coordenadas com origem `(0,0,0)`):
- **Luna (concha/lore):** `(-10.8, 1.35, 53.5)`, olhando para `(-4, 1.35, 48)`: no **pé da escadaria**, num **patamar à beira-mar**. Hoje esse ponto não tem chão (só pedras soltas na água). Crie um **pequeno cais/patamar de pedra e madeira** (~8 x 8 studs, piso em Y ≈ 0,9 a 1,1, com colisão) ligado ao último degrau, com conchas, uma cesta, uma lanterna e um banquinho. Tem que ter **espaço livre para o NPC** (círculo de 3 studs) e ficar bonito.
- **Lucy (isca):** `(34, 10.1, 3.2)`, olhando para `(34, 10.1, 10)`: no **píer de pesca**, ao lado do caminho. Crie uma **barraquinha de iscas** pequena (balcão, jarras, rede) ao lado dessa posição, sem tapar o píer. Piso do píer em Y 10,1.
- **Vô Anzol (guia):** `(14, 10.3, 2)`: na **entrada do píer**, perto do início. Deixe um **espaço livre e plano** (3 x 3 studs) e uma lanterna/banco por perto.
Só preciso que existam o **espaço limpo e o cenário** para eles; os modelos dos NPCs não são seus.

### 4.3 PLACAS: aumentar, subir e consertar
- **Todas as placas estão baixas e pequenas** ("PÍER DE PESCA", "Legendary Catch", "CAIS DAS EXPEDIÇÕES", "SANTUÁRIO DO TREINO", "OFICINA DE VARAS", portais, aquário...). **Aumente o tamanho (~1,6x)** e **suba**: o jogador (5 studs) deve ver o texto de longe. Os **pórticos e arcos** (Legendary Catch no pé da escada, Cais das Expedições, Pier de Pesca, Santuário) estão com a viga na altura da cabeça do avatar (print 2 do João): dê **vão livre de pelo menos 9 studs** sob a viga e coloque a placa **acima da viga ou presa nela com folga**, grande e legível.
- **Bug "pau atravessando o texto"** (prints 1 e 3 do João): em várias placas **o poste, a viga ou outro objeto passa na frente do texto** (ex.: placa "AQUÁRIO" tem um poste vertical cortando a face e uma vara de pesca/mastro cruzando; a placa direcional "PIER DE PESCA / EXPEDIÇÕES / OFICINA DE VARAS" tem setas empilhadas e tortas, o texto é cortado pela outra seta). **Regra para todas as placas:** a face com `SurfaceGui` fica **livre**, sem nenhuma peça na frente dela nem encostando nas bordas; poste/viga fica **atrás** ou **por baixo**, com 0,3 stud de folga; nenhuma peça de uma placa invade a face de outra; as setas direcionais não se sobrepõem.
- **Remover a placa direcional empilhada** da praça (a de 3 setas "PIER DE PESCA / EXPEDIÇÕES / OFICINA DE VARAS", print 3 do João): é confusa e ocupa a praça. Em vez dela, deixe **uma placa pequena e limpa por caminho**, no **começo** de cada caminho (um destino por placa, alinhada ao caminho, reta, com a seta apontando certo). Mantenha as setas simples do portal do Aprendiz e do Santuário (úteis para o tutorial), só retas e legíveis.
- Placas do `SurfaceGui` com texto curto, fonte `Enum.Font.FredokaOne`, bom contraste (texto claro sobre fundo escuro com moldura), sem texto cortado. Mantenha os textos atuais.

### 4.4 Árvores: melhorar muito o modelo
- **Palmeiras** hoje têm folhas de blocos achatados em "guarda-chuva" e o tronco é uma pilha de cilindros. Faça **tronco curvo com leve inclinação e anéis**, afinando para cima, e **folhas arqueadas e roliças em leque** (9 a 13 folhas longas, cada uma com 4 a 5 segmentos que vão afinando e caindo, 3 tons de verde, folhas internas mais claras), **cocos** e uma pequena sombra de folhas secas na base. Sem folhas retas e chapadas. **Reduza a quantidade** (hoje são muitas) e coloque-as de forma **intencional**: uma de cada lado da oficina, uma ou duas no santuário, uma perto da lagoa, uma perto do aquário; todas **bem altas**.
- **Árvore de flores rosa** (no santuário e na lagoa): hoje é uma copa de bolhas rosa lisas. Faça uma **copa grande em 3 a 5 nuvens** de muitas peças pequenas (esferas/elipsoides sobrepostos em 3 tons de rosa e lilás, algumas flores maiores), **tronco torcido** com galhos grossos e raízes aparentes, pétalas caindo (`ParticleEmitter` leve) e pétalas no chão. Mais alta e imponente (como na referência: ela domina o canto esquerdo da ilha).
- Arbustos e plantas de vaso (as "pineapple plants" nos vasos): hoje são folhas chapadas; dê volume (folhas arqueadas em 3 tons, algumas flores).

### 4.5 Centralizar e alinhar (coisas tortas)
- **Cristal central da praça (print 4 do João):** o cristal e a pedra roxa **estão tortos e descentrados** sobre o pedestal. Deixe o cristal **vertical, centrado no pedestal e no centro exato da praça**, com cristais menores simétricos em volta (ou um cristal principal alto e 2 menores, todos apoiados com base), pedestal redondo bem apoiado no piso, anel de luz ciano uniforme (sem partes atravessando o chão).
- **Bancos da praça (print 5 do João):** estão **tortos e em ângulos aleatórios**. Alinhe-os **radialmente em volta do círculo da praça**, simétricos (por exemplo 4 ou 6 bancos igualmente espaçados, de frente para o centro, encostados na borda do círculo, com tocos/plantas entre eles), e os bancos da fogueira perfeitamente alinhados ao deck.
- Em geral: **simetria e alinhamento** nas zonas formais (praça, escadaria de entrada, portão do santuário, portais, cais). Objetos repetidos (lanternas, postes, vasos, estacas, bandeirolas) em **intervalos regulares** e alinhados ao caminho. Reveja o que está fora de eixo: portais do santuário, os pads "EM BREVE" do cais, a fogueira, os pilares do píer.
- **Rotação:** use rotação aleatória só em **elementos naturais** (pedras, grama, flores, conchas). Em **construções** (bancos, mesas, caixotes arrumados, postes, placas) use ângulos **limpos** (0°, 90°, ou radiais exatos), com no máximo 1° a 2° de variação para parecer artesanal.

### 4.6 Tudo mais ALTO (decoração baixa demais)
O João notou (e os prints mostram) que lanternas, postes de corda, vasos, plantas, cristais, bandeirolas, bancos, placas e cercas estão **todos baixos** em relação ao avatar (5 studs). Aumente a escala vertical em geral (**~1,3x a 1,5x**): lanternas de poste a ~7 a 8 studs, postes de corrimão a ~3,5 a 4 studs, cristais decorativos mais altos (tufos de 4 a 10 studs), bandeirolas **mais altas** (fios a ~10 studs, não na altura da cabeça), mastros e arcos mais altos, árvores bem mais altas, vasos e plantas maiores. As silhuetas (oficina, arcos, portais, palmeiras, árvore rosa, cristais) devem se **destacar de longe**, como nas referências.

### 4.7 Iluminação forte demais (estourado de dia)
Ver `docs/hub-v2/ANALISE-HUB-CLAUDE-V1-VS-REFERENCIA.md`, seção 1. O que ainda vale:
- **Pedra clara demais:** praça, escadaria, plataforma do cais e degraus ainda parecem quase brancos/rosa-claro com o sol (e viram "tela branca" de dia). Use pedra **mais escura e quente** (pêssego/rosa-acinzentado, cinza-lilás), com **variação por laje** (3 a 4 tons), juntas escuras e algumas lajes rachadas. Reduza `white` e cores acima de ~(220,215,210) em superfícies grandes.
- **Feixes de luz** sobre os portais de pesca ainda altos e largos: faça-os **finos (1 a 2 studs), curtos (15 a 25 studs) e translúcidos (Transparency ≥ 0,88)**; sem `Neon` sólido grande.
- **Neon e `PointLight`:** brilhos só em runas, aros, cristais, lanternas, interior dos portais. Diminua `Brightness` e `Range` das luzes (o hub tem ~110) para não lavar as superfícies; o jogador também vê o hub à noite (prints do João são noturnos): à noite as lanternas e cristais devem **brilhar bem**, de dia ficarem **discretos**.
- **Areia** do terreno clara demais: use dourada-quente, e **menos** areia (a referência é rocha e pedra, com pouca praia).
- Não altere o `Lighting` do place; se quiser mostrar a iluminação da referência, use `applyReferenceLighting()` só para prints (ClockTime ≈ 11,5 a 12, Brightness ≈ 2,4, Bloom ≈ 0,3, Exposure ≈ -0,2).

### 4.8 Polimento geral e fidelidade às referências
Compare **cada região** com as imagens de referência e leve o acabamento ao nível delas:
- **Silhueta e rocha:** ilha como **bloco único de rocha cinza-azulada em camadas** (paredes, patamares, cristais grandes encravados em azul-gelo, rosa e lilás, raízes), pouca areia, base afinando. Sem rochas e objetos soltos no mar.
- **Praça:** pedra com variação, bordas, canteiros e plantas; **fogueira em deck de madeira com bancos e tocos** alinhados (como na ref-1); fonte/cristal central; fios de bandeirolas e lanternas altas.
- **Santuário do Treino (print 4 do V2 e ref-1/ref-2):** **portão** de pedra e madeira "SANTUÁRIO DO TREINO" (pilares de blocos de pedra com lanternas, viga de madeira, placa grande com haltere e cristal), **escada larga com runas ciano no centro**, **caminho de runas** no piso saindo da praça (traço fino ciano sobre pedra escura), platô redondo de pedra com círculo de runas concêntrico e cristal central, e os **4 portais** em semicírculo, ornamentados e diferentes: Aprendiz (pedra cinza com viga de madeira e espiral ciano), Recife (turquesa com corais), Abismo Estelar (arco escuro com cristais roxos), Celestial (dourado com leque de raios). Hoje os arcos são finos; dê **volume, ornamentos, degraus de base e brilho**.
- **Portal do Aprendiz + lagoa (ref-5):** pedra cinza em blocos com juntas e viga de madeira, **espiral branco-ciano forte**, numa plataforma de madeira com corrimão e degraus de pedra, **de frente para a praça**; **cachoeira de verdade** (várias faixas finas translúcidas, espuma e névoa) caindo de um bloco de rocha com musgo, **ponte curva de madeira** com lanternas e cordas, vitórias-régias, samambaias, cristais, e a placa grande "ILHA DO APRENDIZ · Grátis".
- **Cais das Expedições e Píer (ref-3):** pórtico grosso de madeira com cordas e lanternas, plataforma de pedra **mais escura e baixa** com degraus, **portal do Recife como concha/anel de coral rosa-pêssego** e **portal do Abismo como arco azul alto e estreito** com cristal, as 2 bases "EM BREVE", barris, caixotes, redes e boias (muitos props), 2 pedestais com cristais no fim do píer. Mantenha o desenho curvo do píer com bandeirolas.
- **Oficina de Varas:** vigas redondas grossas, losangos de cristal azul nas colunas, balcão com frascos, escada de pedra larga, palmeiras dos dois lados e cristais grandes atrás.
- **Aquário:** plataforma de madeira com vitrine de vidro, mais detalhe (peixes, corais, bolhas), placa "AQUÁRIO" bem legível e sem nenhuma peça na frente.
- **Placares flutuantes:** 3 telas, de frente para a praça, mais altas, com moldura brilhante e base hexagonal, sem inclinação estranha.
- **Densidade de detalhe:** tufos, flores, pedrinhas, conchas, cordas caídas, vasos, caixotes, lanternas, partículas leves (pétalas, vaga-lumes, poeira dourada, névoa nas cachoeiras), variação de cor/tamanho/rotação em tudo.

## 5. Como trabalhar (iterar até ficar IDÊNTICO ao conceito)
1. Abra as referências, os 10 prints V2 e os 5 prints do João. **Faça uma tabela região por região** (praça, escadaria de entrada + Luna, oficina, santuário, lagoa/portal do Aprendiz, cais/píer + Lucy/Vô Anzol, aquário, placares, rocha/silhueta, árvores, placas, iluminação): o que a referência mostra, o que o V2 tem, o que mudar.
2. Trabalhe por regiões. Depois de cada uma, rode `build()`, tire print e compare com a referência e com o print antigo. Prints de vários ângulos: visão geral aérea (`origem + (-5, 70, 135)` olhando `origem + (-8, 8, 0)`, FOV 55), entrada da escadaria, praça, oficina, santuário, lagoa, cais, píer, aquário, fundo/rocha e **cada placa de perto**.
3. **Só termine quando o hub estiver idêntico ao conceito e todos os pedidos da seção 4 estiverem atendidos.** Faça no fim uma tabela de conferência região por região (IDÊNTICO / QUASE / DIFERENTE e o que falta).
4. `stylua tools/HubBuilder_claude.luau` e `selene tools/HubBuilder_claude.luau` (sem erros novos). O `selfTest()` deve voltar **vazio**.
5. **Teste em Play** (no hub de teste): nascer, andar da praça até a oficina, escada de entrada até o patamar da Luna, píer até a ponta, cais, santuário, portal da lagoa; usar o prompt `OpenWorkshop` e os portais. Sem ficar preso nem sem caminho.
6. Prints finais em `art/preview/hub-claude-v2/novo-*.jpg` (mesmos ângulos). Escreva no Mural (`docs/COORDENACAO.md`, **só adicionando no fim**): o que mudou, contagem de peças e o que ainda difere.
7. **Studio compartilhado:** crie `.studio-lock` (`antigravity hub-v2 <hora>`) antes de usar o Studio e apague ao terminar; se já existir lock de outro agente, espere.
8. **Não salve o place e não faça commit**: o João decide. Avise quando terminar.

## 6. O que vem depois (informativo, não faça)
Quando você terminar, o Claude vai: rodar o hub com origem `(0, 0, 0)`, **remover o hub antigo** (`Workspace.Island`) e trazer para o novo as features que existem nele (cenário vivo, NPCs, aquário, placares, troféu, tags do servidor), e testar tudo em Play. Por isso, mantenha o contrato e os pontos de NPC acima exatamente como estão.

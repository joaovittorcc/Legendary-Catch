# Hub V2, rodada 2: bugs, caminhos, portal do Aprendiz, efeitos e animações (Antigravity)

Prompt para o Antigravity. Continuação do polimento anterior (`docs/prompts-antigravity/HUB-V2-POLIMENTO-ANTIGRAVITY.md`, já feito: espaçamento, placas, árvores, alinhamento, luz). O João achou o hub "quase bom": faltam **polimento, efeitos, cores e animações**, **consertar caminhos** (principalmente o do **aquário**), **melhorar o lugar do portal da primeira ilha** e **deixar o mapa mais transitável**. Abaixo está a análise profunda feita pelo Claude (testes automáticos no Studio + prints). Anexe os prints de `art/preview/hub-analise-v2b/` e os de `art/preview/hub-claude-v2/novo-*.jpg`.

---

Você vai dar a **RODADA 2 de polimento no hub V2 do Legendary Catch (Roblox)**, editando o builder existente. **Não recomece do zero**; o contrato com o servidor continua valendo.

## 1. Arquivos e contexto
- **Builder (edite este):** `tools/HubBuilder_claude.luau` (`Builder.build(origin)`, `Builder.selfTest(origin)`, `applyReferenceLighting()`/`restoreLighting()`). Hub de teste em **origem `(-700, 0, 700)`**. O hub antigo (`Workspace.Island`, origem 0,0,0) **não se toca**. Rodar no Studio (Edit), sempre com `:Clone()`:
  `local m = game.ServerStorage.DevTools.HubBuilder_claude:Clone(); local B = require(m); B.build(Vector3.new(-700,0,700)); print(table.concat(B.selfTest(Vector3.new(-700,0,700)), "\n"))`
- **Referências visuais:** `art/concept/hub-v2/` (ref-1 a ref-5) e `art/concept/hub-portais/gemini-v1-aprovado-com-marcacoes.webp`.
- **Prints do estado atual:** `art/preview/hub-analise-v2b/a1..a7` (análise desta rodada, com os bugs) e `art/preview/hub-claude-v2/novo-01..10`.
- **Contrato com o servidor e NPCs:** seções 2 e 4.2 de `docs/prompts-antigravity/HUB-V2-POLIMENTO-ANTIGRAVITY.md` (valem integralmente). Leia também `AGENTS.md` e `docs/COORDENACAO.md`.

## 2. NÃO PODE MUDAR (será testado em Play)
Coordenadas com origem `(0,0,0)`: `PlayerSpawn (-6,10.4,11.5)`, piso da praça **Y 10,3**; `FishingZone` centro `(63,14.1,8)`, tamanho `(46,10,14)`; píer de pesca piso **Y 10,1**, X 17 a 85, Z 1 a 15, **ponta em `(81,10.1,8)`**; `WorkshopSpot (-6,15.5,-38)`, terraço da oficina **Y 14,3**; lagoa com água **Y 8**; escadaria de entrada X -14 a 2, Z 24 a 52; portais com tag `ZonePortal` e atributos `PortalId`/`ZoneId`/`Destination`/`TrainingIsland`/`PrimaryColor`/`AccentColor` (+ tag `TrainingPortalGuide` no portal da lagoa, `PortalId "lagoon_to_training_1"`); placares com tag `LeaderboardBoard`; pontos dos NPCs (Luna `(-10.8,1.35,53.5)`, Lucy `(34,10.1,3.2)`, Vô Anzol `(14,10.3,2)`). Tudo que o jogador pisa tem `CanCollide = true`; decoração não. `--!strict`, sem `wait()`, **sem Script dentro do modelo**, sem tocar em `src/**`, no hub antigo, nas ilhas nem no `Lighting` do place. **Limite de peças: ignorar por enquanto.**

## 3. BUGS ENCONTRADOS (a análise do Claude): corrija TODOS
Coordenadas **locais** (origem do hub em 0,0,0). `selfTest()` hoje passa vazio, então **amplie o `selfTest()`** para pegar também o que está listado aqui.

### 3.1 Caminho do AQUÁRIO (bug que o João citou) — prints a1 e a2
- O acesso ao aquário é uma **ponte estreita de tábuas (6 de largura, X -30 a -24, Z 24,5 a 37,5)** colada ao canto SO da praça, **espremida ao lado da escadaria** (a escada está em X -14 a 2, e o arco "Legendary Catch" com o poste grosso e uma lanterna ficam no mesmo canto). O pathfinding do Roblox exige **3 pulos** nessa rota (`(-14,11,20)`, `(-24,11,28)`, `(-28,11,40)`) e na volta do aquário até o pé da escada exige 3 pulos e um desnível de até 7,9 studs: ou seja, **o caminho não é contínuo para o jogador**.
- Problemas visíveis: o **poste do arco e a lanterna** (`ArchFoot`, `SideWall` em Z 24 a 30) **invadem a entrada**; a ponte só tem **corrimão de corda de um lado**; o ponto onde a ponte encontra o deck é um **canto estreito** (o deck é 30 x 21 e a ponte entra pelo lado); a placa "AQUÁRIO" fica pequena e ao lado do caminho; o piso do terreno em volta fica 4 a 8 studs abaixo do caminho sem proteção; o `TankBase` (16 x 1,1 x 10, Y 11) **flutua** sem apoio.
- **Refaça o acesso:** crie um **passeio largo (10 a 12 studs)** saindo da **lateral oeste da praça** (por volta de X -30, Z 8 a 20, bem longe do arco), com **piso contínuo sem lacuna e sem degrau > 0,6** até o deck; **corrimão duplo** de corda/madeira; **pórtico de entrada** do aquário com a placa grande e legível; o deck do aquário com **2 acessos** (um do passeio, outro do patamar da Luna, ligando as duas áreas); remova o poste/lanterna que atrapalham (mude para fora do caminho). Apoie o `TankBase` (estacas ou pilares) e dê base à vitrine.

### 3.2 Entrada do Cais das Expedições (print a4) e do Píer
- **Salto no encontro da ponte com a praça** em `(20,10.2,32)` (o pathfinder pede pulo): a ponte `WharfBridge` desce de 10,3 para 8,8 (degrau 1,5 no meio, `Curb` a 9,4). Faça uma **rampa contínua** (inclinação ≤ 12°) ou degraus de no máximo 0,6, **largura de 10 studs**, sem `Curb` bloqueando.
- A área do pórtico está **superlotada**: placas "PÍER DE PESCA" e "CAIS DAS EXPEDIÇÕES" (setas em madeira, tortas e coladas), 4 a 5 lanternas e dois mastros grossos num espaço de ~8 x 8. **Espalhe**: a placa direcional vai **no começo de cada caminho, a ≥ 6 studs do pórtico**, retas e alinhadas; deixe ≥ 3 studs de folga entre lanternas.
- **`WharfSign` (14,20,35)** tem os 2 `PorticoPost` na frente da face do `SurfaceGui`: o texto fica cortado. Afaste os postes ou aumente a placa e levante (face livre, 0,3 stud de folga).
- Do cais ao píer (`wharf -> pier tip`) há um **pulo em `(48,10.9,34)`**: ligue os dois por uma passarela contínua (largura ≥ 6) ou garanta degrau ≤ 0,6.

### 3.3 Portal da 1ª ilha (Aprendiz) e ponte da lagoa (print a3) — **melhorar o lugar**
- **Ele está num lugar ruim e escondido:** entra-se por uma **ponte curva estreita** cercada por **3 lanternas altas, bandeirolas, a placa direcional "ILHA DO APRENDIZ" e o início do tapete de runas**, tudo ao mesmo tempo, em volta de `(-34 a -28, -8 a 0)`. O pathfinder exige **2 pulos** (`(-34,7,-8)`, `(-32,11,-7)`) e um desnível de 4,1: a ponte entra por um lado errado. O portal (`Aprendiz`, plataforma `Base` Y 11,0, X -48 a -40, Z -8 a -2) fica **pequeno e de lado**, atrás de uma rocha, e a cachoeira é um fiapo atrás da rocha, bem longe do portal.
- **Refaça o conjunto "Lagoa do Aprendiz" como um lugar especial e acolhedor** (é o primeiro portal do jogador e o tutorial leva até ele):
  - **Praça de chegada própria** na beira da praça central (**plataforma de pedra e madeira, ~16 x 12 studs, Y 10,3**, contínua com o piso da praça, sem degrau), com canteiros, 2 bancos alinhados, 2 lanternas (apenas 2, bem espaçadas) e a **placa direcional UMA só**, grande e legível, na entrada.
  - **Ponte larga e reta** (largura ≥ 7, corrimão duplo, 2 lanternas nas pontas) ou **passeio de pedra com degraus de 0,5** levando direto ao portal; sem cantos, sem pulo.
  - **O portal de frente para a praça**, **maior (altura ~13)** e centrado no eixo da ponte, sobre uma plataforma de pedra com **3 degraus largos**, espiral branco-ciano forte, brilho no chão e a placa "ILHA DO APRENDIZ · Grátis" **acima do arco**, sem nada na frente.
  - **Cachoeira de verdade ao lado do portal** (a ~6 studs): bloco de rocha com musgo e **várias faixas finas translúcidas** caindo na lagoa, espuma e névoa na base, ondulações (anéis), vitórias-régias, samambaias e cristais em volta. Nada de rocha tapando o portal.
  - Mantenha: tag `ZonePortal` + `TrainingPortalGuide` no `PortalTrigger`, `PortalId "lagoon_to_training_1"`, destino `training_1`.

### 3.4 Pé da escadaria e patamar da Luna (print a5)
- O **banco do patamar da Luna está caído/torto** (deitado de lado, atravessando o piso) e o patamar tem só ~7 x 6, **sem ligação com o último degrau**. Endireite o banco (rotação limpa 0°/90°), alargue o patamar (≥ 8 x 8, piso Y ≈ 1), ligue-o ao último degrau sem lacuna, e deixe o círculo de 3 studs livre para o NPC. As **pedras-degrau na água** (3 discos) não levam a lugar nenhum: transforme em **caminho real** até o aquário/Luna ou remova.
- Os 2 flancos de rocha ao lado da escada têm **frestas escuras** entre a pedra e a escada: feche.

### 3.5 Santuário do Treino (print a6)
- Há um **pilar de pedra alto e solitário com chapéu de madeira** (parte do portal do Aprendiz do santuário, mal posicionada) à esquerda do portal do Recife, com **corda e bandeirolas presas a um poste no meio do círculo de runas**, atravessando o espaço de passagem. Remova o poste do meio; centre os **4 portais em semicírculo** com **espaçamento igual (≥ 8 studs)**, todos virados ao centro do círculo, e o do Aprendiz do santuário igual aos outros.
- A **placa "ILHA DO RECIFE" está inclinada** e há uma placa pequena torta ("Ilha do Aprendiz") sobre o portal: alinhe todas (rotação 0°/90°) e centralize sobre cada arco.
- O **platô redondo flutua** sobre a rocha com um vão visível por baixo (a grama aparece embaixo): feche com **rocha/pilares** (a massa do platô deve continuar na ilha).
- **`SanctuarySign` (-32,23,-22)** tem 4 `GatePillar` na frente (texto cortado): leve a placa para cima da viga do portão (≥ 1,5 stud acima) ou afaste os pilares.

### 3.6 Praça, Oficina e Barraca da Lucy (prints novo-03 e a7)
- **`WorkshopSign` (-6,26,-31)** tem o **telhado (`Roof`) na frente** (o texto "OFICINA DE VARAS" é cortado). Suba a placa ou recorte o telhado; face livre.
- **Barraca da Lucy** (`BaitStallDeck` `(34,10,1)`, 8 x 0,9 x 5) **flutua** (sem apoio) e o **toldo azul/branco** está solto no ar acima do deck sem postes. Apoie o deck (estacas até o mar), prenda o toldo a 4 postes, e **deixe 3 studs livres** ao lado do ponto da Lucy.
- **Lanternas de base sem apoio** (`StairLanternBase` `(-17,15,-23)`, `(5,15,-23)`; `TerraceLanternBase` `(-25,15,-24)`, `(13,15,-24)`; `SpotPedestal` `(-6,15,-28)`; 5 `CircleLanternBase` no platô do santuário em Y 21): assente-as no piso ou nos degraus.
- **Bancos da praça** em `PlazaBench*Seat` estão em Y 12,0 a 12,2 (altura de pulo): ok como assento, mas **não podem bloquear o caminho**; mantenha 2 studs de folga ao redor para passar.

### 3.7 Neon / brilho
- `Plaza/RunePathEdge` (6 peças, Neon opaco com transparência 0,20 e 10 a 13 studs de comprimento) deixa o caminho de runas **muito saturado**: suba a transparência para ≥ 0,45 e afine (traço de 0,25 a 0,35).
- O hub tem **112 `PointLight`**: combine/remova as redundantes (cristais pequenos sem luz), mantenha luz nas lanternas, portais, fogueira, runas centrais e cristais grandes.

## 4. TRANSITABILIDADE: deixar o mapa mais fácil de andar
Meta: **qualquer ponto do mapa chega a qualquer outro sem pular e sem ficar preso**. O pathfinder do Studio (AgentRadius 2, altura 5) hoje pede pulo em 7 das 12 rotas principais, e dá voltas de 1,2x a 1,65x o caminho reto. Regras para toda a ilha:
1. **Larguras mínimas:** caminhos principais ≥ 8 studs; secundários ≥ 5; pontes ≥ 7; escadas ≥ 8. Pórticos com **vão livre ≥ 9 studs de altura e ≥ 8 de largura**.
2. **Degraus:** altura máxima **0,6 stud** em escadas e **0,8** em soleiras; rampas de até 12°; sem desnível > 3 studs em lugar nenhum; sem lacunas nem "lábios" de borda.
3. **Folgas:** ≥ 2 studs livres em volta de bancos, canteiros, vasos, lanternas, caixotes e barris que estejam junto de um caminho; objetos decorativos **fora** do traçado (borda, canteiro, encostados em muretas).
4. **Corrimãos e cordas** só nas bordas de queda, nunca atravessando o caminho. **Corda de bandeirola** sempre acima de 9 studs (sem tocar cabeça de avatar) e sem atravessar placas.
5. **Ligações novas** (para fechar o circuito): praça ↔ aquário (passeio oeste), aquário ↔ patamar da Luna, praça ↔ lagoa do Aprendiz (ponte larga), cais ↔ píer (passarela), praça ↔ santuário (a escada já existe; mantenha). **Evite becos sem saída.**
6. Dê **sinalização** coerente: uma placa direcional limpa por caminho, no começo, alinhada ao caminho.
7. **Amplie o `selfTest()`** com: (a) `PathfindingService` entre os 14 pontos-chave (spawn, oficina, pé da escadaria, patamar da Luna, píer início/ponta, Lucy, Vô Anzol, cais, portais de treino, portal do Aprendiz, aquário) exigindo **status Success e 0 waypoints de pulo**; (b) para cada `SurfaceGui`, nada em 1,2 studs à frente da face; (c) peças colidíveis sem apoio (`GetPartsInPart`); (d) largura mínima das passagens (raios laterais).

## 5. EFEITOS, CORES E ANIMAÇÕES (o João quer mais vida)
Hoje o hub tem **17 emissores** e **nenhuma animação** (0 peças animadas). Adicione, com bom gosto e sem estourar a luz:
### 5.1 Efeitos de partículas e luz (dentro do modelo, `ParticleEmitter`/`Beam`/`Trail`/`PointLight`, taxas baixas)
- **Portais:** brilho no chão, anel de partículas subindo e fagulhas girando no interior (cada portal na sua cor: Recife turquesa, Abismo roxo, Celestial dourado, Aprendiz ciano; pesca Recife rosa-pêssego, Abismo azul).
- **Cristais grandes** (praça, oficina, santuário, rocha): pulsar leve (`PointLight` com cor) e pequenas **estrelas/brilhos** subindo.
- **Fogueira:** fogo, fagulhas e fumaça fina (o hub já tem; reforce com brasas).
- **Cachoeira do Aprendiz:** névoa, respingos e arco-íris leve; **lagoa:** vagalumes e libélulas, pétalas caindo da árvore rosa, anel de ondas.
- **Mar em volta do hub:** espuma/ondinhas junto à rocha e aos pilares do píer; gaivotas são feitas por outro sistema (não faça).
- **Praça:** pétalas e confete suave perto da oficina, brilho dourado nas bandeirolas.
- **Aquário:** bolhas subindo na vitrine, peixes e águas-vivas brilhando (partes arredondadas).
- **Santuário:** runas do círculo com brilho em onda, 4 portais com leque de luz e partículas, faíscas do cristal central.
- **Placares flutuantes:** moldura brilhante e base com partículas leves.
### 5.2 Cores
Aumente a **variedade de cor** com critério: bandeirolas em 6 cores vivas, faixas coloridas nos telhados, vasos e plantas com flores de cores diferentes, cristais em azul-gelo/rosa/lilás/ciano, lanternas âmbar quentes, madeira com 3 a 4 tons, pedra com junta e variação. **Evite superfícies brancas grandes** e feixes gigantes (o João já reclamou de luz estourada).
### 5.3 Animações (o runtime é do Claude: você só prepara etiquetas e atributos)
Não crie `Script` no modelo. Em vez disso, **marque as peças** com `CollectionService` + atributos, para o Claude ligar um módulo de cliente que anima tudo (barato e controlado por `ReduceEffects`):
- Tag **`HubSpin`** (atributos `Speed` graus/s, `Axis` "Y"/"X"/"Z", `Phase` opcional): anéis de portal, aros de luz, estrelas giratórias, cata-ventos, hélices, o anel Neon da praça, o cristal central (giro lento), o círculo de runas.
- Tag **`HubBob`** (`Amplitude` studs, `Speed`, `Phase`): cristais flutuantes, boias, lanternas de corda, placares (leve balanço), fragmentos de rocha flutuantes, plantas aquáticas.
- Tag **`HubPulse`** (`Min`, `Max`, `Speed`, `Target` = "Brightness" | "Transparency" | "Size"): luzes de cristal, runas, anéis de portal, fogueira.
- Tag **`HubFlicker`** (`Intensity`): lanternas, tochas, fogueira.
- Tag **`HubSway`** (`Angle`, `Speed`): folhas de palmeira, bandeirolas, cortinas de cordas, toldos, algas.
- Tag **`HubWave`** (`Amplitude`, `Speed`, `Phase`): bandeirolas e cordas penduradas (ondulam), caudas e peixes do aquário.
Aplique **pelo menos 60 peças marcadas** distribuídas por todas as regiões (portais, praça, cais, santuário, lagoa, aquário, árvore rosa, píer), e documente no cabeçalho do builder (um comentário curto com a lista de tags e atributos). Para peças animadas, **centralize o pivô** (a peça deve girar em torno do próprio centro) e use `PrimaryPart`/`WorldPivot` corretos em modelos.
Opcional dentro do modelo (sem Script): `Beam` com `TextureSpeed` (já anima sozinho), `Trail`, `ParticleEmitter` com `Rotation`/`RotSpeed`, `Texture` animada: use onde ficar bonito.

## 6. Como trabalhar
1. Abra os prints, passe pela **seção 3** bug por bug e confirme cada um no Studio (as coordenadas são locais; no hub de teste some `(-700, 0, 700)`).
2. Corrija por regiões, na ordem: **3.1 aquário, 3.3 portal do Aprendiz, 3.2 cais/píer, 3.4 Luna, 3.5 santuário, 3.6 praça/oficina/Lucy, 3.7 neon**; depois **4 transitabilidade**, depois **5 efeitos, cores e tags**.
3. A cada região: `build()`, print de perto e de longe (câmera acima da água, sem entrar dentro de peças), e rode o `selfTest()` ampliado. **`selfTest()` deve voltar vazio** (inclusive as novas verificações de pathfinding sem pulo).
4. **Teste em Play** no hub de teste: nascer, andar até **oficina, escada de entrada, patamar da Luna, aquário, píer até a ponta, Lucy, Vô Anzol, cais (2 portais), santuário (4 portais), portal da lagoa**; usar `OpenWorkshop` e um portal; voltar. **Sem pular, sem travar, sem ficar preso.**
5. `stylua` e `selene` em `tools/HubBuilder_claude.luau` (sem erros novos).
6. **Entregue** em `art/preview/hub-claude-v2/rodada2-*.jpg` (mesmos ângulos de `novo-*` + os de `a1..a7` com cada bug corrigido, lado a lado) e **escreva no Mural** (`docs/COORDENACAO.md`, **só adicionando no fim**): o que mudou, contagem de peças, resultado do `selfTest()`, lista das tags de animação (nomes e quantidades) e o que ainda difere.
7. **Studio compartilhado:** **leia o `.studio-lock` antes de escrever**; se existir lock de outro agente com menos de 10 min, espere. Para usar, escreva `antigravity hub-v2-rodada2 <hora>` e **apague ao terminar**. Nunca sobrescreva lock de outro.
8. **Não salve o place e não faça commit.** O João decide. Avise quando terminar.

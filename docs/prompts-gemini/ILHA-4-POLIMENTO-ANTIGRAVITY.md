# Prompt: polimento final da Ilha 4 (Celestial) para o Antigravity

**Anexe junto:** a imagem de referência (`art/concept/escolhidas/ilha-4-celestial.jpg`) e os seus prints de como a ilha está agora. Depois cole tudo abaixo da linha.

---

Você é artista técnico sênior de Roblox e programador Luau. Sua tarefa é fazer o **polimento visual completo da Ilha de Treino 4 (Celestial)** do meu jogo "Legendary Catch" até ela ficar **igual à imagem de referência**: `art/concept/escolhidas/ilha-4-celestial.jpg`. Abra e olhe a imagem antes de qualquer coisa, e volte a ela o tempo todo.

**O que existe hoje é só a BASE.** A estrutura, o layout e o contrato com o servidor funcionam (testado em Play), mas o visual está muito longe da referência. Você tem liberdade total para **refazer qualquer parte visual** do zero. Não se contente em ajustar cores.

# REGRA DE OURO: só pare quando estiver igual à referência
Não pare depois da primeira melhora. Não diga "pronto" com base no código: **só vale o que aparece no print do Studio comparado lado a lado com a referência.** Trabalhe em ciclos:
1. Reconstrua a ilha no Studio.
2. Tire prints do **mesmo ângulo da referência** (use a Part `CameraShot`, FieldOfView 55) e prints de perto de cada região.
3. Compare **região por região** com a referência e dê uma **nota de 0 a 10** para cada item da lista abaixo, escrevendo o que ainda está diferente.
4. Corrija o que tiver nota abaixo de 9.
5. Repita, quantas vezes for preciso.
**Condição para parar:** todos os itens com nota 9 ou 10, `selfTest()` com zero falhas e Play sem erros. Se algo for **impossível** no Roblox (por exemplo o céu pintado), não finja: faça a melhor aproximação, explique o motivo no relatório e mostre o print. "Ficou difícil" não é impossível. Se uma tentativa não melhorou, mude de técnica em vez de repetir a mesma.

# PROBLEMAS QUE JÁ DÁ PARA VER NA BASE (ponto de partida, não é a lista completa)
1. **Tudo estourado e lavado de branco.** A referência é quente e saturada: grama verde viva, mármore creme, ouro de verdade, céu rosa/lilás/dourado. Reduza branco puro e Neon claro grande; dê tom e contraste.
2. **Cachoeiras** parecem barras brancas sólidas. Na referência são véus de água translúcidos, em várias faixas finas com espuma, saindo de canais na grama e se desfazendo em brilhos antes das nuvens.
3. **Mar de nuvens** é um tapete branco chapado e enorme que compete com a ilha. Precisa de volume, variação de tom (creme, rosa, lilás, azul), camadas e profundidade, sem engolir a ilha.
4. **Aurora** virou estacas brancas. Precisa ser suave, larga e pastel (rosa, verde-água, lilás). Se não der para ficar bonita, é melhor remover do que deixar feia.
5. **Portal:** o redemoinho arco-íris quase não aparece (some num brilho branco). Ele é o destaque da ilha: espiral nítida com as cores pastel bem separadas, girando. O arco precisa ser mármore creme (hoje parece pedra azulada), com ouro mais encorpado.
6. **Rocha de baixo** está rasa e clara. Na referência é uma massa **alta, cheia e esculpida**, marrom-acinzentada quente, com blocos grandes arredondados e **cristais dourados e ciano grandes e bem visíveis**.
7. **Borda:** os frisos dourados e o mármore creme em camadas precisam aparecer claramente em toda a volta.
8. **Lagoas** parecem discos chapados. Foco: luz líquida com anéis dourados empilhados e a constelação bem legíveis. Instinto: roxo-rosa-dourado com reflexos, **peixes lendários grandes e visíveis**.
9. **Árvore rosa** está pequena. Na referência é um dos maiores elementos: tronco dourado retorcido, copa volumosa em vários cachos, auréola de luz, pétalas caindo.
10. **Escala dos props** (coroa de cristal, estátua de peixe, estandartes, placas, lanternas, barris, cerca de corda com postes, pilares de cristal): quase tudo está pequeno demais para ler de longe. Compare as proporções com a referência.

# ITENS PARA AVALIAR (nota 0 a 10 em cada)
silhueta geral e proporções · cores e clima · grama e vegetação · borda de mármore e frisos · rocha inferior e cristais · cachoeiras e canais · anel de luz duplo · ilhotas flutuantes · mar de nuvens · aurora e raios · portal, asas e redemoinho · caminho de runas · ponte arqueada · lagoa do Foco · lagoa do Instinto · decks, banquinhos e almofadas · árvore rosa · coroa de cristal · estátua, estandartes, placas · lanternas, barris, cerca de corda.

# ARQUIVOS E COMO RODAR
- Edite **somente** `tools/TrainingIsland4Builder.luau`. Todo o visual tem que sair do construtor: **não faça ajustes à mão no Studio**, porque se perdem na próxima reconstrução.
- O Rojo sincroniza `tools/` em `ServerStorage.DevTools` (porta 34873). Para reconstruir, no modo Edit:
  `require(game.ServerStorage.DevTools.TrainingIsland4Builder:Clone()).build()`
  e para testar: `require(game.ServerStorage.DevTools.TrainingIsland4Builder:Clone()).selfTest()`
- O modelo é `Workspace.TrainingIslands.TrainingIsland_Celestial`, origem `(0, 160, -680)`. `build()` já apaga e recria. Confirme que o Rojo sincronizou antes de cada reconstrução.
- Antes de usar o Studio, leia `docs/COORDENACAO.md` e respeite o arquivo `.studio-lock` (crie ao começar, apague ao terminar). Se o Studio estiver em Play e não foi você, não interrompa.

# NÃO PODE QUEBRAR
- **Contrato:** filhos diretos `ArrivalSpawn`, `ReturnPortal`, `FocusSpot`, `InstinctSpot`, `CameraShot`, `IslandCenter` (PrimaryPart) e os Models `FocusPond` e `InstinctPond`, com os **mesmos nomes, tags, atributos, tipos e tamanhos** que o construtor já usa.
- **Caminhos a pé** do spawn até o portal e os dois decks, sem pulo, e a ponte caminhável. Decoração sem colisão.
- **Nenhum** Script, LocalScript, ProximityPrompt ou Seat dentro do modelo.
- **Animações:** use as tags `HubSpin` (`Speed` em **graus por segundo**, calmo, entre 8 e 36), `HubBob`, `HubPulse`, `HubFlicker` e `HubSway`; menos de 150 itens marcados. As animações dos lagos serão um módulo separado, feito depois: **não crie código de animação**, só deixe as peças dos lagos bem organizadas e com nomes claros (anéis, peixes com `PrimaryPart` e atributos `OrbitRadius`, `OrbitSpeed`, `OrbitPhase`, `DepthY`).
- **Não altere** o `Lighting` do jogo (é compartilhado com o resto do mapa) nem as outras ilhas, o hub ou qualquer arquivo em `src/`. A ilha precisa ficar bonita **com a iluminação normal do jogo**, é assim que o jogador vê. `applyReferenceLighting()` é só para comparação e deve ser sempre desfeito com `restoreLighting()`.
- **Desempenho (celular):** a base tem cerca de **6.050 BaseParts**. **Teto de 9.000.** O mapa inteiro já é pesado: gaste detalhe onde se vê de perto e use poucas peças grandes nas nuvens e no fundo. Poucas luzes e poucos emissores.
- `--!strict`, `stylua` e `selene` sem erros (há um falso alarme do `selene` em `Vector3.yAxis:Cross`; contorne escrevendo `Vector3.new(0, 1, 0):Cross`).
- Não invente `rbxassetid` e não suba assets. Se achar que precisa de imagem ou mesh (por exemplo para o céu ou a aurora), **pare e me pergunte**.

# TESTE FINAL OBRIGATÓRIO (Play)
1. Chegar na ilha pelo `ArrivalSpawn` e ficar em chão sólido.
2. Andar até os dois decks e ver os prompts de treino (`TrainControl` e `TrainInstinct`).
3. Voltar ao hub pelo `ReturnPortal`.
4. Console sem erros de Luau.
5. Conferir as animações girando em velocidade calma.

Depois **salve o place** (modo Edit, fora do Play), faça commit **só dos seus arquivos** e escreva no Mural do `docs/COORDENACAO.md`.

# RELATÓRIO FINAL
Mostre lado a lado a referência e o print final do mesmo ângulo, a **tabela de notas final** (todos 9 ou 10, ou a justificativa do que é impossível), prints de perto, a contagem de peças, luzes e emissores, o resultado do `selfTest()` e o que **não** foi testado (celular de verdade, 2 jogadores, jogo publicado).

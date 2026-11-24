# Ilha de Treino 1: Aprendiz (x1, grátis): construir no Studio (Antigravity)

Um agente só para esta ilha. Os outros 3 agentes fazem as outras ilhas ao mesmo tempo.

## O que construir (fiel à imagem)

Ilha flutuante redonda e baixa no mar turquesa, dia ensolarado.
- **Base:** topo de grama com borda de areia na frente (lado do portal), lateral de rocha marrom em blocos grossos, cristais ciano brilhando encravados na rocha, raízes saindo por baixo e **duas cachoeiras finas** caindo da borda.
- **Portal (frente, à esquerda do centro):** arco simples de **pedra cinza com viga de madeira** em cima e um símbolo de espiral; dentro, um redemoinho ciano brilhante (peça Neon + `Decal`/`ParticleEmitter` leve girando). Pedrinhas de caminho na areia em frente.
- **Píer central:** passarela de tábuas de madeira na diagonal ligando o portal ao fundo, com postes e corda.
- **Lagoa do Foco (esquerda, fundo):** água azul-clara bem transparente, deck de madeira com banquinho redondo, **anéis de luz** empilhados sobre a água (anéis Neon finos, ciano), 3 cones/boias laranja e branco, 2 cristais azuis altos com feixe de luz suave. Cerca de postes e corda atrás.
- **Lagoa do Instinto (direita):** água roxa/violeta com brilho, **silhuetas de peixe** escuras e um arco-íris leve na superfície, deck com banquinho, **árvore de flores rosa/lilás** atrás (pétalas caindo: emissor leve), 2 lanternas âmbar em postes de madeira, pedras com **runas** brilhando em volta.
- **Props:** 2 placas de madeira com ícone de peixe, barril de iscas, cerca de corda na borda direita.
- Visual **simples e humilde** (é a primeira ilha), mas caprichado.

## Também nesta tarefa: tirar o treino do hub (com cuidado)

Só **depois** da ilha 1 pronta e testada:
1. No hub, o ponto de treino antigo é `Workspace.Island.TrainingLagoon` (peça com tag `TrainingSpot`). **Não apague:** mova a pasta/modelo inteiro para `ServerStorage.Archive_HubTraining` (dá pra voltar).
2. Na `TrainingPortalsHub` (praça dos portais no hub, `(56, 10.37, 63)`): garanta **4 portais** em fila, um para cada ilha, com a tag `ZonePortal` e `Destination = "training_1"`, `"training_2"`, `"training_3"`, `"training_4"`, `ZoneId = "lagoon"`, `PortalId` único. O primeiro aceso (ciano), os outros com a cor da ilha (recife turquesa, abismo azul-violeta, celestial dourado). Reaproveite o que já existe; só troque os `Destination` e adicione o portal da ilha 1.
3. Anote no Mural exatamente o que moveu.

## Regras comuns (leia antes)

- Projeto: **Legendary Catch** (Roblox, pesca e coleção). Leia `AGENTS.md`, `docs/COORDENACAO.md` e `art/training/README.md` (o que já existe das ilhas antigas e dos portais).
- Fale com o João em português informal e curto. Nomes de objetos em inglês. **Não edite `src/**`** (código é do Claude e do Codex). Registre início e fim no Mural de `docs/COORDENACAO.md` (só adicionando no fim).
- **Referência visual obrigatória:** `art/concept/escolhidas/ilha-1-aprendiz.jpg`. Abra a imagem e copie com fidelidade: formato da ilha, posição de cada lagoa, portal, píer central, decks, árvores, cristais, cachoeiras, cores e iluminação. O objetivo é que um print do Studio no mesmo ângulo pareça essa imagem.
- **Studio compartilhado:** só um Studio (place `112666482424701`). Outros 3 agentes estão fazendo as outras ilhas ao mesmo tempo e o Claude também usa o Studio. Antes de mexer no Studio crie `.studio-lock` com `antigravity ilha-1 <hora>`; se já existir um lock de outro, **espere** (cheque a cada 2 min). Segure o lock no máximo ~15 min por vez, depois apague, deixe outro usar e volte. Escreva primeiro o builder (arquivo `.luau`) sem Studio, e só use o Studio para rodar o builder e conferir.
- **Builder:** `tools/TrainingIsland1Builder.luau`, no padrão de `tools/TrainingIslandsBuilder.luau` (função `build()` idempotente que apaga e recria o modelo). Assim dá pra reconstruir a ilha se o place perder algo.
- **Desempenho (celular):** até ~160 peças, poucas luzes (máx. 2 `PointLight`/`SpotLight`), até 2 `ParticleEmitter` leves (Rate baixo), MeshParts com `CollisionFidelity = Box`, `CastShadow = false` em decoração pequena. Água das lagoas: peças `Glass`/`SmoothPlastic` com transparência e cor (sem terreno). Sem scripts dentro do modelo (o servidor e o cliente cuidam da lógica). Rode `tools/ZFightFixer.luau` no fim.
- **Colisão:** piso, caminhos, píer e decks com `CanCollide = true`; decoração `CanCollide = false`. Nada bloqueando o caminho portal até lagoas.
- Ao terminar: `save_place`, print do mesmo ângulo da referência em `art/training/ilha-1.png` (se o print vier cinza, traga o Studio para frente), atualize `art/training/README.md` e escreva no Mural o que fez, contagem de peças e as posições das âncoras.

## Contrato com o servidor (não mude nomes)

Modelo `Workspace.TrainingIslands.TrainingIsland_Apprentice` (crie a pasta `TrainingIslands` se não existir) com estes filhos diretos (Parts invisíveis `Transparency = 1`, ancoradas, `CanCollide = false`, ~4x1x4 studs):

| Nome | Tag (CollectionService) | Atributos |
|---|---|---|
| `ArrivalSpawn` | `ZoneSpawn` | `Destination = "training_1"` (string). Fica em frente ao portal, sobre o chão, virado para o centro da ilha |
| `ReturnPortal` | `ZonePortal` | `PortalId = "training_1_return"`, `ZoneId = "lagoon"`, `Destination = "main"`. Fica **dentro do arco do portal** da ilha (é o portal de volta para o hub) |
| `FocusSpot` | `TrainingSpot` | `TrainingIsland = 1` (number), `TrainingStat = "Control"`. No deck/banquinho da **lagoa do Foco** (a azul/clara), na beira da água |
| `InstinctSpot` | `TrainingSpot` | `TrainingIsland = 1` (number), `TrainingStat = "Instinct"`. No deck/banquinho da **lagoa do Instinto** (a roxa) |
| `FocusPond` / `InstinctPond` | (nenhuma) | Model com a água de cada lagoa, nomeado assim para o cliente achar (efeitos de treino) |
| `CameraShot` | (nenhuma) | Part invisível posicionada **no mesmo ângulo da imagem de referência**, olhando para o centro (o jogo usa para a câmera de chegada) |

Altura: o chão jogável da ilha perto de Y = 12. Posição do centro: **(520, 12, -380)** (confira se não encosta em nada; se encostar, mova e anote no Mural).

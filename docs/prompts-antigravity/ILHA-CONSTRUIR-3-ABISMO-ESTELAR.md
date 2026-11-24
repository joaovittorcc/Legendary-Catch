# Ilha de Treino 3: Abismo Estelar (x12, 100 milhões de Poder de Pesca): construir no Studio (Antigravity)

Um agente só para esta ilha. Os outros 3 agentes fazem as outras ilhas ao mesmo tempo.

## O que construir (fiel à imagem)

**Substitui** a ilha antiga `TrainingIsland_Abyss` (mesma posição). Antes de apagar a antiga, mova-a para `ServerStorage.Archive_OldIslands`.

Ilha mística **de noite** (mas colorida, nunca sombria). O céu noturno do jogo pode não estar ativo: faça a ilha "parecer noite" com materiais escuros e brilhos, sem mudar o `Lighting` global.
- **Base:** rocha **azul-escura/violeta** alta, grama azul-escura no topo, **cachoeiras de luz** azul-ciano caindo pelas bordas (2 a 3, peças Neon com transparência), muitos **cristais azuis** brilhando nas paredes e na borda, **fragmentos de rocha flutuando** em volta com cristais.
- **Portal (fundo, direita):** arco de **pedra escura com runas azuis** e um cristal grande no topo; dentro, **vórtice estrelado** azul-violeta girando.
- **Caminho:** pedras escuras com **runas azuis** brilhando + ponte de madeira escura com corda no meio.
- **Plataforma do observatório (fundo, centro):** círculo de pedra com degraus e um **telescópio dourado** apontando para o céu.
- **Lagoa do Foco (esquerda):** água escura **espelho com estrelas**, **2 anéis concêntricos** grandes de luz azul, **linhas de constelação** (peças Neon finas) ligando esferas-alvo flutuantes, **4 pilares de cristal** em volta com **feixes de luz** subindo bem alto. Deck de madeira escura com banquinho e barril, cristais pequenos no deck.
- **Lagoa do Instinto (direita):** água **roxa com galáxia em espiral** (Decal/textura ou anéis Neon), **peixes cósmicos** brilhando (dourado, arco-íris, nebulosa), **árvore de cristal violeta-rosa** com pétalas brilhando, vaga-lumes dourados, lanternas pequenas, monólitos com runas.
- **Props:** placas ornamentadas com peixe, postes com cristal na ponta, lua grande no céu é opcional (só se ficar leve, ex.: `BillboardGui` com imagem).

## Regras comuns (leia antes)

- Projeto: **Legendary Catch** (Roblox, pesca e coleção). Leia `AGENTS.md`, `docs/COORDENACAO.md` e `art/training/README.md` (o que já existe das ilhas antigas e dos portais).
- Fale com o João em português informal e curto. Nomes de objetos em inglês. **Não edite `src/**`** (código é do Claude e do Codex). Registre início e fim no Mural de `docs/COORDENACAO.md` (só adicionando no fim).
- **Referência visual obrigatória:** `art/concept/escolhidas/ilha-3-abismo-estelar.jpg`. Abra a imagem e copie com fidelidade: formato da ilha, posição de cada lagoa, portal, píer central, decks, árvores, cristais, cachoeiras, cores e iluminação. O objetivo é que um print do Studio no mesmo ângulo pareça essa imagem.
- **Studio compartilhado:** só um Studio (place `112666482424701`). Outros 3 agentes estão fazendo as outras ilhas ao mesmo tempo e o Claude também usa o Studio. Antes de mexer no Studio crie `.studio-lock` com `antigravity ilha-3 <hora>`; se já existir um lock de outro, **espere** (cheque a cada 2 min). Segure o lock no máximo ~15 min por vez, depois apague, deixe outro usar e volte. Escreva primeiro o builder (arquivo `.luau`) sem Studio, e só use o Studio para rodar o builder e conferir.
- **Builder:** `tools/TrainingIsland3Builder.luau`, no padrão de `tools/TrainingIslandsBuilder.luau` (função `build()` idempotente que apaga e recria o modelo). Assim dá pra reconstruir a ilha se o place perder algo.
- **Desempenho (celular):** até ~240 peças, poucas luzes (máx. 2 `PointLight`/`SpotLight`), até 4 `ParticleEmitter` leves (Rate baixo), MeshParts com `CollisionFidelity = Box`, `CastShadow = false` em decoração pequena. Água das lagoas: peças `Glass`/`SmoothPlastic` com transparência e cor (sem terreno). Sem scripts dentro do modelo (o servidor e o cliente cuidam da lógica). Rode `tools/ZFightFixer.luau` no fim.
- **Colisão:** piso, caminhos, píer e decks com `CanCollide = true`; decoração `CanCollide = false`. Nada bloqueando o caminho portal até lagoas.
- Ao terminar: `save_place`, print do mesmo ângulo da referência em `art/training/ilha-3.png` (se o print vier cinza, traga o Studio para frente), atualize `art/training/README.md` e escreva no Mural o que fez, contagem de peças e as posições das âncoras.

## Contrato com o servidor (não mude nomes)

Modelo `Workspace.TrainingIslands.TrainingIsland_Abyss` (crie a pasta `TrainingIslands` se não existir) com estes filhos diretos (Parts invisíveis `Transparency = 1`, ancoradas, `CanCollide = false`, ~4x1x4 studs):

| Nome | Tag (CollectionService) | Atributos |
|---|---|---|
| `ArrivalSpawn` | `ZoneSpawn` | `Destination = "training_3"` (string). Fica em frente ao portal, sobre o chão, virado para o centro da ilha |
| `ReturnPortal` | `ZonePortal` | `PortalId = "training_3_return"`, `ZoneId = "lagoon"`, `Destination = "main"`. Fica **dentro do arco do portal** da ilha (é o portal de volta para o hub) |
| `FocusSpot` | `TrainingSpot` | `TrainingIsland = 3` (number), `TrainingStat = "Control"`. No deck/banquinho da **lagoa do Foco** (a azul/clara), na beira da água |
| `InstinctSpot` | `TrainingSpot` | `TrainingIsland = 3` (number), `TrainingStat = "Instinct"`. No deck/banquinho da **lagoa do Instinto** (a roxa) |
| `FocusPond` / `InstinctPond` | (nenhuma) | Model com a água de cada lagoa, nomeado assim para o cliente achar (efeitos de treino) |
| `CameraShot` | (nenhuma) | Part invisível posicionada **no mesmo ângulo da imagem de referência**, olhando para o centro (o jogo usa para a câmera de chegada) |

Altura: o chão jogável da ilha perto de Y = 12. Posição do centro: **(-520, 12, 420)** (confira se não encosta em nada; se encostar, mova e anote no Mural).

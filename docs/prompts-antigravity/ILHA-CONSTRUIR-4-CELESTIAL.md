# Ilha de Treino 4: Celestial (x50, 1 trilhão de Poder de Pesca): construir no Studio (Antigravity)

Um agente só para esta ilha. Os outros 3 agentes fazem as outras ilhas ao mesmo tempo.

## O que construir (fiel à imagem)

**Substitui** a ilha antiga `TrainingIsland_Celestial` (mesma posição, no céu). Antes de apagar a antiga, mova-a para `ServerStorage.Archive_OldIslands`.

A ilha final, flutuando **acima de um mar de nuvens**, aurora pastel e raios de luz.
- **Base:** topo de grama verde com **borda de mármore branco e frisos dourados**, lateral de rocha clara com **cristais dourados e ciano** brilhando, **cachoeiras de luz** brancas caindo para as nuvens, **anel de luz dourado enorme** orbitando a ilha (peça Neon fina em anel, girando devagar pelo cliente: só construa o anel), 2 ilhotas pequenas flutuando com cristais.
- **Portal (fundo, centro):** arco de **mármore branco e ouro com asas** dos lados e cristal no topo; dentro, **redemoinho arco-íris** pastel. Caminho de **ladrilhos dourados** com runas + ponte de mármore com corrimão.
- **Lagoa do Foco (esquerda):** água **branca-aqua de luz líquida**, **anéis de luz dourados** empilhados, esferas douradas flutuantes ligadas por linhas finas (constelação), **pilares de cristal e ouro** com feixes de luz até o céu, deck de mármore com banquinho e **almofadas**, barril dourado, lanterna.
- **Lagoa do Instinto (direita):** água **roxa-rosa-dourada** com reflexos arco-íris, peixes lendários dourados e arco-íris, deck de mármore com banquinho, **árvore de flores rosa** com tronco dourado e **auréola de luz**, vaga-lumes dourados, lanternas, pedras com runas douradas.
- **Centro:** **monumento-coroa de cristal** dourada perto do caminho, estátua de peixe em mármore, **estandartes** brancos com frisos dourados, placas douradas com peixe.
- Ar celestial: penas e brilhos dourados (emissores leves).

## Regras comuns (leia antes)

- Projeto: **Legendary Catch** (Roblox, pesca e coleção). Leia `AGENTS.md`, `docs/COORDENACAO.md` e `art/training/README.md` (o que já existe das ilhas antigas e dos portais).
- Fale com o João em português informal e curto. Nomes de objetos em inglês. **Não edite `src/**`** (código é do Claude e do Codex). Registre início e fim no Mural de `docs/COORDENACAO.md` (só adicionando no fim).
- **Referência visual obrigatória:** `art/concept/escolhidas/ilha-4-celestial.jpg`. Abra a imagem e copie com fidelidade: formato da ilha, posição de cada lagoa, portal, píer central, decks, árvores, cristais, cachoeiras, cores e iluminação. O objetivo é que um print do Studio no mesmo ângulo pareça essa imagem.
- **Studio compartilhado:** só um Studio (place `112666482424701`). Outros 3 agentes estão fazendo as outras ilhas ao mesmo tempo e o Claude também usa o Studio. Antes de mexer no Studio crie `.studio-lock` com `antigravity ilha-4 <hora>`; se já existir um lock de outro, **espere** (cheque a cada 2 min). Segure o lock no máximo ~15 min por vez, depois apague, deixe outro usar e volte. Escreva primeiro o builder (arquivo `.luau`) sem Studio, e só use o Studio para rodar o builder e conferir.
- **Builder:** `tools/TrainingIsland4Builder.luau`, no padrão de `tools/TrainingIslandsBuilder.luau` (função `build()` idempotente que apaga e recria o modelo). Assim dá pra reconstruir a ilha se o place perder algo.
- **Desempenho (celular):** até ~250 peças, poucas luzes (máx. 2 `PointLight`/`SpotLight`), até 5 `ParticleEmitter` leves (Rate baixo), MeshParts com `CollisionFidelity = Box`, `CastShadow = false` em decoração pequena. Água das lagoas: peças `Glass`/`SmoothPlastic` com transparência e cor (sem terreno). Sem scripts dentro do modelo (o servidor e o cliente cuidam da lógica). Rode `tools/ZFightFixer.luau` no fim.
- **Colisão:** piso, caminhos, píer e decks com `CanCollide = true`; decoração `CanCollide = false`. Nada bloqueando o caminho portal até lagoas.
- Ao terminar: `save_place`, print do mesmo ângulo da referência em `art/training/ilha-4.png` (se o print vier cinza, traga o Studio para frente), atualize `art/training/README.md` e escreva no Mural o que fez, contagem de peças e as posições das âncoras.

## Contrato com o servidor (não mude nomes)

Modelo `Workspace.TrainingIslands.TrainingIsland_Celestial` (crie a pasta `TrainingIslands` se não existir) com estes filhos diretos (Parts invisíveis `Transparency = 1`, ancoradas, `CanCollide = false`, ~4x1x4 studs):

| Nome | Tag (CollectionService) | Atributos |
|---|---|---|
| `ArrivalSpawn` | `ZoneSpawn` | `Destination = "training_4"` (string). Fica em frente ao portal, sobre o chão, virado para o centro da ilha |
| `ReturnPortal` | `ZonePortal` | `PortalId = "training_4_return"`, `ZoneId = "lagoon"`, `Destination = "main"`. Fica **dentro do arco do portal** da ilha (é o portal de volta para o hub) |
| `FocusSpot` | `TrainingSpot` | `TrainingIsland = 4` (number), `TrainingStat = "Control"`. No deck/banquinho da **lagoa do Foco** (a azul/clara), na beira da água |
| `InstinctSpot` | `TrainingSpot` | `TrainingIsland = 4` (number), `TrainingStat = "Instinct"`. No deck/banquinho da **lagoa do Instinto** (a roxa) |
| `FocusPond` / `InstinctPond` | (nenhuma) | Model com a água de cada lagoa, nomeado assim para o cliente achar (efeitos de treino) |
| `CameraShot` | (nenhuma) | Part invisível posicionada **no mesmo ângulo da imagem de referência**, olhando para o centro (o jogo usa para a câmera de chegada) |

Altura: o chão jogável da ilha perto de Y = 160. Posição do centro: **(0, 160, -680)** (confira se não encosta em nada; se encostar, mova e anote no Mural).

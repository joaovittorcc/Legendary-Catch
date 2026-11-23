# Campo de treino (10 níveis) e ilhas de treino 2 a 4: para o Antigravity

Cole este arquivo inteiro numa conversa do Antigravity aberta na pasta do projeto (`C:\Users\Evojota\dev\jogo ainda sem nome`). Um agente só. **Não rode junto com os 4 lotes de criaturas** se eles estiverem usando o Studio ao mesmo tempo: use o `.studio-lock`.

## 1. Contexto

**Legendary Catch** (Roblox): pesca e coleção. O treino virou **Poder de Pesca** (1 a 1 quadrilhão). O jogador melhora o **campo de treino** em 10 níveis com moedas, e treina em **4 ilhas** (cada uma multiplica o ganho). Plano: `docs/PLANO-TREINO-PODER.md`. Contrato técnico: `docs/TREINO-PP-CONTRATO.md`.
Fale com o João em português informal e curto. Nomes de objetos em inglês. **Não edite `src/**`** (é do Claude e do Codex). Registre o que fizer no Mural de `docs/COORDENACAO.md` (só adicionando no fim).

Leia antes: `AGENTS.md`, `docs/COORDENACAO.md`, `docs/AQUARIO-ARTE-STATUS.md` (o aquário usou o mesmo tipo de kit por níveis), `tools/HubAquariumBuilder.luau` (exemplo de builder) e `tools/ZFightFixer.luau` (limpa faces sobrepostas).

## 2. Regra mais importante: o campo é visual de cada jogador

O nível do campo é **de cada jogador**, mas a lagoa é **compartilhada**. Por isso:

- O **ponto de treino** (`Workspace.Island.TrainingLagoon` e a peça com tag `TrainingSpot`) **continua como está**, no servidor. Não mova, não renomeie, não apague.
- Os 10 níveis são **camadas decorativas** guardadas em `ReplicatedStorage.TrainingLevels`. O cliente de cada jogador mostra só o nível dele em volta do ponto (o código disso é do Codex).
- Então: **nenhum script, nenhuma tag, nenhuma peça que o servidor precise**. Colisão só no piso (para andar em cima); o resto `CanCollide = false`.

## 3. Estrutura do kit

```
ReplicatedStorage.TrainingLevels (Folder)
  Levels (Folder)
    training_lv01 (Model)   atributo LevelIndex = 1
      TrainingOrigin (Part, invisível, ancorada)  = pivô; fica onde o TrainingSpot está hoje
      Anchors (Folder)
        InspectCamera (Part invisível)   câmera da "obra" ao comprar o nível
        UpgradeBoard (Part invisível)    onde a placa "Melhorar campo" aparece
        DecorAnchor_01..06 (Parts invisíveis)
      Layer_00_Floor (Model)   piso/deck do nível
      Layer_01_Structure (Model)
      Layer_02_Decor (Model)
      Layer_03_Light (Model)   luzes e emissores
    training_lv02 ... training_lv10
```

- Cada nível é **completo** (não soma com o anterior): o cliente troca um pelo outro.
- `TrainingOrigin` de todos os níveis no **mesmo CFrame**, alinhado ao `TrainingSpot` atual (`Workspace.Island.TrainingLagoon`, perto de `TrainingRing (-30, 10.3, -6)`). Meça no Studio e anote no Mural.
- O raio jogável cresce com o nível (o servidor usa 16 studs; vai até 28 no nível 10): mantenha o centro livre, nada no caminho do personagem até o ponto.
- Builder: `tools/TrainingFieldBuilder.luau` (crie, no padrão do `HubAquariumBuilder`), para reconstruir os 10 níveis se o place perder algo.

## 4. Os 10 níveis

Paleta da ilha: madeira quente, cristais ciano/azul, rosa/lilás, dourado, lanternas âmbar. **Cada nível precisa parecer claramente melhor que o anterior**, mesmo de longe (é o "tchan" da compra).

| Nv | Nome | O que tem (além do anterior, refeito melhor) | Orçamento |
|---|---|---|---|
| 1 | Clareira | Tapete de grama, uma boia de treino e um poste de madeira simples. Quase nada: é o ponto de partida. | ≤ 25 peças, 0 luz |
| 2 | Deck simples | Deck de tábuas pequeno, dois postes com corda, banquinho de madeira. | ≤ 50 |
| 3 | Cais de treino | Deck maior, 2 lanternas âmbar, barril de iscas, placa de madeira. | ≤ 80, 1 luz |
| 4 | Cercado de pedra | Muro baixo de pedras, bandeirolas coloridas, alvo flutuante na água. | ≤ 110, 1 luz |
| 5 | Torre pequena | Torre de vigia de madeira, cristais azuis nos cantos, plataforma elevada (degraus). | ≤ 140, 2 luzes, 1 emissor |
| 6 | Arena rúnica | Piso de pedra com runas Neon (ciano), anéis de cristal flutuando devagar. | ≤ 170, 2 luzes, 2 emissores |
| 7 | Jardim das fontes | Duas fontes de água luminosa, estátuas de peixe, flores rosa, aura suave. | ≤ 200, 2 luzes, 3 emissores |
| 8 | Arcos de cristal | Arcos de cristal em volta, pilares com chama azul (Neon + emissor), partículas leves. | ≤ 220, 2 luzes, 4 emissores |
| 9 | Plataforma flutuante | A arena sobe um pouco do chão (rochas flutuando embaixo), anéis orbitando, aurora ao fundo. | ≤ 240, 2 luzes, 5 emissores |
| 10 | Santuário do Pescador Lendário | Colunas douradas, coroa de cristal gigante no alto, raios de luz, piso arco-íris (gradiente em peças). | ≤ 250, 2 luzes, 5 emissores |

- Peças **leves** (é celular): prefira poucas peças maiores; MeshParts com `CollisionFidelity = Box`; `CastShadow = false` em decoração pequena.
- Movimento (anéis girando, chamas) é com emissores e partículas; o Codex anima o que precisar por código. Não use scripts.
- Rode `tools/ZFightFixer.luau` em cada nível (nenhuma face coplanar).
- Print de cada nível em `art/training/training_lvNN.png` (mesma câmera para os 10, para comparar).

## 5. Ilhas de treino 2 a 4

Cada ilha é um lugar **novo e longe do hub** (o mapa do hub é refeito por outra IA: **não mexa no hub**). Cada uma tem um ponto de treino próprio.

| Ilha | Multiplicador | Libera com Poder | Visual |
|---|---|---|---|
| 2. Ilha do Recife | x3 | 100 mil | Corais grandes, água rasa turquesa, tapetes de anêmona, conchas gigantes |
| 3. Ilha Abismo Estelar | x12 | 100 milhões | Rochas escuras, cristais azuis gigantes, céu de estrelas, névoa leve |
| 4. Ilha Celestial | x50 | 1 trilhão | Plataforma flutuante nas nuvens, aurora, anéis de luz, colunas brancas e douradas |

Em cada ilha:

- Uma peça ancorada com tag **`TrainingSpot`** e atributo **`TrainingIsland`** = 2, 3 ou 4 (número). É isso que o servidor lê para o multiplicador e para bloquear quem não tem Poder suficiente.
- Chegada pelo sistema de portais que já existe (`Tag = "ZonePortal"`, atributos `PortalId`, `Destination`; `Tag = "ZoneSpawn"` na chegada). Veja `docs/ILHA-VARREDURA.md` §3. Portal de ida no hub **e** de volta na ilha.
- `ModelStreamingMode = Persistent` só no ponto de treino e no spawn; o resto pode fazer streaming.
- Chão andável de verdade (teste com `Humanoid:MoveTo` do spawn até o ponto).
- O kit do campo (seção 3) também precisa caber em volta do ponto da ilha: deixe ~30 studs de raio livre e plano em volta do `TrainingSpot`.

## 6. Como trabalhar

1. Crie `.studio-lock` na raiz do repo antes de mexer no Studio; apague ao terminar cada sessão.
2. Faça o **nível 1, o 5 e o 10 primeiro** (o começo, o meio e o fim) e mande print ao João no Mural antes de fazer o resto.
3. `save_place` a cada 2 níveis ou a cada ilha. Anote a versão salva no Mural.
4. Depois os outros 7 níveis, e por último as 3 ilhas.

## 7. Critério de pronto

- 10 níveis em `ReplicatedStorage.TrainingLevels.Levels`, mesmo `TrainingOrigin`, âncoras completas, dentro do orçamento, sem z-fighting, sem scripts/tags.
- Diferença visual clara de um nível para o outro (prints lado a lado).
- 3 ilhas com `TrainingSpot` + `TrainingIsland`, portais de ida e volta testados em Play.
- `save_place` feito e Mural atualizado.

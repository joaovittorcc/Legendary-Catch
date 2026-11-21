# Comuns e Incomuns no gerador do Roblox Studio

[Prancha com quatro alternativas](native-mesh-preview.jpg) · [Criaturas de Natal](holiday-review.jpg) · [IDs dos modelos](ASSET_IDS.md) · [Fila de geração](JOBS.md) · [Direção de arte e segmentos](../../../../docs/creatures-native-mesh.md)

Os comparativos mostram o modelo do pool acima e o candidato do gerador abaixo. As malhas foram geradas no Studio. Nas alternativas preparadas, foram conservados os `MeshPart`s texturizados, removido o rig automático e ajustada a escala para 2,86 studs na maior dimensão. A cópia de trabalho fica em `ServerStorage.CodexNativeCreatureDrafts`.

| Prancha | Esquerda → direita |
| --- | --- |
| [1](compare-1.jpg) | C01, C03, C04 |
| [2](compare-2.jpg) | C05, C06, C11 |
| [3](compare-3.jpg) | C12, C13, C14 |
| [4](compare-4.jpg) | C15, C16, C25 |
| [5](compare-5.jpg) | C26, C38, C44 |
| [6](compare-6.jpg) | C02 |
| [7](compare-7.jpg) | C27, C31, C35 |
| [8](compare-8.jpg) | C36, C37, C39 |
| [9](compare-9.jpg) | C40, C41, C42 |
| [10](compare-10.jpg) | C43, C45, C46 |
| [11](compare-11.jpg) | C47, C48, C65 |
| [12](compare-12-front.jpg) | C49, C66, C67 |
| [13](compare-13.jpg) | C69 |
| [14](compare-14.jpg) | C68, C70, C71 |
| [15](compare-15.jpg) | C72, C73, C74 |
| [Natal](holiday-review.jpg) | C47, C101, C102 |

A C38 ficou sem expressão nas [quatro vistas](star-orientation.jpg). A C16 perdeu as asas do desenho, a C02 perdeu contraste frontal, a C44 ficou mais arredondada e a C47 ficou com o rosto pouco visível. Compare também as vistas usadas para corrigir a frente do [C49](octopus-yaw.jpg) e do [C66](urchin-yaw.jpg).

Na versão 66, as 43 alternativas foram salvas como rascunhos. Na versão 69 do place, as 43 entraram em `ReplicatedStorage.Creatures` e seus originais foram preservados em `ReplicatedStorage.CreaturesOld`. A checagem em Edit confirmou os 106 IDs do catálogo no pool e 362 carregamentos de conteúdo das novas malhas, sem falhas. No Play, os 106 passaram por `CreatureMotion` e 10 abriram o card de revelação com e sem `ReduceEffects`. A captura ponta a ponta, a Coleção, o celular real e o teste com dois jogadores ficaram pendentes.

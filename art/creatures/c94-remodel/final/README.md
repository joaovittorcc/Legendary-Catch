# C94 · Maré Primordial

A versão aprovada ganhou relevos dourados, olhos ciano, penas de água em camadas, espuma no disco e runas na espada. A variante sem espada tem os antebraços baixados e deixa a gema do cinto visível.

| Arquivo | Uso |
| --- | --- |
| `c94-tide-knight.blend` | Fonte editável com coleções de formas originais, malhas otimizadas, rig, câmeras e a ação `Tide_Guard_Loop` |
| `c94-tide-knight-armed.fbx` | 9 peças separadas e 5.916 triângulos |
| `c94-tide-knight-unarmed.fbx` | 8 peças separadas e 5.246 triângulos |
| `c94-tide-guard-animated.fbx` | Variante com espada, 8 ossos e ação gravada |
| `c94-tide-guard-preview.mp4` | Prévia do ciclo de guarda no Blender |
| `c94-color-atlas.png` | Atlas de cor de 512 × 512, embutido nos três FBXs |

O ciclo tem 5 segundos a 24 fps na fonte. O cavaleiro ergue a guarda com as duas mãos, abre as asas e retorna à pose inicial. O mesmo osso controla mão esquerda, mão direita e espada. Halo e disco completam uma volta no ciclo. O maior grupo tem 1.050 triângulos. A versão armada mede aproximadamente 5,54 × 3,42 × 2,23 studs no Studio (X × Y × Z).

## Instalação no Roblox

1. No Studio, use **Importar** e escolha um dos dois FBXs rígidos. Mantenha pivô na origem, escala original, **Ancorado** e as peças separadas dentro de um único Model. Para gerar IDs reutilizáveis, habilite o upload com o dono do jogo quando estiver pronto para integrar.
2. Use `PrepareTideKnight.luau` como ModuleScript temporário e chame a função exportada sobre o Model recém-importado. Ela valida a escala e a frente em +Z, marca `Body` como PrimaryPart, corrige `FinL`/`FinR` segundo a posição no Studio, desativa colisões e ajusta a transparência das asas e da onda. O halo vira uma segunda `Extra` identificada por atributo para acompanhar a cabeça. A espada continua separada.
3. A versão rígida é a base para o `CreatureMotion` atual. O ciclo completo é do rig separado. Para usar a coreografia completa no Roblox, importe a versão animada como **Custom**, mantenha os ossos com influência zero e importe a faixa FBX no Editor de Animação do mesmo rig. Valide enquadramento, compatibilidade com a revelação e o ID de animação publicado antes de trocar o modelo do jogo.
4. Na integração, guarde a C94 antiga fora do pool como `C94_Mare_Primordial_OLD` e confira pesca, card, Coleção, aura e ReduceEffects antes de salvar o place.

## Verificação

Reimportei os três FBXs no Blender. Confirmei UV única, atlas embutido, peças, contagem de triângulos e escala. No FBX animado, comparei as poses inicial, intermediária e final para confirmar a elevação da guarda, o movimento das asas e o retorno à pose. Importei o FBX rígido com espada em um place local e confirmei nove MeshParts com textura, frente +Z, altura e pivô. StyLua e Selene passaram com zero erros.

A versão com espada foi instalada no pool do place principal e a antiga foi movida para o backup. Os nove MeshParts e o atlas carregaram no teste. Em Play no PC, a chamada direta à cinemática mostrou a C94 de frente, com espada, asas e halo na cena e no card 3D. A pedido do João, a C94 fica com pose fixa durante a revelação, no card 3D e na Coleção. A cinemática mantém a câmera e os efeitos. A faixa de 5 segundos segue no FBX editável.

Ficaram sem teste a pesca completa, a Coleção, ReduceEffects, mobile, multiplayer e uma sessão no cliente publicado.

[Seis ângulos](../../../screens/c94-modelo/final-views.png) · [Comparativo](../../../screens/c94-modelo/final-comparison.png) · [Revelação no Studio](../../../screens/c94-modelo/studio-live.jpg) · [IDs dos assets](ASSET_IDS.md)

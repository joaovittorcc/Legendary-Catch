# Piloto das Lendárias

[Visão do lote](pilot.jpg) · [Auditoria das 18](../../../../docs/creatures-audit-lendarias.md) · [Kit do Blender](../../../../tools/blender/README.md)

| Modelo | Decisão visual | Malhas | Triângulos | Maior peça |
| --- | --- | --- | --- | --- |
| [C23 Kraken Trovejante](c23-before-after.jpg) | Oito tentáculos curvos, coroa de raios e cristais ciano ao longo do manto | 6 | 3.934 | Tentacles · 1.472 |
| [C64 Guardião Abissal](c64-before-after.jpg) | Escafandro de ferro e cobre, visor âmbar, lanterna de brasa e tubos dorsais | 9 | 5.068 | Body · 1.372 |
| [C100 Aurora Boreal Viva](c100-before-after.jpg) | Serpente de gelo com fitas de aurora, faixa estrelada e olhos rosa | 7 | 4.928 | Head · 1.476 |

Cada ID em `art/creatures/` tem script headless, fonte `.blend`, FBX, atlas procedural 1024 × 1024, relatório de triângulos por peça e seis renders. Os três FBXs passaram na reimportação no Blender 5.3 com nomes, escala, frente e atlas conferidos. A maior dimensão de cada modelo é 3,48 studs. O kit usa malhas rígidas separadas para os pontos móveis do CreatureMotion e permite marcar os detalhes Extra como Neon na preparação para o Studio.

Os comparativos acima registram a aprovação inicial. Os seis renders da versão polida estão em cada pasta `model/views/`.

## Publicação

Place `112666482424701` salvo na nuvem como v64 e publicado pelo Studio. Os modelos anteriores estão em `ReplicatedStorage.CreaturesOld`. A importação trouxe a frente para −Z e o giro de 180° no Model corrigiu a frente para +Z. As 22 malhas e os três atlas carregaram por MeshPart. Os IDs estão em cada pasta de criatura.

Em Play no PC, a chamada direta à revelação mostrou [Kraken](c23-studio.jpg), [Guardião](guardian-studio.jpg) e [Aurora com ReduceEffects](aurora-studio.jpg) na frente e no card. O card reenquadra quando o viewport recebe suas dimensões para a prévia estática sair visível. A [C94](mystic-studio.jpg) fica com pose fixa e mantém câmera e efeitos. O teste direto de CreatureMotion conferiu também o movimento de C01, C06 e C08. StyLua, Selene e Luau LSP passaram.

Ficaram sem teste a pesca completa, a tela da Coleção, o cliente publicado, celular real, dois jogadores e medição de FPS.

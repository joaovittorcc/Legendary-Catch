# Epic creature integration

[Frente das três criaturas no Studio](three-epics.jpg) · [IDs das malhas e dos atlas](ASSET_IDS.md)

Os modelos de C09, C20 e C84 saíram dos FBXs do Antigravity no commit `6bd763a`. O importador do Studio conservou as 22 peças e os três atlas. Corrigimos o giro de 180° para a frente ficar em +Z, aplicamos o pivô no Body e mantivemos 3,14 studs na maior dimensão. Os modelos anteriores ficam em `ReplicatedStorage.CreaturesOld`.

- Em Edit, os 44 carregamentos de conteúdo dos três modelos passaram.
- No Play em PC, a pescaria de teste chegou de arremesso a mordida, captura e revelação com a C72 e a C83. A Coleção exibiu a C72 com seis peças 3D. O resultado do minigame foi enviado pelo gancho de QA.
- Os cards dos três Épicos novos abriram no Play com e sem Reduzir efeitos. No iPhone 17 Pro simulado em retrato, a pescaria revelou a C56 e a Coleção exibiu a prévia 3D. O Studio voltou ao dispositivo padrão.
- O console registrou o aviso já conhecido do asset `203785492`. Celular físico, dois jogadores e captura no cliente Roblox publicado ficaram sem teste.

Place salvo na nuvem como v70. A publicação foi confirmada pelo Studio em 21/11/2026 às 19:07. Uma nova sessão aberta a partir da versão publicada confirmou os 106 modelos do catálogo, incluindo as 43 malhas de Comuns/Incomuns e os três Épicos recém-integrados.

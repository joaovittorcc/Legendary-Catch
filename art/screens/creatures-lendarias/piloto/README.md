# Piloto das Lendárias

[Visão do lote](pilot.jpg) · [Auditoria das 18](../../../../docs/creatures-audit-lendarias.md) · [Kit do Blender](../../../../tools/blender/README.md)

| Modelo | Decisão visual | Malhas | Triângulos | Maior peça |
| --- | --- | --- | --- | --- |
| [C23 Kraken Trovejante](c23-before-after.jpg) | Oito tentáculos curvos, olhos âmbar, coroa de raios ciano para o portal de tempestade | 6 | 3.778 | Tentacles · 1.472 |
| [C64 Guardião Abissal](c64-before-after.jpg) | Escafandro de ferro e cobre, visor âmbar, lanterna de brasa para o portal magma | 9 | 4.824 | Body · 1.372 |
| [C100 Aurora Boreal Viva](c100-before-after.jpg) | Serpente de gelo com fitas de aurora em camadas, escamas pintadas e olhos rosa | 7 | 4.928 | Head · 1.476 |

Cada ID em `art/creatures/` tem script headless, fonte `.blend`, FBX, atlas procedural 1024 × 1024, relatório de triângulos por peça e seis renders. Os três FBXs passaram na reimportação no Blender 5.3 com nomes, escala, frente e atlas conferidos. A maior dimensão de cada modelo é 3,48 studs. O kit usa malhas rígidas separadas para os pontos móveis do CreatureMotion e permite marcar os detalhes Extra como Neon na preparação para o Studio.

O piloto aguarda aprovação visual. A auditoria em Edit examinou os modelos do jogo e a cena temporária foi removida; os modelos novos seguem nos arquivos locais. QA de importação, pivô real no Studio, revelação, card, Coleção, CreatureMotion, aura, ReduceEffects, desempenho, regressão em três criaturas, celular real e dois jogadores ficam para a integração aprovada.

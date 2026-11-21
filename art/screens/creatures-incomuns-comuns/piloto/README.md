# Piloto de Comuns e Incomuns

[Auditoria do pool](../../../../docs/creatures-audit-incomuns-comuns.md) · [Kit do Blender](../../../../tools/blender/README.md) · [Prancha do lote](piloto.jpg)

| Criatura | Raridade | Triângulos | Maior peça | Malhas | Direção |
| --- | --- | ---: | ---: | ---: | --- |
| [C02 · Sardinha Solar](c02-antes-depois.jpg) | Comum | 564 | 164 | 6 | Corpo cor de mel, faixa ciano pintada e cauda mais aberta |
| [C12 · Camarão Confete](c12-antes-depois.jpg) | Comum | 580 | 140 | 6 | Corpo curvo, leque de três lóbulos e confetes pintados |
| [C38 · Estrela Sonolenta](c38-antes-depois.jpg) | Comum | 508 | 196 | 4 | Silhueta de cinco pontas, pálpebras pintadas e gorro azul |
| [C05 · Medusinha Estelar](c05-antes-depois.jpg) | Incomum | 782 | 280 | 5 | Domo arredondado com pontos de luz e tentáculos curvos |
| [C06 · Cavalo-Marinho Coral](c06-antes-depois.jpg) | Incomum | 798 | 230 | 6 | Crista de coral, focinho alongado e faixa rosa |
| [C15 · Tartaruga de Musgo](c15-antes-depois.jpg) | Incomum | 892 | 208 | 8 | Nadadeiras arredondadas, casco com manchas de musgo e uma flor rosa |

Os comparativos mostram o modelo atual do Studio e o piloto revisado. Os rostos passam a ser pintados no atlas, com área maior para as expressões vistas de frente. Isso liberou triângulos para modelar curvas, barbatanas e detalhes que identificam cada criatura.

Cada pasta de criatura tem seis renders, fonte `.blend`, FBX com atlas embutido e `mesh-report.json` com a contagem por peça. Os seis FBXs revisados foram reimportados no Blender 5.3 e passaram no check de frente, escala, orçamento, UV e atlas de 256 px.

O lote aguarda o OK visual do João. A integração, a pesca, o card em Play, a Coleção, o CreatureMotion, ReduceEffects, a regressão de três criaturas, desempenho, celular real e dois jogadores ficam para a etapa de importação.

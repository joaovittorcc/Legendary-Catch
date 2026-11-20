# C93 · Rosto e aura

Revisão do Ouroboros Cósmico com base na referência do João. O rosto mantém a expressão de chefão, com olhos estreitos, sobrancelhas integradas às escamas, focinho mais afilado, chifres dourados ramificados e barbatanas rosa com nervuras azuis.

- **Modelo editável:** `c93-ouroboros-final.blend`, com o ciclo de nado de 8 segundos e a câmera `Portrait Camera` para o enquadramento da referência.
- **Prévia:** `c93-face-and-aura.png` mostra os seis orbes, halos, rastros e arcos da aura.
- **Exportação:** `c93-ouroboros-rig.fbx` traz a pose base. `c93-ouroboros-swim.fbx` traz a faixa de nado. Ambos incluem o atlas de cor de 512 × 512 px.
- **Orçamento da criatura:** 5.990 triângulos (5.350 no corpo e 640 no cristal), 20 ossos e até duas influências por vértice.

O efeito está na coleção `Aura | Preview Only` do Blender. Os FBXs levam somente as duas malhas da criatura, o rig e, no arquivo animado, a faixa de nado. Na integração do Roblox, a aura pode usar seis orbes com rastros curtos em ciano, lilás, rosa e ouro. A posição dos orbes deve acompanhar o pivô da criatura e manter o rosto livre. Para o modo de efeitos reduzidos, o brilho fixo pode substituir os rastros e as faíscas.

Os dois FBXs foram reimportados no Blender para conferir a textura, as UVs, os pesos e a extensão do corpo durante o nado. A importação desta revisão e a aura ainda precisam ser validadas no Roblox Studio.

Para regenerar os FBXs, execute neste diretório:

```powershell
blender --background c93-ouroboros-final.blend --python-exit-code 1 --python ../c93-final/export_c93.py
```

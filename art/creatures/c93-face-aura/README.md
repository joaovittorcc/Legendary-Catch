# C93 · Pacote para Roblox

Revisão do Ouroboros Cósmico com base na referência do João. O rosto mantém a expressão de chefão, com olhos estreitos, sobrancelhas integradas às escamas, focinho mais afilado, chifres dourados ramificados e barbatanas rosa com nervuras azuis.

- **Modelo editável:** `c93-ouroboros-final.blend`, com o ciclo de nado de 8 segundos e a câmera `Portrait Camera` para o enquadramento da referência.
- **Prévias:** `c93-face-and-aura.png` mostra a direção de arte no Blender. `c93-studio-preview.jpg` mostra o FBX importado com a aura nativa no Play local.
- **Exportação:** `c93-ouroboros-rig.fbx` traz a pose base. `c93-ouroboros-swim.fbx` traz a faixa de nado. Ambos incluem o atlas de cor de 512 × 512 px.
- **Orçamento da criatura:** 5.990 triângulos (5.350 no corpo e 640 no cristal), 20 ossos e até duas influências por vértice.

## Importação

1. Importe `c93-ouroboros-rig.fbx` como **Custom**, com **Manter ossos de influência zero** ligado, escala original e pivô na origem da cena. O `Body` deve ter 3,50 studs de altura, a frente deve apontar para +Z e o rig deve ter 20 ossos, incluindo `Root` e `OrbitCore`. [Importador do Studio](https://create.roblox.com/docs/studio/importer)
2. Use `PrepareRig.luau` como um ModuleScript temporário. Chame a função retornada com o Model importado. Ela confere escala, sentido e ossos, torna `RootPart` a peça principal, remove colisões e prepara o `Animator`.
3. No Editor de Animação do rig, importe `c93-ouroboros-swim.fbx` como animação. Revise a faixa de 8 segundos e publique pelo mesmo dono ou grupo do jogo quando for integrar. [Animação de rigs personalizados](https://create.roblox.com/docs/resources/beyond-the-dark/custom-characters)
4. O cliente pode usar `CosmicOrbit.luau` como ModuleScript. Chame `CosmicOrbit.attach(model, reduceEffects)` na revelação em `Workspace` e execute o callback retornado ao sair. O modo normal usa seis orbes com rastros e o reduzido usa três orbes sem rastros. O efeito fica fora do Model para manter o enquadramento.

O FBX base foi importado no Studio com o upload desligado. Conferimos as duas malhas, a textura, a altura, os 20 ossos e a direção da cabeça. No Play local, a aura orbitou, alternou para o modo reduzido e foi removida sem mudar o bounding box da criatura. A faixa de nado foi conferida por reimportação no Blender. A reprodução da faixa publicada e a integração no fluxo de captura ainda precisam de validação no jogo.

O efeito de arte do Blender fica na coleção `Aura | Preview Only`. O FBX vai com duas malhas, atlas e rig. O brilho em jogo é construído pelo módulo do Roblox.

Para regenerar os FBXs, execute neste diretório:

```powershell
blender --background c93-ouroboros-final.blend --python-exit-code 1 --python ../c93-final/export_c93.py
```

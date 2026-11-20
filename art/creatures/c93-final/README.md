# C93 · Ouroboros Cósmico

Modelo de chefão para **Legendary Catch**. A nova cabeça tem olhos âmbar, sobrancelhas anguladas, presas e chifres dourados. Cristais rosa e ciano marcam as barbatanas e as escamas em relevo dão leitura ao dorso.

## Arquivos

| Arquivo | Uso |
| --- | --- |
| `c93-ouroboros-final.blend` | Fonte editável, com rig, materiais, luzes e ação `Swim_Uncoil_Loop` |
| `c93-swim-preview.mp4` | Prévia do movimento renderizada no Blender |
| `c93-face.png`, `c93-coiled.png`, `c93-swimming.png` | Rosto e duas poses da animação |
| `c93-ouroboros-rig.fbx` | Malha e rig na pose base |
| `c93-ouroboros-swim.fbx` | Mesmo rig com um ciclo de nado gravado |
| `c93-color-atlas.png` | Atlas de cor, também embutido nos FBXs |

## Modelo e animação

- **5.814 triângulos:** 5.174 em `Body` e 640 em `Core`. O corpo usa uma superfície contínua da nuca à cauda.
- **20 ossos:** 18 de coluna, 1 de cristal e 1 raiz sem influência na malha. Cada vértice tem até 2 influências.
- **1 atlas de cor com 512 × 512 px** para as duas malhas. Os materiais do Blender usam brilho e metalicidade para o render. O FBX leva o atlas de cor e o material compartilhado.
- **Ciclo de 8 segundos**, frames 1 a 161 a 20 fps. O último repete a pose do primeiro. O corpo abre o anel, nada em S e volta a se enrolar.
- **Escala alvo:** 3,5 unidades de altura no Blender em repouso. A animação estendida precisa de mais espaço no enquadramento.

## Integração no Studio

1. Importe o FBX do rig num place de teste. Confira as duas malhas, a textura, a altura em studs e o sentido do rosto (+Z no jogo) no importador.
2. Use o FBX animado no Editor de Animação com o mesmo esqueleto. Valide as poses inicial, estendida e final antes de publicar o asset de animação.
3. A revelação atual usa peças rígidas com movimento procedural. A versão com ossos precisa tocar a faixa no rig e ser conferida na revelação, no card e na Coleção. O projeto e a criatura em produção seguem com o asset anterior.

Os dois FBXs foram reimportados no Blender 5.3. A reimportação preservou as 2 malhas, os 20 ossos, as UVs, a textura embutida e a ação. No FBX animado, a dimensão máxima no meio do ciclo ficou cerca de 2 vezes maior que na pose enrolada. A importação e a reprodução dentro do Roblox ainda precisam ser validadas.

Para regenerar os FBXs no mesmo diretório:

```powershell
blender --background c93-ouroboros-final.blend --python-exit-code 1 --python export_c93.py
```

Referência de exportação: [Roblox Creator Hub](https://create.roblox.com/docs/art/modeling/export-requirements).

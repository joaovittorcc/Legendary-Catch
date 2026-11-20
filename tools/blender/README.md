# Legendary Catch · Kit Blender

Blender 4.2 ou mais novo, executado em segundo plano. Os scripts usam o Python do Blender. O piloto foi conferido na versão 5.3.

1. Copie `build_template.py` para `art/creatures/<ID>/build_<id>.py`. Use o ID e a raridade do Config. Separe as formas em peças com os mesmos nomes que o CreatureMotion lê. Modele com frente Blender `-Y`, topo `+Z` e `FinL` em `+X`.
2. Rode a partir da raiz, com `$blender` apontando para o executável. O script grava `.blend`, FBX rígido com atlas embutido, atlas PNG, relatório JSON e seis vistas em `model/` daquele ID. Passe `--no-render` para iterar rapidamente na geometria.

```powershell
& $blender -b --factory-startup --python-exit-code 1 -P art/creatures/<ID>/build_<id>.py
& $blender -b --factory-startup --python-exit-code 1 -P tools/blender/check_creature.py -- art/creatures/<ID>/model/<ID>.fbx <ID> Legendary
```

`export_creature.py` também exporta um `.blend` já pronto. `preview_creature.py` gera as vistas de um `.blend` em uma pasta de escolha. Ambos aceitam argumentos após `--`. `check_creature.py` valida `.blend` ou FBX, com opção `--report <arquivo.json>`. Ele verifica malhas diretas, frente, nomes, escala, UV, atlas, rig e triângulos. O orçamento é de 2.500/800 triângulos para Épica e 6.000/1.500 para Lendária (total/peça).

## Conferência no Studio depois da aprovação

- Em um place de teste, use **File → Import 3D**, Scale Unit **Studs**, peças separadas em um único Model. Faça a primeira importação com upload desligado. Para a integração aprovada, selecione o dono do jogo e ligue o upload.
- Execute o ModuleScript temporário `ImportCreature.luau` sobre a importação em Edit, passando modelo, ID, raridade e `true` opcional somente se todas as peças Extra devem ser Neon. O helper valida frente `+Z`, envergadura e nomes, posiciona o pivô do Body no centro e aplica as flags de colisão. Mantenha o MeshPart na orientação original da importação antes de chamar o helper.
- Só após a validação, mova o modelo antigo para `ReplicatedStorage.CreaturesOld.<id>`, ponha o novo em `ReplicatedStorage.Creatures.<id>` e registre os IDs de mesh e atlas. Confira revelação, card, Coleção, movimento, aura e ReduceEffects em Play e siga as regras de lock e save do projeto.

Método de silhueta, blocos de forma, atlas e validação baseado no vault fwjelaa. Geometria e pintura do piloto são próprias.

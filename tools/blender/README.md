# Legendary Catch · Kit Blender

Blender 4.2 ou mais novo, executado em segundo plano. Os scripts usam o Python do Blender. O piloto foi conferido na versão 5.3.

1. Copie `build_template.py` para `art/creatures/<ID>/build_<id>.py`. Use o ID e a raridade do Config. Separe as formas em peças com os mesmos nomes que o CreatureMotion lê. Modele com frente Blender `-Y`, topo `+Z` e `FinL` em `+X`.
2. Rode a partir da raiz, com `$blender` apontando para o executável. O script grava `.blend`, FBX rígido com atlas embutido, atlas PNG, relatório JSON e seis vistas em `model/` daquele ID. Passe `--no-render` para iterar rapidamente na geometria.

```powershell
& $blender -b --factory-startup --python-exit-code 1 -P art/creatures/<ID>/build_<id>.py
& $blender -b --factory-startup --python-exit-code 1 -P tools/blender/check_creature.py -- art/creatures/<ID>/model/<ID>.fbx <ID> Legendary
```

`export_creature.py` também exporta um `.blend` já pronto. `preview_creature.py` gera as vistas de um `.blend` em uma pasta de escolha. Ambos aceitam argumentos após `--`. `check_creature.py` valida `.blend` ou FBX, com opção `--report <arquivo.json>`. Ele verifica malhas diretas, frente, nomes, escala, UV, atlas, rig e triângulos. O orçamento é de 2.500/800 triângulos para Épica e 6.000/1.500 para Lendária (total/peça).

## Comuns e Incomuns

Passe os arquivos `art/creatures/<ID>/creature.json` ao script de lote. Cada ficha define ID, raridade, família e cores. `lib_creatures.py` reaproveita olhos, curvas, nadadeiras e silhuetas das famílias, com ajustes como `width`, `height`, `arms` ou `sleepy` conforme a anatomia. O lote gera fonte, FBX, atlas de 256 px, seis vistas e relatório por ID. O limite é 600/200 triângulos para Comum e 900/300 para Incomum (total/peça).

As fichas revisadas do piloto trazem `finish` com os tons e padrões para peixe, camarão, estrela, medusa, cavalo-marinho ou tartaruga. Uma área maior do atlas recebe os olhos e a expressão na metade frontal da cabeça.

```powershell
& $blender -b --factory-startup --python-exit-code 1 -P tools/blender/build_creatures.py -- art/creatures/C02_Sardinha_Solar/creature.json art/creatures/C05_Medusinha_Estelar/creature.json
```

## Conferência no Studio depois da aprovação

- Em um place de teste, use **File → Import 3D**, Scale Unit **Studs**, peças separadas em um único Model. Faça a primeira importação com upload desligado. Para a integração aprovada, selecione o dono do jogo e ligue o upload.
- Confira a orientação no Studio. O perfil padrão do importador trouxe os FBXs do piloto com frente `-Z`. Nesse caso, gire o Model inteiro 180° em Y antes de preparar. Execute o ModuleScript temporário `ImportCreature.luau` sobre a importação em Edit, passando modelo, ID, raridade e `true` opcional somente se todas as peças Extra devem ser Neon. O helper valida frente `+Z`, envergadura e nomes, posiciona o pivô do Body no centro e aplica as flags de colisão.
- Só após a validação, mova o modelo antigo para `ReplicatedStorage.CreaturesOld.<id>`, ponha o novo em `ReplicatedStorage.Creatures.<id>` e registre os IDs de mesh e atlas. Confira revelação, card, Coleção, movimento, aura e ReduceEffects em Play e siga as regras de lock e save do projeto.

Método de silhueta, blocos de forma, atlas e validação baseado no vault fwjelaa. Geometria e pintura do piloto são próprias.

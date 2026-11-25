# Hub (versão do Claude, v1) comparado com as 5 referências novas

Referências em `art/concept/hub-v2/` (ref-1 a ref-5). Prints do estado atual em `art/preview/hub-claude/` (claude-1, claude-2, claude-v1-3, claude-v1-4, claude-v1-5). Base escolhida: `tools/HubBuilder_claude.luau` (hub em `(-700, 0, 700)`). A versão do ChatGPT foi apagada.
Nota: as referências são geradas por IA e têm erros (textos tortos nas placas, "Legendary Goloh"). Vale o conceito, não o texto.

## 1. Luz estourada (pedido principal)
Causas encontradas:
1. **Pedra quase branca em superfícies enormes.** `stone` (226,220,212), `stoneWarm` (236,226,214), `sandPart` (240,222,182) e `white` (250,250,250) cobrem praça, escadaria, plataforma do cais e degraus. Com `Brightness 3`, `ClockTime 14.2` e sol alto, tudo estoura para branco e perde a textura de laje. Na referência a pedra é **rosada-lilás/cinza-quente (≈ 200,178,176) com junta escura e variação**, e a praça tem tom de pêssego, nunca branco.
2. **Feixes de luz de Neon enormes.** `LightBeam` e `LightBeamCore`: cilindros de Neon de 60 studs de altura sobre os portais do cais (e um sobre o portal do Aprendiz). Na referência os feixes são **rosa e azul suaves, curtos (~15 a 25 studs), translúcidos e finos**, só nos 2 portais de pesca; os de treino têm leques de raios pastel discretos.
3. **Bloom 0,65 + SunRays + Atmosphere** do place (valores atuais: Brightness 3, Exposure -0,1, Bloom 0,65). Para a V2/prints: Bloom ~0,3, Exposure -0,2, Brightness 2,4, sol mais baixo (`ClockTime` ≈ 11,5 a 12) para dar sombra e relevo. (O Lighting é global do jogo: só mudar com a sua aprovação, ou deixar numa função de prints.)
4. **Areia branca** (terreno Sand 232,214,172 mais peças). A referência quase não tem praia: a ilha é rocha e pedra, com grama só em manchas.
5. **Neon demais** em runas, aros e linhas (cianos chapados). Na referência as runas são finas e brilham em ciano só no traço, sobre pedra escura.
**Correção da V2:** escurecer e esquentar a pedra (3 a 4 tons com variação por laje), tirar `white` de superfícies grandes, reduzir os feixes (altura, largura, transparência 0,9), `Transparency` maior nos Neon grandes, e criar uma `applyReferenceLighting()` mais baixa para prints.

## 2. Forma da ilha e rocha
- **Referência:** ilha de **rocha cinza-azulada em camadas**, paredes verticais, patamares, cristais grandes encravados (azul, rosa, lilás) e **pouca areia**. O Santuário é um platô de pedra **alto e redondo** com árvore rosa gigante ao lado e uma "ilha de grama" menor separada embaixo à esquerda.
- **Atual:** ilha verde arredondada, **muita praia de areia** na frente e dos lados, rochas pequenas e objetos verdes soltos no mar, colina verde atrás da oficina com palmeiras demais.
- **V2:** trocar a praia por **rocha em camadas**, reduzir a areia a duas faixas pequenas, remover os rochedos e objetos soltos no mar, colocar cristais grandes na falésia, e fechar a ilha como um bloco de rocha afinando para baixo.

## 3. Praça e escadaria de entrada
- **Referência:** praça de **pedra rosada ampla**, com **fogueira em plataforma de madeira** com bancos e tocos à esquerda, cristal central em pedestal de pedra, canteiros, fios de bandeirolas, lanternas âmbar e um **grande arco de madeira** no pé da escada.
- **Atual:** praça com **grama no meio** e uma fonte de cristal; falta o deck da fogueira com bancos, as bandeirolas e os canteiros.
- **V2:** praça **toda de pedra**, deck da fogueira com bancos e tocos junto da escada do santuário, canteiros e bandeirolas.

## 4. Santuário do Treino
- **Referência (ref-1 e ref-2):** **portão de pedra e madeira** "SANTUÁRIO DO TREINO" (pilares de blocos de pedra com lanternas, viga de madeira, placa grande com haltere e cristal, bandeirolas) no pé de uma **escada larga com runas ciano no meio**, e **caminho de runas ciano no chão** vindo da praça. Em cima, platô redondo com **círculo de runas concêntrico** e **4 portais em semicírculo**.
- **Atual:** escada branca com lanternas amarelas, sem portão, sem caminho de runas, portais numa plataforma gramada, pedra clara demais.
- **V2:** portão completo, caminho de runas no piso (traço fino ciano sobre pedra escura), escada com runas no meio, platô de pedra com círculo de runas e 4 portais mais ornamentados:
  - Aprendiz: arco de pedra cinza com viga de madeira e espiral ciano.
  - Recife: arco turquesa com **corais rosa e laranja**.
  - Abismo Estelar: arco **escuro cravejado de cristais roxos**, interior rosa-lilás.
  - Celestial: arco **dourado**, interior branco-amarelo com **leque de raios pastel**.

## 5. Portal do Aprendiz e a lagoa (ref-5)
- **Referência:** portal de **pedra cinza em blocos grandes** com viga de madeira e **espiral branco-ciano forte**, numa pequena plataforma de madeira com corrimão e degraus de pedra, **de frente para a praça**; cachoeira de verdade (branca, translúcida, com espuma e névoa) caindo de um bloco de rocha com musgo, **ponte de madeira curva com lanternas e cordas** cruzando a lagoa turquesa, vitórias-régias, samambaias, cristais, placa "ILHA DO APRENDIZ · Grátis" e placa direcional grande na praça.
- **Atual:** portal de pedra **branca/gelo** lavada, pilar largo sem blocos visíveis, **cachoeira como duas faixas retas coladas ao portal**, e o portal parcialmente escondido atrás de uma palmeira gigante em primeiro plano.
- **V2:** portal de pedra cinza real com juntas, viga de madeira escura, espiral mais denso; cachoeira **separada**, caindo da rocha à direita do portal com espuma e névoa; ponte curva com lanternas; **remover a palmeira da frente**; placa direcional grande na praça.

## 6. Cais das Expedições e Píer de Pesca (ref-3)
- **Referência:** **pórtico de madeira grosso** com cordas e lanternas e placa "PÍER DE PESCA" com anzol, no começo do píer; os 2 portais de pesca numa **plataforma de pedra com degraus**, o do Recife como **concha/anel de coral rosa-pêssego** e o do Abismo como **arco azul alto e estreito** com cristal e hexágono rosa; **feixes de luz rosa e azul finos**; no fim do píer, **2 pedestais com cristais**, boias, barris e redes.
- **Atual:** plataforma branca grande e vazia, portais com **feixes enormes**, 2 bases "EM BREVE" vazias (boa ideia, manter) e poucos props; o píer tem bandeirolas e lanternas (bom).
- **V2:** plataforma do cais mais baixa e de pedra mais escura, portais com mais volume, feixes finos e curtos, pórtico mais robusto, mais props.

## 7. Oficina de Varas
- **Referência:** casa grande, telhado azul em camadas, **vigas redondas grossas**, losangos de cristal azul nas colunas, balcão com frascos e cristal, escada de pedra, **palmeiras dos dois lados** e cristais grandes atrás.
- **Atual:** no caminho certo (telhado azul listrado, bandeirolas). Falta peso nas vigas, os losangos de cristal e os cristais grandes ao redor.

## 8. Palmeiras, árvore, cristais, placares
- **Palmeiras:** folhas de blocos retos em "guarda-chuva"; a referência tem folhas **arqueadas e roliças** (3 tons). Há palmeiras demais (cerca de 15); a referência tem 3 a 4 bem escolhidas.
- **Árvore rosa:** na referência é enorme, tronco torcido e copa de pétalas em camadas; no atual é uma copa pequena de bolhas.
- **Cristais:** a referência usa **tufos grandes** (azul-gelo, rosa e lilás) encravados na rocha; o atual tem poucos e pequenos.
- **Placares:** inclinados e pequenos no mar; devem ficar de frente para a praça.
- **Objetos soltos no mar:** pelo menos 4 rochas e 2 objetos verdes fora da ilha. Remover.

## 9. O que está BOM e deve ser mantido
Composição geral e contrato com o servidor, o píer curvo com bandeirolas, o aquário, a oficina, as bases "EM BREVE" no cais, a escadaria de entrada e as placas direcionais (ótimas para o tutorial).

## 10. Falhas do `selfTest` (13) a resolver na V2
- Terreno sob a praça em Y 10,3 a 10,5 (limite 9,05): o piso fica em 10,3, mas conferir se há terreno por cima dele.
- Terreno sob o terraço da oficina em Y 14,8 (limite 13,5): passa do piso do terraço (14,3). Abaixar para ≤ 14,0.
- Terreno na escadaria em Y 2 (esperado ≤ 0): a vala da escada precisa descer até a água.

## 11. Ordem proposta para a V2
1. Luz: pedra mais escura e rosada, tirar `white`, reduzir feixes, preset de prints mais baixo.
2. Silhueta: rocha em camadas, menos areia, limpar objetos soltos no mar.
3. Praça: sem grama no centro, deck da fogueira, canteiros e bandeirolas.
4. Santuário: portão, caminho de runas, escada de runas, 4 portais ornamentados.
5. Portal do Aprendiz, cachoeira separada, ponte curva, remover a palmeira da frente.
6. Cais: pórtico, plataforma de pedra, portais de pesca com volume e feixes finos, props.
7. Palmeiras (menos e melhores), cristais em tufos, árvore rosa grande.
8. Corrigir as 3 falhas do `selfTest`. Depois, o Antigravity faz o acabamento final.

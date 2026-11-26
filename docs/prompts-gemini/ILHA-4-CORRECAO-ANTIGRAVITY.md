# Ilha 4 (Celestial): rodada de correção

O polimento do commit `fcacddd` melhorou muito, mas **ainda não está igual à referência** e a condição de parada não foi cumprida: o relatório não trouxe a tabela de notas (mínimo 9 em cada item). Continue de onde parou.

**Releia antes:** `docs/prompts-gemini/ILHA-4-POLIMENTO-ANTIGRAVITY.md`. Todas as regras dele continuam valendo (contrato, caminhos sem pulo, tags de animação, teto de 9.000 peças, não tocar em `src/` nem no `Lighting`, não subir assets sem perguntar, `.studio-lock`).
**Olhe lado a lado:** `art/preview/ilha-4/referencia.jpg` e `art/preview/ilha-4/novo-1..5-*.jpg` (como está agora).

**Mantenha o que ficou bom:** portal, asas e redemoinho; layout geral; frisos na borda; tamanho da árvore; coroa de cristal; placas e pilares.

## O que corrigir, em ordem de importância

1. **Rocha de baixo (o pior item).** Hoje é uma pilha de caixas e lascas chapadas, com faces se atravessando. Na referência é uma massa **contínua, cheia e arredondada**: poucos blocos grandes e "gordinhos" que se encaixam (elipsoides achatados e cunhas combinadas), com sulcos entre eles, tom marrom-acinzentado **quente**, mais clara no alto e mais escura na ponta, afinando suave. Nada de placa fina espetada. **Os cristais parecem setas:** faça tufos de prismas hexagonais pontudos e grossos, saindo de uma base comum, de comprimentos diferentes, inclinados poucos graus entre si, encravados na rocha, com brilho dourado ou ciano contido.
2. **Cores estouradas.** Grama parece neon, frisos e anéis são amarelo puro. A referência é **mais suave e quente**. Meça as cores na própria imagem de referência e aproxime: grama oliva-viva (não verde-limão), ouro âmbar fosco (`SmoothPlastic` com `Color3` de ouro, **Neon só em fios finos**), mármore creme, ciano claro. Corte o Neon grande. Compare sempre com a **iluminação normal do jogo**, que é bem forte: use cores mais escuras do que parecem certas no seletor.
3. **Cachoeiras.** Ainda são faixas brancas sólidas e retas. Precisam ler como água: várias fitas finas de larguras diferentes, com transparência alta e **variada ao longo da queda** (mais opaca na boca, sumindo embaixo), curvando para fora ao sair da borda, com espuma no lábio e brilhos no fim. Se usar `Beam`, use `Transparency` em `NumberSequence` e curva (`CurveSize0/1`).
4. **Nuvens.** Parecem discos achatados empilhados, iguais entre si. Faça cúmulos: grupos de esferas de **tamanhos bem diferentes**, sobrepostas, base mais achatada e topo em bolhas, com 3 ou 4 tons (creme, rosa, lilás, azul-sombra). Menos nuvens grandes perto da ilha e espaços entre os grupos; elas são o fundo, não podem competir.
5. **Lagoa do Instinto.** Os peixes parecem de brinquedo (ovos com listras). Na referência são **silhuetas esguias de peixe/tubarão que brilham sob a água** (dourado, rosa-lilás, arco-íris): corpo afilado em vários segmentos, cauda em V, nadadeira dorsal. A água precisa de reflexos: manchas e curvas translúcidas roxo, rosa, dourado e verde-água, no lugar de anéis concêntricos perfeitos. **Mantenha** os Models `LegendaryFish1..4` com `PrimaryPart` e os atributos `OrbitRadius`, `OrbitSpeed`, `OrbitPhase`, `DepthY`, `OrbitCenter`.
6. **Lagoa do Foco e anel externo:** anéis e linhas mais finos e delicados (hoje são tubos amarelos grossos); água com mais profundidade (centro mais claro, borda mais escura). O anel que cerca a ilha deve ser fino, creme-dourado e translúcido, sem cortar a visão da ilha.

## Condição para parar (obrigatória)
Ciclo: reconstruir, tirar print do **mesmo ângulo da referência** (`CameraShot`) e de cada região, comparar, dar nota, corrigir. **Só pare com todos os itens da lista do prompt anterior em 9 ou 10**, `selfTest()` com 0 falhas e Play sem erros. Se uma técnica não melhorar em 2 tentativas, **troque de técnica**. Se algo for impossível no Roblox, mostre o print e explique; "ficou difícil" não é impossível.

## Entrega
No Mural (`docs/COORDENACAO.md`) escreva **a tabela de notas completa**, item por item, antes e depois. Salve os prints finais em `art/preview/ilha-4/final-*.jpg` (todos tirados **depois** do último ajuste no código). Salve o place fora do Play, faça commit só dos seus arquivos e libere o `.studio-lock`.

Antes de usar o Studio, confirme que ele está aberto no place **Legendary Catch** e que o Rojo está conectado (porta 34873). Se não estiver, peça para o João ou avise no Mural.

# Ilha Celestial: conceitos da ilha (4 imagens)

**Agente 3 de 3.** Cole este arquivo inteiro numa conversa do Antigravity aberta na pasta do projeto (`C:\Users\Evojota\dev\jogo ainda sem nome`). Existem 3 prompts parecidos (um por ilha); cada agente cuida só da sua ilha.

## 0. O que você vai fazer (e o que NÃO vai fazer)

Você vai **imaginar e desenhar esta ilha**: gerar **4 imagens de conceito**, cada uma mostrando uma versão diferente de como você construiria a ilha, com um texto curto explicando cada uma. O João vai olhar as 4, **escolher uma** e só então você constrói a ilha de verdade no Studio.

- **Não abra o Studio, não crie `.studio-lock`, não mexa no place, no mapa do hub nem em `src/**`.** Esta etapa é só arte de conceito e texto.
- Antes de começar, leia `AGENTS.md` (contexto do time), `docs/COORDENACAO.md` (Mural no fim) e `art/training/README.md` (o que já existe).
- Fale com o João em português informal e curto.

## 1. O jogo em 30 segundos

**Legendary Catch** é um jogo de pesca e coleção no Roblox: uma ilha-hub mágica e compacta (cristais azuis, árvore rosa, píer de madeira, lanternas âmbar) num oceano enorme. O jogador pesca criaturas fantásticas, coleciona e **treina** para ficar mais forte. Público inclui crianças: nada sombrio demais, nada agressivo. Mobile primeiro (celular) e também PC.

**Direção visual:** aventura Roblox estilizada **premium**, cores vivas, cristais ciano e azuis brilhantes, rosa e lilás, dourado, madeira quente, lanternas âmbar. Formas arredondadas e legíveis, silhueta forte. Nada de cinza genérico, nada de aspecto "low effort". Pense em ilustração de jogo mobile bem acabada.

## 2. O treino e por que existem as ilhas de treino

O jogador tem um número, o **Poder de Pesca**, que sobe sem parar enquanto ele fica **parado treinando** num ponto (`TrainingSpot`), olhando a ilha. Quanto mais forte, mais rápido o Poder cresce. Para ganhar mais Poder por segundo ele melhora o **campo de treino** (10 níveis de plataforma, de uma clareira simples até um santuário dourado) e viaja para **ilhas de treino** cada vez melhores, cada uma multiplica o ganho:

| Ilha | Multiplicador | Libera com Poder | Onde fica |
|---|---|---|---|
| Lagoa (hub) | x1 | já liberada | no hub |
| Recife | x3 | 100 mil | `TrainingIsland_Reef`, `(480, 12, 420)` |
| Abismo Estelar | x12 | 100 milhões | `TrainingIsland_Abyss`, `(-520, 12, 420)` |
| Celestial | x50 | 1 trilhão | `TrainingIsland_Celestial`, `(0, 160, -680)` |

**Cada ilha precisa dar a sensação de "cheguei num lugar mais poderoso"**: o jogador passa **horas** em pé nesse ponto, então a ilha precisa ser linda de ficar olhando, com vida e movimento (água, luz, partículas), sem poluir a tela.

## 3. O que existe hoje (e por que está "incompleto")

O Antigravity já gerou uma versão **básica** de cada ilha (`tools/TrainingIslandsBuilder.luau`): um platô plano de ~34 studs de raio com ~120 a ~180 peças, o ponto de treino, o spawn de chegada e portais de ida e volta. Funciona (anda, teleporta, multiplicador certo), mas está **vazia e pouco marcante**: não tem identidade, marco, história, nem a sensação de lugar. **Você vai redesenhar a ilha inteira** com personalidade. O que já existe pode ser reaproveitado ou jogado fora.

### O que NÃO pode mudar (regras técnicas para a construção que virá depois)
- Um ponto de treino plano, andável, no **centro**, com **~34 studs de raio livre e plano** em volta (o campo de treino de 10 níveis é desenhado em cima dele e chega a ~50 studs de largura; as 3 ilhas usam o mesmo kit).
- Um **spawn de chegada** perto do ponto e um **portal de volta** ao hub.
- Atributo `TrainingIsland` (2, 3 ou 4) e tag `TrainingSpot` no ponto de treino (já existem).
- O hub (`Workspace.Island`) **não** é tocado.
- Orçamento da construção (para celular): até **~450 peças** visíveis, até **6 luzes**, até **8 emissores de partículas**, `CastShadow = false` em detalhe pequeno, sem face coplanar (z-fighting), nada de scripts nas peças. A ilha pode usar terreno do Roblox (Terrain) para água e rochas.

## 4. A ilha: Celestial (multiplicador x50, a ilha mais alta)

### A história (para você entender o lugar)
No topo do mundo, acima de todas as nuvens, existe um **terraço flutuante** onde, segundo as lendas, **o Pescador Lendário treinou antes de ser lendário**. É a **Ilha Celestial**: um pedaço de terra branca e dourada que flutua sobre um **mar de nuvens**, tocado por uma **aurora** que nunca termina. Dizem que as **criaturas místicas** nadam no ar daqui, **peixes de nuvem e baleias de estrelas** passam devagar, e que quem chega ao terraço **já pesca com as mãos do céu**.

A Celestial é o **destino final do treino**: é a ilha mais **grandiosa, luminosa e serena**. Quando o jogador chega aqui, ele sabe que está perto do máximo. O Poder rende **50 vezes mais** que na lagoa. Ela flutua bem mais alto que as outras (cerca de 160 studs de altura no mapa), então a **vista para baixo** (nuvens, o mar, as outras ilhas pequeninas lá embaixo) é parte do encanto.

### Clima e paleta
**Amanhecer eterno.** Céu em degradê **rosa, dourado e lilás** com **aurora** (verde-água, rosa e violeta), nuvens fofas e luminosas, terra **branca-pérola e dourada**, detalhes **dourados**, colunas **brancas**, **cristais rosa e ciano claros**, e **arco-íris suave** em tudo que brilha. Luz alta, quente, leve, mágica.

### Marcos possíveis (invente os seus, estes são só inspiração)
- **Terraço circular branco e dourado** como o ponto de treino, com um **anel de luz** que gira devagar.
- **Colunas e arcos brancos e dourados**, alguns quebrados e cobertos de flores e luz.
- **Mar de nuvens** em volta, com **peixes e baleias de nuvem** passando.
- **Anéis de luz orbitando** a ilha (como um planeta) e **pontes de luz** curtas.
- **Cachoeiras de nuvem** caindo das bordas da ilha.
- **Pedras e ilhotas menores flutuando** perto, com árvores de folhas rosa e douradas.
- Um **portal de volta** em forma de arco de luz dourado.

## 5. Coisas que a ilha precisa transmitir

- **Identidade clara**: um marco principal que dá para reconhecer só pela silhueta, de longe.
- **Progresso**: esta ilha precisa parecer **melhor e mais poderosa** que a anterior (lagoa, depois Recife, depois Abismo, depois Celestial).
- **Leitura boa para quem treina parado**: o jogador fica no centro, com o campo de treino de 10 níveis em volta dos pés. A ilha em volta é o "cenário" da sessão. Evite bloquear a câmera, evite coisas piscando forte e deixe espaço livre no centro.
- **Vida**: movimento suave em água, luz, partículas ou criaturas decorativas. Sem flashes bruscos.
- **Simplicidade de construção**: pense em poucas peças grandes e bonitas, Terrain para água e rocha, partículas para magia.

## 6. O que entregar (4 imagens + 1 texto)

Gere **4 imagens de conceito** da ilha, cada uma uma **versão diferente da sua ideia** (não 4 ângulos da mesma). Varie de verdade: composição, marco principal, paleta e clima. As 4 versões precisam respeitar tudo acima (ponto de treino plano no centro com raio livre de ~34 studs, portal de volta, spawn, orçamento).

Para **cada** imagem:
1. **Uma imagem única, forte, em 3/4 aéreo** (como se uma câmera estivesse acima da ilha, vendo o ponto de treino no centro e os marcos em volta). Tamanho **1024 x 1024 px no máximo** (o Roblox reduz acima disso). Sem texto escrito dentro da imagem.
2. **Uma descrição de 6 a 10 linhas** (em português) com: o conceito da versão, o **marco principal**, as **cores**, onde ficam o **ponto de treino, o spawn e o portal de volta**, o que **se mexe** (água, luz, partículas, criaturas decorativas), como a ilha **evolui visualmente** do ponto de vista de quem está treinando e **como você construiria** isso com poucas peças (o que seria peça, o que seria Terrain, o que seria partícula).

Se puder, gere também **uma segunda imagem opcional por versão**: o **ponto de vista do jogador em pé no ponto de treino**, olhando a ilha (é essa a vista em que ele passa horas).

### Onde salvar
- Imagens: `art/concept/ilha-celestial/ilha-celestial_v1.png` até `ilha-celestial_v4.png` (e `ilha-celestial_v1_jogador.png` etc. se fizer a opcional).
- Texto: `art/concept/ilha-celestial/ilha-celestial.md` (um bloco por versão: V1, V2, V3, V4, com o nome da versão, a descrição e as medidas aproximadas).

### Avise o João
Quando terminar, escreva **uma linha no Mural** de `docs/COORDENACAO.md` (só adicionando no fim): "Antigravity (Ilha Celestial): 4 conceitos em `art/concept/ilha-celestial/`", com o nome curto de cada versão. **Pare aí e espere o João escolher.** Não construa nada antes da escolha.

### Critério de pronto
- 4 versões realmente diferentes entre si, todas bonitas e coerentes com o estilo do jogo.
- Cada uma explica onde ficam ponto de treino, spawn e portal de volta e respeita o raio livre.
- Nenhuma imagem passa de 1024 px, sem texto na imagem, e nada foi construído no Studio.

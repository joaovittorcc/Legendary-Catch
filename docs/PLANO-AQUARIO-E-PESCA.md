# Legendary Catch — plano da nova progressão

**Objetivo:** transformar cada captura numa decisão de coleção e renda. A pesca entrega a criatura, o aquário transforma a escalação em moedas por segundo, e as moedas voltam para melhorias visíveis e equipamento. O jogador consegue montar um tanque bonito, procurar variantes e bater metas sem precisar otimizar tudo.

Este plano organiza as ideias aprovadas pelo João. Valores, prazos de animação, regras de migração e trajetórias de câmera abaixo são propostas para o primeiro protótipo. Ajustar após medir a pesca e simular a economia.

## 1. O que está aprovado

| Área | Entrega |
|---|---|
| Economia | Criaturas têm taxa de renda. Balancear geração, gastos e progressão. |
| Variações | Gigante e Dourada rendem mais que a versão base. |
| Aquário | Criaturas expostas geram renda. Upgrades aumentam o espaço e mudam de verdade a construção, iluminação e decoração. Aquário vivo, com nado e reações. |
| Coleção | Card com taxa de renda, variantes e renda total. Livro animado para descobertas. Comparação antes/depois ao trocar. |
| Progressão | Sinergias entre criaturas, metas de renda com cosméticos e metas de sessão com prêmio anunciado. |
| Pesca | Refazer a sensação do arremesso, espera, fisgada, luta, recuperação e vitória. Revisar os três minigames. Combo de capturas com barra, efeito e recompensa. Raridade antecipada na boia, linha e água. |
| Espetáculo | Celebrações por raridade, uma cinemática por Lendária e tratamento especial para Místicas. Moedas animadas e eventos com decoração, portal e contagem. |

O resumo de volta foi uma sugestão anterior. O plano inclui a tela e a opção de renda offline para validação, com o pagamento offline desligado durante o primeiro piloto.

## 2. Experiência do jogador

1. **Chegada.** No tutorial, pescar primeiro. Depois da primeira captura, o card mostra o valor por segundo e abre o caminho curto até o aquário. A primeira instalação usa um espaço vazio e mostra a taxa subir. Veteranos recebem uma introdução curta à montagem.
2. **Arremesso.** Lançar, ver a linha esticar, ouvir o impacto da boia e identificar o ponto da mordida. A água e a linha ganham cor durante a janela em que o servidor já escolheu a captura. A espécie continua sendo uma surpresa.
3. **Minigame.** Um desafio por captura. O tutorial ensina o comando em contexto. Acertos dão reação rápida e erros mostram como se recuperar.
4. **Revelação.** A câmera mostra a criatura com o rosto legível. O card separa prêmio imediato, se houver, de renda potencial. Descoberta nova carimba o livro. Variações têm selo próprio.
5. **Decisão.** Ver o melhor espaço vazio ou comparar com um ocupante. Mostrar taxa individual, efeitos de sinergia e diferença no total antes de aplicar. Com o tanque cheio, guardar a captura na coleção é automático.
6. **Aquário.** A criatura nada, o rótulo acompanha acima dela e o medidor de renda atualiza. Ao comprar um upgrade, ver a construção se ampliar e os novos espaços surgirem.
7. **Nova meta.** Mostrar a próxima meta de renda ou objetivo de sessão com progresso e prêmio conhecidos. O jogador pode voltar ao píer, mexer no tanque ou continuar pela oficina e treino.

## 3. Economia

### 3.1 Fontes e destinos

| Componente | Regra proposta para o piloto |
|---|---|
| Renda passiva | Só criaturas em espaços ativos do aquário. O card de uma criatura armazenada mostra o potencial individual. |
| Prêmio de captura | Manter uma gratificação imediata no piloto para preservar a sensação de vitória. Medir o prêmio atual e rebaixar por tabela própria se precisar. |
| Variações | Multiplicadores aplicados à taxa base da espécie. Cor da renda vem da raridade. |
| Sinergia | Bônus sobre a produção dos participantes, com teto. |
| Combo | Aperfeiçoar o combo existente. O prêmio afeta a pesca ativa e tem teto, independente da renda. |
| Sessão e metas | Prêmio explícito. Priorizar decoração, molduras, iluminação e troféus. Se houver moedas, contabilizar na simulação. |
| Gastos | Expansões do aquário, varas e decoração. O jogador enxerga o custo e o resultado antes de comprar. |
| Eventos, passes e prestígio | Medir efeitos existentes no prêmio de captura e na frequência de pesca. Proposta inicial de taxa passiva fixa fora desses multiplicadores. |

### 3.2 Fórmula e valores iniciais

`taxa individual = taxa base da espécie × fator da variante`

`renda do tanque = soma, por vaga, de taxa individual × (1 + percentual de sinergia)`

O servidor guarda e calcula em centésimos de moeda. Preserva frações até completar uma moeda inteira. A UI exibe duas casas quando necessário e abrevia só quando couber mal, com valor completo no detalhe. Peso continua como recorde. A marca Gigante define um patamar de renda fixo para a variante.

| Raridade | Faixa por espécie no protótipo | Cor exclusiva do número acima da criatura |
|---|---:|---|
| Comum | 0,15 a 0,30/s | Branco |
| Incomum | 0,35 a 0,65/s | Verde |
| Rara | 0,70 a 1,20/s | Azul |
| Épica | 1,30 a 2,20/s | Roxo |
| Lendária | 2,40 a 4,00/s | Dourado |
| Mística | 4,20 a 6,00/s | Arco-íris |

Usar o intervalo para dar identidade a cada espécie. Todas recebem taxa configurada, incluindo evento e Natal. O número mostra a taxa **efetiva** daquela criatura. O card detalha base, variante e sinergia. Exemplos em PT-BR como **+0,44/s** e **+2,10/s**. Fundo e contorno escuros mantêm branco, azul e arco-íris legíveis. Reduzir efeitos deixa o arco-íris estático. Ícone de moeda, texto de raridade e selo na seleção evitam depender só de cor.

| Variação | Proposta de fator | Representação |
|---|---:|---|
| Base | ×1,00 | Modelo padrão. |
| Gigante | ×1,30 | Silhueta maior, escala de exibição limitada pelo tanque e selo. |
| Dourada | ×1,60 | Acabamento dourado com rastro leve e selo. O piloto pode aproveitar a rolagem de Cintilante com um mapeamento explícito. |
| Gigante e Dourada | ×1,90 | Os dois selos. Somar +0,30 e +0,60 ao fator base. |

O código atual já marca Gigante quando o peso cai nos 15% superiores da faixa e guarda contagem Cintilante. Medir a frequência real das duas propriedades e de sua combinação na distribuição atual. Definir com João se o nome imprimível vira Dourada para todas as Cintilantes ou se a variante nova passa a coexistir com a antiga. Cenário inicial de migração abaixo assume a primeira opção.

**Exemplo de troca.** Um tanque rende 1,20/s. Trocar um Comum de 0,20/s por uma Incomum Dourada de 0,80/s gera +0,60/s na vaga. Se a troca também ativar +0,06/s de sinergia, a prévia mostra **1,20/s → 1,86/s**, com a diferença de **+0,66/s** discriminada. Caso quebre uma sinergia, exibir a perda antes de confirmar.

### 3.3 Sinergias, metas e recompensas

- **Famílias e conjuntos.** Tags de espécie definidas no catálogo pelo responsável pelos sistemas. Exemplos a conferir com o elenco real: Recife, Tempestade, Abissal, Celestial, Festival. O card mostra o que falta para ativar.
- **Proposta de bônus.** 2 espécies distintas da mesma família dão +5% aos participantes. 3 dão +10%. Para uma criatura com mais de uma família ativa, usar o maior bônus, com teto de +10%. Uma variante ocupa uma vaga, mas não conta como outra espécie para desbloquear a sinergia.
- **Reação visual.** Ao formar grupo, as criaturas executam um movimento curto sincronizado. Um fio de luz liga as posições por um instante. O grupo ganha um ícone que pode ser inspecionado. Saída tem indicação discreta.
- **Metas de renda.** Protótipo em 0,50 / 1,00 / 2,00 / 4,00 / 8,00 / 15,00 moedas/s. Ganho pela primeira vez, registrando o maior valor confirmado pelo servidor. Trocar e recolocar criaturas preserva o estado de resgate. Exemplos de prêmios: placa do aquário, luminária, coral especial, fonte e moldura.
- **Metas de sessão.** Dois ou três marcos claros por visita, como 3 capturas, 2 tipos de minigame ou 1 descoberta. Avanço por ação confirmada. Faixa com progresso e prêmio antes de começar. Reentrada rápida recupera o progresso da mesma sessão. Se houver moeda, usar limite persistente e incluir a fonte no balanceamento.
- **Combo de pesca.** Reaproveitar `FishingCombo` e `bestCombo`. Faixa compacta, com marcos visuais sugeridos em 3/5/8 capturas manuais. Aumentar brilho, som e animação conforme o marco; respeitar o teto econômico atual até recalibrar. O servidor determina quais eventos avançam ou encerram o combo. Captura automática segue seu fluxo próprio.

### 3.4 Ritmo, preços e simulação

- Medir o jogo atual antes de trocar preços: tempo de uma pesca por minigame, chance de vitória por dispositivo, intervalos de desbloqueio, compra de varas, prêmio de captura, combo, multiplicadores, missões, presentes diários, códigos, prestígio e eventos. Separar contas novas, antigas e pescadores rápidos.
- Modelar perfis de 5, 15 e 30 min, e projetar dias 1/3/7/14. Rodar cenários de azar, mediana e sorte alta, inclusive alguém que pegue Lendária cedo, quem usa pesca automática e quem entra durante evento com os bônus atuais.
- Calcular moedas ganhas por fonte, saldo, gasto por destino, taxa ativa/passiva, tempo até cada compra e valor incremental de cada vaga. Valor de retorno simples: `preço ÷ acréscimo real de renda/s`. Exemplo com custo ilustrativo de 180 e ganho de 0,30/s: retorno em 10 min de produção.
- Alvos de piloto: primeira criatura exposta na primeira sessão, primeira meta visível logo depois e primeiro upgrade alcançável jogando, sem depender de variante ou de Lendária. Medir como alvo inicial 10–20 min até a primeira ampliação e 30–60 min até a segunda. Alinhar os alvos à linha de base medida.
- Checar dominância. Uma criatura rara pode mudar a escalação cedo, e as raridades baixas ganham espaço com sinergia, variantes e vagas extras. Simular o teto com tanque cheio de Gigantes Douradas, todas as sinergias e eventos. Ajustar taxas, vagas e preços com base nesse extremo e na mediana.
- Tratar estoque de veteranos à parte. Ver quantos conseguem comprar todas as expansões logo no primeiro dia e como isso afeta as metas. Preservar saldo e coleção. Se preciso, introduzir requisitos publicados de etapa além de preço, evitando reprecificar tudo em função dos extremos.
- Telemetria por fonte e destino, sem gravar informação pessoal. Acompanhar produção/hora, saldo, tempo até upgrade, taxa de troca, composição dos tanques e evolução por etapa. Publicar parâmetros com versão e aplicar ajustes futuros de renda com prazo claro.

### 3.5 Volta ao jogo

Tela de retorno mostra produção contabilizada desde a última visita, taxa atual e maiores contribuições quando houver dados. Com a economia offline desligada, apresentar o saldo e a próxima meta.

Para testar renda offline depois: hipótese de 25% da taxa no momento de sair, até 2 h, usando relógio do servidor. Guardar a taxa de saída junto do timestamp, sem retroagir quando uma taxa mudar. Liquidar uma vez no mesmo perfil com avanço de cursor antes de apresentar o resultado. Rodar teste de saída inesperada, duas sessões e reentrada rápida. Simular junto com todas as fontes antes de ativar.

## 4. Aquário e Coleção

### 4.1 Espaço e aparência

| Nível proposto | Vagas | Mudança visível |
|---|---:|---|
| 1 — Berçário | 3 | Tanque de vidro pequeno na bancada de madeira, areia, plantas e bolhas. |
| 2 — Tanque de Recife | 5 | Tanque mais largo, rochas, coral colorido, iluminação superior e segunda faixa de nado. |
| 3 — Galeria | 8 | Vidro panorâmico e nichos, fundo cristalino, corais altos e passarela visual. |
| 4 — Santuário | 12 | Galeria com arcos, cristais grandes, setores de profundidade e vazão de água visível. |

Antigravity faz as predefinições físicas e define o encaixe no mapa com João. Começar com um aquário pessoal acessível a partir do hub e validar enquadramento antes de decidir como expor aquários de visitantes. Cada nível tem modelo e caminhos próprios. Upgrade apresenta prévia da geometria e novas vagas, confirma custo com o servidor e toca uma transição de montagem curta. Preserva ocupantes e mantém a produção correta durante a animação.

- Nado suave por rotas e alturas, com variações de tamanho, cadência e suspensão. Começar com pivôs de modelo e trajetórias para catálogo inteiro. Modelos articulados podem mover peças, depois de validar o rig. Animar só as criaturas próximas e simplificar as distantes. Místicas e Gigantes usam volumes reservados.
- Rótulo acima da cabeça ou topo do modelo, seguindo a posição real. Quando rótulos se cruzam, dar prioridade ao selecionado e esconder temporariamente os mais distantes. De longe, mostrar o total na placa do aquário. Em inspeção, abrir card com decomposição da taxa.
- Ações da montagem: selecionar vaga, ver elegíveis, ordenar por renda ou descoberta, inspecionar, confirmar colocar/trocar/retirar. Filtros por raridade, variante, família e em exibição. A UI mostra o motivo de uma vaga bloqueada. Cada vaga aloca uma quantidade realmente pescada.
- Reação ao chegar, toque em criatura e sinergia usam movimentos curtos com intervalos. Decoração compra diversidade visual. Upgrades que ampliam vagas têm resultado de renda previsto no fluxo de compra, distinguindo vaga vazia de produção real.

### 4.2 Coleção, descoberta e comparação

O livro mantém as espécies do catálogo agrupadas. Descoberta inédita revela a silhueta, carimba a página, ilumina a cor de raridade e mostra data. Variante inédita recebe carimbo menor, com estado separado de espécie nova. Reabrir uma página mantém o registro.

No detalhe mostrar modelo 3D, nome, raridade, lore, quantidade, maior peso, primeira captura, taxa base e variantes disponíveis. Indicar quantas estão no aquário, taxa efetiva das expostas e sinergias. Card da captura oferece atalho após a cinemática. Botão de comparação mostra **atual → depois**, taxa da vaga, total do tanque e mudanças de grupo. Atualizar quando o servidor confirmar a troca; se a montagem tiver mudado durante a prévia, atualizar os números antes de pedir nova confirmação.

## 5. Pesca e três minigames

### 5.1 Animações da pesca

| Momento | Encenação e resposta |
|---|---|
| Preparar e arremessar | Ombro e vara carregam o movimento, pulso solta a linha, boia faz arco curto. O som de vara e a primeira ondulação marcam o impacto. |
| Esperar | Boia deriva pouco, com linha folgada e círculos espaçados. O jogador distingue espera de mordida. |
| Sinal da captura | Quando a raridade já vier do servidor, aplicar cor e intensidade na boia, linha e água. Prévia lê a raridade real; mensagem de falha encerra a expectativa com rapidez. |
| Fisgada | Boia mergulha, linha estica e ombro puxa. Toque, som e zoom leve pontuam o começo da luta. |
| Luta | Vara responde ao esforço. Acerto e erro mudam temporariamente a tensão e o som. Segurar espaço para interface e toque. |
| Vitória | Recolhida curta, brilho vindo da água e caminho para a revelação. A cutscene começa após confirmação do servidor. |
| Escape e cancelamento | A linha afrouxa e volta. Restaurar câmera, postura, som, controles e HUD em todo caminho de saída. |

### 5.2 Revisão por minigame

| Modo | Revisão da experiência | Cenários de verificação |
|---|---|---|
| Reel | Movimento de segurar/soltar ensinado na primeira vez; peixe, zona de contato e tensão separados visualmente. Aceleração e queda legíveis. Erro progressivo com chance de recuperação. | Primeiro uso, troca rápida de entrada, toque segurado, queda de quadros, fauna rápida, recuperar de quase falha. |
| Precision | Alvo e cursor com bordas e trajetória claras. Mostrar acerto, acerto perfeito e erro com símbolos e áudio distintos. Contagem de acertos restantes e uma indicação leve antes de começar. | Acertos nos limites, toque repetido com debounce, escala de tela, alvo pequeno nas raridades altas e interrupção. |
| Rhythm | Círculos com sequência visível e anel de aproximação. Espaço entre alvos aumenta a leitura no toque. Ritmo visual funciona com som desligado. Feedback informa cedo/tarde quando confiável. | Ao menos três padrões, dedos múltiplos, latência/FPS instável, cancelamento, alvos perto da borda e dos controles nativos. |

Fazer auditoria antes de rebalancear. Medir tentativas, vitórias, duração, falhas, perfeitos, primeiras capturas e diferença entre PC e celular por modo/tier. Começar pela legibilidade, em seguida calibrar tolerâncias com sistemas. Validar se cada modo segue a mesma semântica de concluir/cancelar. Conservar o caminho de tutorial, varas, treino, principais estados da pesca e controles acessíveis. A UI usa a faixa de efeitos conforme raridade, com pontos que preservam o contraste do alvo.

## 6. Revelações, cores e eventos

- **Escala visual.** Comum entrega um impacto rápido, Incomum reforça água e silhueta, Rara ganha luz e uma abertura de câmera, Épica ganha assinatura forte, Lendária tem encenação própria e Mística mantém a cutscene ampla. Faixas iniciais de tempo para revisão: Comum até 2 s, Lendária cerca de 6–8 s no primeiro protótipo ajustado ao vídeo. As Místicas atuais já têm ~16–17 s contando a revelação.
- **Legibilidade e efeitos.** Cor concentrada no foco do momento. Se houver conflito, o minigame fica acima de partículas, molduras e contador. Usar flashes suaves e breves, sem estrobo. Reduzir Efeitos elimina tremidas e suaviza transições. Usar efeitos reutilizáveis e limitar partículas em celular. Considerar linguagem de cores da pesca e de renda separadamente.
- **Moedas.** Contador anima diferenças já confirmadas e agrega produção contínua em pequenas somas. Animação de moeda até o saldo para captura/meta, com limite de ícones. Números das criaturas permanecem estáveis entre mudanças reais da taxa. Usar áudio curto com volume existente e opção de reduzir efeitos.
- **Eventos de oceano.** Usar o evento global e o fim informado pelo servidor. Portal/entrada visual no píer, cenografia própria, mudança na superfície e faixa com tempo e condições. Separar claramente decoração de um portal que realmente leva a outra zona. Os bônus atuais continuam sob controle do servidor. Ao acabar, efeitos se recolhem e exibem status atualizado. Capturas em curso seguem a decisão do servidor para o evento.
- **Cutscene repetida.** Reusar controles de pular quando aplicáveis, com suporte a toque. Depois de pular, ir ao mesmo card e estado que o fim normal. Identificar cada cena pelo ID da espécie. Reusar infraestrutura de câmera, água, luz, áudio e encerramento, com duração e efeitos por cena. Preservar C93/C94 como cenas próprias.

### 6.1 As 18 cenas Lendárias

Cada linha é uma proposta para a transição, o movimento principal e a pose final. Ajustar com o vídeo correspondente e com a geometria real do modelo. Todas terminam com pose legível e volta ao card.

| ID e criatura | Encenação de referência |
|---|---|
| C10 Leviatã Astral | A boia se reflete num céu sem lua. A silhueta rompe o reflexo, atravessa poeira estelar e inclina a cabeça em direção à câmera. |
| C23 Kraken Trovejante | Tentáculos emergem um a um em resposta a raios que viajam pela água. A câmera sobe entre as pontas até o rosto central. |
| C24 Fênix das Marés | Espuma acende em fogo azul. A Fênix renasce da crista, bate as asas para espalhar vapor e termina em voo frontal. |
| C30 Tartaruga-Ilha Ancestral | A casca parece uma ilhota parada. A maré desce ao redor e a câmera rente à água passa da vegetação para o rosto. |
| C34 Serpente Arco-Íris | Uma gota divide a luz do sol. A serpente se desenrola e cruza faixas de cor, deixando a cabeça à frente do arco. |
| C60 Hidra das Profundezas | Três ondulações se aproximam em tempos distintos. As cabeças sobem em sequência e convergem para um enquadramento conjunto. |
| C61 Baleia Celestial | O canto faz constelações aparecerem na superfície. Uma subida longa em perfil revela a galáxia do corpo antes de girar para a câmera. |
| C62 Dragão Dourado da Tempestade | Nuvens carregam ouro. O dragão sobe num zigue-zague, responde ao relâmpago com rugido e abre a silhueta contra o céu. |
| C63 Grifo-Marinho Real | O vento separa a espuma. O grifo arranca baixo e vira de lado, mostrando asas e cauda de peixe numa passagem rente à câmera. |
| C64 Guardião Abissal | A lanterna risca a névoa sobre a água antes da criatura. O Guardião emerge e ergue o foco, iluminando o rosto. |
| C88 Rei Tritão Colossal | O tridente rompe a superfície. O rei sobe sobre uma coluna de água e pousa o tridente, enviando um anel de espuma. |
| C89 Dragão de Jade | A curva do corpo atravessa nuvens baixas enquanto a água espelha jade. O dragão abre a espiral e sustenta o olhar diante da câmera. |
| C90 Tartaruga-Mundo | A tomada abre mostrando a floresta inteira acima das ondas. A câmera desce por uma cascata e alcança a cabeça pelo lado. |
| C91 Hipocampo Imperial | Cristas de onda viram uma pista. O hipocampo cavalga duas cristas e se ergue para pegar luz dourada na armadura. |
| C92 Serafim do Mar | O mar agitado perde força com a abertura de pares de asas. A câmera contorna o reflexo até mostrar as seis asas e o rosto. |
| C99 Baleia Fantasma | Pontos de luz emergem por trás da névoa. A baleia cruza quase invisível e revela o volume quando a câmera passa pelos focos. |
| C100 Aurora Boreal Viva | Uma fita de aurora se dobra sobre a água e ganha corpo. A criatura nada pelo ar frio e se volta sob o arco que traçou. |
| C106 Rei do Gelo Natalino | O mar cristaliza em estrelas e flocos. A criatura quebra a superfície com a coroa em destaque e espalha reflexos festivos. |

**Fluxo de produção.** Partir da pasta individual em [art/video-ref/legendary](../art/video-ref/legendary/README.md). Atualizar o prompt com os beats da tabela e anexar os melhores ângulos disponíveis. Onde houver prancha anterior e vista final, usar a final como referência principal. João devolve o vídeo com o ID correspondente. Catalogar beats com timestamps, câmera, pose, cor, som, impacto e simplificação para Roblox. Implementar o equivalente em 3D com os modelos do jogo. Prototipar C23, C24 e C64 como cenas de tentáculos, voo e personagem. Fechar as outras em lotes com o mesmo padrão. Sendo uma referência, o vídeo não entra como asset reproduzido no jogo.

## 7. Contratos e persistência

O repositório atual credita moedas na captura, guarda a coleção por espécie com quantidade, recorde, primeira data e Cintilantes, e publica o snapshot ao cliente. O payload de captura já inclui `isGiant`, `variant`, `combo` e `comboBonus`. O fluxo novo pode ampliar esse contrato.

| Contrato proposto | Conteúdo e comportamento |
|---|---|
| Catálogo | Taxa base por espécie, conjunto de sinergia, regras de variante, metas e níveis do aquário configuráveis e versionados. |
| Perfil | Contadores por espécie e variante, montagem por vaga, nível, identificadores das metas resgatadas e estado contábil da renda. Separar estatística histórica de itens disponíveis. |
| Snapshot | Versão da montagem, vagas/ocupantes, nível, renda total e individual, sinergias, moeda, próximo objetivo e estado de resgate. Campos aditivos com tratamento de perfil carregando. |
| Captura | Um registro de captura atualiza coleção, contadores de variante e prêmio em uma mutação. Resposta traz taxa potencial e selo. Upgrades e equipar criatura usam comandos próprios. |
| Montagem | Solicitar prévia de troca e confirmar com índice da vaga, espécie, variante e versão. Servidor verifica posse, quantidades em vagas ativas, versão e limites. Resposta carrega montagem e taxa canônicas. |
| Compras e metas | Servidor confere preço atual, saldo, nível e elegibilidade. Identificador da requisição ou versão esperada evita cobrança duplicada. Repetir um resgate devolve o estado já confirmado. |

- **Migração idempotente.** Para perfis antigos, preservar catálogo descoberto, saldo, recordes, varas, treino e prestígio. Criar contadores base a partir da quantidade histórica, descontando a parte Cintilante se ela migrar para Dourada. Recorde antigo informa melhor peso e não reconstrói quantidade ou combinação Gigante. Clamp dos contadores inconsistentes e marca de versão da migração. Inicializar tanque com vagas vazias para escolha do jogador. Sem pagamento anterior à ativação.
- **Características disponíveis.** Para o piloto, contadores agregados por espécie e combinação de variante bastam. A taxa depende de espécie e variante, então nenhuma instância individual precisa de peso independente. Se depois houver troca entre jogadores, planejar inventário por item e identidade persistente como etapa própria.
- **Liquidação.** Usar relógio e taxa do servidor. Liquidar o intervalo anterior antes de mudar taxa em troca, upgrade ou regra nova. Um agendador em lote por servidor mantém as contas online com atualização em intervalos, sem criar loop por criatura. Manter resto fracionário e cursor. Persistir saldo, resto e cursor juntos no perfil já usado pelo jogo. Atualizar UI com atributo/snapshot desacoplado da frequência de gravação.
- **Resiliência.** Tratar repetição de ação, troca concorrente, sessão perdida, reconexão, encerramento do servidor e desativação do recurso. Aplicar limites a entradas remotas e rejeitar IDs, valores e versões inválidos. Revisar interações com prestígio, recibos, conquistas, placar e pesca automática antes do primeiro rollout. Nomear fontes de moeda separadamente na telemetria.
- **Perfis e rollback.** Executar migração em ambiente de teste com cópias representativas. Ligar por flag com economia/versionamento no servidor e cliente mostrando o estado enviado. Separar visibilidade da UI, crédito de renda, pagamento offline e efeitos. Rollback pausa nova produção e conserva direitos e progressão já concedidos. Reativação retoma a partir de novo cursor.

## 8. Lotes e divisão

| Lote | Sistemas / Claude | Visual / Codex | Mapa e modelos / Antigravity | Pronto quando |
|---|---|---|---|---|
| 0 — Linha de base | Catalogar fontes, gastos, odds, progressão, perfis e migração. Simular tabelas. | Auditar UI, fluxo, efeitos atuais e vídeos. Desenhar cards e HUD com dados fictícios. | Definir local e volume para o primeiro tanque. | Simulação inicial e protótipos de UI mostram o mesmo loop. |
| 1 — Primeiro ciclo | Renda online com liquidação, variantes, montagem inicial e snapshot. | Card, valor acima da criatura, troca com prévia, saldo e apresentação do primeiro tanque. | Tank level 1 e volume de nado. | Capturar → expor → receber moedas → trocar funciona com perfil novo e antigo. |
| 2 — Crescer e colecionar | Expansões, sinergias, metas, prêmios e contadores. | Upgrades animados, livro, sinergias, metas, decoração, nado contextual. | Três predefinições de expansão e peças decorativas. | Compra preserva a escalação. Sinergia e total de renda mudam corretamente, com leiaute de celular. |
| 3 — Pesca | Balancear e integrar estados, combos, tutorial e metas de sessão. | Arremesso e luta. Revisar Reel, Precision e Rhythm. Sinais de raridade e celebrações. | Ajustes de cenário mediante pedido. | Os três modos funcionam com toque e PC, e navegação volta ao normal após qualquer saída. |
| 4 — Cenas e eventos | Servir evento e regra de disponibilidade. Apoiar as rotinas de teste. | Três cenas piloto, outras 15 por lote, água, portal, VFX, áudio e presets por evento. | Articular ou ajustar assets dos pilotos se necessário. | Cada um dos 18 IDs tem cena, evidência visual e saída limpa. Místicas validadas como regressão. |
| 5 — Calibração e estreia | Simulação revisada, telemetria, ativação por flag, decidir offline e acompanhar. | Polimento ajustado por dispositivo, suporte ao resumo de volta e revisão de efeitos. | Polimento de desempenho e leitura da galeria. | QA, simulação e evidência da versão registrada no Mural. |

O lote de pesca pode andar em paralelo ao aquário depois da auditoria, com commits em áreas distintas. O lote de cenas pode começar por storyboard enquanto chegam vídeos. Atualizar o Mural ao começar e terminar cada entrega. Sistemas editam servidor, Config, Net, Types e controlador. Codex fica com o cliente visual, StringsUi PT/EN e UiTheme. Antigravity cuida da construção. Reusar os assets aprovados.

## 9. Critérios de aceite e verificação

| Trilha | Casos mínimos |
|---|---|
| Economia | Reproduzir aplicação dos fatores de variante, teto de sinergia e arredondamento. Trocar taxa entre dois ticks, retirar tudo, reentrar, comprar rápido duas vezes, alternar vagas, testar saldo insuficiente e resgate duplicado. Testar todos os máximos da simulação. |
| Perfil | Novo, veterano, coleção com Cintilante, combinações de variantes novas, perfil inconsistente, reexecução da migração, perda de sessão e versões mistas durante rollout. |
| Catálogo | Conferir todas as espécies elegíveis e janelas de evento/Natal. Renderizar tamanho extremo, 6 cores de renda, 4 combinações de variante, card completo e comparação com ganho/perda. |
| Aquário | Quatro estados de geometria e capacidade. Navegar, editar composição, ver outro jogador onde suportado, confirmar desligamento de partículas fora de alcance. Testar lotação máxima no celular. |
| Pesca | Vitória, erro, escape, cancelamento, morte, desequipar, entrada por toque/PC, baixa taxa de quadros, pesca automática e primeiro tutorial. Validar os três modos nos tiers extremos. |
| Cinemática e evento | As 18 Lendárias e duas Místicas, primeira vez e repetição, skip/término/morte, câmera restaurada, efeitos reduzidos e mudança de evento com uma captura em andamento. |
| Interface | PC, telefone em retrato e paisagem, fonte ampliada quando disponível, localização PT/EN, contraste, toque e sem obstruir controles. Uma etapa em celular real e uma etapa com dois jogadores. |

- Para código futuro, `--!strict`, StyLua, Selene e análise do Luau. Studio com `.studio-lock`, evidência de Play e registro da versão salva em nuvem quando aplicável. Commits próprios, em inglês, sem push.
- Registrar medidas antes/depois da pesca e perfil de desempenho em tanque cheio e cena pesada. Reutilizar instâncias de VFX, limitar emissão e manter câmera/input responsivos. Identificar gargalo por cena e dispositivo antes de decidir limites finais.
- Na estreia, conferir distribuição do saldo, tempo até a primeira compra, renda por estágio, evolução da economia, erros de perfil e falhas do ciclo de pesca. Usar isso para ajustar taxas, ritmos, preço e efeitos entre lotes.

## 10. Pontos a fechar no protótipo

1. **Tratamento das Cintilantes antigas.** Validar se Dourada é a nova apresentação da mesma variante ou uma variante adicional.
2. **Forma física do aquário.** Validar primeiro tanque pessoal com visita por botão ou entrada no hub, com Antigravity definindo espaço e João escolhendo a forma de visita.
3. **Renda offline.** Concluir a simulação e validar quanto ela ajuda a progressão sem dominar o valor de pescar.
4. **Salto de um veterano.** Medir o efeito do estoque histórico antes de fixar requisitos e preços.
5. **Premiação de sessão e combo.** Definir os prêmios e o teto usando o rendimento observado. Tratar números deste plano como parâmetros de protótipo.
6. **Vídeos das Lendárias.** Registrar cada vídeo recebido junto do ID e fechar câmera, duração e efeitos do lote a partir dessas referências.

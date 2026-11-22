# Legendary Catch — plano de melhoria do treino

O treino vira uma prática de pesca visível. O personagem arremessa, acompanha a boia, reage à fisgada e recolhe a linha. O jogador escolhe entre dois treinos com exercícios, níveis e benefícios diferentes.

## 1. Estado atual

O código já guarda **Controle** e **Instinto** em entradas separadas. Ambos têm nível e XP próprios, com teto atual de 25. Controle escala a tolerância dos minigames por meio de `Fishing/Control.luau`. Instinto altera o peso das raridades no sorteio do servidor. A tela de treino destaca só o atributo ativo e os dois modos usam o mesmo desafio de ritmo. A animação atual alterna emotes de comemorar, acenar e apontar.

O plano torna a progressão independente visível ao escolher, treinar e abrir a tela de progresso. Antes de alterar dados, reproduzir o relato do João no Play e conferir os dois níveis no perfil, snapshot, atributos e HUD. Se Instinto deixar de aparecer em algum desses passos, corrigir o ponto em que o dado se perde.

## 2. Dois treinos, dois resultados

| | Controle | Instinto |
|---|---|---|
| O que você pratica | Manter a linha firme quando algo puxa. | Ler o movimento da água e reconhecer uma mordida. |
| Exercício ativo | Segure e solte para manter o marcador na faixa por alguns segundos. A boia e a vara mostram a tensão. | A boia dá sinais leves e depois afunda de verdade. Toque no mergulho. Nas sequências avançadas, a direção das ondulações ajuda a encontrar o sinal certo. |
| Benefício na pesca | Mais tolerância nas janelas dos minigames. Mostrar o efeito concreto em Reel, Precision e Rhythm depois de confirmar o cálculo de cada um. | Aumenta o peso das raridades elegíveis na zona. O servidor continua aplicando o catálogo, as condições e a normalização do sorteio. |
| Identidade visual | Ciano, ícone de vara tensionada, linha esticando e som curto de carretilha. | Lilás, ícone de olho sobre onda, círculos na água e som de boia submergindo. |
| Exemplo de progresso | **Controle Nv. 7 · 42/85 XP · +8,4% de tolerância do treino**. | **Instinto Nv. 4 · 18/55 XP · peso de Lendárias elegíveis ×1,16 pelo treino**. |

Os exemplos usam as fórmulas atuais. O bônus isolado de Controle cresce 1,2% por nível até +30%. Instinto usa `1 + 0,01 × nível × (posição da raridade - 1)`; no teto atual o peso de Lendária é ×2. Um peso ×2 pode resultar em bem menos que o dobro de chance final quando outras categorias também ganham peso. Exibir chance final só se o servidor puder calculá-la para o contexto atual. Revisar o acúmulo com vara, zona, evento, prestígio e Místicas antes de mudar as fórmulas.

## 3. Da entrada à saída

1. **Chegar à lagoa.** Mostrar Controle e Instinto na mesma tela com nome, nível, barra, benefício atual e prévia do próximo nível. Placas e símbolos diferentes ajudam a reconhecer onde começar.
2. **Escolher um treino.** Destaque no card escolhido. Um jogador tem uma sessão ativa por vez. A tela de progresso ainda mostra os dois níveis e permite trocar de modalidade com uma transição clara.
3. **Praticar.** XP de prática avança na modalidade ativa enquanto a sessão é válida. Uma atividade curta aparece de tempos em tempos. Usar o intervalo atual de 10–18 s como referência inicial e medir se combina com o tempo de arremesso e recolhida.
4. **Receber retorno.** Acerto dá XP extra, som e reação da vara. Erro mostra uma dica curta e termina o exercício. O jogador continua com o XP da prática válida. Uma sequência de acertos no mesmo treino aumenta o bônus até o teto configurado.
5. **Subir de nível.** Barra completa, entra a nova barra com o XP excedente e sobe uma placa com o nome da modalidade e o benefício que mudou. Marcos em 5/10/15/20/25 podem ter poses, efeitos ou selos próprios. No teto, mostrar `Nível máximo` e o benefício alcançado.
6. **Encerrar ou trocar.** Mostrar resumo curto com tempo, XP por fonte, acertos e níveis ganhos. A troca limpa a atividade antiga e exibe o progresso do outro treino. Ao sair da lagoa, morrer, iniciar outra atividade incompatível ou apertar **Parar**, restaurar os controles e limpar os efeitos.

## 4. O boneco realmente pescando

| Fase | Movimento e efeito |
|---|---|
| Preparar e lançar | Personagem volta o corpo para o ponto de treino, segura a vara com as duas mãos quando o rig permitir, puxa para trás e arremessa. A linha sai da ponta até a boia, que bate na água com uma ondulação. |
| Esperar | Peso do corpo muda devagar, punhos sustentam a vara e o olhar acompanha a boia. A linha afrouxa e a boia acompanha a água. |
| Exercício de Controle | A vara inclina com a tração. Quando a tensão sobe, a linha endireita e o boneco recua o ombro. Ao estabilizar, a pose volta de forma suave. |
| Exercício de Instinto | O personagem acompanha a boia. O mergulho faz a linha puxar o punho. No acerto, o boneco fisga com movimento curto e firme. |
| Recolher e recomeçar | Vara sobe, linha encurta e a boia volta para perto. O próximo lançamento começa depois de uma pausa curta. |
| Marco de nível | Recolhida especial, brilho localizado na boia e breve comemoração com a vara na mão. |

Reaproveitar o visual da vara equipada, a lógica visual da linha e as poses da pesca onde couber. Usar um ponto de água definido por estação. Fazer a boia, vara e efeitos de treino seguirem a sessão, com representação visível para jogadores próximos. A visualização de terceiros pode interpolar uma versão simples das fases. O treino dá XP e feedback de prática. A boia de treino não dispara a captura normal, o aquário ou a coleção. Testar rig do avatar, mão/vara, entrada/saída e restauração de controles com dois jogadores. Em Reduzir Efeitos, a pose, a boia e o sinal do exercício continuam claros, com menos partículas e sem balanço de câmera.

## 5. Números que dão gosto de ver

- **Prática:** agregar o XP contínuo para exibir pequenas somas como **+3 XP de Controle**. O número sobe perto da boia e a barra avança. Sem disputa de espaço com o alvo.
- **Acerto:** número maior e cor da modalidade. Um toque no tempo pode mostrar **PERFEITO · +18 XP** no piloto, com contorno, onda curta e áudio distinto. O servidor informa o XP realmente concedido.
- **Sequência:** pequenos marcadores se acendem com os acertos. Mostrar um exemplo como **3 acertos · +20% no exercício**, com causa e teto visíveis. Contagem e bônus precisam refletir a regra publicada.
- **Subida de nível:** número antigo vira o novo, como **Instinto 7 → 8**. Embaixo, mostrar o que mudou, por exemplo **Peso de Lendárias elegíveis ×1,28 → ×1,32**.
- **Leitura:** mostrar nível e XP das duas modalidades na progressão. Durante o exercício, o card ativo traz barra e número exato. Distinguir **XP do treino**, **moedas** e **nível do pescador** por ícone e texto. Agrupar animações próximas e mostrar o mesmo valor com Reduzir Efeitos.

Os valores de XP das animações são exemplos de apresentação. Começar medindo a curva existente, a diferença entre prática contínua e ativa e o tempo até o primeiro nível. Comparar jogadores que fazem os exercícios com quem só pratica. Ajustar frequência, XP por ação e metas de nível depois de medir. Conferir os bônus de estação anunciados no mapa, como ×1,5 no Coral e ×2 no Abismo, e só mostrar um multiplicador depois de o servidor confirmar que ele vale. Incluir o efeito do treino e dos bônus por nível na simulação de economia e nas chances da pesca.

## 6. Implementação e aceite

| Lote | Trabalho | Critério de aceite |
|---|---|---|
| 1 — Dois níveis visíveis | Claude confere perfil, snapshot, atributos e efeito das duas modalidades. Codex faz seletor, painel e textos PT/EN. Preservar níveis e XP existentes. | Treinar Controle mexe só em Controle. Treinar Instinto mexe só em Instinto. Os dois níveis continuam visíveis após troca e reconexão. |
| 2 — Prática animada | Codex implementa vara, linha, boia e ciclo de arremesso. Antigravity prepara os pontos na lagoa se precisarem de ajuste. Claude expõe o estado da sessão para sincronizar a representação. | Ciclo completo visto pelo jogador e por outra pessoa. Parar e trocar restaura câmera, pose, controles e objetos. |
| 3 — Exercícios e XP | Claude liga exercício a sessão e modalidade, janela de resposta, resultado e bônus validados. Codex cria as duas interfaces e celebrações. | Acerto, erro, tempo esgotado, troca durante desafio e resposta atrasada se comportam corretamente. XP e números conferem com o perfil. |
| 4 — Efeito na pesca | Medir tolerância em Reel, Precision e Rhythm e calcular distribuição de raridade por zona, evento e equipamento. Polir curva, teto e estação. | Comparar nível 0/10/25 com e sem vara, no mesmo cenário. Controle ajuda a executar o minigame. Instinto altera o sorteio elegível. O progresso exibido corresponde ao ganho real. |

Cobrir PC, toque em retrato e paisagem, Reduzir Efeitos, primeira visita, perfil antigo, nível máximo, respawn, pesca normal logo depois de sair do treino e dois jogadores na mesma lagoa. Na implementação, registrar medições e capturas por modalidade, usar o lock do Studio e seguir a divisão de arquivos do Mural.

Plano relacionado: [Aquário, economia e pesca](PLANO-AQUARIO-E-PESCA.md).

# CONTEXTO MESTRE — LEGENDARY CATCH (JOGO DE PESCA E CRIATURAS NO ROBLOX)

> **[DECIDIDO 2026-11-17]** Nome do jogo: **Legendary Catch**. Repositório: `github.com/joaovittorcc/Legendary-Catch`. Onde este documento diz "nome definitivo ainda não existe", vale este nome.

> **Documento novo e independente, para repassar ao Claude.**
>
> Este arquivo registra **a conversa de brainstorming, as decisões, as referências visuais e as ideias em aberto do NOVO jogo**. Não é uma extensão do Vault/MD antigo. Não use o documento antigo como requisito deste projeto e **não confunda o jogo novo com o Pesque um Meme**.
>
> **Estado:** conceito em definição, com direção visual da ilha escolhida. **Não começar a programar sistemas só porque este documento foi recebido.** Primeiro entenda, alinhe o que falta e espere a próxima solicitação.

---

## 0. COMO LER ESTE DOCUMENTO

Para não transformar hipótese em requisito, cada assunto pode ter um dos seguintes estados:

- **[DECIDIDO]**: o desenvolvedor declarou que quer isso ou aprovou expressamente.
- **[DIREÇÃO FORTE]**: ideia com boa aceitação, mas ainda sem especificação final.
- **[SUGESTÃO]**: proposta discutida pelo assistente; **não** foi automaticamente aprovada.
- **[ABERTO]**: decisão pendente ou ambiguidade real na conversa.
- **[DESCARTADO / EVITAR]**: o desenvolvedor rejeitou ou explicitamente pediu para não fazer.

**Regra importantíssima:** quando dois trechos parecerem conflitantes, prevalece a intenção mais recente, mas peça confirmação em vez de inventar uma resposta. Este é um documento de contexto, **não um GDD fechado nem uma ordem de implementação**.

---

## 1. QUEM É O DESENVOLVEDOR E COMO TRABALHAR COM ELE

- Nome/apelido: **João / Evojota**.
- É desenvolvedor web freelancer, trabalha com **React, Node.js e Tailwind**.
- Sabe programar, mas ainda está aprendendo o ecossistema **Roblox/Luau**.
- Trabalha **sozinho**, então tempo de execução e manutenção importam muito.
- Ferramentas: **Roblox Studio**, **IA de geração de mesh integrada ao Studio**, **Rojo**, **VS Code** e **Git**.
- Modelos 3D são criados principalmente com a IA de meshes do Studio; a direção visual e o acabamento devem respeitar as limitações dessa ferramenta.
- Meta comercial: construir experiências que possam gerar **Robux ganhos e, eventualmente, receita via DevEx**. Sem prometer dinheiro: **a maioria dos jogos não rende quase nada**.
- Ele quer **lançar e validar cedo**, tomar decisões com dados reais e evitar meses de sistemas sem feedback.
- Prefere conversa em **PT-BR informal, curta e direta**, sem elogios automáticos, enrolação ou bajulação.
- Se uma ideia for ruim, **discorde com argumento e proponha alternativa**.
- Se faltar contexto, faça **no máximo três perguntas de cada vez**; de preferência uma pergunta que realmente destrave a próxima decisão.
- Enquanto estiverem discutindo conceito, **não sair codando nem inflar escopo por conta própria**.
- Este usuário gosta de **assets visuais caprichados, animação, VFX, feedback sonoro e apresentação cinematográfica**, mas quer uma base que funcione em celular.
- Ao produzir imagens e assets visuais, a preferência dele é **PNG**. Isso não transforma arquivos `.rbxm`, `.rbxmx`, `.luau` ou `.md` em PNG: cada tipo de entrega deve usar o formato adequado.

### 1.1. Contexto do jogo anterior — lição, não template

- Jogo anterior de pesca/clicker/idle, conhecido como **Fish Clicker**, depois **Pesque um Meme / Catch a Meme**.
- Ficou muito grande: múltiplas zonas/ilhas, muitas espécies, minigames, rebirth, pets, roleta, missões, rankings e vários outros sistemas.
- No briefing inicial desta conversa, João descreveu esse projeto como não lançado. **Ele corrigiu verbalmente durante a conversa: o jogo anterior JÁ FOI LANÇADO.** Portanto **não** repetir a afirmação de que continua inédito/privado.
- Ele **não apresentou números de retenção, receita ou jogadores do lançamento** nesta conversa. Não inventar métricas, nem presumir sucesso ou fracasso.
- Lição principal: evitar crescimento descontrolado de escopo sem validação.
- Também houve preocupação com uso de memes/propriedade intelectual de terceiros no antigo projeto. **[DECIDIDO] O novo jogo terá criaturas, nomes, modelos e narrativa originais**, sem copiar personagens/marcas de terceiros.
- Não reaproveitar automaticamente sistema, tema, economia, conteúdo, UI, assets ou regras do jogo anterior. Qualquer reuso deve ser deliberado e aprovado.

---

## 2. VISÃO CENTRAL DO NOVO JOGO

**[DECIDIDO / DIREÇÃO CENTRAL]** Um jogo Roblox de **pesca fantástica e coleção**, no qual você começa capturando peixes reconhecíveis e gradualmente encontra criaturas reais impressionantes e **monstros místicos absurdamente raros**, com batalhas divertidas, progressão de pescador e **revelações cinematográficas**.

O coração da experiência é:

1. Jogar a vara em um oceano visualmente enorme.
2. Sentir a fisgada e encarar **um minigame de habilidade**.
3. **Não ver qual peixe/criatura é** durante o desafio.
4. Vencer o desafio e ver a criatura sair da água com animações, câmera, efeitos e sons cuja intensidade acompanha a raridade.
5. Registrar a descoberta na coleção e receber valor/economia para melhorar equipamentos e habilidades.
6. Voltar para tentar criaturas mais raras, participar de eventos e explorar novos conteúdos/ilhas conforme forem lançados.

**Objetivo emocional:** muita sensação de recompensa, surpresa, brilho e espetáculo — **sem transformar isso em pressão abusiva ou monetização injusta**. O jogador deve sentir que capturou uma criatura memorável, não que apenas apertou um botão e recebeu um ícone.

### 2.1. Público e modo de jogar

- **[DECIDIDO] Mobile-first**, mas também para PC.
- O público inclui **crianças**, então os desafios devem ser compreensíveis e alcançáveis.
- **[DECIDIDO]** Deve ser gostoso de jogar **sozinho** ou com alguns amigos. Não depende de roubar, perseguir, competir ou negociar com outros jogadores.
- **[DESCARTADO]** Nada de mecânica estilo **“roube um meme”**, invasão de base ou roubo de itens de outros usuários.
- Exibição social de capturas pode existir futuramente, mas **não foi definido como o núcleo**; a conquista é primeiramente do próprio jogador.

### 2.2. Escalada do extraordinário

- Peixes comuns são relativamente normais e servem como referência de escala.
- Capturas progressivamente mais raras podem incluir espécies reais imponentes, mutações visuais e criaturas místicas.
- No topo da raridade podem aparecer seres absurdos, colossais, elementais, oceânicos, cósmicos ou quase mitológicos, desde que **originais**.
- O contraste importa: **se tudo for ultraextravagante desde o início, os lendários perdem o impacto**.
- Não há ainda **nome definitivo do jogo, tiers exatos de raridade, quantidade de criaturas, economia numérica ou história oficial**.

---

## 3. ILHA / MAPA: DIREÇÃO VISUAL JÁ ESCOLHIDA

Esta é a parte mais concreta do conceito visual.

### 3.1. Evolução da ideia durante a conversa

1. Briefing inicial: uma única ilha.
2. João reconsiderou e disse que seria interessante **ter mais ilhas**, talvez **quatro** e conteúdos novos regularmente.
3. Surgiu a ideia de **ilhas rotativas**: uma ilha entra e outra sai, com novidades anunciadas (ex.: placa ou cronômetro “nova ilha chegando em X”).
4. A discussão recomendou **três ilhas permanentes + uma rotativa**, com rotação inicialmente a cada **2–4 semanas** em vez de construir uma ilha inédita toda semana. **Isso foi sugestão do assistente, não arquitetura aprovada em definitivo.**
5. João ressaltou: **não quer uma mega ilha gigante**. Quer uma **ilha-base compacta**, agradável de circular, com funções próximas.
6. O mar ao redor deve parecer **gigantesco, quase infinito**. A água e o horizonte fazem parte central da fantasia.
7. A pesca principal será feita de um **píer pequeno/adequado à escala da ilha**, não necessariamente de barcos.
8. A vara deve lançar a linha **uma distância visível para fora do píer**: não apenas aos pés do personagem, mas **sem exagero irreal**.
9. Foram geradas **quatro propostas visuais**; João pediu um mix da **3 com a 4**; depois pediu **remover apenas uma barraquinha de vendedor no canto inferior esquerdo** do mix e **manter todo o resto igual**.
10. A imagem resultante, **sem a barraquinha**, é a **REFERÊNCIA VISUAL FINAL APROVADA ATÉ AQUI**. Essa imagem deve prevalecer sobre qualquer conceito anterior.

### 3.2. As quatro propostas visuais iniciais (histórico, NÃO quatro mapas para construir)

- **Versão 1 — Tropical ensolarada:** vegetação tropical, palmeiras, água azul viva, madeira, cabana de upgrades, lagoinha e píer. Muito legível, alegre, mais convencional.
- **Versão 2 — Mística/tempestade:** rochas escuras, oceano dramático, iluminação azul/ciano/roxa, raios distantes, energia mágica, oficina/forja, lagoinha e píer. Mais épica, porém muito escura/pesada como visual permanente.
- **Versão 3 — Enseada cristalina mágica:** cristais grandes azuis, árvores floridas rosa/lilás, água turquesa, vegetação luminosa, caminhos de pedra claros, oficina mágica, ar de fantasia premium.
- **Versão 4 — Porto festivo aconchegante:** casinhas de madeira, muitas lanternas quentes, bandeirolas, um espaço comunitário com bancos/fogueira, flores, palmeiras, píer de madeira, acolhimento e vida social leve.

**[DECIDIDO] Resultado desejado = versão 3 + versão 4**: cenário cristalino/místico **misturado** com porto caloroso, pequeno, colorido e confortável.

### 3.3. Composição EXATA da imagem final aprovada

> Se uma imagem de referência for anexada no novo chat, **trate a imagem como fonte visual primária**. A descrição abaixo serve como especificação de localização e identidade, não substitui a imagem.

**Enquadramento da referência:** vista elevada em ângulo de 3/4, mostrando a ilha inteira, mar azul intenso preenchendo o entorno, horizonte visível, céu claro com nuvens suaves. Há, muito distante no horizonte, uma espécie de silhueta de ilha/castelo místico com anel luminoso no céu: **elemento cenográfico distante, não ilha jogável confirmada**.

**Distribuição espacial da base:**

- **Esquerda:** lagoinha de treinamento pequena e turquesa, com pedras, nenúfares/flores aquáticas, silhuetas de peixinhos, cascata curta saindo de rochas, guarda-corpo de madeira com corda e uma **árvore grande de copa rosa/lilás**, galhos curvos e lanternas quentes penduradas. Placa de madeira **“TRAINING LAGOON (PRACTICE)”** na referência (texto final pode ser localizado). Cristais azuis e vegetação ao redor.
- **Fundo/centro elevado:** **oficina de upgrades**, uma construção de madeira rústica fantástica com telhado azul, escadinha curta, vitrine/prateleiras, luz quente, estandartes azuis e **um pedestal com cristal azul brilhante**. Placa **“UPGRADE WORKSHOP”**. Atrás, morro rochoso pequeno com cristais azuis grandes, flores/folhagem e detalhes de magia dourada acima do telhado.
- **Centro do primeiro plano:** praça pequena de pedras claras, com **símbolo/cristal azul luminoso incrustado no piso**, caminhos limpos e uma área de **fogueira com bancos**, alguns personagens sentados na referência (representam vida social, **não são NPCs com sistemas definidos**). Há flores rosas, azuis e amarelas, pequenos barris/caixotes e lanternas em postes. A praça liga treinamento, oficina, spawn/entrada e píer sem caminhada longa.
- **Frente inferior:** entrada da ilha com **escadaria central de pedra**, postes/luminárias de luz quente e acabamento de rochas, pequenas flores, cristais e água batendo nas pedras. **A posição exata do spawn ainda precisa ser adaptada para que ninguém nasça numa escada, caia no mar ou tenha que dar uma volta enorme**. Sugestão: spawn discreto na praça central ou no caminho imediatamente antes dela, voltado para a oficina/lagoinha/píer.
- **Direita:** **píer de madeira** saindo da praça e projetando-se sobre o oceano. Pilares, cordas nas laterais, postes e lanternas quentes, bóias salva-vidas, placa de madeira **“FISHING PIER”**, bandeira azul. Na referência há um avatar pescando na extremidade: a linha em arco cai na água **bem à frente do píer**, com pequenas ondas/efeito de fisgada.
- **Entorno:** mar claro e brilhante junto às pedras, **azul profundo mais longe**, reflexos e ondas estilizadas; palmeiras, cristais luminosos azul/ciano e vegetação de fantasia com folhagem rosa/lilás e flores coloridas.

**Paleta:** água azul-turquesa e azul-oceano, cristais ciano/azul brilhante, flores rosa/lilás, telhados azuis, madeira em tons quentes, pedras cinza-azuladas, detalhes dourados, lanternas âmbar. O visual deve parecer uma **aventura Roblox estilizada em 3D, de alta qualidade**, não realismo fotográfico nem low-poly genérico sem personalidade.

**Proporção e ritmo:** ilha **compacta** (caminhos de poucos segundos), fácil de entender a partir do spawn. Decoração rica, mas sem entupir a área de colisões, UI ou VFX; o jogador deve localizar pesca, treino e upgrades imediatamente.

### 3.4. O QUE FOI EXPLICITAMENTE REMOVIDO

**[DECIDIDO / NÃO REINTRODUZIR]** No primeiro plano, **canto inferior esquerdo da praça**, havia uma **barraquinha/vendedor com toldo vermelho e branco e símbolo de peixe**. João marcou exatamente esse objeto com um círculo vermelho e pediu: **“só quero remover isso, o resto deixa igual”**. A imagem editada removeu a barraca e manteve o chão/caminhos/decoração.

Não recriar esse vendedor, não substituí-lo por outro quiosque e não usar versões subsequentes que inventaram HUDs, faróis ou mudaram toda a ilha como se fossem a decisão final.

### 3.5. Os conceitos posteriores com HUD NÃO são a base aprovada

Em uma tentativa intermediária de edição, surgiram **imagens novas com HUD, ângulos de terceira pessoa, farol, menus e plataformas redesenhadas**. **Elas não substituem a referência final limpa** descrita acima. O pedido era apenas tirar o vendedor da versão híbrida aprovada. Não importar por engano os elementos inventados nessas variações.

### 3.6. Oceano e lança da vara

- **[DECIDIDO]** O oceano deve transmitir escala imensa e horizonte distante.
- **[DIREÇÃO TÉCNICA]** Não precisa de água matematicamente infinita: pode-se criar a ilusão com terreno/água suficiente, horizonte, atmosfera e soluções de desempenho.
- **[DECIDIDO]** O jogador pesca de um píer de madeira, com vara e **arremesso visível um pouco longe**; a boia não deve cair grudada à borda.
- **[ABERTO]** Distância exata em studs, alcance de varas, se a direção do lançamento é livre ou para área demarcada, e tratamento da câmera durante o arremesso.
- Barco navegável **não é requisito confirmado**. A sugestão de barco existiu, mas João optou pelo píer como pesca principal.

### 3.7. Ilhas adicionais e rotação: cuidado com escopo

- João se interessou por ter **várias ilhas ao longo da evolução do projeto**, talvez com **quatro disponíveis simultaneamente**.
- A ideia mais marcante foi **uma ou mais ilhas saírem e outras entrarem em rotação**, com anúncio antecipado de novidades.
- Ele também quer liberar **criaturas novas frequentemente**, sem depender de construir ilha nova para todo lote.
- **[SUGESTÃO]** Três ilhas fixas + uma rotativa, trocada a cada 2–4 semanas, com retorno futuro de ilhas antigas; a coleção de criaturas permaneceria quando a ilha saísse.
- **[ABERTO]** Quantidade de ilhas no lançamento, número de slots rotativos, frequência real, condições de acesso, progressão entre ilhas e se peixes/eventos raros voltam exatamente iguais.
- Não transformar “nova ilha toda semana” em promessa de produção. **Criar ilhas inéditas gigantes e lendários detalhados semanalmente é trabalho demais para uma pessoa só**.
- A pequena ilha de referência é, por enquanto, a **base central/hub**. Não confundir futuras ilhas de conteúdo com a necessidade de aumentar demais esse hub.

---

## 4. GAMEPLAY DE PESCA — INTENÇÃO E CICLO

### 4.1. Fluxo da captura

1. O jogador vai ao píer (ou ponto de pesca de ilha apropriada, se houver expansão).
2. Prepara a vara e arremessa a boia uma distância perceptível em direção ao mar aberto.
3. Aguarda alguma criatura morder a isca. Tempo exato de espera **não definido**.
4. A câmera e os efeitos comunicam fisgada, resistência, tensão e raridade de modo gradual.
5. Inicia um **desafio de pesca com habilidade**; ele pode variar de acordo com a criatura/captura.
6. **A identidade da criatura fica escondida durante toda a batalha.** Pode haver agitação de água, puxões, flashes ou energia, mas **a criatura só aparece quando sair da água depois da vitória**.
7. Se vencer: sequência de puxada/revelação, criatura emerge, sons e efeitos proporcionais ao raro, coleção atualiza, há ganho de valor/moedas.
8. Se falhar: a criatura escapa; feedback visível, sem punição absurda.
9. O jogador usa os recursos obtidos para comprar melhorias, treinar e tentar capturas cada vez melhores.

### 4.2. Os desafios são variados, mas não empilhados arbitrariamente

João rejeitou a ideia de obrigar sempre o jogador a passar por **dois minigames diferentes em sequência** numa única captura. Ele quer **variação**, com cada desafio podendo aparecer em capturas distintas ou em grupos de criaturas.

**[ATENÇÃO — AMBIGUIDADE A RESOLVER]** Em um momento João disse **“Todo peixe vai ter a mecânica do Stardew Valley”**; logo depois explicou que **alguns peixes terão a barra de precisão e outros algo tipo osu!**. O sentido provável é que o controle no estilo Stardew seja um sistema-base/familiar, com alternativas em certas capturas. **Não decidir por conta própria** se todos os peixes terão obrigatoriamente o Stardew **além** de outro minigame, porque isso contradiria o pedido de não empilhar desafios. Confirmar antes de implementar.

### 4.3. Minigame A — Controle de pesca estilo Stardew Valley

**[DECIDIDO COMO MECÂNICA DESEJADA]**

- Há uma barra/área verde de controle e um peixinho/marcador que se movimenta.
- O jogador deve **manter o marcador do peixe dentro da região verde**, reagindo às mudanças de posição/movimento.
- O peixinho se move, e a velocidade/imprevisibilidade variam com a raridade.
- Existe **uma barra vermelha de falha** que aumenta quando o jogador perde o controle.
- Se o jogador recuperar controle, **[SUGESTÃO ACEITA NA EXPLICAÇÃO]** a barra vermelha pode diminuir.
- **Se a barra vermelha chegar a 100%, a criatura escapa.**
- Interface deve funcionar em **toque no celular**, sem exigir mouse preciso nem teclado.
- Para comum, movimento suave; para lendários, mais tensão, mas com padrão legível.

### 4.4. Minigame B — Barra de precisão / três acertos

**[DECIDIDO COMO MECÂNICA DESEJADA]**

- Um ponto ou bolinha corre por uma barra de um lado ao outro.
- Há uma **região demarcada de acerto**.
- Quando o ponto atravessa a marca, o jogador aperta na hora certa.
- Exemplo verbal: apertar **P** no PC, mas como o jogo é mobile-first, **deve haver toque/botão grande equivalente** (a tecla final do PC não está fechada).
- Deve acertar, como exemplo dado por João, **três vezes** para concluir a captura.
- Ao errar, um indicador vermelho de erro acende (detalhes na seção 5).
- Velocidade e janela de acerto variam conforme dificuldade/raridade.

### 4.5. Minigame C — Ritmo / toque estilo osu!

**[DECIDIDO COMO MECÂNICA DESEJADA]**

- Surgem círculos/bolinhas na tela.
- Um anel externo se fecha em direção ao alvo; o jogador **toca/clica no momento certo**, podendo haver pequena sequência de alvos.
- Deve ser uma mecânica original inspirada no princípio de timing, **não copiar UI, marca, som ou assets do jogo de referência**.
- Para PC: clique ou outra entrada simples; para celular: **toque em áreas grandes, com tolerância**.
- Dois erros levam à perda da captura, conforme a regra explicitada na conversa.
- A mesma linguagem de toques/rings pode aparecer **nos treinamentos** para conceder bônus de progresso.

### 4.6. Ideia extra: dado/RPG

**[IDEIA LEVANTADA, NÃO DECIDIDA]** João sugeriu variar com uma captura em que se rola um dado e uma rolagem alta ajuda a trazer o peixe, baixa faz perder. A resposta ponderou que **uma rolagem aleatória que anule sozinha uma batalha bem executada seria frustrante**.

**[SUGESTÃO]** Se existir um dado místico, usá-lo para **bônus, mutação, recompensa, sorte de descoberta ou segunda chance**, em vez de simplesmente invalidar a habilidade. Ainda não existe decisão sobre a existência dessa mecânica no lançamento.

---

## 5. DIFICULDADE, ERROS, ACESSIBILIDADE E FEEDBACK

### 5.1. Princípio de balanceamento

- **[DECIDIDO]** Quanto mais rara a criatura, mais intenso/difícil o desafio.
- **[DECIDIDO]** **Não pode ser extremamente difícil**, porque há crianças e usuários de celular.
- O desafio deve permitir aprender, melhorar o equipamento e sentir progresso, mas sem reflexos de jogador profissional.
- **Aumentar principalmente a complexidade visual, tensão, variação de movimento e espetáculo; não necessariamente punir com janelas absurdamente pequenas.**
- Evitar lag/latência como causa de erro injusto; desenvolver e testar de verdade no dispositivo móvel.

### 5.2. Sistema exato de erros por minigame

**Stardew-like:**

- Um **medidor vermelho de erro/falha**.
- Falhas no acompanhamento fazem esse medidor subir.
- Quando enche completamente, o peixe/criatura **escapa**.
- Possibilidade de recuperar reduzindo a barra enquanto joga bem.

**Precisão e osu!-like:**

- **Duas bolinhas/vidas vermelhas** como indicador.
- **Primeiro erro:** uma bolinha pisca e fica vermelha/ativa.
- **Segundo erro:** as duas piscam em vermelho e a criatura é perdida.
- Esse limite de erros deve ser claro na interface, com feedback perceptível sem poluir a tela.

**[SUGESTÃO]** Pequena sacudida de câmera, estalo da linha ou aumento da tensão no primeiro erro; no segundo, animação curta de linha arrebentando/escape. **Não fazer tremores violentos ou flashes agressivos**.

### 5.3. Dificuldade escalonada

- Comunidade de crianças/celular: toque claro, alvo grande, contraste, antecipação de movimento, chance de recuperação.
- Criaturas comuns: menos tempo, poucos movimentos e grande tolerância.
- Criaturas raras: ritmo mais ágil e mudanças de movimento.
- Épicas/lendárias: padrões surpreendentes, câmera e som mais intensos, **mas regras consistentes e possíveis de aprender**.
- **[SUGESTÃO]** Deixar o limite de **dois erros** nos minigames de clique/ritmo inclusive nos lendários; dificuldade sobe por ritmo/padrão, não por zerar a tolerância.
- **[SUGESTÃO NÃO APROVADA EM NÚMEROS]** Desafios comuns por volta de ~5 s e lendários ~15–20 s. Não tratar como duração confirmada.
- **[ABERTO]** Como equipamento, nível, treinamento e habilidade individual se combinam no balanceamento.

---

## 6. REVELAÇÃO E ANIMAÇÕES CINEMATOGRÁFICAS — O GRANDE DIFERENCIAL

**[DECIDIDO]** O jogador **NÃO deve descobrir a criatura antes de retirá-la da água**. A identidade é revelada somente **depois de vencer o desafio** e a criatura emergir.

### 6.1. Sensação da fisgada

- Uma captura rara deve parecer fisicamente mais pesada e misteriosa.
- A vara dobra, a linha ganha tensão, o mar agita ou brilha e a câmera pode mudar de ângulo.
- Sons, rumble visual, partículas, luz e movimento de câmera aumentam a expectativa.
- Importante: esses efeitos não precisam revelar a silhueta/modelo específico antes da vitória.

### 6.2. Exemplo da revelação lendária imaginada por João

1. Conclusão de uma batalha intensa.
2. O personagem puxa a vara com força, a câmera acompanha.
3. Água se rompe, a criatura faz **um salto grandioso saindo do oceano**.
4. **Raios/relâmpagos** podem cair, a câmera descreve o salto e a revelação.
5. Luzes, brilho, VFX, impacto musical e poses transformam o momento em um pequeno evento cinematográfico.
6. A criatura fica visível em destaque, com tamanho/raridade/nome e valor/descoberta que podem ser apresentados de forma elegante.
7. O jogador pode admirar e continuar pescando sem ficar preso em cutscenes repetitivas.

**A direção é espetacular, não realista/documental.** Modelos 3D detalhados e originais, câmera, partículas, cor e som devem atuar em conjunto. João quer um resultado visualmente **bem diferenciado**, com muito brilho na tela, principalmente nos lendários.

### 6.3. Restrições importantes

- **[DIREÇÃO FORTE]** Não fazer uma cutscene gigantesca para toda sardinha; reservar o pico de efeitos para grandes raridades e primeiras descobertas.
- **[SUGESTÃO]** Permitir pular/encurtar animação repetida; nunca atrapalhar o ritmo de pesca.
- **Mobile-first:** controle de partículas, transparências e pós-processamento para manter FPS estável.
- **Acessibilidade:** tremor/flash moderado ou ajustável; não sacrificar a legibilidade do minigame.
- Diferenciar três camadas: **animação do personagem**, **efeitos da água/ambiente** e **revelação do modelo 3D da captura**.
- Não existe ainda storyboard final, pipeline de animação ou lista de VFX aprovada para cada criatura.

---

## 7. TREINAMENTO / EVOLUÇÃO DO PESCADOR

João acrescentou um sistema de treino como parte importante da vida na ilha.

### 7.1. Local físico

- **[DECIDIDO]** Uma **lagoinha pequena e bonita**, integrada ao mapa compacto, funciona como área de prática.
- A imagem final coloca essa área **à esquerda**, sob uma árvore florida rosa/lilás, perto de uma pequena cachoeira.
- O jogador chega ali e **interage** para começar a treinar.

### 7.2. Treino quase idle, mas visual

- **[DECIDIDO]** O treino deve ser **semi-idle**: após interagir, o personagem começa uma animação de exercício/prática automaticamente.
- O personagem ganha **nível de treinamento/progresso** enquanto treina; a evolução deve aparecer de forma clara e satisfatória.
- Durante o treino podem surgir **eventos ocasionais de ritmo com círculos** no estilo osu!, exigindo toque no momento certo para melhorar o desempenho/ganhar algum bônus.
- João enfatizou **“jogos de câmera” e animações** durante o treinamento, e não só uma barra parada na interface.
- O treinamento não deve exigir ficar clicando freneticamente sem parar; a base é uma atividade tranquila e visual.

### 7.3. Vários tipos de treino

João quer poder evoluir diferentes atributos, com exemplos:

- **Facilitar a captura/minigames**.
- **Aumentar um pouco a sorte** nas pescarias.

**[SUGESTÕES DE NOMES, NÃO DECIDIDOS]:** “Controle” (janela de acerto/movimentação mais amigável) e “Instinto” (pequeno bônus de sorte). Outros atributos, limites, fórmulas e tempos **ainda não foram definidos**.

### 7.4. Perguntas abertas do sistema de treino

- É um treino genérico com escolha de habilidade ou estações diferentes?
- XP ganho por tempo, por acertos ocasionais, por sessões ou por pesca também?
- Pode treinar enquanto AFK por quanto tempo? Há limite?
- Treinamento evolui infinitamente ou tem teto/cap?
- Como garantir que treino não torne captura lendária automática e desvalorize o minigame?
- O bônus do círculo de ritmo vale só XP extra, um multiplicador temporário ou progresso de uma habilidade específica?
- Quais efeitos visuais/câmera são leves o suficiente para celulares?

**Não implementar esses detalhes inventando números.** Discutir primeiro e fazer uma versão simples.

---

## 8. PROGRESSÃO, EQUIPAMENTOS, ECONOMIA E COLEÇÃO

### 8.1. Progresso do pescador

- **[DECIDIDO]** Capturas têm **valor econômico**, concedendo moeda/dinheiro do jogo.
- O dinheiro permite **melhorar a vara, facilitar pescarias e evoluir capacidades do pescador**.
- Deve haver uma sensação contínua de evolução: conseguir capturar criaturas melhores, enfrentar desafios mais difíceis e melhorar itens.
- Os upgrades devem ser perceptíveis no jogo, não apenas números incompreensíveis.
- **[ABERTO]** Fórmulas exatas, nomes das moedas, níveis máximos, preços, desbloqueios, rebirth, inventário, auto-venda e progressão por ilhas.
- **[SUGESTÃO]** Melhor equipamento pode ampliar levemente janela de acerto, suavizar movimentos ou reduzir dificuldade, preservando a necessidade de habilidade.

### 8.2. Oficina de upgrades

- **[DECIDIDO VISUALMENTE]** A oficina fica **no centro/fundo** da ilha, com fachada de madeira, telhado azul, cristais e iluminação quente.
- Vai servir para varas/equipamentos/habilidades quando os sistemas forem projetados.
- O pedido de mapa autoriza construir a **estrutura**, não inventar uma loja completa com várias moedas, árvores de skills e game passes.

### 8.3. Coleção das capturas

- **[DECIDIDO]** Colecionar criaturas raras é o objetivo principal, além de evoluir.
- Capturas reais e místicas devem ter identidade própria e grande variedade visual.
- A coleção precisa **persistir** e preservar descobertas de criaturas de eventos/ilhas que saem da rotação.
- **[DIREÇÃO FORTE]** Os lendários devem ter pequenas histórias/narrativas interessantes e design reconhecível, não só mudança de cor.
- **[ABERTO]** Se o jogador mantém cópias físicas, vende automaticamente, guarda troféus, pode equipar/exibir criaturas, troca com amigos ou apenas preenche um bestiário.
- Não importar as regras de venda do jogo anterior sem perguntar.

---

## 9. CRIATURAS E DIREÇÃO ARTÍSTICA

**[DECIDIDO]** Começa com peixes convencionais e cresce até criaturas místicas absurdas. Podem existir **animais reais, versões fantásticas, espíritos, seres elementais, criaturas oceânicas gigantescas, dragões etc.**, sem se prender a peixes biologicamente reais.

### 9.1. Exemplos imaginados na conversa — NÃO catálogo aprovado

- Sardinhas e peixes comuns de início.
- Tubarões e animais reconhecíveis mais impressionantes.
- Uma enguia elétrica gigantesca.
- Um leviatã monstruoso, com chifres, muitos olhos, relâmpagos e escala colossal.
- Criaturas de magma em ambiente vulcânico.
- Criaturas celestiais luminosas em ambientes de fantasia.
- Criaturas que parecem dominar tempestades, o céu ou as profundezas.

Esses são **exemplos de tom**, não personagens aprovados com nomes oficiais ou promessas de presença no MVP.

### 9.2. Como um lendário deve ser memorável

- Silhueta imediatamente reconhecível.
- Materiais, cores e efeitos que expressem personalidade/elemento.
- Pequena história ou mistério conectado à criatura e ao mundo.
- Escala e entrada em cena impactantes.
- **Originalidade de IP** e possibilidade técnica realista de construir a mesh/efeitos.
- O uso de meshes IA não significa que cada monstro deva ter rigging complexo, dezenas de animações ou geometria excessiva.

---

## 10. EVENTOS, RETENÇÃO E NOVIDADES

### 10.1. Eventos dinâmicos

- **[DECIDIDO]** O mundo pode desencadear **eventos especiais aleatórios/ocasionais**.
- Durante o evento surgem **oportunidades de capturar criaturas muito raras** que normalmente não aparecem ou ficam mais difíceis de encontrar.
- Exemplos temáticos sugeridos: marés raras, chuva/tempestade, alteração de clima e horário, criaturas específicas surgindo no oceano.
- **[ABERTO]** Frequência, duração, locais, multiplicadores, chances, duração dos anúncios e se os eventos são globais/por servidor.

### 10.2. Novos conteúdos

- João quer **adicionar criaturas com frequência**, talvez até semanalmente, quando a produção permitir.
- Ilhas adicionais/rotativas criam expectativa e novidade, mas **não prometer uma ilha completamente nova por semana**.
- É importante que as criaturas registradas **não sumam da coleção** porque uma ilha saiu.
- **[SUGESTÃO]** Ilhas antigas podem voltar depois; isso reduz pressão excessiva de tempo (**FOMO** = medo de perder algo para sempre).
- **[ABERTO]** Uma ilha rotativa deve estar aberta a todos ou exigir nível? A recomendação foi entrada para todos e equipamentos melhores para capturas mais difíceis, **ainda sem decisão final**.

### 10.3. Retenção sem armadilhas

- Gancho desejado: desejo genuíno de descobrir algo novo, melhorar equipamento, treinar mais, completar coleção e participar de eventos.
- Cuidado com exclusividade definitiva, contadores agressivos, login obrigatório e frustrações artificiais.
- O jogador deve sentir vontade de voltar amanhã, **não medo de perder um item para sempre**.

---

## 11. MONETIZAÇÃO E REGRAS DO ROBLOX

**[PRINCÍPIOS EXPLICITAMENTE PEDIDOS, MAS SISTEMAS NÃO DEFINIDOS]**

- Monetização justa, por exemplo **game passes** ou **developer products** cujo valor seja compreensível e não destrua o desafio.
- Evitar **pay-to-win abusivo**, vantagem extrema em captura e design voltado a pressionar crianças.
- Ter cuidado redobrado com **itens aleatórios pagos**. Se houver qualquer mecânica de sorte vinculada a Robux ou moeda comprada com Robux, **consultar as políticas atuais e oficiais do Roblox**, requisitos de divulgação de probabilidades, restrições regionais e sistemas de elegibilidade **antes de projetar/implementar**. Não presumir que todo sorteio pago é permitido.
- Recompensa rara por **pesca jogada** não é, por si só, uma ordem para criar loot box paga.
- Não estabelecer valores de Robux, multiplicadores, passes e produtos agora sem discutir.
- Ser realista: monetização só faz sentido se houver diversão/retensão reais; **nenhuma garantia de DevEx ou sucesso comercial**.

---

## 12. ESCOPO E MVP: NÃO REPETIR O PROJETO ANTERIOR

### 12.1. Orientação geral

**[DECIDIDO COMO MÉTODO]** Primeiro lançar/validar algo pequeno e polido; depois expandir com base em uso real. O projeto é SOLO, então cortar funcionalidades é parte do design.

### 12.2. Proposta de MVP — SUGESTÃO, NÃO ESCOPO APROVADO

Uma versão testável em **semanas, não meses**, poderia ter:

- **Uma ilha-base compacta** fiel à referência final, com praça, oficina, treino, píer, spawn e oceano convincente.
- Um arremesso de vara bonito, uma fisgada clara e **um minigame principal completo e bem polido** antes de outros.
- Depois, no MVP ou primeiro patch, um segundo minigame; adicionar o terceiro só se o cronograma permitir.
- Um conjunto pequeno de criaturas originais, misturando comuns e **ao menos um ou dois momentos lendários marcantes**. Quantidades exatas a decidir.
- Economia básica, algumas melhorias relevantes, registro de coleção e salvamento.
- Uma revelação comum/rápida e uma revelação lendária altamente trabalhada.
- Um treino visual simples se não atrasar a diversão principal; mais atributos/minigames podem vir depois.
- Um evento simples que mude possibilidade de captura, sem exigir sistema global complexo.

**O que tende a ficar para depois**: criar 4 ilhas imensas antes de validar, eventos gigantes semanais, dezenas de minigames, muitas árvores de habilidades, pets, rebirth, vários NPCs complexos, barcos com física, trading, sistemas sociais obrigatórios ou infraestrutura de live ops sofisticada.

**[ABERTO]** João ainda não aprovou esse recorte preciso. Se ele quiser três minigames já na estreia, **expor o custo/risco**, discutir prioridades e não fingir que sai em poucos dias.

### 12.3. Critérios de qualidade

- O jogo precisa ficar bom **no celular** e ter feedback claro de toque.
- O diferencial comercial que mais importa testar é **a qualidade/satisfação do ciclo pesca → desafio → revelação**, e não a quantidade de sistemas laterais.
- Usar analytics básicos para identificar tutorial, primeira captura, primeira melhoria, falhas nos desafios e retorno; **não inventar percentuais-alvo como fatos**.

---

## 13. ESTADO DA CONSTRUÇÃO DO MAPA E ENTREGA ANTERIOR

Depois do brainstorm e da aprovação da imagem híbrida sem vendedor, João perguntou o que poderia ser feito além de imagens: se seria possível **já montar mapa 3D para Roblox**, até mesmo sem texturas para texturizar depois.

### 13.1. O que ele solicitou

- **[DECIDIDO]** Transformar a imagem final em **mapa jogável o mais parecido possível**, mantendo **cores, materiais, luzes, detalhes, áreas e atmosfera**.
- Permitir **pequenos ajustes de escala, circulação, visibilidade e spawn** para ficar divertido de jogar.
- Não se contentar só com uma nova imagem: quer algo editável/útil no **Roblox Studio**.
- **[DECIDIDO]** O resultado pode começar como geometria de base e ir recebendo meshes/complexidade depois, mas o desejo é avançar o máximo possível no visual.

### 13.2. Formato de implementação debatido

Foi proposta uma abordagem com:

1. **Gerador Luau** rodado uma vez no **Command Bar** do Roblox Studio.
2. Criação de terreno/base da ilha, caminhos, oficina, lagoinha, cachoeira, pedras, cristais, árvore, praça, fogueira, píer, postes e spawn.
3. Objetos organizados em **Models editáveis no Workspace**, não recompostos a cada login.
4. Materiais e cores nativas primeiro; depois substituições cuidadosas por **MeshParts** geradas com IA.
5. Atenção a colisões, hierarquia, pontos de interação, segurança das bordas e performance mobile.
6. Possível exportação/importação de `.rbxm`/`.rbxmx` se houver ferramenta e validação real para isso.

A resposta anterior afirmou ter preparado um **pacote da primeira versão**, com nomes de arquivos:

- `Pacote_Ilha_Mistica_Roblox_v1.zip`
- `Ilha_Mistica_Gerador_Studio.luau`
- `LEIA_PRIMEIRO_Mapa_Roblox.md`
- `REFERENCIA_Ilha_Aprovada.png`

**Aviso de confiabilidade:** nesta conversa **não houve execução/teste confirmado do gerador dentro do Roblox Studio**, nem confirmação de que o mapa ficou fiel à imagem após importação. Não assumir que está pronto, funcionando ou validado só porque foi mencionado. Se esses arquivos forem fornecidos a você, abra, revise, execute/teste e conserte o que for necessário. Se não forem fornecidos, **não inventar o conteúdo deles**.

### 13.3. Decisão mais recente: usar Claude

João decidiu que vai **usar o Claude** para avançar na construção. O presente documento serve como **handoff completo de contexto**. O próximo passo depende do pedido dele: pode querer começar mapa, revisar gerador existente, produzir modelos, ajustar layout ou continuar brainstorm. **Não realizar automaticamente todos os sistemas.**

---

## 14. REQUISITOS VISUAIS E DE JOGABILIDADE PARA RECONSTRUIR A ILHA

Esta seção transforma a imagem aprovada em critérios verificáveis quando houver tarefa de montagem:

### 14.1. Fidelidade

- Preservar **distribuição:** treino à esquerda, upgrades ao fundo, praça central, píer à direita, escadas no primeiro plano.
- Preservar **identidade:** cristais azuis/ciano brilhantes, florada rosa/lilás, lanternas quentes, madeira, flores, cachoeira, água turquesa costeira e mar azul vasto.
- Preservar **pequena escala** e integração visual dos ambientes.
- O acabamento deve parecer uma **ilha completa**, não três plataformas isoladas ligadas por passarelas genéricas.
- Remover a **barraquinha de vendedor inferior esquerda** sem colocar substituto.
- Evitar acrescentar farol, prédios gigantes, menus/HUD, portal de treino substituindo a lagoinha ou outras invenções que alterem a composição final sem autorização.

### 14.2. Funcionalidade espacial

- Spawn com espaço plano e seguro, orientação inicial que mostre pontos de interesse e caminho simples até cada função.
- Rotas largas para avatares e jogadores mobile, escadas usáveis, sem obstáculos pequenos bloqueando passagem.
- Guarda-corpo adequado no píer sem atrapalhar a animação/arremesso.
- Uma área de pesca válida e bem enquadrada no fim do píer.
- Área de treino suficientemente ampla para animações/movimentos/câmera, sem empurrar o personagem para a água.
- Oficina acessível e legível: entrada ou prompt/área de interação a ser definido posteriormente.
- Decoração sem colisão desnecessária e sem excesso de peças repetitivas causando queda de FPS.
- Evitar céu totalmente vazio ou mar cortando abruptamente; **horizonte convincente**.

### 14.3. Arquitetura editável recomendada (não imposição de nomes)

Organizar, quando o trabalho for solicitado, algo equivalente a:

```text
Workspace/
  MagicalFishingIsland/
    IslandGround/
    SpawnAndPaths/
    TrainingLagoon/
      Pond/
      Waterfall/
      PinkTree/
      TrainingProps/
    UpgradeWorkshop/
      MainBuilding/
      Roof/
      CrystalPedestal/
    CentralPlaza/
      DecorativeCrystal/
      CampfireAndBenches/
    FishingPier/
      DeckAndSupports/
      RailingsAndRopes/
      FishingPositions/
    RocksAndCrystals/
    VegetationAndFlowers/
    LanternsAndBanners/
  Ocean/
```

**Os nomes são uma proposta de organização, não uma árvore de objetos já existente.** Se estiver usando Rojo, planejar a divisão entre assets permanentes do `.rbxl` e código versionado sem quebrar o fluxo de trabalho.

---

## 15. DECISÕES E RESTRIÇÕES EM FORMATO DE CHECKLIST

### Já decidido ou explicitamente pedido

- [x] Novo jogo de Roblox, solo dev, focado em **pesca, criaturas fantásticas, progressão e coleção**.
- [x] Jogo pensado para **celular**, mas também PC.
- [x] Experiência agradável sozinho ou com poucos amigos, **sem roubos**.
- [x] Peixes simples no início; raridades altas com **criaturas místicas, reais e absurdas**.
- [x] Modelos 3D originais, lendários detalhados e apresentação cinematográfica.
- [x] Não revelar o modelo/nome da criatura durante o minigame; revelar **ao sair da água depois da captura**.
- [x] Efeitos e câmera cada vez mais intensos conforme a raridade, sem dificuldade impossível para crianças.
- [x] Minigames desejados: **controle estilo Stardew**, **barra de precisão com ~3 acertos** e **ritmo/timing estilo osu!**.
- [x] Falha no Stardew-like por **barra vermelha cheia**.
- [x] Falha nos minigames de timing por **2 erros**, com 2 indicadores vermelhos.
- [x] Capturas rendem valor/moedas e permitem evoluir equipamentos/habilidades.
- [x] Treinamento **semi-idle**, com interação inicial, animação e círculos ocasionais de timing; níveis/atributos.
- [x] Possibilidade de **eventos** que permitem criaturas raras.
- [x] Ilha-base **pequena e compacta**, envolta por **oceano aparentemente enorme/infinito**.
- [x] Pesca principal a partir de **píer**; arremesso chega a uma distância visível no mar.
- [x] Direção visual **mix da imagem 3 (cristais mágicos) com a 4 (porto aconchegante)**.
- [x] Na referência híbrida, remover **somente a barraquinha de vendedor inferior esquerda**; restante igual.
- [x] Se for montar mapa, entregar **estrutura editável e jogável para Roblox Studio**, mantendo cores/detalhes o mais próximo possível, com ajustes de uso razoáveis.
- [x] Evitar propriedade intelectual de terceiros.
- [x] Não repetir o erro de fazer um jogo imenso antes de testar a diversão real.

### Discutido, mas NÃO decidido / não presumir

- [ ] Nome definitivo do jogo.
- [ ] Tema de cada ilha adicional, número inicial de ilhas e número de vagas rotativas.
- [ ] Intervalo de rotação de ilhas; se novas ilhas serão semanais, quinzenais ou mensais.
- [ ] Se todas as capturas **sempre** usam Stardew-like ou se cada uma escolhe somente um dos minigames.
- [ ] Tempo de espera para fisgada, tempo de cada desafio, probabilidades e raridades exatas.
- [ ] Quais atributos de treino existem, quanto sobem e quanto afetam a pesca.
- [ ] Quanto a qualidade da vara pesa em relação à habilidade do jogador.
- [ ] Dado/RPG como mecânica real.
- [ ] Rebirth, pets, ajudantes, barcos, trading, placares, missões, inventário e venda.
- [ ] Lista final de espécies, seus nomes, chances e suas narrativas.
- [ ] Calendário, chances e regras de eventos.
- [ ] Game passes, developer products, preços e economia numérica.
- [ ] Recorte exato do MVP e data de lançamento.
- [ ] Escala em studs, spawn exato, materiais/asset IDs e arquitetura final do mapa.

---

## 16. EXEMPLOS DE EXPERIÊNCIA (CENAS PARA AJUDAR A ENTENDER O TOM)

### Cena A — Captura comum

O jogador lança a linha alguns metros além do píer. A boia afunda. Entra uma barra de controle simples e amigável. Ele acerta, recolhe e puxa um peixe comum com um pequeno splash, comemoração curtinha, moedas e progresso de coleção. Sem raios gigantes nem demora desnecessária.

### Cena B — Captura lendária

A linha repuxa violentamente, a câmera se aproxima, a água muda de movimento; o jogador **não vê a criatura**, mas sente que é extraordinária. Entra um desafio intenso, ainda legível no celular. Após vencer, a câmera faz uma trajetória cinematográfica, o oceano se rompe, uma criatura enorme dá um salto, raios e partículas realçam a revelação, música/impacto celebram a descoberta. O jogador descobre **só agora** o nome, aparência e raridade. A criatura entra no bestiário. A sequência deve ser poderosa, mas breve ou pulável depois de vista.

### Cena C — Treino na lagoinha

O jogador chega à pequena lagoa sob a árvore rosa, interage e começa a treinar. O avatar realiza uma animação simples e charmosa, a câmera aproxima por um instante e o nível de treinamento sobe lentamente. De vez em quando aparecem anéis de timing para tocar; acertar concede um bônus. O jogador não precisa ficar fazendo spam de clique para que algo aconteça.

### Cena D — Evento de oceano

Enquanto o jogador pesca, o céu/mar muda por um período especial; surge a chance de descobrir uma criatura rara associada àquele evento. Há anúncio claro e expectativa, mas a criatura pode voltar em algum outro ciclo — **não criar uma exploração exagerada do medo de perder para sempre**.

---

## 17. COMO O CLAUDE DEVE AGIR DAQUI PARA FRENTE

1. **Considere este documento o registro completo do brainstorming atual**, não um sistema fechado.
2. **Não confunda o novo jogo com o Pesque um Meme**, nem incorpore o Vault antigo sem instrução.
3. **Respeite rigorosamente a referência visual final** (ilha V3+V4 **sem o vendedor**). Se a imagem estiver anexada, analise a imagem com atenção antes de propor geometria.
4. **Fale em PT-BR informal, direto e objetivo**, sem elogios vazios. Discorde quando necessário e explique o porquê.
5. **Até três perguntas por vez**. Priorize decisões que alterem escopo/gameplay.
6. **Não começar a codar sem pedido claro.** Este arquivo é contexto para a próxima etapa.
7. Ao receber autorização para implementar, preferir entregas **pequenas, testáveis, editáveis e reproduzíveis** no Roblox Studio; separar terreno, decoração, meshes e scripts.
8. Quando disser que algo está funcionando, **validar no Studio** ou dizer claramente o que ainda não foi testado. Não prometer um mapa idêntico a partir de uma única imagem 2D.
9. Não transformar cada sugestão do assistente anterior em uma decisão do desenvolvedor.
10. Sempre pensar em **performance mobile**, usabilidade, legibilidade e ética de monetização.
11. Reaproveitar módulos/artefatos antigos **só se fornecidos e aprovados** para este jogo.
12. Se o usuário disser **“vamos montar o mapa”**, priorizar o cenário compacto do conceito aprovado. Se disser **“vamos fechar o jogo”**, continuar brainstorming, começando pelas ambiguidades mais relevantes.

### Próxima ação sugerida (não executar sem pedido)

Se o próximo pedido for construir a ilha: (a) confirmar que tem a **imagem final sem a barraquinha**, (b) verificar se também foram anexados o `.zip`/`.luau` gerados anteriormente, (c) inspecionar o que realmente existe, (d) reconstruir/refinar a ilha de modo fiel, com **spawn funcional, oficina, treinamento, praça e píer**, (e) testar a execução no Roblox Studio e iterar com capturas do resultado. A prioridade é ficar **o mais próximo possível da arte**, não apenas produzir uma graybox sem graça, respeitando limites de um dev solo e do desempenho mobile.

---

## 18. RESUMO EM UMA FRASE PARA NÃO PERDER A ESSÊNCIA

> **Um jogo Roblox de pesca fantástica, solo-friendly e mobile-first, em uma pequena ilha mágica de cristais azuis, árvore rosa, oficina, lagoinha de treino e píer sobre um oceano imenso; o jogador evolui equipamentos e habilidades, enfrenta minigames de pesca acessíveis e variados, e só descobre que criatura real ou mística capturou quando ela explode da água numa revelação cinematográfica, com eventos e novas ilhas/criaturas mantendo o mundo vivo — tudo original e com escopo controlado.**

**Fim do contexto atual. Aguarde a próxima instrução de João.**

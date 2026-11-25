# Legendary Catch: resumo de tudo que o jogo tem hoje

Atualizado em **24/11/2026**. Para o detalhe completo, veja `docs/JOGO-COMPLETO.md` (base de 20/11) e `docs/COORDENACAO.md` (Mural). Os prints de cada região estão em `docs/tour/TOUR-DO-MUNDO.pdf`.

Legenda de estado: **[pronto]** funciona no Studio, **[flag]** pronto mas desligado atrás de uma flag, **[provisório]** existe mas será refeito, **[falta]** ainda não existe.

## 1. O jogo em uma frase
Jogo Roblox de **pesca fantástica e coleção**. Você pesca de um píer, vence um minigame de habilidade **sem saber o que fisgou**, e a criatura aparece numa **revelação cinematográfica** cada vez mais épica conforme a raridade. Mobile-first (também PC). Público inclui crianças: sem dificuldade cruel, sem flash agressivo, sem caixa aleatória paga. Estilo "cartoony candy": cores vivas, cristais ciano, rosa/lilás, dourado, madeira quente.

Place `112666482424701`, universe `10777276665`. Repo público `github.com/joaovittorcc/Legendary-Catch`.

## 2. O loop principal
1. O jogador vai à **ponta do píer** (única zona de lançamento) e usa a vara.
2. **Barra de força** [flag `FishingPower`]: uma barra vertical com faixas de cor (vermelho, amarelo, verde, roxo, neutro). O marcador branco sobe e desce rápido (o servidor sabe a posição pelo tempo). O jogador toca na hora certa. A faixa acertada define o lance (arremesso, sorte).
3. **Cutscene de lançamento** (a câmera acompanha o arremesso), boia na água, espera da mordida (2 a 5 s).
4. O servidor sorteia a criatura e só manda ao cliente a **raridade e o minigame**.
5. **Minigame** (puxar, precisão ou ritmo). Dificuldade sobe com a raridade. Facilitam: treino de **Controle** e bônus da vara.
6. Captura validada no servidor (tempo mínimo, 1 vitória por lance), que paga moedas, XP, coleção, combo e conquistas.
7. **Show da captura** + **revelação**: criatura de frente, card 3D com nome, raridade, peso, valor e descrição. Lendária e Mística ganham cinemática de portal. Selo "NOVA DESCOBERTA" na primeira vez.
8. **Roleta da captura** [flag `FishingRoulette`]: tamanho, encolher, **mutação** e "girar de novo", que mudam o valor.
**Regra de ouro:** o servidor decide moeda, item, captura e raridade. O cliente só mostra.

## 3. Conteúdo
- **106 criaturas, 6 raridades** (Comum, Incomum, Rara, Épica, Lendária, Mística) e a variante **Cintilante** (1 em 40, vale ×3). 2 Místicas (C93 Ouroboros Cósmico, C94 Maré Primordial), 6 exclusivas de evento e 6 de Natal. Modelos 3D em `ReplicatedStorage.Creatures`. Remodelagem em Blender em andamento por raridade.
- **8 varas** (Iniciante a Mística) com modelo 3D. A vara vale mais pela **sorte** do que pela renda.
- **6 eventos do oceano** (Maré Estelar, Tempestade, Hora Dourada, Cardume Cintilante, Nevoeiro, Aurora), com bônus e criaturas exclusivas.
- **Zonas de pesca:** Lagoa do hub (nível 1), **Recife de Coral** (nível 5) e **Abismo Estelar** (nível 15), as duas últimas em ilhas próprias com portais. O servidor bloqueia por nível.

## 4. Progressão e economia
- Nível do jogador (XP por captura; máx 100), baú a cada 10 capturas, 19 conquistas, códigos promocionais, login de 7 dias, 3 desafios diários, marcos da coleção.
- **Prestígio "Maré Nova"** (1 milhão de moedas + 60 espécies, até 10 vezes).
- **Auto-pesca** (passe) [falta rebalancear a economia com ela].
- **Monetização:** VIP, boost de sorte, pacotes de moedas, passe de auto-pesca. **Todos os IDs estão em 0** (a UI esconde a compra).

## 5. Treino (mudança grande em andamento)
- **Treino antigo (hub)** [pronto]: Lagoa de Treino no hub, semi-idle, Controle e Instinto (nível até 25), anel de ritmo bônus.
- **Poder de Pesca / treino v2** [flag `TrainingPower`]: cada stat ganha **Poder (PP)** de 1 até 1e15, multiplicado pelo **campo de treino** (10 níveis comprados), pela **ilha** e pelo prestígio. O Poder total define qual **skin da barra de força** você usa (6 skins: Madeira, Cristal, Ametista, Rosa Neon, Dourada, Cósmica).
- **Decisão de 24/11:** só se treina **nas ilhas**. O treino do hub sai.
- **4 ilhas de treino:**
  | Ilha | Multiplicador | Exige | Estado |
  |---|---|---|---|
  | 1. Aprendiz | x1 | grátis | **[pronto]** (Gemini + ajustes). Lagoas do Foco e do Instinto, portal de pedra. Falta polir (rocha, cachoeiras, peso). |
  | 2. Recife | x3 | 100 mil de Poder | [provisório]. Prompt do Gemini pronto para refazer. |
  | 3. Abismo Estelar | x12 | 100 milhões | [provisório] |
  | 4. Celestial | x50 | 1 trilhão | [provisório] |

## 6. Mundo
Detalhes e prints no PDF `docs/tour/TOUR-DO-MUNDO.pdf`.
- **Ilha-hub** (compacta): Oficina de Varas (loja de varas), praça central com fogueira e cristal, escadaria de entrada, Lagoa de Treino (cachoeira e árvore rosa), **Píer de Pesca**, aquário em construção, placares flutuantes, troféu, dia/noite e "mundo vivo" (fogueira, gaivotas, peixes pulando, neve no Natal).
- **Portais:** praça de 2 portais de pesca e plataforma de 4 portais de treino (hoje bagunçadas, **serão redesenhadas**).
- **Ilhas de pesca** Recife e Abismo, e as **4 ilhas de treino**.
- **3 NPCs** que só conversam: Vô Anzol (guia), Lucy (iscas) e Luna (conchas e lore). O código ainda tem o nome antigo "Marina" no lugar de Lucy.
- Outros jogadores pescando aparecem com linha e boia.

## 7. Interface
HUD com moedas, nível com barra de XP, menu, próximo objetivo, presente diário e slot da vara. Na pesca fica só moedas e nível. Painéis: Coleção, Oficina, Conquistas, Prestígio, Placar, Ajustes (volume, reduzir efeitos, códigos), Desafios, Marcos, Treino. Textos em PT e EN (`StringsUi`). **Falta** mostrar o Poder de Pesca no HUD de forma completa e o painel do campo de treino (prompt do Codex pronto).

## 8. Arquitetura (resumo)
`src/server`, `src/client` e `src/shared` sincronizados pelo **Rojo**. Features carregam sozinhas por pasta. ProfileStore guarda o perfil. Remotes com limite por jogador. Geradores de mapa e modelos em `tools/` (por exemplo `TrainingIsland1Builder.luau`). O mapa e os meshes vivem no **place**, não no git: depois de mexer, sempre `save_place`. Atributos `Dev*` existem só para testar no Studio e devem ser desligados no lançamento.

## 9. Time
- **João:** decide e testa.
- **Claude:** sistemas, servidor, configs, revisão e integração no Studio.
- **Codex:** UI, revelações, minigames e QA.
- **Antigravity / Gemini:** mapa, 3D, criaturas e VFX.
Coordenação pelo Mural em `docs/COORDENACAO.md`. Um agente por vez no Studio (`.studio-lock`).

## 10. O que falta e o que nunca foi testado
- **Flags desligadas no jogo publicado:** `FishingPower`, `FishingRoulette`, `TrainingPower`. Ligam só depois de testar.
- **Só o João:** API Access do Studio, produtos e passes Robux, ícone e thumbnails, testar no **celular real** e com **2 jogadores**, desligar os `Dev*`, salvar o place.
- **Do time:** polir a Ilha de Treino 1, refazer as ilhas 2 a 4, **redesenhar a zona de portais do hub**, mover o treino do hub para as ilhas, HUD do Poder de Pesca, rebalancear a economia com a auto-pesca, reforçar o anti-cheat do minigame, trocar "Marina" por "Lucy".
- **Nunca testado:** celular real, 2+ jogadores, jogo publicado, save real, compras reais.

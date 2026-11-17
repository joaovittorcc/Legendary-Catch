# Noite de 2026-11-17 — backlog dos três agentes

> Coordenador: **Claude Code** (o João mandou: o Claude distribui tarefas e confere o trabalho).
> Regras de convivência, dono de cada arquivo e contrato: `docs/COORDENACAO.md`. Escreva no Mural ao começar e terminar cada item.
> Meta: de manhã o João abre o Studio e joga um **jogo completo de ponta a ponta**: primeiro login guiado, pesca, coleção com ~24 criaturas com modelo 3D bonito, variantes raras, desafios diários, oficina, treino, eventos, sons, salvamento, tudo funcionando no celular.
> Escopo: **não inventar sistema fora desta lista** sem o Claude aprovar no Mural.

## Antigravity — mapa e modelos (Studio)
Dono de: `tools/IslandGenerator.luau`, `Workspace.Island`, `ServerStorage.MapMeshes`, modelos em `ReplicatedStorage.Creatures`.

- **A1 — Tags do mapa.** Garanta 1 peça com cada tag: `FishingZone` (caixa invisível no fim do píer, ~40×10×14), `TrainingSpot` (lagoa), **`WorkshopSpot` (frente da oficina — está faltando)**. Commit do gerador.
- **A2 — Modelos 3D das criaturas.** Para **cada id** em `src/shared/Config/Creatures.luau` (o Claude vai aumentar a lista para ~24), gere um mesh com o `generate_mesh` do Studio no estilo da ilha (cartoon 3D premium, cores vivas, silhueta legível; comuns simples, lendários detalhados e grandiosos), confira de vários ângulos, e instale em `ReplicatedStorage.Creatures` **com o nome igual ao id**. Antes, mova o modelo antigo de peças para `ServerStorage.CreaturePrototypes`. Regras: sem scripts dentro, peças ancoradas, `CanCollide/CanQuery/CanTouch` falsos, maior dimensão ~3 studs (o código reescala), frente virada para +Z, remova tags de IA dos clones. No máximo 2 gerações ao mesmo tempo. Nome/descrição de cada criatura estão em `src/shared/Strings.luau` (`creatureName`, `creatureLore`). Originais, sem IP de terceiros.
- **A3 — Vida no mapa.** Cardumes de peixinhos nadando perto do píer e da lagoa (só cliente ou leve), gaivotas, bolhas, brilho na água. Leve para celular.
- **A4 — Salvar o place** (Arquivo > Salvar na Roblox, ou `save_place` do MCP) depois de A1/A2/A3 e anotar no Mural.

## Codex — visual
Dono do que está em `docs/COORDENACAO.md` §2 + `src/client/Features/Tutorial/**`, `Missions/**`, `Audio/**`.

- **X1 — Tutorial do primeiro login** (`Features/Tutorial`): lê `Data.get().tutorial` (Claude entrega; ver contrato §4.6). Seta 3D/indicador até o píer, dica "toque para lançar", explica o minigame na primeira fisgada, mostra a coleção depois da 1ª captura, aponta a oficina quando tiver moedas para a Vara de Coral e a lagoa de treino. Pulável.
- **X2 — Desafios diários** (`Features/Missions`): painel com os 3 desafios do dia (progresso, recompensa, botão Resgatar), toast ao completar, contador até o reset. Remotes no contrato §4.6.
- **X3 — Variantes**: payload `caught.variant` ("" ou "Shiny"): revelação com brilho/arco-íris especial e selo "CINTILANTE"; coleção mostra se já tem a variante.
- **X4 — Sons** (`Features/Audio`): lance, fisgada, tensão do minigame, acerto/erro, captura por raridade (crescendo), revelação lendária, UI (clique, abrir painel), moeda, nível de treino, ambiente do mar/lagoa e música calma. Use **somente áudios do próprio Roblox** (criador Roblox na Creator Store) e liste os IDs no topo do módulo. Volume pelos Ajustes.
- **X5 — Recompensas da coleção**: barra de progresso por raridade no bestiário e resgate dos marcos (contrato §4.6).
- **X6 — Passe de celular e desempenho**: Device Emulator (iPhone SE, iPhone 14, tablet Android): nada cortado, botões ≥ 44 px, nada sob o pulo/hotbar. Orçamento de partículas; "Reduzir efeitos" desliga o pesado.
- **X7 — Tela de carregamento + câmera de chegada** no primeiro spawn (pré-carrega modelos das criaturas e UI).

## Claude — sistemas
- **S1** Catálogo para ~24 criaturas (dados, valores, lore, revealStyle) — libera A2.
- **S2** Variantes (Cintilante ~1/40, valor ×3) no servidor + coleção registra variante.
- **S3** Desafios diários (3 por dia, reset 00:00 UTC, recompensa em moedas) + remotes.
- **S4** Estado do tutorial no perfil, avançado pelo servidor nos eventos reais.
- **S5** Marcos da coleção (completar raridade / X espécies) com recompensa.
- **S6** Ajustes salvos no perfil (volume, reduzir efeitos) + remote.
- **S7** Revisão geral, testes de ponta a ponta, Mural e vault.

- **X8 — Loja de Robux** (aba na Oficina ou botão na HUD): lista `Config/Products` (pacotes de moedas, boost de sorte 15 min, passe VIP). **Esconda o botão de compra quando o id for 0** (produto ainda não existe). Compra: `MarketplaceService:PromptProductPurchase(player, id)` / `PromptGamePassPurchase`. Mostre o boost ativo na HUD com contagem (atributo `LuckBoostEndsAt` no Player, `os.time()`) e selo VIP (atributo `Pass_vip`). Textos claros do que cada coisa faz; nada de pressão (sem "últimas unidades", sem contagem falsa).

- **X9 — Revelações por estilo**: garanta efeito próprio para **todos** os `revealStyle` de `Config/Creatures` (splash, bubbles, spark, prism, storm, crystal, cosmic, **magma, cloud, frost**). Cada um com identidade (cores, partículas, som). Teste com `DevForceRarity` + as criaturas C20–C24.
- **X10 — Inglês automático**: `src/shared/StringsUi.luau` passa a ter versão EN com o **mesmo formato**, escolhida no require pelo idioma do jogador (`LocalizationService.RobloxLocaleId`: começa com `pt` → PT, senão EN). O Claude faz o mesmo em `Strings.luau`. Nenhum texto fixo fora desses arquivos.
- **X11 — QA final de ponta a ponta** no Device Emulator (celular pequeno em paisagem): perfil novo → tutorial inteiro → 5 capturas → oficina → treino → desafios → coleção → ajustes. Corrija o que for visual; o que for sistema, anote no Mural pro Claude.

## Rodada 3 (2026-11-17 ~01:50)
- **A5 — Varas em mesh 3D (Antigravity)**: gere com `generate_mesh` um modelo para cada vara de `src/shared/Config/Rods.luau` (starter, coral, crystal, storm, astral — cores em `color`/`tipColor`; da simples à épica: Astral com cristais e brilho dourado). Instale em `ServerStorage.RodModels` com nome = id. **Convenção obrigatória**: pivô do modelo no ponto de pegada (onde a mão segura), comprimento ao longo de **-Z**, ~7–8 studs no total, uma peça chamada **`Tip`** na ponta da vara (onde sai a linha), sem scripts. O servidor já usa o modelo se existir (fallback em peças).
- **X12 — Anúncio de captura grande (Codex)**: remote `CatchAnnounce` (S→C, para todos) com `{userId, displayName, creatureId, rarity, variant}` quando alguém pega Lendário ou Épico Cintilante: banner no topo com nome do jogador, criatura e raridade (não para o próprio jogador que já vê a revelação), som curto. Placar na lista de jogadores já existe (`leaderstats` Coins/Catches).
- **X13 — Prévia 3D da vara na Oficina (Codex)**: quando `ServerStorage.RodModels` existir, o servidor não replica; peça no Mural se quiser os modelos em `ReplicatedStorage` para a prévia.
- **X14 — Tela de título (Codex)**: no primeiro carregamento, logo "Legendary Catch" estilizado (texto com gradiente/brilho, cristais, ondas), botão Jogar grande, câmera passando pela ilha atrás; depois cai no fluxo de chegada/tutorial. Pulável, uma vez por sessão.
- **X15 — Criaturas vivas (Codex)**: animação procedural (balanço, nado, giro suave, pulsar nos Neon) para os modelos no bestiário e na pose da revelação. Funciona em qualquer modelo de `ReplicatedStorage.Creatures` (meshes do Antigravity).

## Rodada 4 (2026-11-17 ~02:10)
- **X16 — Lendários únicos (Codex)**: cada lendário com uma assinatura própria na revelação, além do revealStyle: Leviatã Astral (túnel cósmico + constelação), Kraken Trovejante (tentáculos de silhueta + raios em sequência), Fênix das Marés (chamas azuis subindo da água + renascimento). Pulável depois de visto.
- **X17 — Artes de divulgação (Codex)**: monte cenas bonitas no Studio (ilha de dia, píer com linha brilhando, uma revelação lendária, bestiário cheio) e salve capturas em `art/marketing/` (thumbnails 16:9 e uma imagem quadrada para ícone, sem UI de debug). O João sobe no Creator Hub.
- **X18 — Juice (Codex)**: moedas voando até o contador ao capturar, "x3 seguidas!" para capturas seguidas sem escapar (só visual, cliente conta), vibração leve no celular (HapticService, respeitando Reduzir efeitos), número de peso subindo rápido no cartão.
- **Preços das varas subiram** (Coral 500, Cristal 3.000, Tempestade 15.000, Astral 60.000): confira se a Oficina e o tutorial continuam certos.

## Rodada 4 — Antigravity
- **A6 — Conferência visual**: em Play, equipe cada uma das 5 varas (Player `DevGrantCoins`=100000 no servidor, depois `Remotes.BuyRod:FireServer(id)` no cliente) e confira de 3 ângulos que a vara sai da mão apontando pra frente/cima e que a linha sai da `Tip`. Ajuste o modelo (não o código) se estiver torto. Depois confira os 24 modelos no bestiário e numa revelação (`DevForceRarity`). Dica: o `screen_capture` só pega a imagem se a janela do Studio estiver visível (não minimizada nem atrás de outra).
- **A7 — Qualidade das criaturas**: refaça os modelos mais fracos (pouco detalhe, cor errada, sem cara) — prioridade para os 3 lendários (C10, C23, C24) e os 4 épicos (C09, C20–C22), que precisam ser os mais impressionantes. Guarde o anterior em `ServerStorage.CreaturePrototypes`.
- **A8 — Salvar o place** e Mural.

## Rodada 5 (2026-11-17 ~02:40)
- **A9 — Pedestal do Troféu (Antigravity)**: na praça, um pedestal bonito (pedra clara + cristal + aro dourado, ~4 studs de altura) com uma peça invisível no topo com a tag **`TrophyPedestal`** (o servidor coloca em cima dela o modelo da criatura mais rara pescada no servidor e um letreiro com o nome de quem pegou). Sem colisão no topo. Commit do gerador + salvar o place.
- **A10 — Passada final do mapa contra a arte (Antigravity)**: compare com `art/reference/island-approved.png` e ajuste o que estiver mais distante (cores, cristais, lanternas, vegetação), sem mudar posições de píer/oficina/lagoa/tags. Confira desempenho (instâncias, luzes). Salve o place.

## Rodada 6 (2026-11-17 ~02:50) — Antigravity
- **A11 — Desempenho celular**: meça instâncias, partes, luzes, partículas e triângulos do mapa + criaturas; confirme `Workspace.StreamingEnabled` com raio adequado à ilha compacta; corte o que pesar sem perder o visual (merge de peças decorativas, `CastShadow` desligado em decoração pequena, menos luzes dinâmicas). Anote antes/depois no Mural.
- **A12 — Andabilidade e limites**: caminhe (`Humanoid:MoveTo`) por todos os caminhos (spawn, píer, oficina, lagoa, escada, pedestal) e confira que ninguém fica preso nem cai em buraco; coloque uma **barreira invisível no mar** (anel de paredes sem colisão visual, ~250 studs do centro) para o jogador não nadar até a borda do oceano; garanta que quem cai na água consegue voltar (escada/rampa na margem ou respawn suave).
- **A13 — Salvar o place** e Mural.

## Rodada 7 (2026-11-17 ~03:15) — Antigravity
- **A14 — NPC guia**: um pescador veterano **original** (estilo da ilha: chapéu de pescador, colete, barba branca, vara nas costas), parado perto da entrada do píer olhando pra praça, sem atrapalhar o caminho. Pode ser rig R15 com acessórios/mesh, ancorado, `CanCollide` só no corpo. Tag **`GuideNPC`** no Model e um **`Attachment` chamado `SpeechPoint`** ~1 stud acima da cabeça (o Claude coloca os balões de fala ali). Uma pose parada simpática (sem animação obrigatória). Salve o place e Mural.

## Rodada 8 (2026-11-17 ~03:45) — Antigravity
- **A15 — QA de ponta a ponta (segundo par de olhos)**: perfil novo (no Studio o save é simulado, cada Play começa do zero), jogue como um jogador de verdade: título → tutorial inteiro → 10 capturas (forçando raridades variadas com `DevForceRarity`) → coleção → marcos → oficina (`DevGrantCoins`) → comprar/equipar varas → treino → desafios → ajustes (reduzir efeitos) → evento (`workspace:SetAttribute(""DevStartEvent"",""starTide"")`). **Não corrija código de ninguém**: anote cada bug no Mural com passo a passo, arquivo provável e gravidade. Corrija só o que for do mapa.
- **A16 — Salvar o place** e Mural.

## Rodada 9 (2026-11-17 ~05:12) — Antigravity
- **A17 — Textura quebrada**: `ReplicatedStorage.Creatures.C02_Sardinha_Solar.body.body_geom.TextureID` aponta pra `rbxassetid://203785492` (não é imagem: "Asset type does not match requested type" no console do cliente). Troque por uma textura válida ou remova (cor sólida), e confira os outros 23 modelos + varas + MapMeshes com o mesmo teste (nenhum `TextureID`/`Texture`/`MeshId` inválido). Confira também o `107799601678302` que apareceu no boot.
- **A18 — Ponto de pesca visível**: na ponta do píer (dentro da `FishingZone`), um marcador discreto na água pra o jogador novo saber onde lançar: anel de luz ciano suave/boias decorativas/pequenos peixes saltando (barato: 1 emitter no máximo, sem luz dinâmica nova). Não mude a FishingZone nem o píer.
- **A19 — Salvar o place** e Mural.

## Rodada 9 — Codex (ao voltar do limite, ~05:46)
Leia o Mural desde 02:27 antes: o Claude fez X17/X18 nos seus arquivos (`Features/Juice`, `art/marketing`) e corrigiu o balão do guia e as placas.
- **X19 — TrainingHud encavalado** (bug #2 do QA A15): com o card `TutorialGuide` visível, a barra `Treinando Controle – Nível N [Parar]` encosta embaixo dele (botões Parar e Pular colados). Arquivo: `src/client/Features/Training`. Reposicione/empilhe sem sobrepor, no celular compacto também.
- **X20 — Contraste do OceanEventHud** (bug #3): banner `Maré Estelar 2:16` ilegível contra céu claro. Fundo mais sólido/escuro + stroke, mesma identidade por evento. Arquivo: `src/client/Features/Events`.
- **X21 — Troféu bonito**: o `WorldText` (Claude) só traduz o texto da placa. Estilize no cliente: placa com a cor da raridade, selo ✦ Cintilante, giro suave do modelo da criatura em cima do pedestal (`TrophyPedestal` > `TrophyDisplay`; atributos `TrophyCreature/TrophyPlayer/TrophyWeight/TrophyVariant`). Respeite Reduzir efeitos. Não altere o texto (é do WorldText) nem o servidor.

## Rodada 10 (2026-11-17 ~05:58) — Codex
- **X22 — Modo foto**: depois da revelação de Épico/Lendário (ou pelo botão na HUD), botão "Foto" que esconde toda a UI, deixa a criatura na pose, câmera orbitável por arraste/toque por alguns segundos e uma moldura discreta com o nome do jogo + nome da criatura. Toque/Esc volta. Só cliente; respeite Reduzir efeitos. Ideia: o jogador tira print e compartilha.
- **X23 — Galeria de telas pro João**: no Device Emulator (celular paisagem) e no PC, capture cada tela em PT: título, HUD na praça, os 3 minigames, revelação comum, revelação lendária, coleção, detalhe de criatura, marcos, oficina, loja de Robux, treino, desafios, ajustes, banner de evento, troféu, modo foto. Salve em `art/screens/` (jpg, nomes curtos tipo `01-titulo.jpg`) e um `art/screens/README.md` com uma linha por imagem. Corrija o que ficar feio no caminho (só seus arquivos; o resto no Mural).

## Rodada 10 — Antigravity (~06:08)
- **A20 — Estátuas das lendas**: na praça (ou caminho do píer), 3 estátuas pequenas de pedra clara com detalhes dourados representando os lendários (Leviatã Astral C10, Kraken Trovejante C23, Fênix das Marés C24) — silhueta reconhecível, sem cor viva (é o "sonho" do jogador). Base com placa sem texto (ou só ícone de estrela). Sem colisão nas partes finas, sem bloquear caminhos, `CastShadow` só na base. Barato em triângulos.
- **A21 — Arco de boas-vindas no spawn**: arco de madeira + cristais com "Legendary Catch" (nome do jogo não precisa tradução), lanternas âmbar (sem luz dinâmica nova, use Neon). Conferir que não atrapalha a câmera de chegada/título do Codex.
- **A22 — Salvar o place** e Mural. Codex está fazendo prints (X23): combine o lock, Plays curtos.

## Rodada 11 (2026-11-17 ~06:55) — Codex
- **X24 — Presente do dia (cliente)**: o servidor já dá moedas no 1º login de cada dia UTC (`Config/Missions.dailyGift`: 100 no 1º dia, +50 por dia visitado, teto 400; **nunca zera** se o jogador faltar — sem FOMO). Snapshot novo: `daily = { lastDay, days, lastGift, grantedAt }`. Mostre um cartão de boas-vindas ("Presente do dia #N: +X moedas", com o Vô Anzol ou um baú de cristal) **só se** `os.time() - daily.grantedAt < 120` (foi dado neste login) e uma vez por sessão; depois do título/chegada e sem atrapalhar o tutorial (no 1º dia pode juntar com a mensagem de boas-vindas). Moedas voando (Juice). Respeite Reduzir efeitos. Textos em `StringsUi` PT/EN.
- **X25 — Raridade sem depender só de cor** (acessibilidade/daltonismo): em todo lugar que a raridade aparece (revelação, coleção, cartões, banner, troféu), garanta o **nome** da raridade e/ou um ícone distinto por raridade (ex.: 1–5 estrelas), não só a cor. Confira contraste do texto sobre as cores de raridade.

## Rodada 12 (2026-11-17 ~07:08) — Codex
- **X26 — Próxima meta na HUD**: depois do tutorial, um chip discreto com o próximo objetivo calculado do snapshot + Config (ordem: próxima vara que ainda não tem → "Faltam N moedas pra Vara de Coral" com barrinha; senão próximo marco da coleção → "Faltam N espécies"; senão desafio diário pronto pra resgatar). Toque abre a tela certa. Não cobre botão de pular/hotbar; some em painéis/minigame.
- **X27 — Caça a vazamentos (celular)**: em Play de ~3 min fazendo 10 capturas + abrir/fechar todos os painéis 5x, meça antes/depois: número de instâncias em PlayerGui, partículas vivas, conexões (onde der pra contar) e memória (`Stats:GetTotalMemoryUsageMb()`). O que crescer sem parar é vazamento: corrija nos seus arquivos; o que for de outro, Mural.

## Rodada 11 — Antigravity (~07:09)
- **A23 — Catálogo das criaturas**: tire 1 print de cada uma das 24 criaturas (fundo limpo, mesma câmera/escala, 3/4 de frente) e salve em `art/creatures/Cxx-nome.jpg` + `art/creatures/README.md` com raridade e uma linha sobre o modelo. É pro João ver o elenco de manhã.
- **A24 — Passada de qualidade nas que ficaram mais fracas no catálogo** (prioridade Raro → Incomum → Comum que não foram refeitas no A7): cara/olhos legíveis, silhueta única, cores da raridade. Guarde a anterior como `*_v1` em `ServerStorage.CreaturePrototypes`. Atualize o print depois.
- **A25 — Salvar o place** e Mural.

## Rodada 13 (2026-11-17 ~07:29) — Codex
- **X28 — Galeria atualizada pro João**: refaça só as telas que mudaram desde o X23 e adicione as novas (presente do dia, chip de próxima meta, estrelas de raridade na revelação/coleção, troféu estilizado, estátuas e arco do Antigravity vistos do spawn, modo foto). Atualize `art/screens/README.md`. PT, celular paisagem + PC.
- **X29 — Revisão final dos seus textos**: leia `StringsUi` PT e EN inteiros como um jogador de 10 anos: erros, termos inconsistentes (ex.: "Desafios" x "Missões", "Oficina" x "Loja"), frases longas demais pro celular. Corrija e liste no Mural o que mudou. Se achar algo no `Strings` (Claude), anote no Mural.

## Rodada 12 — Antigravity (manhã, aprovado pelo João)
- **A23/A24 — retomar**: terminar o catálogo `art/creatures/` (24 prints + README) e refazer as mais fracas (Raro → Incomum → Comum), guardando `*_v1`.
- **A26 — Limpeza**: remover do `Workspace` o modelo solto "Stylized cartoon electric storm eel..." (sobra de geração); conferir que nada de rascunho ficou fora de `Island`/`ServerStorage`.
- **A27 — Mais vida na ilha**: peixinhos saltando de vez em quando perto do píer e da lagoa, vaga-lumes/brilhos suaves perto das lanternas. Barato (no máximo 2 emitters novos, sem luz dinâmica nova), respeitando o orçamento do A11.
- **A28 — Salvar o place** e Mural. O Codex só gera imagens agora (mockups de HUD), não deve usar o Studio.

## Rodada 13 — Antigravity (manhã, Studio quebrado: só papel)
- **A29 — Ficha das criaturas novas**: `Config/Creatures.PLANNED` tem C25–C30 (nome e lore em `Strings`): Ouriço Gelatina (Comum), Peixe-Pipa (Comum), Ermitão de Cristal (Incomum), Náutilo Aurora (Raro), Dragão-Folha Esmeralda (Épico), Tartaruga-Ilha Ancestral (Lendário — uma ilha pequena nas costas, a mais impressionante). Escreva `art/creatures/PLANNED.md` com, pra cada uma: silhueta, paleta (cores da raridade), detalhes que dão personalidade, tamanho relativo e o prompt que você vai usar no `generate_mesh`. **Não gere nada no Studio** até o João consertar a interface do Studio (em branco desde ~08:20). Mural ao terminar.

## Pedido pro Codex (depois da HUD)
- **X30 — Novo recorde**: o payload `caught` agora tem `isRecord` (pesou mais que o melhor anterior da espécie; nunca no 1º) e `previousBest` (kg). Mostre um selo "Novo recorde! 2,4 kg → 3,1 kg" no cartão da revelação, discreto pra Comum e mais festivo pra raridades altas.

## Pedido do João (~09:50) — Antigravity
- **A30 — Tirar a marcação da água**: remova o marcador do A18 (anel ciano + boias na frente do píer). O João não quer marcação na água. Mantenha a `FishingZone` como está.
- **A31 — Vara bem feita**: refaça os modelos em `ServerStorage.RodModels` com muito mais acabamento, começando pela `starter` (a que o jogador vê primeiro): cabo de cortiça/madeira com anéis, molinete com manivela e carretel, guias (passadores) ao longo da vara, ponta fina e flexível, ponteira `Tip` Neon. Depois coral, crystal, storm, astral, cada uma mais épica. **Mesma convenção**: pivô no grip, comprimento em -Z (~7–8 studs), peça `Tip` na ponta, sem scripts. Guarde as antigas em `ServerStorage.RodPrototypes`. Confira na mão do personagem (Play) e na prévia da Oficina. Salve o place.
- O Studio do João mostra a janela preta, mas o MCP funciona. Use `.studio-lock` (Claude e Codex também vão dar Play).

## Pedido do João (~10:07) — Codex: HUD v2 "dopaminosa"
A HUD atual (madeira feita com Frames/UIStroke) ficou séria e quadrada demais. O João quer **mais colorida, animada, infantil e arredondada**, bem "dopaminosa".
- **Gere as artes imagem por imagem** com o gerador de imagem (fundo transparente, PNG, ≤1024 px): placa de moedas, cada botão (Coleção, Oficina, Desafios, Ajustes) com ícone grande e fofo, cartão do presente, faixa da próxima meta + barra, slot da vara, selo de raridade (5 cores), fundo dos painéis. Estilo: cartoon brilhante, cantos bem arredondados, contorno grosso escuro, gradientes vivos (ciano/azul cristal, rosa/lilás, dourado, madeira quente só como detalhe), brilho/reflexo no topo, cara de jogo infantil premium. Salve em `art/hud-v2/` com um README listando cada peça.
- **Monte a HUD com essas imagens** (`ImageLabel`/`ImageButton` + `SliceCenter` onde esticar). Suba as imagens pro Roblox pelo MCP do Studio (`upload_image`/asset) e anote os `rbxassetid` num módulo de assets da HUD. Se o upload não funcionar, pare e registre no Mural (não invente id).
- **Animação**: botões quicam ao tocar (escala 0.9→1.05→1), brilho passando de tempos em tempos, moedas pulsando quando ganham valor, ícones com leve balanço ocioso, presente do dia tremendo/brilhando até abrir. Tudo respeitando **Reduzir efeitos** (sem balanço/brilho contínuo).
- Continua valendo: celular primeiro, botões ≥44 px, nada sobre o pulo/joystick, textos em `StringsUi`.
- **Ciclo até ficar bom**: ajusta → sincroniza (rojo build + `game:GetObjects`, ver Mural 09:32) → Play → `screen_capture` → compara → repete. Prints finais em `art/screens/hud-v2/` (PC e celular). Mural ao começar e terminar.

## Pedido do João (~10:25) — Antigravity, agente 2: 10 criaturas novas
Gere os **modelos 3D de 10 criaturas novas** (além das 24 que já estão no jogo), em `ReplicatedStorage.Creatures` com nome = id:
- C25 Ouriço Gelatina (Comum), C26 Peixe-Pipa (Comum), C27 Ermitão de Cristal (Incomum), C28 Náutilo Aurora (Raro), C29 Dragão-Folha Esmeralda (Épico), **C30 Tartaruga-Ilha Ancestral (Lendário)** — fichas e prompts prontos em `art/creatures/PLANNED.md`.
- C31 Carpa Celeste (Incomum, koi translúcida azul-céu com nadadeiras de nuvem), C32 Espadarte Relâmpago (Raro, espadarte prateado com raios amarelos e rastro de luz), C33 Orca Aurora (Épico, orca com manchas que brilham em verde/rosa/roxo de aurora), **C34 Serpente Arco-Íris (Lendário, serpente marinha longa com cada escama de uma cor, crista dourada e chifrinhos)**. Escreva a ficha dessas 4 no mesmo `PLANNED.md`.
- Ids, raridade e lore já estão em `Config/Creatures.PLANNED` e `Strings`. **Os 2 lendários têm que ser os mais impressionantes do jogo** (no nível ou acima do Leviatã/Kraken/Fênix).
- **Convenção** igual às 24: frente em +Z, ~3 studs (lendários podem ser maiores), sem scripts/tags/colisão, Neon só onde brilha, orçamento de triângulos parecido com as atuais (máx ~8k nos lendários).
- Print de cada uma em `art/creatures/` (mesmo enquadramento do catálogo) e atualize o README. Salve o place.
- **Não** mova nada pra `Config/Creatures.LIST` (o Claude libera no jogo depois de conferir).
- Studio compartilhado com o agente 1 do Antigravity (varas) e com Claude/Codex: `.studio-lock` sempre que for dar Play ou salvar; `generate_mesh` em Edit pode rodar sem Play. Mural ao começar e a cada 2–3 criaturas.

## Pedido do João (~12:10) — Antigravity
### Agente 2: mais 30 criaturas (C35–C64)
Ids, raridade, nome e lore já estão em `Config/Creatures.PLANNED` e `Strings` (8 Comuns, 7 Incomuns, 6 Raros, 4 Épicos, **5 Lendários**). Gere os 30 modelos em `ReplicatedStorage.Creatures` (nome = id), escreva a ficha de cada um em `art/creatures/PLANNED.md` e um print em `art/creatures/`.
- **Os 5 lendários têm que ser EXTREMAMENTE épicos e detalhados**, os melhores do jogo (acima do Leviatã/Kraken/Fênix/Tartaruga/Serpente): C60 Hidra das Profundezas (3 cabeças), C61 Baleia Celestial (galáxia dentro do corpo, anéis), C62 Dragão Dourado da Tempestade, C63 Grifo-Marinho Real (meio águia, meio peixe), C64 Guardião Abissal (gigante antigo com armadura e lanterna). Podem ter mais triângulos (até ~12k) e várias peças Neon. Gere em mais de uma tentativa e fique com a melhor.
- **Já gere pensando na animação** (próxima seção): partes separáveis (cauda, barbatanas, cabeça, asas, tentáculos).
- Convenção de sempre: frente +Z, ~3 studs (lendários podem ser maiores), sem scripts/colisão, `Anchored`. Não mexa no `Config`. Mural a cada 5 criaturas.

### Agente 1: separar as criaturas em partes pra animação
O Claude vai animar as criaturas por partes (cauda abanando, barbatanas batendo, asas, tentáculos, cabeça). Pra isso cada modelo precisa ter as partes separadas. Use a ferramenta `segment_mesh` do MCP (até 5 nomes por chamada) nas **34 atuais** (e depois nas 30 novas, quando o agente 2 terminar cada lote).
- **Nomes padronizados** (exatamente estes, só os que existirem na criatura): `Body` (obrigatório, vira o `PrimaryPart`), `Head`, `Tail`, `FinL`, `FinR`, `Fins` (quando não der pra separar esquerda/direita), `Wings`, `Tentacles`, `Legs`, `Claws`, `Shell`, `Extra` (enfeites: coroa, árvore, chifre...).
- Resultado fica em `ReplicatedStorage.Creatures.<id>` (mesmo nome, mesma posição/orientação +Z, mesmo tamanho, pivô no centro do Body, tudo `Anchored`, sem solda). Guarde o original estático em `ServerStorage.CreaturePrototypes` como `<id>_static`.
- Se o `segment_mesh` cortar mal alguma, tente outra lista de nomes; se não der, deixe só `Body` e anote no Mural.
- Confira 3–4 no print antes de seguir em lote. Salve o place. `.studio-lock` ao salvar/dar Play. Mural a cada lote.

## Pedido do João (~12:50) — Codex: minigames refeitos (prioridade sobre o resto da HUD)
O João achou os minigames "fofinhos" demais e pouco intuitivos. Refaça os 3 (mantendo `run(area, tier, color, done) -> stop` e `done(success, perfect)`). Números novos já estão em `Config/Fishing` (o Claude ajusta balanceamento):
- **Ritmo (estilo osu!)**: **tela inteira**, **sem fundo/painel** — só as bolinhas aparecendo em pontos aleatórios da tela (longe das bordas, da HUD, do pulo e do joystick), cada uma com o anel fechando; toque/clique nela no tempo certo. Bolinhas grandes e bem destacadas (cor da raridade, número de ordem, contorno grosso, brilho), feedback "Perfeito/Bom/Errou" em cima de cada uma. Quantidade por raridade: `RHYTHM.rings` = 3, 5, 8, 12, **15 no Lendário**; anéis mais rápidos (`shrinkSeconds`) e intervalo menor (`gapByTier`) quanto mais raro. Desafio leve, nunca cruel.
- **Precisão (acertar a barrinha)**: mais desafiador. O marcador é **errático**: finge que vai, não vai, vai e volta, muda de velocidade (`reverseRate`, `speedJitter` por tier; mais aleatório quanto mais raro, `markerSpeed` maior). **Tempo pra decidir**: `decisionSeconds` = 5 s pra cada acerto; se demorar, conta como erro (mostre um anel/contador regressivo).
- **Puxar (estilo Stardew)**: hoje está bugado, lento e pouco intuitivo — refaça do zero. Controles: **segurar clique/toque** (sobe), **W/S ou ↑/↓ ou espaço**, e **arrastar** a zona com o dedo/mouse (a zona segue o dedo). Física mais responsiva (aceleração rápida, sem "patinar"), barra de progresso clara, o peixe se mexe de forma legível. **Mini tutorial** na primeira vez (2–3 frases + animação mostrando segurar/arrastar), com "não mostrar de novo".
- Todos: celular primeiro, ≥44 px, respeitar `Control.ease()` e Reduzir efeitos, `PressInput` (ele afunda toques — botões de UI não recebem toque durante o minigame). Ciclo Play → print até ficar bom; prints em `art/screens/minigames/`. Mural.

## Pedido do João (~13:40) — Codex: refazer a interface usando o kit de referência
O João achou a UI fora da HUD **feia: esticada, cheia de quebras**. Só os 4 ícones de cima e as moedas ficaram bons. Prints do problema: `art/screens/ui-problems/` (painel com cabeçalho duplicado atrás, título minúsculo, "Fechar" em texto, fundo esticado sem acabamento).
- **Referência nova**: `art/reference/roblox-ui-kit/` (cópia local da pasta do João, **fora do git**: são referências de terceiros, olhe mas não publique as imagens). Leia primeiro `docs/superpowers/specs/2026-10-25-roblox-ui-skill-design.md` e `roblox-ui/references/README.md`. Tem um kit em Luau pronto (`roblox-ui/kit/`: `Containers`, `Controls`, `Readouts`, `Feedback`, `Motion`, `Util`, tema `Themes/StudSimulator`) e ~1.100 imagens.
- **Estilo-alvo**: o nosso colorido/cartoon (HUD v2) no padrão "Stud/Modern Cartoon Simulator" do kit: olhe `references/ui-styles/09-modern-cartoon-simulator`, `10-chunky-candy-buttons`, `11-glossy-bubble`, `13-pet-collector-grid`, `style-refs/studs/mockup-*.png` (shop, inventory, settings, reward, hud) e `visual-refs/studs-ui/`.
- **Regras do kit pra adotar**: FredokaOne com contorno escuro grosso no texto; painel com **aba de título sobressaindo no canto de cima** com ícone grande quebrando a borda; **botão X fechar sobressaindo no canto** (não texto); gradiente de 3 cores nos botões; cantos ≈ 0.045 no painel e 10–14 px nas linhas; abrir painel = escala 0.85→1 Back/Out 0.2 s + blur do mundo; apertar botão = 0.9→1; **um painel por vez** e HUD escondida com painel aberto; grade com células em **pixel** recalculadas no resize (evita o bug de rolagem); toque ≥ 44 px; nada sob a barra do Roblox/notch.
- **O que refazer**: Coleção (grade de criaturas estilo pet collector + detalhe), Oficina (cards de vara estilo shop), Loja Robux, Desafios (linhas com barra de progresso e botão resgatar), Marcos, Ajustes (estilo settings do kit), card da revelação, faixa do tutorial, presente do dia e toasts. Pode usar o kit direto (copiar módulos pro `Features/Hud`) ou reimplementar no `Panel` atual — o que ficar mais limpo.
- Artes novas: gere e suba igual à HUD v2 (servidor local + `upload_image`, ids em `art/hud-v2/ASSET_IDS.md`).
- Ciclo: Play → `screen_capture` de cada painel **aberto pelo jogo** (PC e celular) → compara com 2–3 referências → repete. Prints finais em `art/screens/ui-v3/`. Mural.

## Pra depois (João, ~13:40): modelos no Blender
- Plano: quando for gerar criatura nova, **pedir ao Codex/GPT um modelo base** (low-poly, partes separadas) pra ser **finalizado no Blender** via MCP. Modelos **bem detalhados mas leves** (≤ ~8–10k faces). Conectar o MCP do Blender (Blender 5.3 já instalado via Steam) e liberar `asset:write` no Assistant do Studio numa sessão com o João.

### Decisão de estilo (Claude, ~13:55) — vale pra todo o pedido acima
- **Fora do escopo: minigames** (o João e o Codex fazem à parte, como já está em andamento). Não mexa no visual dos minigames nesta tarefa.
- **Estilo escolhido: "Cartoony candy"** = `ui-styles/09-modern-cartoon-simulator/rhos-cartoony-1.png` + `13-pet-collector-grid/cute-cartoony-1.png` + botões de `10-chunky-candy-buttons`. É o que casa com a HUD v2 (ícones fofos, contorno grosso, cores vivas). Regras:
  - **Painel**: moldura colorida com contorno escuro grosso, **cor do botão que abriu** (Coleção ciano, Oficina laranja, Desafios rosa, Ajustes roxo), **miolo creme claro** (não gradiente chapado esticado), cantos bem redondos, sombra suave embaixo. Proporção fixa (`UIAspectRatioConstraint`) + `UISizeConstraint`: nunca esticar pra tela toda no PC.
  - **Título**: fita/aba colorida **centralizada em cima**, sobressaindo da borda, texto grande FredokaOne branco com contorno escuro, ícone do painel ao lado (os mesmos da HUD v2).
  - **Fechar**: botão redondo vermelho com X branco no canto de cima direito, sobressaindo da borda (não texto "Fechar").
  - **Botões**: "chunky" 3D: cor viva com faixa mais escura embaixo (dá volume), brilho no topo, contorno escuro, aperta afundando (0.9→1). Verde = comprar/resgatar, azul = equipar/ver, cinza = bloqueado, amarelo = destaque.
  - **Células/cartões** (Coleção, Oficina, Desafios): cartão creme arredondado com borda da cor da raridade, ícone/modelo grande, nome embaixo, selo de estrelas; descoberta = silhueta escura com "?".
  - **Linhas de desafio/marco**: ícone redondo à esquerda, texto, barra de progresso arredondada com "x / y", botão à direita (como as linhas de ACHIEVEMENTS da referência).
  - **Ajustes**: sliders e toggles do mesmo pack (bolinha grande, trilho arredondado).
  - Card da revelação, presente do dia, toasts e faixa do tutorial no mesmo estilo.

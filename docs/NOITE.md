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

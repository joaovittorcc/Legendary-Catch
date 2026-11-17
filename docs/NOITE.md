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

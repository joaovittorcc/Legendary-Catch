# Coordenação Claude ↔ Codex — Legendary Catch

> Lido pelos dois agentes **no começo de cada tarefa**. Contrato, divisão de arquivos, regras de convivência e mural de recados.
> Visão do jogo: `CONTEXTO_MESTRE.md`. Mapa atual: `MAPA.md`.

## 1. Quem faz o quê

| | **Claude Code** (sistemas) | **Codex** (visual) |
|---|---|---|
| Foco | Servidor, dados, economia, regras, contratos, ferramentas | HUD, telas, minigames (visual), revelações, VFX, animações, sons |
| Princípio | Servidor é autoridade; publica dados pro cliente | Lê dados do contrato; nunca decide nada que vale moeda/item |

## 2. Dono de cada arquivo

Só o dono edita. Precisa de algo no arquivo do outro? Escreva no **Mural** (seção 6).

**Claude**
- `src/server/**`
- `src/shared/**` **exceto** `src/shared/StringsUi.luau` e `src/shared/UiTheme.luau`
- `src/client/init.client.luau`, `src/client/Data/**`
- `src/client/Features/Fishing/init.luau` (controlador), `Fishing/Control.luau`, `Fishing/PressInput.luau`
- `tools/**`, `docs/PLANO-CLAUDE.md`, seções 1–5 deste arquivo

**Codex**
- `src/client/Features/Hud/**`, `Collection/**`, `Shop/**`, `Settings/**`, `Events/**`, `Others/**` (e outras features só visuais que criar)
- `src/client/Features/Fishing/Ui.luau`, `Effects.luau`, `Line.luau`, `Reveal.luau`, `Minigames/**`
- `src/client/Features/Training/**` (cliente do treino é visual; o servidor é do Claude)
- `src/shared/StringsUi.luau`, `src/shared/UiTheme.luau`
- `AGENTS.md` (pode atualizar a própria parte)

**Antigravity** (terceiro agente, mapa e modelos): `tools/IslandGenerator.luau`, `Workspace.Island`, `ServerStorage.MapMeshes`, modelos em `ReplicatedStorage.Creatures`. Claude e Codex não mexem no mapa.

**Backlog da noite de 2026-11-17: `docs/NOITE.md`** (Claude coordena). Ninguém apaga/renomeia `ReplicatedStorage.Creatures`, `ServerStorage.MapMeshes`.

## 3. Regras de convivência (mesma pasta, mesmo `main`)

1. **Git:** nunca `git add -A` / `git add .`. Faça `git add <seus arquivos>`. Nunca `reset`, `checkout --`, `stash`, `rebase`, `push --force`. **Sem push** — o João envia de manhã.
2. **Formatação:** `stylua <seus caminhos>` — nunca `stylua src` inteiro (formataria o arquivo do outro no meio da edição).
3. **Commits** pequenos, Conventional Commits em inglês, terminando com a linha de co-autoria do agente.
4. **Rojo:** um só, já rodando na porta **34873** (iniciado pelo Claude). Ninguém sobe outro Rojo nem desconecta o plugin.
5. **Studio (MCP):** um Play por vez. Antes de dar Play, crie `.studio-lock` na raiz com `<agente> <hora>`; apague ao parar. Se existir lock de outro com menos de 10 min, espere/trabalhe em outra coisa. Não salve o place sem motivo (cada save vira versão); se salvar, anote no Mural.
6. **Teste antes de dizer pronto:** `stylua` + `selene` + `luau-lsp analyze` sem erro **nos seus arquivos**, e Play no Studio quando a mudança aparece na tela. Diga o que não testou.
7. **Não quebre o contrato.** Campo novo é aditivo. Mudou contrato? Atualize a seção 4 e avise no Mural.

## 4. Contrato (dados que a UI consome)

### 4.1 Carregamento das features do cliente
`src/client/init.client.luau` carrega **todo** ModuleScript em `Client/Features` que tenha `start()`, em ordem de `order` (número, padrão 100; menor primeiro). Feature nova não precisa mexer no init.

```lua
local MyFeature = {}
MyFeature.order = 200 -- opcional
function MyFeature.start() end
return MyFeature
```

### 4.2 Dados do jogador no cliente — `Client/Data` (Claude)
```lua
local Data = require(StarterPlayerScripts.Client.Data)
Data.get(): Snapshot?            -- nil até carregar
Data.changed: RBXScriptSignal     -- (snapshot: Snapshot)
Data.waitLoaded(): Snapshot
```
`Snapshot` (tipo exportado em `src/shared/Types.luau`):
```lua
{
	coins: number,
	equippedRod: string,
	rodsOwned: { string },
	collection: { [creatureId: string]: { count: number, bestWeight: number, firstAt: number } },
	training: { [stat: string]: { level: number, xp: number } },
	stats: { catches: number, legendaries: number },
}
```
Atributos rápidos no `Player` (para contadores animados): `Coins` (number), `DataLoaded` (bool), `TrainingStat` (string, "" parado), `Train_<Stat>_Level`, `Train_<Stat>_XP`.

### 4.3 Configs compartilhadas (Claude) — `ReplicatedStorage.Shared.Config`
- `Creatures` — `LIST`, `get(id)`, campos: `id, rarity, tier, baseValue, weightMin, weightMax, revealStyle?`. Nome/descrição em `Strings.creatureName` / `Strings.creatureLore`.
- `Fishing` — `RARITY_ORDER`, `RARITY_COLORS`, parâmetros dos minigames.
- `Rods` — `LIST`, `get(id)`: `id, price, controlBonus, luckBonus, color, order`. Nome em `Strings.rodName`.
- `Training` — níveis, XP.
- `Events` — eventos do oceano: `id, durationSeconds, rarityBoost`. Nome em `Strings.eventName`.

### 4.4 Remotes — `ReplicatedStorage.Remotes` (nomes em `Shared.Net`)
| Remote | Direção | Payload |
|---|---|---|
| `FishingUpdate` | S→C | `{event, castId, kind?, tier?, rarity?, creatureId?, weight?, value?, isNew?, count?}` — `event`: cast, rejected, bite, caught, escaped, cancelled |
| `CastLine` / `CancelFishing` / `SubmitCatch(castId, success)` | C→S | — |
| `TrainingUpdate` | S→C | `{event: ring/levelUp/stopped, ...}` |
| `StopTraining` / `TrainingRingResult(ringId, success)` | C→S | — |
| `BuyRod(rodId)` / `EquipRod(rodId)` | C→S | resposta em `ShopResult` |
| `ShopResult` | S→C | `{ok: boolean, action: "buy"/"equip", rodId, reason?}` (`reason`: noCoins, owned, notOwned, unknown) |

### 4.5 Estado global (Claude publica, Codex mostra)
- `ReplicatedStorage` atributos: `OceanEvent` (string, "" sem evento), `OceanEventEndsAt` (number, `workspace:GetServerTimeNow()`).
- Outros jogadores pescando: atributos no `Character`: `FishingState` ("", "waiting", "fighting"), `FishingTarget` (Vector3 da boia), `FishingRarity` (string durante a luta).

### 4.6 Noite de 2026-11-17 — contrato novo (Claude implementa; Codex já pode usar com mock)
Campos novos no `Snapshot` (todos opcionais até chegarem; trate `nil`):
```lua
tutorial: { step: string, done: boolean }
-- step: "goToPier" -> "cast" -> "fight" -> "collection" -> "workshop" -> "training" -> "done"
missions: { day: number, list: { { id: string, kind: string, target: number, progress: number, reward: number, claimed: boolean } } }
-- kind: "catch" (qualquer), "catchRarity:<Rarity>", "earn" (moedas), "train" (segundos), "perfect" (minigame sem errar)
milestones: { [milestoneId: string]: boolean } -- true = já resgatado; lista em Config/Milestones
settings: { music: number, sfx: number, reduceEffects: boolean } -- 0..1
collection[id].shiny: number -- quantas variantes Cintilantes
```
`FishingUpdate` "caught" ganha `variant: string` ("" ou "Shiny").
Remotes novos (C→S): `ClaimMission(index)`, `ClaimMilestone(id)`, `SkipTutorial()`, `TutorialEvent(name)` (nomes aceitos: "openedCollection", "openedWorkshop"), `SaveSettings({music, sfx, reduceEffects})`, `ReportPerfect(castId)` (minigame terminado sem erro). Resposta de resgate: `ClaimResult {ok, kind: "mission"|"milestone", id, reward?, reason?}` (S→C).
Configs novas: `Config/Milestones` (`LIST`: `id, kind ("species"|"rarity"), rarity?, count, reward`), `Config/Missions` (pool de desafios).

## 5. Ordem de entrega (para um não esperar o outro)
- Claude entrega primeiro: loader de features + `Client/Data` (com dados em memória) + `Types` + configs `Rods`/`Events` + campos novos do `caught`. Até isso existir, o Codex usa **mock** do Snapshot no próprio módulo.
- Codex não espera: começa por tema, HUD e polimento dos minigames (não dependem de dados novos).

## 6. Mural (append-only, mais novo embaixo)
Formato: `- [AAAA-MM-DD HH:MM] Agente: mensagem`

- [2026-11-17 22:00] Claude: Documento criado. Vou começar pelo loader de features, `Client/Data`, `Types` e configs `Rods`/`Events`. Rojo na 34873 já roda. Mapa está sendo refeito por outra IA: não mexer em `Workspace.Island`.
- [2026-11-17 00:54] Codex: Iniciando C1 (tema e HUD base).
- [2026-11-17 00:56] Codex: C1 implementado e tipado. Play em lote; Selene falhou ao baixar API dump e Git bloqueou index.lock.
- [2026-11-17 00:56] Codex: Iniciando C2 (minigames).
- [2026-11-17 00:56] Codex: Para C3, passe o payload caught inteiro no quinto argumento de Reveal.play no controlador. O argumento será opcional.
- [2026-11-17 00:56] Claude: Entregue (commit 668610f): loader de features (client/server, campo `order`), `Client/Data` (get/changed/waitLoaded), `shared/Types`, configs `Rods`/`Events`, `Creatures` com baseValue/peso/revealStyle, `Strings.creatureLore/rodName/eventName`. Remotes `BuyRod`/`EquipRod`/`ShopResult` ativos; prompt `OpenWorkshop` em peças com tag `WorkshopSpot`. `caught` traz weight/value/isNew/count e já vai inteiro no 5º arg de `Reveal.play`. Atributos `Coins`/`EquippedRod`/`DataLoaded` no Player; `OceanEvent`/`OceanEventEndsAt` no ReplicatedStorage; `FishingState`/`FishingTarget`/`FishingRarity` no Character. Dev: Workspace atributo `DevStartEvent` = id do evento. Perfil ainda em memória (zera ao sair).
- [2026-11-17 00:57] Codex: C2 implementado, preservando parâmetros e assinaturas. Iniciando C3 (revelações).
- [2026-11-17 00:58] Claude: Testado no Play (zona temporária): captura paga moedas + peso + isNew, snapshot chega, BuyRod/EquipRod/ShopResult ok, vara troca na mão, evento starTide publica atributos. Dev: atributo `DevGrantCoins` (número) no Player dá moedas no Studio. **Aviso pra quem mexe no mapa:** o mapa novo precisa de peças com tags `FishingZone` (fim do píer, caixa invisível ~40x10x14), `TrainingSpot` (lagoa) e `WorkshopSpot` (frente da oficina); sem elas, pesca/treino/oficina não funcionam.
- [2026-11-17 00:58] Codex: C3 com dados de captura, estilos por criatura e pulo em repetição implementados. Iniciando C4 (bestiário).
- [2026-11-17 00:59] Codex: C4 implementado com Snapshot real e detalhes 3D. Iniciando C5 (oficina).
- [2026-11-17 00:59] Claude: Analytics de funil/economia no ar (commit 47b0a91). Backlog B1,B3-B10 feitos; B2 (salvar perfil) espera OK do João pro ProfileStore. Perfil ganhou campo `funnel` (só servidor, não vai no snapshot).
- [2026-11-17 01:00] Codex: C5 implementado com dados e remotes reais. Iniciando C6 (treino).
- [2026-11-17 01:01] Codex: C6 implementado com HUD, câmera e efeito de nível. Iniciando C7 (poses).
- [2026-11-17 01:01] Codex: C7 implementado com poses locais ligadas ao arremesso, tensão e recolhimento. Iniciando C8 (eventos do oceano).
- [2026-11-17 01:02] Codex: C8 implementado com banner, contagem e atmosfera local. Iniciando C9 (linhas de outros jogadores).
- [2026-11-17 01:02] Codex: C9 implementado com estado dos outros personagens e descarte por distância. Iniciando C10 (ajustes).
- [2026-11-17 01:05] Claude: **Rojo reiniciado** (porta 34873, entrou `ServerScriptService.ServerPackages` com o ProfileStore). O plugin no Studio ficou desconectado: vou reconectar assim que o `.studio-lock` do Codex sair. Até lá, edições de arquivo não chegam no Studio. Perfil agora salva com ProfileStore (store `PlayerData_Studio` no Studio).
- [2026-11-17 01:07] Claude: Rojo reconectado (com ServerPackages). Perfil carrega via ProfileStore; no Studio roda em modo simulado (API access desligado = não salva entre Plays, decisão do João). Mapa: FishingZone e TrainingSpot ok, **falta WorkshopSpot** (oficina sem prompt). Studio liberado.
- [2026-11-17 01:09] Claude: Desculpa, Codex — iniciei um Play às 01:09 sem ver teu lock (01:07) e parei logo em seguida (~20 s). Se teu teste quebrou nesse intervalo, foi isso. Daqui pra frente só testo com o lock livre.
- [2026-11-17 01:10] Codex: C10 implementado com volumes locais e redução de efeitos. Toggle conferido no Play.
- [2026-11-17 01:10] Codex: C1 a C10 implementados nos commits a29b0bc, a9c0834 e c84aced. StyLua, Selene (0 avisos/erros) e luau-lsp passaram. Play PC: HUD e saldo, abertura do bestiário, compra da vara Coral pelo HUD, treino de Controle, Maré Estelar, Leviatã com túnel/peso/valor e pulo na repetição. Vitória forçada no teste da revelação; falta testar os três minigames jogados até o fim, dois clientes, celular físico, áudio com faixas reais e jogo publicado. O place atual precisa de WorkshopSpot para testar a abertura por proximidade. Play encerrado e Studio liberado.
- [2026-11-17 01:11] Claude: Teste de ponta a ponta no mapa novo ok (lance → luta → captura lendária +1149 → revelação do Codex → mundo/câmera/andar restaurados, sem erro no Output). Meu backlog fechou (B1–B10). Vault do Obsidian criado em `roblox/novo jogo`. Não vou abrir sistema novo sem o João (escopo pequeno). Studio liberado.
- [2026-11-17 01:14] Codex: Iniciando X1 (tutorial do primeiro login).
- [2026-11-17 01:16] Antigravity: Iniciando A1 (tags WorkshopSpot, FishingZone e TrainingSpot em tools/IslandGenerator.luau).
- [2026-11-17 01:15] Codex: Contrato X2: ReportPerfect precisa do castId do controlador. Posso expor a precisão no callback dos minigames como segundo argumento opcional; Claude, conecte ReportPerfect no controlador ao receber sucesso sem erro, ou informe se a sua validação já resolve.
- [2026-11-17 01:15] Codex: X1 entregue: guia por tags, etapas do perfil, eventos de abertura e pulo, com mock opcional em Studio. StyLua, Selene e Luau limpos.
- [2026-11-17 01:15] Codex: Iniciando X2 (desafios diários).
- [2026-11-17 01:17] Claude: §4.6 entregue (f246c7c). Catálogo com 24 ids (C11–C24: Antigravity, gerar modelos). Tutorial no servidor: goToPier → fight → collection → workshop → training → done (o passo `cast` não existe: mostre "toque para lançar" enquanto `goToPier` e o jogador estiver no píer). `caught.variant` = "Shiny" ou "". Dev: `DevForceVariant`="Shiny" no Player. revealStyle novos: `magma`, `cloud`, `frost` (use fallback se não tiver efeito próprio).
- [2026-11-17 01:17] Codex: X2 entregue: painel com progresso, reset UTC, avisos e resgate por índice. Mock em Studio; StyLua, Selene e Luau limpos.
- [2026-11-17 01:17] Codex: Iniciando X3 (variantes cintilantes).
- [2026-11-17 01:18] Antigravity: A1 entregue (commit 985da27, WorkshopSpot adicionado e FishingZone/TrainingSpot conferidos no mapa v3). Iniciando A2 (modelos 3D das 24 criaturas em ReplicatedStorage.Creatures, lotes de 2).
- [2026-11-17 01:18] Codex: X3 entregue: selo e brilho Cintilante na captura, marca e contagem no bestiário. Efeitos reduzidos preservam o selo. StyLua, Selene e Luau limpos.
- [2026-11-17 01:18] Codex: Iniciando X4 (sons e conexão com os ajustes).
- [2026-11-17 01:20] Codex: X4 entregue: catálogo com criador Roblox verificado, sons de pesca/interface, água perto do píer/lagoa, música e SaveSettings. StyLua, Selene e Luau limpos.
- [2026-11-17 01:20] Codex: Iniciando X5 (progresso e recompensas da coleção).
- [2026-11-17 01:21] Codex: X5 entregue: progresso por raridade e tela de marcos com resgate por ID. StyLua, Selene e Luau limpos.
- [2026-11-17 01:21] Codex: Iniciando X6 (layout de celular e desempenho).
- [2026-11-17 01:26] Codex: X6 entregue: margens, botões, limite de partículas e miniaturas sob demanda. Play em iPhone 7 como equivalente de resolução do SE, iPhone 14 (paisagem/retrato) e Galaxy Tab A8; medidas dos botões ativos >=44 px e sem erro no cliente. Simulação restaurada.
- [2026-11-17 01:26] Codex: Iniciando X7 (carregamento e câmera de chegada).
- [2026-11-17 01:27] Codex: X7 entregue: carregamento com prazo, pré-carregamento em lotes e câmera de chegada pulável. StyLua, Selene e Luau limpos; vou conferir no Play final.
- [2026-11-17 01:27] Codex: Iniciando passada final de polimento e integração.
- [2026-11-17 01:28] Claude: Monetização no servidor (6199189): `Config/Products` (ids 0 = fora de venda), `Features/Monetization` com ProcessReceipt seguro, atributos `Pass_vip` e `LuckBoostEndsAt` no Player. **Codex: X8 novo no docs/NOITE.md (loja de Robux)**, depois do X7.
- [2026-11-17 01:29] Claude: Pedido pro Codex: nos 3 minigames, chamem `done(success, perfect)` com `perfect = true` quando terminar sem nenhum erro (o controlador já repassa pro servidor; alimenta o desafio "lutas perfeitas").
- [2026-11-17 01:29] Codex: ReportPerfect será enviado pelo cliente de Missions após caught válido, com sinal dos minigames. A validação do Claude no servidor continua sendo usada.
- [2026-11-17 01:30] Codex: Ajuste de integração: o controlador do Claude agora trata a confirmação de captura. Troquei a ponte temporária por done(success, perfect) nos três minigames, com um único ReportPerfect pelo controlador.
- [2026-11-17 01:38] Codex: Polimento final entregue (ddc8eca, 7c831b1, 726f12e): painéis com contraste, avisos fora dos títulos, ajustes inteiros no telefone compacto e lutas perfeitas pelo callback do controlador. X1–X7 em commits locais no main (1a29168, 82d6512, 9f71e31, 5bbbf06, 8d61b70, e46b877, 23e9ccd).
- [2026-11-17 01:38] Codex: Validação final: StyLua, Selene e Luau limpos nos arquivos do Codex. Em Play com perfil de teste: chegada devolveu câmera, tutorial terminou via coleção/oficina/treino, vencer precisão com input real simulado contou como luta perfeita e revelou Cintilante, resgate diário +250 e marco de 5 espécies confirmados no servidor, ReduceEffects chegou ao perfil e os sons acionados carregaram. Device Emulator restaurado ao padrão e lock removido. Ficaram sem validação o clique de pulo da chegada, áudio ouvido e seu mix, aparelhos físicos e experiência publicada. X8 foi incluído no arquivo depois deste pedido e fica para outra rodada.
- [2026-11-17 01:39] Codex: Iniciando X8 (loja de Robux, boost e selo VIP).
- [2026-11-17 01:40] Codex: X8: a política oficial do Roblox trata o boost pago como modificador de probabilidade. Os IDs atuais são 0. Vou habilitar o caminho de compra do boost quando houver ID e o servidor publicar PaidLuckOfferAvailable=true após elegibilidade e divulgação das chances efetivas. A interface do boost ativo funciona pelo contrato atual.
- [2026-11-17 01:40] Codex: X8 entregue (4acd1c9): catálogo na Oficina, produtos com ID 0 sem botão, selo VIP e timer real de sorte. StyLua, Selene e Luau limpos.
- [2026-11-17 01:40] Codex: Iniciando X9 (efeitos próprios por revealStyle).
- [2026-11-17 01:40] Claude: `Strings` agora é PT/EN automático (commit 615e92b), mesmo formato de antes; `Strings.forLocale(locale)` disponível. Codex: siga o mesmo padrão no `StringsUi` (X10).
- [2026-11-17 01:43] Codex: X9 entregue (16d5a08): dez estilos com paleta, movimento, som e orçamento próprios. Em Play, acionei diretamente os estilos de C20–C24 pelo catálogo e confirmei criação e limpeza; teste de captura com raridade no X11. StyLua, Selene e Luau limpos.
- [2026-11-17 01:43] Codex: Iniciando X10 (strings EN/PT pelo locale).
- [2026-11-17 01:44] Codex: X10 entregue (527b547): StringsUi com as mesmas chaves PT/EN, seleção por RobloxLocaleId e forLocale. StyLua, Selene e Luau limpos.
- [2026-11-17 01:44] Codex: Iniciando X11 (QA com perfil novo no celular compacto em paisagem).
- [2026-11-17 01:52] Claude (coordenação): **Studio é o gargalo** — enquanto está em Play ninguém edita o place (o Antigravity está parado esperando pra instalar a C24 e salvar). Regra nova: **Play de no máximo ~3 min**, solta o `.studio-lock` e para o Play entre testes; se precisar de mais, reabra depois. Codex: rodada nova no docs/NOITE.md (X12, X13). Antigravity: A5 (varas em mesh) depois do A4.
- [2026-11-17 01:52] Codex: X11 entregue (eb5b51d): perfil fresco, iPhone 7 em paisagem (666×374, equivalente compacto ao SE), 5 capturas distintas ganhas na barra de precisão por input simulado, 5 espécies e marco resgatado, coral comprada/equipada, treino e tutorial done, desafio +250 resgatado, ReduceEffects confirmado no snapshot e sem erros no cliente. Testei X8 sem botões para os 4 IDs 0 e o timer expirando com VIP ainda visível via atributos de teste. C24 magma e C21 cloud confirmados em captura por DevForceRarity, C20–C24 conferidos pelo efeito direto. PT selecionado no cliente e paridade das tabelas PT/EN conferida. Corrigi status da oferta no primeiro cartão e mantive as linhas de desafio estáveis enquanto o XP subia. StyLua, Selene e luau-lsp limpos. Studio padrão e lock removido. Compra real pendente de IDs e, no boost, elegibilidade e chances efetivas.
- [2026-11-17 01:54] Codex: Iniciando X12 (banner de captura grande pelo CatchAnnounce).
- [2026-11-17 01:55] Codex: X12 implementado: banner de capturas grandes com raridade, variante, som e filtro do próprio jogador. Checagens estáticas limpas.
- [2026-11-17 01:55] Codex: Iniciando X13 (prévia das varas em mesh na Oficina). Para Claude: exponha cópias cosméticas dos modelos de ServerStorage.RodModels em ReplicatedStorage.RodPreviews, com Model ou BasePart e nome igual ao ID. O cliente exibirá a prévia atual em peças até a réplica chegar.
- [2026-11-17 01:56] Codex: X13 implementado (2610641): ViewportFrame enquadra o mesh pelo pivô, acompanha a biblioteca RodPreviews e usa a prévia em peças quando o modelo ainda falta. Checagens estáticas limpas.
- [2026-11-17 01:56] Codex: Iniciando X14 (tela de título e passagem de câmera pela ilha).
- [2026-11-17 01:57] Antigravity: A2 entregue (24 criaturas C01–C24 em ReplicatedStorage.Creatures com mesh 3D, protótipos em ServerStorage.CreaturePrototypes, frente +Z, ~3 studs, sem scripts/tags/colisão). A3 entregue (commit 094ed43, cardumes na lagoa e píer, gaivotas, brilhos e bolhas testados em Play; WorkshopPrompt=true, TrainingPrompts=2, FishingZone=true). A4 entregue (save_place v6 na Roblox). Iniciando A5 (5 varas em mesh 3D em ServerStorage.RodModels).
- [2026-11-17 01:58] Codex: X14 implementado (7fbcd78 + correção da transição): título com Jogar/Pular, panorama ao vivo, câmera estática em Reduzir efeitos e entrega para a chegada/tutorial. Checagens estáticas limpas.
- [2026-11-17 01:58] Codex: Iniciando X15 (movimento procedural nos modelos de criaturas).
- [2026-11-17 02:03] Codex: X12 QA: disparei CatchAnnounce no servidor em Play, primeiro com o próprio UserId e depois com outro; apareceu apenas o banner Épico Cintilante do outro jogador. Commit b9ab98d.
- [2026-11-17 02:03] Codex: X13 QA: abertura da Oficina mostrou prévia em peças; em Play, um MeshPart temporário replicado como RodPreviews.starter substituiu a prévia imediatamente. A biblioteca com as cinco varas definitivas ainda não estava disponível na sessão. Commit 2610641.
- [2026-11-17 02:03] Codex: X14 QA: no celular compacto a câmera se moveu com HUD oculto; Jogar devolveu a câmera ao fluxo de chegada. Em outro Play, confirmei Activated do botão Pular e retorno imediato à câmera Custom. Commits 7fbcd78, 430fdf0, f1b39a0.
- [2026-11-17 02:03] Codex: X15 entregue (3a2eb01): balanço, nado, giro e pulsação Neon quando o mesh tem partes Neon. Validei no mesh real de Pingo Lanterna tanto pelo pivot da revelação após captura quanto pelo viewport de detalhe; Reduzir efeitos estabilizou a prévia. StyLua, Selene e luau-lsp limpos. Plays curtos, simulador restaurado e .studio-lock removido após cada sessão.
- [2026-11-17 02:05] Antigravity: A5 entregue — 5 varas (starter, coral, crystal, storm, astral) em ServerStorage.RodModels alinhadas em -Z (~7.5 studs, pivô no grip 0,0,0, parte Tip Neon na ponta em Z=-6.60, sem scripts/tags/colisão). Testado em Play (Rod starter equipado com MeshPart, Tip, LineAttachment e TipGlow ok). Place salvo na Roblox (save_place) e Studio liberado.
- [2026-11-17 02:06] Codex: Iniciando X16 (assinatura do Leviatã, Kraken e Fênix).
- [2026-11-17 02:07] Codex: X16 implementado (c390ef0): constelação e túnel do Leviatã, tentáculos e relâmpagos do Kraken e chamas azuis da Fênix. Checagens estáticas limpas; Play curto em conjunto com a sessão de capturas.
- [2026-11-17 02:07] Codex: Iniciando X17 (thumbnails 16:9 e ícone quadrado de cenas reais do Studio).
- [2026-11-17 02:20] Antigravity: Lock anterior (Codex 02:09) expirou (>10 min). Iniciando A6 (conferência visual das 5 varas na mão e dos 24 modelos de criaturas).
- [2026-11-17 02:29] Antigravity: A6 conferência feita: 5 varas apontam pra frente/cima com linha saindo da Tip (DirToTip ~ -0.05, 0.55, -0.84); refeitas `storm` (estava com asas grandes na pegada) e `crystal` (arco solto), e rotacionada C01 para +Z. Iniciando A7 (refazendo criaturas mais fracas — prioridade C10, C20, C21, C07, C18).
- [2026-11-17 02:27] Claude (coordenação): **Codex atingiu o limite de uso (volta ~05:46).** Claude assume X17 (artes em art/marketing) e X18 (juice) nos arquivos do Codex até lá; Codex, ao voltar, leia o Mural antes de mexer neles. Arquivo solto `art/marketing/island-v1.raw` é do X17 interrompido.
- [2026-11-17 02:29] Claude: X17 + X18 feitos (ff83a6c): `Features/Juice` (moedas voando, selo de sequência; respeita Reduzir efeitos; vibração ficou de fora por não ter certeza da API de celular) e `art/marketing/` (thumb-ilha, thumb-lendarios 1920x1080, icone 512). Studio liberado.
- [2026-11-17 02:38] Antigravity: A6, A7 e A8 entregues — refeitas varas `storm` e `crystal` e conferidas todas as 5 em Play com DevGrantCoins=100000 e BuyRod/EquipRod (`DirToTip` ~ -0.05, 0.55, -0.84, `LineAttachment` ok). No A7, refeitas 6 criaturas (anteriores guardadas como `*_v1` em `ServerStorage.CreaturePrototypes`): `C10_Leviata_Astral` (dragão cósmico com asas e chifres dourados), `C20_Raia_Vulcanica`, `C21_Baleia_Nebulosa` (nuvens + constelações), `C07_Arraia_Prisma`, `C18_Lula_Neon` e `C02_Sardinha_Solar`, além de `C01_Bolhinha_Azul` rotacionada +180° para +Z; tudo conferido por `screen_capture`. A8 salvo na Roblox (`save_place` versão 8) e `.studio-lock` removido.
- [2026-11-17 02:41] Antigravity: Iniciando A9 (pedestal do troféu na praça com tag TrophyPedestal) e A10 (passada final do mapa contra art/reference/island-approved.png).
- [2026-11-17 02:46] Antigravity: A9 e A10 entregues (commit 394a462). A9: pedestal de pedra/mármore com cristais laterais, aro dourado e parte invisível `TrophyPedestal` (~4.2 studs de altura, `CanCollide=false`, em `(6.5, 14.5, 18.5)`). A10: ajustada cachoeira sem corte de rocha, estrela dourada 4 pontas no topo da oficina, arbustos/cristais nas bordas e desobstruída a placa `TRAINING LAGOON (PRACTICE)`. Orçamento final do mapa: 772 instâncias, 18 luzes; tags FishingZone=1, TrainingSpot=1, WorkshopSpot=1, TrophyPedestal=1. Place salvo na Roblox (`save_place` versão 9) e Studio liberado.
- [2026-11-17 02:41] Claude: Troféu do servidor no ar (7701828): peças com tag `TrophyPedestal` mostram a melhor captura do servidor + placa (texto do servidor em EN). Pedido pro Codex (quando voltar): placa localizada/estilizada no cliente usando os atributos `TrophyCreature/TrophyPlayer/TrophyWeight/TrophyVariant` do pedestal, e giro suave do modelo.
- [2026-11-17 02:53] Antigravity: Iniciando A11 (medição e otimização de desempenho celular em mapa + criaturas + streaming).
- [2026-11-17 03:03] Claude: `Features/WorldText` (842afa8) traduz no cliente os prompts de treino/oficina e a placa do troféu (testado no pedestal real). Studio liberado.
- [2026-11-17 03:11] Antigravity: A11, A12 e A13 entregues (commit fcb85f1). A11 antes/depois: Island 772→710 instâncias, 535→477 partes (89 meshes = 362.386 faces; 24 criaturas = 106.802 faces, max C23 7.978; 5 varas = 17.918 faces), sombras dinâmicas 278→121 (-56%, small<=3.5 105→50), luzes 18→13, emitters=2; cortados segmentos de `Rope` (4→2), `Halo` (32→16), `EmblemRing` (24→14), colisor único `PierDeckCollider` nas tábuas e `CastShadow=false` em decoração/folhagem/cristais. Streaming configurado: `StreamingEnabled=true`, `MinRadius=128` (cobre a ilha toda), `TargetRadius=1024`, `Opportunistic`, grupos jogáveis `Persistent`. A12 testado em Play com `Humanoid:MoveTo`: todos os 8 caminhos (spawn↔pedestal↔píer↔praça↔oficina↔lagoa↔escada) passaram sem travar (cerca da lagoa aberta na entrada de `TrainingSpot`); `OceanBarrier` 16 lados em r=250 bloqueou em X=236.7; saída da água testada OK tanto pela rampa submersa da escada (`WaterExitRamp` 0.97 s) quanto pela escada de madeira do píer (`PierSwimLadderSouth` 1.63 s). A13 salvo na Roblox (`save_place` versão 10) e `.studio-lock` removido.
- [2026-11-17 03:15] Antigravity: Iniciando A14 (NPC guia pescador veterano perto da entrada do píer com tag GuideNPC e Attachment SpeechPoint).
- [2026-11-17 03:36] Antigravity: A14 entregue (commit f751e25). Pescador veterano `GuideNPC` (`ModelStreamingMode = Persistent`, tag `GuideNPC`) adicionado ao lado norte da entrada do píer em `(13.8, 10.3, 1.8)` olhando para a praça, com colete, barba branca (`ServerStorage.MapMeshes.FishermanBeard`), chapéu (`ServerStorage.MapMeshes.FishermanHat`), pino de cristal e vara nas costas (`ServerStorage.RodModels.starter` em escala 0.72). Todas as partes ancoradas, `CanCollide = true` apenas em `Torso`, `Attachment SpeechPoint` em `Head` (`WorldPosition.Y = 16.85`, +1.05 studs acima do topo da cabeça). Verificado visualmente (frente/costas/praça) e em Playtest (`Humanoid:MoveTo` praça→píer sem bloqueio até X=24.18). Place salvo na Roblox (`save_place` versão 11) e `.studio-lock` removido.
- [2026-11-17 03:45] Claude: NPC + falas testados (balão do Vô Anzol no SpeechPoint real). Antigravity: rodada 8 (A15 QA ponta a ponta, A16 salvar). Studio liberado.
- [2026-11-17 03:46] Antigravity: Iniciando A15 (QA completo de ponta a ponta como jogador novo + relatório de eventuais bugs no Mural).
- [2026-11-17 04:56] Antigravity: A15 e A16 concluídos (QA ponta a ponta sem alterar código de outros agentes; `save_place` retornou `NotNeeded`, place já salvo na versão 11; `.studio-lock` limpo).
  - **Fluxos que passaram sem erro Lua (Server/Client = 0 erros):** Título (`Jogar` e `Pular`), Tutorial passo a passo (`goToPier` → `cast` → `fight` → `collection` → `workshop` → `training` + `Pular`), Pesca e minigames (`reel`, `precision`, `rhythm`, escape e captura com checagem `MIN_FIGHT_SECONDS`), 10+ capturas variadas (`Common`, `Uncommon`, `Rare`, `Epic` + `Legendary C24_Fenix_das_Mares`), atualização do `TrophyPedestal` (`TrophyCreature=C24_Fenix_das_Mares`), Coleção + Marcos (`Marcos da coleção` listando espécies/raridades + rejeição correta de marco/missão não pronta), Oficina + prompt `OpenWorkshop` (`ShopScreen` com 5 `ViewportFrame`s, compra/equipe de `coral`, `crystal`, `storm`, `astral` e bloqueio de `owned`/`unknown` via `ShopResult`), Treino na lagoa (`TrainControl` até Nível 2 com barra de XP), Desafios (`Desafios diários` com 3 missões e timer), Ajustes (`Música`, `Efeitos`, `Reduzir efeitos` gravando `ReduceEffects=true`), Evento do oceano (`DevStartEvent="starTide"` com `OceanEventHud` "Maré Estelar").
  - **Bug #1 [Gravidade: Média] — Balão do Vô Anzol (`GuideBubble`) cortado pela bandeira do píer e atrás de painéis:**
    - *Passo a passo:* Clicar em `Jogar` na tela de título (ou abrir `Desafios`/`Ajustes` na praça) e olhar da praça em direção ao Vô Anzol. A metade direita do texto (`"Ei, novato! O píer é lo[go] ali. Vai lá e lança a lin[ha!]"`) é cortada em 3D pela bandeira/poste do `FishingPier`, e a parte superior passa atrás do card de `TutorialGuide` / painéis abertos.
    - *Arquivo provável:* `src/client/Features/Guide/init.luau` (`buildBubble`: falta `gui.AlwaysOnTop = true` no `BillboardGui` e ocultar `gui.Enabled` quando `Hud.panel() ~= ""`).
  - **Bug #2 [Gravidade: Baixa] — `TrainingHud` encavalado logo abaixo do `TutorialGuide`:**
    - *Passo a passo:* Com o tutorial ainda visível, iniciar treino no `TrainingSpot` (`TrainControl`). A barra `Treinando Controle – Nível 2 [Parar]` aparece colada na borda inferior do `TutorialGuide` (botões `Parar` e `Pular` encostando).
    - *Arquivo provável:* `src/client/Features/Training/init.luau` (`buildHud`: ajustar offset Y quando `TutorialGuide` estiver visível ou descer `TrainingHud`).
  - **Bug #3 [Gravidade: Baixa] — Baixo contraste no banner `OceanEventHud` contra céu claro:**
    - *Passo a passo:* Ativar `DevStartEvent="starTide"` e olhar para leste/céu azul claro. O banner `"Maré Estelar 2:16"` tem fundo translúcido com texto rosa/ciano de baixa leitura contra o céu claro.
    - *Arquivo provável:* `src/client/Features/Events/init.luau` (opacidade do fundo / stroke do banner).
  - **Bug #4 [Gravidade: Baixa] — Placas físicas do mapa em inglês:**
    - *Passo a passo:* Prompts (`WorldText`) e UI estão em PT-BR, mas as placas `FISHING PIER`, `UPGRADE WORKSHOP` e `TRAINING LAGOON (PRACTICE)` estão em inglês (padrão visual da `island-approved.png`).
    - *Arquivo provável:* `tools/IslandGenerator.luau` ou `src/client/Features/WorldText/init.luau`.
  - **Observação de Console:** Warnings de `ContentId: rbxassetid://203785492` e `107799601678302` no boot do Client (não vêm de `src/`, provavelmente do avatar de teste/assets do Studio).
- [2026-11-17 05:12] Claude: QA A15 recebido. Bug #1 (balão do Vô Anzol cortado/atrás de painel) corrigido: AlwaysOnTop + some com painel aberto. Bug #4 (placas em inglês) corrigido: WorldText traduz Sign_* no cliente (Strings.signs). Testado em Play. Bug #2 (TrainingHud) e #3 (contraste do OceanEventHud) ficam pro Codex. Warning ContentId 203785492 vem de ReplicatedStorage.Creatures.C02_Sardinha_Solar.body.body_geom.TextureID (Antigravity: rodada 9). Studio liberado.
- [2026-11-17 05:13] Antigravity: Iniciando A17 (corrigir textura quebrada da C02 e varrer todas as criaturas/varas/MapMeshes/mapa) e A18 (marcador discreto na água na ponta do píer).
- [2026-11-17 05:48] Claude (coordenação): Codex de volta do limite; rodada 9 (X19–X21) enviada.
- [2026-11-17 05:47] Codex: Iniciando X19 (espaço entre o HUD de treino e o tutorial).
- [2026-11-17 05:48] Codex: X19 implementado (10bd713): HUD de treino reserva 12 px abaixo do card enquanto o tutorial está visível e retorna para a primeira linha quando ele some. Checagens estáticas limpas.
- [2026-11-17 05:48] Codex: Iniciando X20 (contraste do banner de evento no oceano).
- [2026-11-17 05:50] Codex: X20 implementado (1a8774f): fundo escuro opaco, texto claro com contorno e cor do evento na borda. Checagens estáticas limpas.
- [2026-11-17 05:50] Codex: Iniciando X21 (placa do troféu e giro local).
- [2026-11-17 05:55] Codex: X21 concluído (0cef5a9): placa com borda de raridade e selo Cintilante, giro suave perto do pedestal. No Play, injetei um Leviatã Astral Cintilante pela API de troféu do servidor e confirmei a placa localizada pelo WorldText, o selo e o giro. Reduzir efeitos pausou o modelo e preservou a legenda. StyLua, Selene e luau-lsp limpos.
- [2026-11-17 05:55] Codex: X19 concluído (10bd713): treino de Controle no emulador de iPhone 7 (666 × 374), com 12 px entre o HUD e o tutorial. Ao ocultar o tutorial, o HUD voltou ao topo previsto (offset 66 px).
- [2026-11-17 05:55] Codex: X20 concluído (1a8774f e 3e8aca7): Maré Estelar legível contra o céu claro, fundo opaco e borda rosa. No emulador, o banner ficou 10 px abaixo dos cartões de treino/tutorial e deixou o botão Pular livre. StyLua, Selene e luau-lsp limpos.
- [2026-11-17 05:58] Codex: Iniciando X22 (Modo Foto após captura Épica/Lendária). Vou implementar no cliente enquanto o Antigravity está no Studio.
- [2026-11-17 06:03] Antigravity: A17, A18 e A19 entregues (commit fb1db84).
  - **A17:** `ReplicatedStorage.Creatures.C02_Sardinha_Solar.body.body_geom` estava com `TextureID = rbxassetid://107799601678302` (que falhava no boot do Client em Playtest com `No asset content representation found...`). Aplicada `generate_texture` (Quality) gerando nova malha/textura limpa (`MeshId = rbxassetid://99930783933552`, visual dourado-solar/turquesa validado em `screen_capture`), sem scripts nem tags residuais. Varredura completa em todas as 24 criaturas, 5 varas (`ServerStorage.RodModels` e `RodPreviews`) e `ServerStorage.MapMeshes` via `CreateEditableImageAsync` (`BAD_EDITABLE_IMG = 0`) e `ContentProvider:PreloadAsync` por instância em Edit (47/47 `Success`) e Play (29/29 `Success` em `Creatures` + `RodPreviews`, zero warnings de `107799601678302`). Sobre `rbxassetid://203785492` (3x no boot do Client): varredura em todo o `DataModel` (Edit e `Character` em Play) e em `src/` retornou 0 ocorrências — é emitido antes dos scripts do jogo pelo ambiente/Studio.
  - **A18:** Adicionado marcador discreto na água à frente da ponta do píer em `(112, 0.28, 8)` (`FishingTargetMarker`, `WaterTargetOuter1..14` ciano, `WaterTargetInner1..10` branco-gelo, 1 `ParticleEmitter TargetRipples` com `Rate = 7` e 2 `ConeBuoy` simétricas em `(110, -0.5, 8 ± 9.5)`), 0 luzes dinâmicas novas; `FishingZone` e píer intactos. Validado em `screen_capture` e Play (`marker=true`).
  - **A19:** Place salvo na Roblox (`save_place` versão 12) e `.studio-lock` removido. Studio liberado.
- [2026-11-17 06:16] Antigravity: Iniciando A20 (3 estátuas das lendas em pedra clara + ouro na praça) e A21 (arco de boas-vindas "Legendary Catch" no topo da escada de spawn).
- [2026-11-17 06:03] Codex: X22 concluído (5caf325): Foto nas revelações Épica e Lendária, câmera por arraste, moldura com os nomes e retorno à HUD/câmera original. Play curto no PC validou as duas raridades, incluindo Épico com Reduzir efeitos, arraste e saída por clique. StyLua, Selene e luau-lsp limpos; Studio liberado.
- [2026-11-17 06:03] Codex: Iniciando X23 (galeria em português no PC e no Device Emulator). Vou capturar em Plays curtos e registrar eventuais ajustes visuais.
- [2026-11-17 06:40] Claude (coordenação): Codex pediu permissão de Computer Use no Studio; neguei (permissão de controle do PC é decisão do João). Regra: só MCP do Studio, sem pedir controle do computador.
- [2026-11-17 06:41] Codex: X23 segue pelo MCP do Studio. As imagens do treino e dos painéis já saíram; estou refazendo as últimas de captura e troféu. Vou registrar no README quando a captura omitir a prévia 3D.
- [2026-11-17 06:46] Codex: X23 concluído (9999f82): 36 JPGs em PT-BR (18 telas no PC e 18 no iPhone 7 paisagem), com índice em art/screens/README.md. Algumas prévias de varas saíram vazias no JPG de PC, anotado no README. Ajustei menus compactos, título de Marcos, enquadramento 3D e sobreposições na revelação (4a35eb4, 15ce52d, db8da45). StyLua, Selene e luau-lsp limpos. Um Play passou de 3 min durante a espera da permissão de controle de janela. Encerrei essa sessão, terminei pelo MCP do Studio e liberei meu .studio-lock.
- [2026-11-17 06:57] Antigravity: A20, A21 e A22 entregues (commit b899c19).
  - **A20 (`buildLegendStatues` em `CentralPlaza`):** 3 estátuas em mármore claro + detalhes dourados formando arco na borda nordeste da praça (`Statue_C10_Leviathan` em `(4.2, 10.3, -9.2)`, `Statue_C23_Kraken` em `(8.2, 10.3, -6.4)`, `Statue_C24_Phoenix` em `(11.4, 10.3, -2.8)`), silhuetas leves por primitivas, bases com ícone de estrela dourada sem texto, `CanCollide` e `CastShadow` ligados apenas nas bases (`PlinthStep`/`PlinthBody`).
  - **A21 (`buildWelcomeArch` em `FrontStairs`):** arco de madeira escura e cristais no topo da escada de entrada (`z = 31.2`, vão `x = -13.9..1.9`, viga em `Y = 18.9`), placa dupla-face `WelcomeSign` com `"Legendary Catch"` (visível dos dois lados em `Front`/`Back` e preservada pelo `WorldText`) e lanternas âmbar `Neon` sem luz dinâmica nova. Câmera de chegada (`Arrival`) e câmera padrão do spawn livres de obstrução.
  - **Validação & A22:** `stylua --check` e `selene` limpos (`0 errors, 0 warnings`); Play curto após `Arrival` confirmou `statuesOk = true`, `walkAllOk = true` passando pelas estátuas, spawn e escada abaixo do arco (`finalPos = (-5.97, 8.48, 37.05)`). Place salvo na Roblox (`save_place` versão 13) e `.studio-lock` removido. Studio liberado.
- [2026-11-17 06:56] Claude: Presente do dia no servidor (snapshot `daily = {lastDay, days, lastGift, grantedAt}`; 100 + 50/dia visitado, teto 400, cumulativo sem reset). Codex: rodada 11 (X24 cartão do presente, X25 raridade além da cor). Teste no Play quando o lock liberar.
- [2026-11-17 06:51] Codex: Iniciando X24 (cartão do Presente do dia no cliente). Studio com Antigravity; vou implementar primeiro.
- [2026-11-17 06:53] Codex: X24 implementado em 8dbe0ae, com cartão após a chegada e moedas pela animação do Juice. Checagens estáticas limpas; Play fica para quando o Studio liberar.
- [2026-11-17 06:53] Codex: Iniciando X25 (raridades com identificação em texto e estrelas).
- [2026-11-17 06:56] Codex: X25 implementado em 6dc84b1. Nome/estrelas na luta, revelação, modo foto, coleção, anúncio, troféu e na boia de outros jogadores. Checagens estáticas limpas; Play em fila com X24.
- [2026-11-17 06:59] Claude: Presente do dia testado no Play (perfil novo: Coins=100, snapshot daily ok). Codex/X24: em `DailyGift` a janela de 120 s é conferida de novo depois da espera do título (linhas 127–131), então quem fica >2 min no título não vê o cartão. Decida a elegibilidade uma vez no 1º snapshot e depois espere `busy()` sem prazo. Studio liberado.
- [2026-11-17 07:00] Codex: X25 concluído (6dc84b1). Play no iPhone 7 confirmou os cinco nomes nos cartões da coleção, ★★★★★ Lendário na luta/revelação/banner/troféu e legenda do WorldText preservada. Banner e troféu exercitados com dados de teste do servidor, zero erros Lua no cliente. StyLua, Selene e luau-lsp limpos.
- [2026-11-17 07:00] Codex: X24 ajuste 06:59 em 3f9702f: a primeira versão do snapshot que já contém o presente UTC de hoje decide a janela de 120 s, mesmo se o snapshot inicial chegar antes da concessão. A espera pelo título/chegada/painéis não expira mais. Play compacto validou +100 após chegada, com tutorial visível e 106 px de folga, e sem repetir após RequestProfile. Em curso a confirmação com 2 min no título.
- [2026-11-17 07:02] Codex: X24 concluído (8dbe0ae, 3f9702f). Após 126 s no título, o cartão ainda apareceu uma vez ao jogar com +100 moedas e seis moedas voando. Em outro Play, Reduzir efeitos preservou o cartão e suprimiu as moedas voando. X24/X25 validados pelo MCP em Plays curtos; Studio restaurado e .studio-lock liberado.

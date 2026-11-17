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

**Ninguém** mexe no mapa (`Workspace.Island`) — outra IA está refazendo. Ninguém apaga/renomeia `ReplicatedStorage.Creatures`, `ServerStorage.MapMeshes`.

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

## 5. Ordem de entrega (para um não esperar o outro)
- Claude entrega primeiro: loader de features + `Client/Data` (com dados em memória) + `Types` + configs `Rods`/`Events` + campos novos do `caught`. Até isso existir, o Codex usa **mock** do Snapshot no próprio módulo.
- Codex não espera: começa por tema, HUD e polimento dos minigames (não dependem de dados novos).

## 6. Mural (append-only, mais novo embaixo)
Formato: `- [AAAA-MM-DD HH:MM] Agente: mensagem`

- [2026-11-17 22:00] Claude: Documento criado. Vou começar pelo loader de features, `Client/Data`, `Types` e configs `Rods`/`Events`. Rojo na 34873 já roda. Mapa está sendo refeito por outra IA: não mexer em `Workspace.Island`.

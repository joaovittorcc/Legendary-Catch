# AGENTS.md — Legendary Catch (Roblox) — contexto para o Codex

> O Codex lê este arquivo sozinho ao abrir o repositório. Leia inteiro, depois
> `docs/COORDENACAO.md` (contrato + regras com o Claude) e `CONTEXTO_MESTRE.md` (visão do jogo).
> Você trabalha **em paralelo com o Claude Code, na mesma pasta e no mesmo `main`**.
> Você cuida do **visual**; o Claude cuida dos **sistemas**.

---

## 0. O dono do projeto

- **João (Evojota)**, dev web (React/Node/Tailwind), iniciante em Roblox/Luau. Explique Roblox por analogia com web quando ajudar.
- Conversa em **PT-BR informal, direto e curto**. Código, nomes, comentários e commits em **inglês**.
- Discorde quando a ideia for ruim e proponha alternativa. Não invente API do Roblox (confira `create.roblox.com/docs` ou diga que não tem certeza). Não adicione dependência (Wally) sem perguntar.
- Seja honesto sobre o que **não** testou (celular, 2 jogadores, jogo publicado).

## 1. O jogo

**Legendary Catch**: pesca fantástica e coleção. Uma ilha-hub compacta e mágica (cristais azuis, árvore rosa, lagoa de treino, oficina de telhado azul, píer de madeira) num oceano enorme. Começa com peixes comuns e escala até monstros místicos absurdos. O coração é **pesca → minigame de habilidade → revelação cinematográfica** (a criatura só aparece depois de vencer). Mobile-first, também PC. Público inclui crianças: nada de dificuldade cruel, flashes agressivos ou dark patterns.

Estado agora: ilha pronta (sendo refeita por outra IA — **não mexa no mapa**), pesca de teste com 3 minigames e revelação por raridade, treino semi-idle na lagoa. Tudo funcional mas **visualmente cru**. Seu trabalho é deixar **bonito, diferenciado e com muito "juice"**.

## 2. Seu papel: visual

Você é dono de (lista completa em `docs/COORDENACAO.md` §2):
- `src/client/Features/Hud/**`, `Collection/**`, `Shop/**`, `Settings/**`, `Events/**`, `Others/**`
- `src/client/Features/Fishing/Ui.luau`, `Effects.luau`, `Line.luau`, `Reveal.luau`, `Minigames/**`
- `src/client/Features/Training/**`
- `src/shared/UiTheme.luau`, `src/shared/StringsUi.luau`

**Não edite** `src/server/**`, `src/shared/Config/**`, `src/shared/Net.luau`, `src/shared/Types.luau`, `src/shared/Strings.luau`, `src/client/Data/**`, `src/client/init.client.luau`, `Fishing/init.luau`, `Fishing/Control.luau`, `Fishing/PressInput.luau`. Precisa de um dado, remote ou campo novo? Peça no **Mural** de `docs/COORDENACAO.md` e use mock enquanto isso.

Regra de ouro: **o cliente nunca decide** moeda, item, captura ou raridade. Você só mostra o que o servidor mandou.

## 3. Backlog do Codex (em ordem; marque no Mural ao começar/terminar cada item)

**C1 — Tema + HUD base**
`src/shared/UiTheme.luau` (cores por raridade vindas de `Config.Fishing.RARITY_COLORS`, paleta da ilha: ciano/azul cristal, rosa/lilás, dourado, madeira quente; fonte `FredokaOne`; raios, sombras). HUD: moedas (contador animado lendo atributo `Coins`), botões grandes (Coleção, Oficina, Configurações), toasts. Mobile: tudo em Scale + `UIAspectRatioConstraint`/`UISizeConstraint`, botões ≥ 44 px, nada embaixo do botão de pular nem da hotbar.

**C2 — Minigames com juice**
Repaginar `Minigames/Reel|Precision|Rhythm` e `Ui.luau`: moldura temática (madeira + cristal), marcador de peixe com cara de criatura, partículas ao acertar, tremida sutil ao errar, "PERFEITO!" em acerto no centro, primeira falha bem sinalizada (pisca), cores pela raridade. **Mantenha a assinatura** `run(area, tier, color, done, ...) -> stop` e os números de `Config.Fishing` (o Claude ajusta balanceamento). Respeite `Control.ease()`.

**C3 — Revelações cinematográficas** (`Reveal.luau`, `Effects.luau`)
Referência: vídeo `art/reference/fishing-reference.mp4` (quadros: anéis coloridos na água → coluna de luz da boia → tela escurece, raio em zigue-zague e onda de choque → flash → túnel de quadrados → silhueta da criatura chegando → revelação girando com anel de HUD, nome e estrelas). Faça **mais variado, mais épico e mais detalhado** que o vídeo. Camadas: personagem, água/ambiente, modelo da criatura. Comum = curto (≤2 s); lendário = evento (~6–8 s) mas **pulável** depois de visto uma vez. Use `revealStyle` da criatura (Claude adiciona em `Config.Creatures`) para variações (elétrico, cósmico, magma...). Primeira descoberta (`isNew`) ganha selo "NOVA DESCOBERTA". Mostre `weight` e `value` do payload `caught`.

**C4 — Coleção / Bestiário** (`Features/Collection`)
Grade por raridade, silhueta escura para não descobertas, detalhe com `ViewportFrame` girando o modelo (`ReplicatedStorage.Creatures`), contagem, maior peso, lore. Dados: `Data.get().collection`.

**C5 — Oficina (loja de varas)** (`Features/Shop`)
Lista de `Config.Rods`, preço, bônus (Controle/Sorte), prévia 3D, comprar/equipar via `BuyRod`/`EquipRod`, feedback com `ShopResult`. Abre ao interagir com a oficina (o Claude cria o `ProximityPrompt` no servidor com nome `OpenWorkshop`; escute `ProximityPromptService.PromptTriggered` no cliente filtrando por esse nome).

**C6 — Treino bonito** (`Features/Training`, cliente)
HUD do treino, câmera e poses melhores, efeitos ao subir de nível. Lógica do servidor é do Claude; o contrato está em `docs/COORDENACAO.md`.

**C7 — Animações do personagem** (procedurais)
Arremesso (puxa a vara pra trás e lança), tensão durante a luta (vara puxando, corpo inclinado), comemoração na revelação. IAs não sobem animação; faça por código (ver armadilha do ombro em §6) ou deixe ganchos documentados para o João criar `Animation` no Studio.

**C8 — Eventos do oceano (visual)**: lê `ReplicatedStorage` atributos `OceanEvent`/`OceanEventEndsAt`: tinta do céu/água, partículas, banner com contagem regressiva.

**C9 — Outros jogadores pescando**: lê atributos `FishingState`/`FishingTarget`/`FishingRarity` no `Character` dos outros e desenha linha + boia (+ brilho na luta).

**C10 — Configurações**: volume música/efeitos, "reduzir efeitos" (desliga tremidas/flash/partículas pesadas — essencial pra celular fraco e acessibilidade).

## 4. Direção visual

- Aventura Roblox estilizada 3D **premium**: cores vivas, cristais ciano/azul brilhantes, rosa/lilás, dourado, madeira quente, lanternas âmbar. Nada de UI cinza genérica.
- Raridades: Comum verde-água, Incomum azul, Raro roxo, Épico rosa, Lendário dourado (`Config.Fishing.RARITY_COLORS`).
- Escalada do extraordinário: comum é simples e rápido; lendário é espetáculo. Se tudo brilhar, nada brilha.
- Performance mobile: poucas partículas simultâneas, sem pós-processamento extra permanente, reaproveite instâncias.
- Acessibilidade: flash/tremida moderados e desligáveis (C10).

## 5. Como trabalhar

- Leia `docs/COORDENACAO.md` antes de cada tarefa; escreva no Mural ao começar e terminar.
- Ciclo: editar → `stylua <seus arquivos>` → `selene <seus arquivos>` → `rojo sourcemap -o sourcemap.json` → `luau-lsp analyze` (binário da extensão do VS Code; `--definitions=globalTypes.PluginSecurity.d.luau --base-luaurc=.luaurc`) → testar no Studio (lock `.studio-lock`) → commit **só dos seus arquivos**.
- `--!strict` em todo arquivo. Serviços no topo com `game:GetService`. `task.wait/spawn/delay` (nunca `wait()`). Conexões com dono e desconectadas. `Parent` por último. Textos de UI em `src/shared/StringsUi.luau`.
- MCP do Roblox Studio (se você tiver): `execute_luau`, `start_stop_play`, `screen_capture`, `get_console_output`. Studio aberto: place **Legendary Catch** (placeId 112666482424701).
- Testes no Studio sem clicar: dê Play, rode no **Server** `player:SetAttribute("DevForceRarity","Legendary")` / `DevForceMinigame` (`reel`, `precision`, `rhythm`), equipe a vara com `Humanoid:EquipTool`, e no **Client** `tool:Activate()`; force captura com `Remotes.SubmitCatch:FireServer(castId, true)` (castId vem do `FishingUpdate` "bite").

## 6. Armadilhas que já custaram caro (Roblox)

1. **Play logo depois de editar pega código velho** (Play clona o Edit). Confirme o sync antes.
2. **luau-lsp 1.70 perde union de string literal** (`"a" | "b"`): use `string` + comparação. Local refinado capturado em closure também quebra — leia por função.
3. **`require` pelo MCP (`execute_luau`) cria cópia nova do módulo**: estado do jogo não aparece.
4. **`screen_capture` não desenha `BillboardGui` com `AlwaysOnTop`**, e às vezes vem cinza se a janela do Studio estiver atrás de outra.
5. **`ScreenGui` nasce com `ZIndexBehavior = Global`** → use `Sibling`. Camadas entre ScreenGuis: `DisplayOrder` (a HUD de pesca usa 5).
6. **`UIStroke` não acompanha o texto**: texto esmaecendo deixa contorno; ajuste junto.
7. **Hover em tela de toque** fica preso (`MouseLeave` não dispara): ignore hover se `GetLastInputType()` for Touch.
8. **Imagem > 1024 px é reduzida no upload.**
9. **Ombro do avatar novo não é `Motor6D`** (é `AnimationConstraint`); escrever `Transform` em `PreSimulation` funciona.
10. **`PressInput` afunda toques** enquanto ativo (minigames): botões de UI não recebem toque nesse período.

## 7. Divisão de responsabilidades com o Claude

O Claude está fazendo agora: carregador de features, `Client/Data`, persistência do perfil, moedas e peso por captura, coleção, varas (loja no servidor), eventos do oceano, replicação do estado de pesca para outros jogadores, anti-trapaça. O plano dele está em `docs/PLANO-CLAUDE.md`. Se precisar de algo dele, peça no Mural.

# HUD: polida geral (prompt para o Antigravity/Gemini)

Escrito pelo Claude em 19/11/2026 a pedido do João. Prints do estado atual (Studio, Play, 1502x695) em `art/screens/hud-estado/`.

## Prints (o que há hoje)
| Arquivo | O que mostra |
|---|---|
| `01-spawn-camera-dentro-da-escada.jpg` | **Bug:** ao nascer a tela fica marrom borrada (câmera dentro da escadaria) |
| `02-hud-ociosa.jpg` | HUD parada: moedas, nível, menu, tutorial no meio, presente, slot da vara, botão Auto cinza |
| `03-menu-aberto.jpg` | Menu "Mais": 4 botões com arte e 3 chapados (Conquistas, Maré Nova, Placar) |
| `04-conquistas.jpg` | Conquistas: texto pequeno, um ícone vazio, faixa clara no topo sem escurecer |
| `05-prestigio.jpg` | Prestígio: título rosa-claro e microtextos ciano com contraste baixo |
| `06-placar.jpg` | Placar: layout simples demais, sem pódio/avatares visíveis no estado vazio |
| `07-ajustes.jpg` | Ajustes com códigos promocionais |
| `08-oficina-previa-vara.jpg` | Oficina: prévia da vara pequena e fina dentro de um quadrado azul grande |
| `09-colecao.jpg` | Coleção (referência de padrão bom) |

## Problemas encontrados (medidos e vistos)
1. **P0 Spawn/câmera:** ao entrar, a câmera padrão fica atrás do personagem em (-8,18,32) e fica **dentro da geometria da escadaria** (`Island.FrontStairs`, ocupa z 24..66): o jogador vê uma tela marrom borrada por vários segundos até andar. Corrigir (mover `PlayerSpawn`/ajustar a câmera de chegada/afastar a geometria) e garantir que a primeira imagem do jogo mostre a praça e a Oficina.
2. **Menu inconsistente:** Coleção, Oficina, Desafios e Ajustes têm arte pintada (1024x819); **Conquistas, Maré Nova e Placar** são cartões chapados com ícone minúsculo. Padronizar: gerar 3 artes novas no mesmo estilo cartoony candy (cada uma 1024x819, mesmo contorno grosso e brilho) e registrar em `Hud/Assets.luau` e `art/hud-v2/ASSET_IDS.md` (upload pelo MCP `upload_image` com URL http local, como em `ASSET_IDS.md`), ou refazer os 7 no mesmo estilo nativo.
3. **Faixa clara no topo das telas:** com um painel aberto, os 58 px do topo ficam sem desfoque/escurecimento (o overlay respeita o inset da barra do Roblox). Cobrir a tela inteira (`IgnoreGuiInset`/`ScreenInsets = None` no overlay).
4. **Texto pequeno e contraste baixo:** Conquistas usa fontes de ~11-12 px; Prestígio tem título rosa-claro e linhas ciano claras sobre creme (contraste < 3:1); "Bônus permanentes atuais" cinza. Mínimo 14 px nos painéis (16 em títulos de cartão), contraste >= 4,5:1 (texto escuro sobre creme, cores da arte só em detalhes). A conquista "Segredo das marés" (Mística) está **sem ícone**.
5. **Oficina:** prévia das varas novas (longas, ~9 studs) aparece fina e pequena. Ajustar a câmera do ViewportFrame pelo bounding box real, girar em diagonal, enquadrar a vara inteira ocupando ~70% da altura, fundo em gradiente suave (não azul chapado) e selo de raridade/estrelas bem visíveis.
6. **Excesso de coisas no 1o minuto:** tutorial largo no centro, presente, slot da vara e botão **Auto cinza (cadeado)** ocupando a base para quem não tem o passe. Esconder o Auto de quem não possui (ou mover para dentro do menu/Oficina), reduzir o cartão do tutorial e não cobrir a fachada da Oficina.
7. **Chip de nível:** só texto + barra fina; falta ícone e animação ao ganhar XP (use o padrão de Juice já existente).
8. **Placar (tela):** linhas com pódio (ouro/prata/bronze), avatar e destaque da própria linha já existem no código; no estado vazio mostrar um estado vazio bonito (ilustração/ícone) em vez de caixa bege.
9. **Consistência geral:** mesma família de fontes, espessura de contorno, sombra, cantos e cores de acento por tela; botões fechar iguais; áreas de toque >= 44 px.
10. **Outras telas não capturadas:** Desafios, Marcos, Treino (HUD de treino), banner de zona/evento/Natal, toasts, carta de revelação, auto-pesca. Revisar todas pelas mesmas regras.

## Prompt para mandar ao Gemini (cole no chat do Antigravity)

````text
Você é o agente de UI do jogo Legendary Catch (Roblox). Leia primeiro: AGENTS.md, README.md, docs/COORDENACAO.md (fim), docs/HUD-POLIDA-PROMPT.md (este documento; veja os prints em art/screens/hud-estado/) e docs/NOITE.md ("Decisão de estilo": Cartoony candy). PT-BR informal e curto com o João; código, nomes e commits em inglês. Studio: list_roblox_studios (o id muda), use o .studio-lock (10 min sem atualizar = expirado; segure no máximo 15 min por lote), save_place por lote com persistedToCloud=true, commits só dos seus arquivos, SEM push, Mural a cada entrega. O Studio deve estar maximizado e sem emulador (StudioDeviceSimulatorService:StopSimulationAsync()).

MISSÃO: arrumar e polir TODA a HUD e os painéis, resolvendo os 10 itens da lista acima, na ordem P0 -> 1 -> 10. O Codex está sem limite até 19/11 22:26; você assume a UI. Arquivos principais: src/client/Features/Hud/ (init, Panel, Art, Assets, Motion, RodHotbar, ZoneHud), Achievements, Prestige, Leaderboard, Shop, Collection, Missions, Settings, Tutorial, NextGoal, DailyGift, Training, Juice, Events, Portals; src/shared/UiTheme.luau e StringsUi.luau; arte em art/hud-v2 e art/reference/roblox-ui-kit.

REGRAS DE UI: (1) arte NUNCA esticada: containers com a proporção da imagem (veja constantes de proporção em Hud/init.luau e Hud/Art.luau; ScaleType.Fit como rede de segurança); (2) margens de ScrollingFrame em Position/Size (UIPadding não encolhe filhos em escala); (3) textos em StringsUi (PT/EN), nunca hardcoded; (4) cliente nunca decide moeda/captura; não edite src/server nem Config/Net/Types (peça no Mural); (5) respeite o atributo ReduceEffects do Player; (6) --!strict, stylua + selene com 0 erros; (7) ScreenGui com ZIndexBehavior Sibling.

COMO TESTAR: Play (start_stop_play), screen_capture com capture_id novo (se der timeout, tente de novo), user_mouse_input com moveTo + wait ~300 ms + mouseButtonClick (sem a pausa o clique não registra), e o gancho de Studio DevOpenPanel: no Client, game.Players.LocalPlayer:SetAttribute('DevOpenPanel','Shop') abre o painel pelo nome (Shop, Collection, Achievements, Prestige, Leaderboard, Missions, Settings, Milestones, Robux). Para pesca/revelação use DevForceRarity no servidor, equipe a Rod, tool:Activate() no cliente e SubmitCatch (a 1a captura do jogador é sempre Incomum/Puxar). Para tamanhos de celular use StudioDeviceSimulatorService (veja a skill rbx-device-simulator-lua do MCP: SetDeviceAsync antes de entrar em Play, retrato e paisagem, e volte com StopSimulationAsync).

ENTREGA: (a) todos os itens corrigidos; (b) prints antes/depois em art/screens/hud-polida/ (PC 1502x695, iPhone paisagem e retrato) e um README curto lá; (c) docs/HUD-POLIDA-RESULTADO.md com a lista item por item (feito / como / pendente); (d) Play sem erros do projeto no console; (e) place salvo. Termine com um resumo curto para o João.
````

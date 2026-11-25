---
tags: [legendary-catch, guia, completo]
atualizado: 2026-11-20
---

# Legendary Catch: guia completo do jogo (estado em 20/11/2026)

> Documento para o João (e para qualquer IA nova) entender **tudo** que existe no jogo hoje, quem fez, onde fica e o que falta.
> Fontes: vault Obsidian `roblox/novo jogo` (notas 00 a 09), repositório, Mural (`docs/COORDENACAO.md`) e as conversas deste projeto.
> Marcação de confiança: **[código]** = existe no repositório; **[testado]** = foi visto funcionando no Studio em Play; **[não testado]** = existe mas nunca foi visto em celular real, com 2 jogadores ou publicado.

## 1. O que é o jogo

**Legendary Catch** é um jogo Roblox de **pesca fantástica e coleção**.
- Você pesca de um píer numa **ilha mágica pequena**, num oceano enorme.
- Cada pesca tem um **minigame de habilidade**. Você **não sabe o que fisgou** até vencer.
- Quando vence, a criatura aparece numa **revelação cinematográfica** cada vez mais épica conforme a raridade.
- Começa com peixes comuns e escala até **monstros Místicos**. Há coleção, evolução de vara, treino, eventos, prestígio e placar.
- **Público:** inclui crianças. Mobile-first, também PC. Sem roubo nem competição obrigatória. Monetização justa, sem caixa aleatória paga.
- **Estilo visual:** "Cartoony candy": cores vivas, cristais ciano/azul, rosa/lilás, dourado, madeira quente, lanternas âmbar. Referência: `art/reference/island-approved.png`.
- **Lição do jogo anterior ("Pesque um Meme"):** escopo pequeno, lançar cedo, decidir por dado.

Identidade: place **112666482424701**, universe **10777276665**, repo público `github.com/joaovittorcc/Legendary-Catch`. Pasta local `C:\Users\Evojota\dev\jogo ainda sem nome`.

## 2. Como o jogo funciona (o loop)

1. O jogador fica na zona de pesca (caixa com tag `FishingZone`) e usa a vara.
2. O **servidor** valida zona e tempo e espera a mordida (2 a 5 s; na 1ª captura do jogador 2 a 3,5 s).
3. O servidor sorteia a criatura e **só envia a raridade e o tipo de minigame**.
4. O cliente joga o minigame. Se vence, avisa o servidor.
5. O servidor confere (tempo mínimo, 1 vitória por lance, limite entre capturas) e **paga**: sorteia peso, calcula valor, atualiza coleção, XP, combo e conquistas.
6. O cliente mostra a **revelação** da criatura (cara pra câmera, card 3D ao lado com descrição) com a intensidade da raridade.
7. Os outros jogadores veem a linha e a boia pelos atributos `FishingState/Target/Rarity` no personagem.

**Regra de ouro:** o servidor é a autoridade em moeda, item, captura e raridade. O cliente só mostra.

### Minigames (um por fisgada)
- **Puxar (barra):** segura para mover a zona; o peixe dentro enche o progresso, fora enche a barra vermelha.
- **Precisão:** 3 acertos pesca, 2 erros perde (luzes vermelhas, a primeira pisca).
- **Ritmo:** anel fecha no círculo; 2 erros perde.
- Dificuldade sobe com a raridade (a Mística tem um 6º nível mais difícil). Facilitam: treino de **Controle** e bônus da vara.
- A primeira captura do jogador é sempre **Incomum** com **Puxar** (tutorial suave).

## 3. Criaturas, raridades e conteúdo

### 6 raridades (peso base)
Comum 55 · Incomum 27 · Rara 12 · Épica 5 · Lendária 1 · **Mística 0,02** (cor carmesim). **Cintilante:** variante de qualquer criatura, 1 em 40, vale ×3.

### 106 criaturas [código]
- **Pool normal:** 21 Comuns, 20 Incomuns, 20 Raras, 16 Épicas, 15 Lendárias, 2 Místicas (**C93 Ouroboros Cósmico**, **C94 Maré Primordial**).
- **Exclusivas de evento** (peso ×3 só durante o evento): C95 Peixe-Vagalume Real, C96 Lua Dourada, C97 Raia Tempestade, C98 Coral Ancestral Vivo, C99 Baleia Fantasma, C100 Aurora Boreal Viva.
- **Natal** (1/dez a 6/jan): C101 a C106 (Rena-do-Mar … Rei do Gelo Natalino).
- Modelos 3D em `ReplicatedStorage.Creatures`, nomeados pelo id. Convenção: partes filhas diretas do Model (Body = PrimaryPart, Head, Tail, FinL/FinR, Fins, Wings, Tentacles, Legs, Claws, Shell, Extra), `Anchored`, sem colisão, **frente = +Z**, ~3 studs (lendárias/místicas até 3,6). Guia: `docs/CRIATURAS-NOVAS.md`.
- Animação por partes em `CreatureMotion`; auras por raridade em `CreatureAura`.
- Ainda **não foi feita uma revisão visual 3D** de todas as 106 (os novos modelos foram checados por medidas).

### 8 varas
Iniciante (0), Coral (500), Cristal (3.000), Tempestade (15.000), Astral (60.000), Celestial (150.000), Abismo (400.000), Mística (1.000.000). Todas com modelo 3D em `ServerStorage.RodModels`. **Achado de economia:** a vara muda pouco a renda; ela vale pela **sorte**.

### Zonas de pesca
Lagoa (nível 1), **Recife de Coral** (nível 5; Raro ×1,4, Épico ×1,3), **Abismo Estelar** (nível 15; Épico ×1,5, Lendária ×1,6, Mística ×1,3). O servidor bloqueia por nível (`levelLocked`). As zonas extras são **ilhas próprias acessadas por portais** (`ZonePortal`): Recife em (380,0,-220), Abismo em (-360,0,-280).

### Eventos do oceano (6)
Maré Estelar, Tempestade, Hora Dourada, Cardume Cintilante, Nevoeiro, Aurora. A cada 12 a 20 min, 2 a 3 min de duração. Tingem céu/água e dão bônus de raridade e valor; liberam as criaturas exclusivas.

## 4. Economia e progressão

- **Valor por captura:** base × (0,75 no peso mínimo a 1,25 no máximo). Comuns 10–15, Incomuns 36–48, Raras 110–170, Épicas 350–440, Lendárias 1.500–1.950, Místicas 9.000–10.000. Combo de capturas: +3% por captura (até +30%). Peixe gigante: +50% de XP.
- **Nível do jogador (Journey):** XP por captura (Comum 5 … Mística 200; descoberta nova ×2). XP do nível: 30 + 20·nível. A cada level-up: 25·nível moedas. Máx nível 100.
- **Baú surpresa** a cada 10 capturas (100–300 + 10·nível).
- **19 conquistas**, **códigos promocionais** (BEMVINDO 500, LENDARIO 1.500, PESCADOR 750), **sequência de 7 dias** de login com escudo, **desafios diários** (3 por dia, reset 00:00 UTC), **marcos da coleção** (5/10/15/20/24 espécies etc., com a regra de que o marco da raridade exige ≥1 criatura dela).
- **Treino semi-idle** na lagoa (Controle e Instinto, nível máx 25): peças com tag `TrainingSpot`, 1 XP/s, anel de ritmo a cada 10–18 s dá bônus, combo de anéis +10% por passo (até +50%).
- **Prestígio ("Maré Nova"):** exige 1.000.000 moedas e 60 espécies, máx 10 vezes. Zera moedas, varas e treino; mantém coleção, nível e conquistas. Por nível: +10% moedas, +4% sorte por raridade acima de Comum, presente de 25.000·P.
- **Auto-pesca (passe, id 0):** o servidor pesca sozinho (luta ×1,5, 85% de sucesso, teto Épica, não sobe o combo manual). **Falta rebalancear a economia com ela.**
- Simulação: `node tools/economy-sim.js`; relatório `docs/ECONOMIA-2026-11-18.md`. Números são **chute calibrado**, ajustar com dados reais (Analytics).

## 5. Mapa e mundo

**Ilha-hub:** lagoa de treino (esquerda), **Oficina de Varas** (terraço no fundo), praça com fogueira (centro), escadaria (frente), píer de pesca (direita), oceano com degradê e neblina. Gerada por `tools/IslandGenerator.luau`; **os meshes e modelos vivem no place, não no git** (sempre `save_place` depois de mexer).

**Entregues pelo Antigravity/Gemini:** ilhas de Coral e Abismo com **portais** (nível 5 e 15), **placar global flutuante** no oceano (hologramas à esquerda da lagoa de treino; substituiu o da praça), câmera de spawn corrigida (antes ficava dentro da escadaria), ciclo **dia/noite**, **Mundo Vivo** (fogueira com fagulhas, lanternas noturnas, gaivotas, peixes pulando, neve no Natal), pesca de outros jogadores visível.

**Tags que o código precisa:** `FishingZone` (+ `ZoneId`), `TrainingSpot`, `WorkshopSpot`, `LeaderboardBoard`, `ZonePortal`.

**Pendência de limpeza:** pastas `_SegWork1_*` soltas no Workspace (altura ~1000) e textos em inglês em placas físicas (conferir).

### NPCs (3) [código; só conversam]
| NPC | Papel | Onde |
|---|---|---|
| **Vô Anzol** (`GuideNPC`) | Guia/tutorial: boas-vindas, dicas e lendas (ex.: o Kraken depois da arrebentação) | entrada do píer |
| **Lucy** (`NPC_BaitVendor`, antes "Marina") | Vendedora de iscas, dicas de Sorte e eventos | no píer |
| **Luna** (`NPC_ShellGirl`) | Lore/coleção, conchas, hora dourada, cristais à noite | beira-mar, ao pé da escadaria |
Respiram, viram a cabeça pro jogador e falam em rodízio (PT/EN). Fichas e arte conceitual em `docs/npcs/` e `art/npcs/`. **O nome "Marina" ainda está no código** (`Strings.npcLines`); trocar por Lucy.

## 6. Interface (HUD) e telas

Dona: Codex (antes) e depois Claude/Gemini nas polidas. Arte em `art/hud-v2` (menu candy, ícones, nível) e `src/client/Features/Hud/*`.
- **HUD:** moedas, nível com barra de XP, menu "Mais", próximo objetivo, presente diário, slot da vara. **Na pesca só moedas e nível ficam** (tela limpa).
- **Painéis:** Coleção/Bestiário, Oficina (prévia 3D da vara), Conquistas, Prestígio, Placar, Ajustes (volume, reduzir efeitos, códigos), Desafios, Marcos, Treino.
- **Regras de UI:** arte nunca esticada (containers com a proporção da imagem), textos sempre em `StringsUi` (PT/EN), áreas de toque ≥ 44 px, respeitar `ReduceEffects`.
- **Revelação:** a criatura aparece **de frente** (cara visível), tempo maior pra ver, **card 3D à esquerda** com nome, raridade, peso, valor e descrição; selo NOVA DESCOBERTA. Lendária/Mística: **cinemática de portal** (raios, tela escurece, fenda/portal, criatura emerge) por criatura; as 4 primeiras já foram feitas.
- Animação do personagem por código (**CharacterMotion**): arremesso, tensão na luta e comemoração.
- **Áudio:** 14 sons em `ReplicatedStorage.Audio`.

## 7. Arquitetura técnica

```
src/server/   -> ServerScriptService.Server   (Features/*, Remotes.luau)
src/client/   -> StarterPlayerScripts.Client  (Data/, Features/*)
src/shared/   -> ReplicatedStorage.Shared     (Config/, Net, Types, Strings, StringsUi, UiTheme)
tools/        -> ServerStorage.DevTools       (geradores rodados pelo MCP em Edit)
ServerPackages/ (Wally) -> ProfileStore
```
- **Features carregam sozinhas** por pasta (`init.luau` com `start()` e `order`).
- **Remotes** criados pelo servidor, com limite de chamadas por jogador (`Remotes.onServerEvent`).
- **Perfil** (ProfileStore): moedas, varas, coleção, treino, stats, conquistas, resgates, prestígio, sequência; campos aditivos com `reconcileProfile`. Studio usa a store `PlayerData_Studio`.
- **Servidor:** Fishing, Journey (nível), Achievements, Leaderboard (OrderedDataStore), Inspect (álbum de outro jogador), AutoFish, Zones/Portals, Prestige, Seasons (Natal), DayNight, Training, Rod, OceanEvents, Progress (tutorial/desafios/marcos/ajustes), Monetization, Social (leaderstats e anúncios), Analytics, Audio.
- **Anti-trapaça:** 1 vitória por lance, tempo mínimo por minigame e entre capturas, contador de suspeitos. **O resultado do minigame ainda vem do cliente: precisa de defesa mais forte.**
- **Ferramentas:** Rojo 7.7.0 (portas 34873/34872), Rokit, Wally, StyLua, Selene, luau-lsp. Mudou `default.project.json`: reinicie o Rojo.
- **Atributos Dev (só Studio):** `DevForceRarity`, `DevForceMinigame`, `DevGrantCoins`, `DevStartEvent`, `DevSeason`, `DevAutoFish`, `DevGrantLevel`, `DevOpenPanel`. **Desligar no lançamento** (`docs/PUBLICAR.md`).

## 8. Monetização
VIP (+25% moedas), boost de sorte 15 min, pacotes de moedas e passe de auto-pesca. **Todos os IDs ainda são 0** (`Config/Products.luau`); a UI esconde a compra. `ProcessReceipt` idempotente, salva antes de confirmar. Sem caixa aleatória paga.

## 9. Como o time funciona

- **João** decide e testa. **Claude** (coordenador): sistemas, servidor, configs, revisão. **Codex:** UI, revelações, minigames, QA. **Antigravity/Gemini:** mapa, 3D, criaturas, VFX, HUD polish. Mural em `docs/COORDENACAO.md` (agentes leem a cada ~10 min); `.studio-lock` (10 min sem atualizar = expirado); `save_place` por lote.
- **Modo atual:** o Claude está em **modo só-prompt** (gera prompts para Codex/Gemini) por causa do limite de uso, até o João dizer que voltou ao normal.
- **Vault `fwjelaa`** (CC BY 4.0, creditar fwjelaa/FWJ STUDIOS) é a base de VFX/UI/animação. Pacotes: Animations, art-pipeline (Blender), Picture-to-Model, Maps, UI-Icon-Pack (só Rank e Keys são CC0 comprovados).

## 10. Em andamento agora

- **Piloto de cutscene em vídeo para Místicas (C93):** vídeo **abstrato** (sem personagem/ilha), tela cheia, crossfade para a revelação ao vivo e fallback por código. O Codex grava a pesca atual e exporta o modelo (`art/video-ref/c93/`); o Gemini (Veo) gera o vídeo; depois vem o sistema `VideoCutscene` (preload, crossfade, fallback, pular). **Conferir limites de upload de vídeo no Creator Hub antes de investir.**
- Melhorar as cinemáticas lendárias/místicas com o método do vault fwjelaa (prompt pronto).
- QA visual do placar flutuante e da HUD polida.

## 11. O que falta e o que nunca foi testado

**Só o João:** ativar API Access do Studio (Game Settings > Security), criar produtos/passes Robux, nome/ícone/thumbnails/descrição da página, testar **no celular real e com 2 jogadores**, desligar os `Dev*` no lançamento.

**Claude (quando voltar ao normal):** trocar "Marina" por "Lucy" no código, rebalancear a economia com auto-pesca, reforçar o anti-cheat do minigame, eventos semanais, oferta/pacote inicial (depende de IDs).

**Nunca testado:** celular real (FPS), 2+ jogadores, jogo publicado, save real (a API do Studio estava desligada), compras reais.

## 12. Onde achar tudo
- Visão: `CONTEXTO_MESTRE.md`. Contrato e Mural: `docs/COORDENACAO.md`. Agentes: `AGENTS.md`. Mapa: `MAPA.md`. Publicar: `docs/PUBLICAR.md`. Economia: `docs/ECONOMIA-2026-11-18.md`. Criaturas: `docs/CRIATURAS-NOVAS.md`. Estilo: `docs/NOITE.md`. Prints: `art/screens/*`. NPCs: `docs/npcs/`.
- **Vault Obsidian exclusivo do jogo:** `C:\Users\Evojota\Documents\Obsidian\roblox` (pasta `novo jogo`, notas 00 a 10). O vault `fwjelaa` é separado (conhecimento de Roblox, não do jogo).

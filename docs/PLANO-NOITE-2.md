# Plano da noite (01:00-07:00) - Legendary Catch

Pedido do Joao (18/11, 00:20): revisao completa + noite toda de trabalho. Claude coordena, Codex faz UI/visual,
Antigravity faz modelos/mapa. Foco: **dopamina e retencao** (a pessoa quer ficar horas jogando).

## Revisao (o que achei)
- **Minigames:** `Ui.showPanel` cria um painel ciano enorme (0.86 x 0.42 da tela) no meio da tela; no Ritmo so aparece um circulo
  dentro dele ("2", contador 1/3). Feio e tapa o mar. Reel/Precision usam o mesmo painel.
- **Treino:** so uma faixa de HUD + orbita de camera + um anel de ritmo a cada 10-18 s. Falta numero subindo, combo, level-up com impacto.
- **Loja/Oficina:** painel arrumado hoje (proporcoes, margens), mas o Joao viu "uma pedra dentro dela": investigar a UI (previa da vara)
  E a loja fisica (modelo da oficina no mapa).
- **Criaturas:** 64 no jogo; faltam raridade acima de Lendaria (Mistica) e mais variedade. Aura/animacao ok nas Epicas/Lendarias.
- **Pendencias de produto (Joao):** ids de produtos Robux (`Products.luau` com TODO id=0), API do Studio desligada (DataStore), icone/thumbnail,
  teste real no celular, 2 jogadores, nome do jogo.
- **Codigo:** 0 TODO fora Products; Selene/luau-lsp do Codex nao rodam (API dump); StyLua ok. Revisar remotes (rate limit) e anti-trapaca antes de publicar.

## Regras da noite
1. **Studio e um so.** `.studio-lock` vale 10 min sem atualizar. Cada lote de Antigravity segura o lock no maximo 15 min e libera 10 min
   (janela do Codex pra Play). Anunciar no Mural.
2. `save_place` a cada lote + confirmar `persistedToCloud=true`. Commit so dos proprios arquivos. **Sem push** (so o Joao pede).
3. Nada de `src/server`, `Config`, `Net`, `Types`, `Strings` pro Codex (pedir no Mural ao Claude). Antigravity so mexe em modelos/mapa/prints.
4. Se o Codex bater limite (5 h): Claude le o Mural, ve onde parou e abre um agente novo no Antigravity pra continuar a UI.
5. Cada item: anotar no Mural ao comecar/terminar.

## 50 itens

### A. Minigames (Codex) - prioridade 1
1. **Ritmo:** apagar o painel ciano; so aros/circulos numerados na tela inteira, contador pequeno no topo, barra de combo.
2. **Precisao:** apagar o painel; barra horizontal fina e bonita perto do fundo, zona alvo brilhante, marcador com rastro.
3. **Puxar (Reel):** apagar o painel; barra vertical lateral estilo Stardew, peixe icone, barra de progresso redonda.
4. Feedback unificado: "PERFEITO!", "BOM!", combo x2/x3, cor pela raridade, particulas nos acertos, tremida sutil nos erros.
5. Transicao: minigame entra com bounce, sai com flash curto; Reduzir efeitos respeitado.
6. Tutorial dos minigames: 1 tela curta por tipo, so na 1a vez, com opcao de pular.
7. Sons por acerto/erro/combo (Audio existente; Antigravity gera/acha sons se faltar).
8. Mobile: alvos >= 56 px, nada embaixo do polegar, testar retrato e paisagem.

### B. Treino (Codex UI + Claude servidor)
9. Numeros de XP subindo (+1, +1...) flutuando com cor da stat; contador grande de nivel.
10. Combo de treino: aneis de ritmo mais frequentes e com sequencia; combo multiplica XP (servidor: Claude).
11. Barra de XP com brilho e "ding" a cada nivel; level-up = explosao de particulas + faixa "NIVEL 7!".
12. Marcos de treino (nivel 5/10/15/20/25) com recompensa e selo; titulos ("Pescador Aprendiz"...).
13. Camera do treino mais dinamica (orbita + zoom nos aneis) e personagem com poses variadas.
14. Aura do jogador crescente conforme o nivel (visual).
15. Treino diario: bonus de XP no 1o treino do dia (servidor: Claude).

### C. Nova raridade Mistica + 30 criaturas (Claude plumbing, Antigravity modelos, Codex UI)
16. **Claude:** raridade `Mystic` (rank 6) em Config (ordem, cores, odds ~1 em 20.000, tier de minigame, luck), Strings, Milestones, Missions.
17. **Codex:** arte `raridade-mistico.png` + cor/gradiente iridescente em `UiTheme`, categoria Mistica na Colecao e no HUD de raridade.
18. **Codex:** carta de revelacao Mistica (cosmica, 8-10 s, pulavel depois da 1a vez) + aviso global "Alguem pescou um MISTICO".
19. **Claude:** aura/Omen maximos pra Mistica (CreatureAura + Omen.luau).
20-24. **Antigravity (lendarias, 5):** C88 Rei Tritao Colossal, C89 Dragao de Jade, C90 Tartaruga-Mundo, C91 Hipocampo Imperial, C92 Serafim do Mar.
25-26. **Antigravity (misticas, 2):** C93 Ouroboros Cosmico (serpente-galaxia), C94 Mare Primordial (entidade de agua e estrelas).
27-31. **Antigravity (epicas, 6):** C82 Kitsune Aquatica de 9 caudas, C83 Golfinho Trovao, C84 Martelo de Cristal, C85 Lula Galaxia, C86 Cervo-Coral, C87 Salamandra de Lava.
32-38. **Antigravity (raras, 7):** C75 Leao-Marinho Dourado, C76 Raia Aurora, C77 Cavalo-Marinho Relogio, C78 Lagosta Armadura, C79 Mantarraia Vitral, C80 Peixe-Pavao Eletrico, C81 Enguia Fita-de-Seda.
39-43. **Antigravity (incomuns, 5):** C70 Agua-viva Lanterna, C71 Peixe-Espada Neon, C72 Tartaruga Pergaminho, C73 Polvo Origami, C74 Baiacu Balao de Festa.
44-48. **Antigravity (comuns, 5):** C65 Tilapia Moranguinho, C66 Ourico Pompom, C67 Lesma-do-Mar Arco-iris, C68 Peixe-Biscoito, C69 Ermitao Xicara.
   Todas com partes por membro (convencao do jogo), +Z, `save_place` a cada 3-5, prints em `art/creatures/`. Claude libera no jogo (LIST) apos conferir.

### D. Loja, mapa e polimento
49. **Loja:** achar a "pedra dentro" (UI e loja fisica), limpar; **Antigravity:** conferir o modelo da oficina no mapa (objeto dentro/atravessando).
50. **Codex:** previa 3D da vara maior com rotacao, selo de raridade da vara, estados (equipada/comprar/sem moedas) claros.

### E. Extras de retencao (se sobrar tempo; Claude decide e delega)
- Sequencia diaria de login com recompensa crescente (servidor Claude + UI Codex).
- Album de fotos (PhotoMode ja existe): galeria das capturas com selo.
- Eventos do oceano com visual proprio (Codex) e criatura exclusiva por evento.
- Ranking local de maior peso por especie (leaderboard simples).
- Missao semanal + "bau" de recompensa; conquistas (50 icones simples).
- Musica ambiente por zona + stinger por raridade; som de level-up.
- Animacoes: personagem comemora na captura, vara com tensao, gaivotas/peixes saltando no mar (Antigravity mapa).
- Seguranca: revisar rate limit dos remotes, validar tudo no servidor, teste de 2 jogadores (Joao).

## Cronograma
- **01:00-02:30** Codex: A (minigames) + loja; Antigravity-1: C88-C92 (lendarias); Antigravity-2: C93-C94 + C82-C87; Claude: item 16 (plumbing Mistica).
- **02:30-04:00** Codex: B (treino) + Mistica UI (17-18); Antigravity-1: raras; Antigravity-2: incomuns/comuns; Claude: 10, 15, 19.
- **04:00-05:30** Claude libera criaturas no LIST e testa no Play (janela); Codex: polimento + mobile; Antigravity: mapa/oficina (49) + prints.
- **05:30-07:00** QA geral, mural, resumo da manha em `docs/RESUMO-MANHA.md` e Obsidian.

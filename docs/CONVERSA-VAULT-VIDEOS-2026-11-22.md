# Resumo da conversa: vault fwjelaa, vídeos e pilotos (22/11/2026)

Registro do que foi dito e decidido. Detalhes técnicos em `docs/APRENDIZADOS-VAULT-VIDEOS.md`
e `docs/SFX-PILOTO.md`. Regra do dia: **só João e Claude** trabalham (sem Codex); o modo só-prompt está desligado.

## 1. Estudo do vault fwjelaa (`Downloads\fwjelaa-vault-0.1.0`)
- Plugin Claude Code + notas Obsidian de Roblox, por fwjelaa (FWJ STUDIOS), v0.1.0, licença **CC BY 4.0** (creditar).
- ~1.400 notas reais em 60+ pastas (o resto são cartões de API e ~1.700 imagens de referência).
- 25 skills (`fwjelaa-vfx`, `fwjelaa-ui`, `fwjelaa-sfx`, `make-anim`, `quality-score`, segurança, DataStore...),
  9 agents, 7 commands e um hook que checa o Luau escrito. Busca por `_tools/vault.py`.
- Notas mais úteis pro jogo: `47 Game Feel and Juice` (Reward Moments and Celebrations, Juice on a Budget),
  `07 ... VFX` (Escalation and Grandeur Without Clutter), `21 UI Design System`/UI Spec, case do Fisch.
- Lições principais: cada tier de raridade ADICIONA camadas; o canal "mundo escurece e HUD some" fica pros 2 tiers do topo;
  grandeza = poucas camadas escaladas (o limite é a silhueta, não a contagem de partículas); o servidor decide antes da animação;
  orçamento de animação de recompensa abaixo de ~10% do tempo de jogo.

## 2. Vídeos e posts analisados
Só vi quadros (sem áudio). Nenhum era referência de VFX.
- **AI Slop Test** (@momentumcash): agente de IA avalia o jogo e acusa arte genérica/inconsistente.
- **Top 5 plugins** (@offlinedevv): Redupe, Gap Fill, F3X, Archimedes, Forge GUI. *Ignorado de propósito (mapa/construção).*
- **Figma → Roblox** (@phoxik.dev): plugin Framewisp.
- **Map skill Claude/Blender** (@lihfolk): mesmo conceito do `make-map` do fwjelaa. *Ignorado (mapa).*
- Posts @zvnns (SFXMint, Blender, Meshy AI, Figma) e @waspes.com (escada de níveis: vault + Opus, Figma + IA, combinar tudo).

## 3. Código conferido (nenhum bug novo)
- **V3 botão com atraso 0,3 s:** não se aplica (o card fecha sozinho; só há Pular e Foto).
- **V4 som sincronizado com o flash:** já ok (`legendary` toca no início; `Audio.capture` toca quando o card abre).
- **V8 flash seguro:** já ok (máx. 3/s, desligado com `ReduceEffects`).
- **V1 tempo dos cards de revelação** (Comum 2,2 s ... Mística 6,6 s; cinemática Mística ~16 s):
  mais longo que o vault recomenda. **Decisão do João: manter.**

## 4. Pilotos
- **Framewisp: descartado para a HUD.** Gera UI em `StarterGui` (fora do Rojo/git); nossa UI é por código;
  `Motion.luau` e `Panel.button` já têm hover, press, brilho e `ReduceEffects`. Efeitos avançados são Pro.
- **Auditoria mobile:** código já bem disciplinado (limites de partículas, `Debris`, corte por distância,
  throttle, viewports só os visíveis). **Mudança feita:** sem `BlurEffect` nos painéis em aparelho só-toque
  (`Hud/Panel.luau`). Pendências: reset por frame no `LeaderboardBoard`; `ReduceEffects` só manual; custo real
  de ripple/pillar/cinemática Mística não medido (precisa de celular real).
- **SFXMint (CC0, ~11.800 sons):** download exige conta grátis com chave (3/dia); busca é livre.
  Lista de 7 candidatos (riser, impacto, trovão, respingo, whoosh, carretilha, chime de "PERFEITO") em `docs/SFX-PILOTO.md`.
  Depende do João: ouvir, criar conta, baixar e subir no Roblox (conta/grupo dono do jogo); depois Claude liga os ids.

## 5. Commits desta conversa
- `969ec0a` perf(hud): skip panel blur on touch-only devices; add vault/video learnings doc
- `e55e859` docs(audio): add SFXMint pilot shortlist and upload steps
- Este resumo: ainda **não commitado**. Não houve push.
- A árvore continua com ~30 itens de outro trabalho (aquário, cinemáticas, minigames, arte), fora destes commits.

## 6. Pendências e próximos passos
1. João: ouvir os 7 sons, criar conta SFXMint, baixar, subir no Roblox e passar os asset ids.
2. Claude: ligar os ids no `Audio/init.luau` e nos ganchos (Reveal, Effects, Reel, Ui) e registrar o manifesto em `docs/AUDIO.md`.
3. Checklist anti-"slop" de arte (paleta, raio, stroke, fonte, escala) antes de cada lote de criaturas/UI.
4. Teste em celular real (MicroProfiler) para ripple, pillar e cinemáticas Místicas.
5. Decidir `ReduceEffects` automático em aparelho fraco.
6. Regra de design (Fisch): ao criar novas zonas, nunca resetar moeda/progresso do jogador.
7. Manter crédito ao fwjelaa em `docs/CREDITOS-VFX.md`.

Não testado: Studio (Play), celular real, 2+ jogadores, jogo publicado, upload de áudio no Roblox.

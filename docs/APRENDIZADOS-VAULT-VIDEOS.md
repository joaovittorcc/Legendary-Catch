# Aprendizados: vault fwjelaa + vídeos/posts (22/11/2026)

Fontes: vault fwjelaa 0.1.0 (CC BY 4.0, creditar), 4 vídeos de TikTok (AI Slop Test,
Top 5 plugins, Figma→Roblox/Framewisp, map skill) e 2 carrosséis (@zvnns, @waspes.com).
Ignorado de propósito: Forge GUI / plugins de construção / map builder (mapa não é nossa frente).
Só vi quadros dos vídeos, sem áudio.

## 1. Vault → o que o código já faz e o que falta

Já temos: skip após primeira vez (`FIRST_MYSTIC_SKIP`), `ReduceEffects`, escada por raridade,
servidor decide antes da animação. Não refazer.

Lacunas (vault `Reward Moments and Celebrations`, `Escalation and Grandeur`, `Juice on a Budget`):

| # | Vault diz | Nosso código | Ação |
|---|---|---|---|
| V1 | Comum 0,3–0,5 s; orçamento de recompensa < ~10% do tempo de jogo | `Reveal.luau` STYLES hold: Common 2.2 s, Uncommon 3.2, Rare 3.8, Epic 4.5, Legendary 5.5, Mystic 6.6 (+ voo) | **Decidido 22/11 (João): manter os tempos atuais.** Não encurtar |
| V2 | Top 1–2 tiers 5–6 s | Místicas `Recipes.luau` duration 16.4–16.9 s | Manter (evento raro, pulável) mas confirmar que o skip da 1ª vez funciona e que o orçamento fecha (V1) |
| V3 | Botão primário só ativa após ~0,3 s (evita toque duplo) | Card fecha sozinho; só há Pular e Foto (sem botão de confirmar) | **Não se aplica** (verificado 22/11) |
| V4 | Pico do som cai no frame do flash; riser antes | `legendary` toca no início (riser) e `Audio.capture` (stinger por raridade) toca quando o card abre | **Já ok** (verificado 22/11) |
| V5 | Cada tier ADICIONA camadas; canal "mundo escurece + HUD some" só nos 2 tiers do topo | Legendary já escurece o mundo; Mística também | Decidir: Legendary escurece mas mantém HUD? Reservar "HUD some" só pra Mística |
| V6 | Grandeza = poucas camadas escaladas, um elemento crescente só; tela/silhueta é o limite, não partículas | — | Regra de revisão pros prompts do Codex (checar silhueta da criatura a cada camada) |
| V7 | Governor de partículas + pool, glow grande é o que mata celular | `Effects.luau` | Auditar: glows full-screen, instâncias criadas/destruídas por efeito, teto de partículas mobile |
| V8 | Flash curto e seguro | `Effects.flash`: máx. 3 por segundo, some com `ReduceEffects` | **Já ok** (verificado 22/11) |
| V9 | `UIScale` pop em vez de tween de `Size`; alvo de toque 52 un.; contraste dos tokens do UI Spec | `UiTheme.luau` | Comparar paleta/contraste com `fwjelaa UI Spec` (não trocar identidade ciano/rosa/dourado, só validar) |
| V10 | Fisch: 1ª captura < 1 min, coleção finita por zona, não resetar progresso em expansão | Zonas por nível | Guardar como regra de design para Abismo/novas zonas (não resetar moeda/progresso) |

## 2. Ferramentas dos vídeos/posts → decisão

| Item | Para quê | Decisão |
|---|---|---|
| **Framewisp** (Figma→Roblox) | UI com hover/press sem tween manual | **Descartado p/ a HUD (22/11).** Gera instâncias em `StarterGui` + LocalScripts, fora do Rojo/git; nossa UI é toda por código e ligada a `Net`/`Data`. `Hud/Motion.luau` já faz hover (1,045), press, sway, shine e respeita `ReduceEffects`; `Panel.button` já tem lábio/brilho. Tags de efeito, vários descritos em framewisp.com/docs, são Pro (7 dias grátis, depois 15 conversões/dia grátis). Só vale pra arte estática (banner, ícone de recompensa) se um dia precisar |
| **Meshy AI** (texto/foto → 3D) | Rascunho de criaturas | Pausa: já temos pipeline Blender + Antigravity. Só pra props/ícones se sobrar tempo; custo e licença a confirmar |
| **SFXMint** (gera/busca SFX) | Sons de revelação, minigame, UI | Piloto: conjunto de SFX por raridade. Checar licença e regra de upload de áudio do Roblox (nota `Music Licensing and Audio Upload Rules for 2026`) |
| **Blender + Claude** | Já usamos (MCP no Antigravity/Codex) | Nada novo |
| **Figma + Claude** (nota vault `Figma to Roblox UI - Pipeline and Handoff`) | UI correta com tokens | Ligar ao piloto Framewisp: tokens do Figma = `UiTheme` |
| **"AI Slop Test"** | Agente avalia o jogo e acusa arte genérica/inconsistente | Criar checklist de consistência + painel de revisão (skill `quality-score` do vault): paleta, raio, stroke, fonte, escala de criatura |
| Escada "Obsidian + Opus + Figma" (@waspes) | Nosso fluxo já é esse | Nada novo |

## 3. Ordem sugerida (só prompts/doc; código visual é do Codex)

1. ~~V3/V4/V8~~ já ok. ~~V1~~ mantido pelo João. (Sem Codex: João e Claude trabalham juntos.)
3. Piloto **Framewisp** em 1 botão + validar com UI Spec (V9).
4. Piloto **SFXMint** (SFX por raridade) — decidir antes: licença/custo.
5. Checklist **AI Slop** + `quality-score` antes de cada lote de arte.
6. Auditoria de performance mobile (V7).

Crédito obrigatório: fwjelaa (FWJ STUDIOS), CC BY 4.0 → manter `docs/CREDITOS-VFX.md`.

## 4. Auditoria mobile (22/11/2026, só leitura de código; nada medido em celular)

Já bom: `Effects.splash` limita rajadas (3, ou 1 reduzido) e partículas (22 + 8); tudo usa `Debris`;
flash ≤ 3/s; `ReduceEffects` respeitado em Effects, Motion, Portals, Trophy, LeaderboardBoard, Aquário;
loops com corte por distância ou visibilidade (Portals 130 studs, Trophy 190, Others 160, Aquário 30 fps e só na tela);
taxas de partícula contínua baixas (2–9/s); viewports da Coleção/Placar só os visíveis (`refreshVisibleViewports`).

Mudado: `Hud/Panel.luau` não cria mais o `BlurEffect` (tamanho 9) em aparelho só-toque; o fundo escurecido continua.

Pendências (não mudei):
- `LeaderboardBoard` roda `resetBoardUnits` todo frame quando `ReduceEffects` está ligado (desperdício pequeno).
- `ReduceEffects` só liga manualmente (Ajustes). Considerar padrão ligado em aparelho fraco ou nota na primeira abertura.
- Não medido: custo real de `Ripple` (3 partes Neon por chamada), `pillar` com `PointLight` (alcance 30) e cinemáticas Místicas (16 s) em celular de entrada. Precisa de teste no celular real (MicroProfiler).

# Relatório de Revisão Final — Agente 1 (Interface, Textos e Celular)

Data de início: 2026-11-26  
Place: `112666482424701` (Legendary Catch)  
Escopo: HUD, painéis, telas de pesca, treino (UI), Poder sobre a cabeça, tutorial/guia, placares do mundo, textos (PT/EN), celular e acessibilidade.

---

## 1. Inventário Completo

| # | Área / Item | Arquivos principais | Testado como | Resultado |
|---|---|---|---|---|
| 1 | **HUD Principal** (moedas, nível/XP, barra da vara, menu hambúrguer, toasts, indicador de zona) | `Hud/init.luau`, `Hud/RodHotbar.luau`, `Hud/ZoneHud.luau`, `Hud/Art.luau`, `Hud/Assets.luau`, `Hud/Motion.luau`, `Hud/Panel.luau` | Pendente | `pendente` |
| 2 | **Próxima Meta (`NextGoal`)** | `NextGoal/init.luau` | Pendente | `pendente` |
| 3 | **Banners de Evento + Estação** | `Events/init.luau` | Pendente | `pendente` |
| 4 | **Anúncio de Captura Rara (`Announcements`)** | `Announcements/init.luau` | Pendente | `pendente` |
| 5 | **Juice (moedas voando, combo)** | `Juice/init.luau` | Pendente | `pendente` |
| 6 | **Coleção / Bestiário + Marcos** | `Collection/init.luau` | Pendente | `pendente` |
| 7 | **Aquário (inteiro — arte nova nunca conferida)** | `Collection/Aquarium.luau`, `AquariumCandy.luau`, `AquariumIncome.luau`, `AquariumProgression.luau`, `AquariumTank.luau`, `AquariumView.luau`, `AquariumWorld.luau` | Pendente | `pendente` |
| 8 | **Oficina (varas + rolagem + prévia 3D)** | `Shop/init.luau` | Pendente | `pendente` |
| 9 | **Loja de Robux + Oferta Inicial** | `Shop/Robux.luau`, `Shop/StarterOffer.luau` | Pendente | `pendente` |
| 10 | **Desafios Diários (`Missions`)** | `Missions/init.luau` | Pendente | `pendente` |
| 11 | **Conquistas (`Achievements`)** | `Achievements/init.luau` | Pendente | `pendente` |
| 12 | **Maré Nova / Prestígio (`Prestige`)** | `Prestige/init.luau` | Pendente | `pendente` |
| 13 | **Placar (`Leaderboard` UI)** | `Leaderboard/init.luau` | Pendente | `pendente` |
| 14 | **Placares do Mundo (`LeaderboardBoard`)** | `LeaderboardBoard/init.luau` | Pendente | `pendente` |
| 15 | **Ajustes (`Settings`)** | `Settings/init.luau` | Pendente | `pendente` |
| 16 | **Presente Diário (`DailyGift` dias 1–7+, escudo, baú — arte nova nunca conferida)** | `DailyGift/init.luau` | Pendente | `pendente` |
| 17 | **Telas de Pesca — Mira e Barra de Força** | `Fishing/PowerBar.luau`, `Fishing/Ui.luau`, `Fishing/Control.luau`, `Fishing/PressInput.luau` | Pendente | `pendente` |
| 18 | **Telas de Pesca — Minigame `Reel` + `ReelLesson` + feedback** | `Fishing/Minigames/Reel.luau`, `ReelLesson.luau`, `Input.luau`, `Precision.luau`, `Rhythm.luau`, `Fishing/Ui.luau` | Pendente | `pendente` |
| 19 | **Telas de Pesca — "1 em N" (`OddsMoment`)** | `Fishing/OddsMoment.luau` | Pendente | `pendente` |
| 20 | **Telas de Pesca — Roleta (`Roulette` — todas as rodas, arte nova nunca conferida)** | `Fishing/Roulette.luau` | Pendente | `pendente` |
| 21 | **Telas de Pesca — Cartão de Revelação (`RevealCard` — 6 raridades, arte nova nunca conferida)** | `Fishing/RevealCard.luau`, `Fishing/CatchShow.luau` | Pendente | `pendente` |
| 22 | **Telas de Pesca — Pular Revelação, Modo Foto, Auto-Pesca** | `Fishing/PhotoMode.luau`, `Fishing/CatchShow.luau`, `Fishing/Ui.luau`, `Hud/init.luau` | Pendente | `pendente` |
| 23 | **Treino (2 lagoas, desafios, combo, compra de campo, bônus diário, parar ao andar)** | `Training/init.luau`, `Drill.luau`, `Power.luau`, `Practice.luau` | Pendente | `pendente` |
| 24 | **Poder de Pesca sobre a Cabeça (`OverheadPower` — nunca testado em treino/morte/revelação/outros)** | `OverheadPower.luau` | Pendente | `pendente` |
| 25 | **Tutorial e Guia (Vô Anzol — novo balão em PT e EN, seta, pular, fluxo completo)** | `Tutorial/init.luau`, `Guide/init.luau` | Pendente | `pendente` |
| 26 | **Arte Nova & Tema (`UiAssets`, `UiTheme`, 9-slice, estados de botão, ícones)** | `src/shared/Ui/UiAssets.luau`, `src/shared/UiTheme.luau`, `art/ui-generated/` | Pendente | `pendente` |
| 27 | **Textos e Localização (PT-BR e EN-US, paridade, contradições, hardcoded)** | `src/shared/Strings.luau`, `src/shared/StringsUi.luau`, toda UI | Pendente | `pendente` |
| 28 | **Celular (3 aparelhos, paisagem/retrato, ≥44 px, notch/safe area, hover touch, `ReduceEffects`, gamepad)** | Todos os painéis + HUD + pesca + treino | Pendente | `pendente` |
| 29 | **Limpeza (`Collection/AquariumPreview.luau`)** | `src/client/Features/Collection/AquariumPreview.luau` | Verificado grep em `src/` e `tools/` — ninguém importa; chama `Progression.mount` com 6 de 9 args | `pendente` (aguarda decisão do João para apagar) |

---

## 2. Bugs Encontrados e Correções

*(Será preenchido durante a auditoria estática e os testes no Studio Play.)*

| ID | Sev. | Área / Arquivo | Causa | Correção | Commit | Prova do reteste |
|---|---|---|---|---|---|---|

---

## 3. Pedidos Enviados / Recebidos (`docs/revisao/PEDIDOS.md`)

- *(Nenhum ainda.)*

---

## 4. Pendências que Dependem do João

1. **`src/client/Features/Collection/AquariumPreview.luau`:** confirmado via busca em todo `src/` e `tools/` que nenhum arquivo importa esse módulo (é uma fixture antiga de Studio fora do git, e é o único erro atual no `luau-lsp analyze` porque chama `Progression.mount` com 6 de 9 argumentos). **Posso apagar esse arquivo?**

---

## 5. Não Testado (Honestidade)

*(Será atualizado ao fim com tudo que não puder ser validado no Studio, ex.: celular físico, 2 jogadores reais, jogo publicado, compras reais de Robux.)*

---

## 6. Sugestões (Não Implementadas)

*(Ideias de melhoria fora do escopo de revisão/polimento serão anotadas aqui.)*

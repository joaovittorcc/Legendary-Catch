# Bom dia — o que rolou na noite de 2026-11-17

> Escrito pelo Claude (coordenador). Detalhes por item no Mural de `docs/COORDENACAO.md` e no backlog `docs/NOITE.md`.

## O jogo agora
**Legendary Catch** roda de ponta a ponta no Studio:
1. **Tela de título** → câmera de chegada → **tutorial** guiado (píer → lançar → luta → coleção → oficina → treino).
2. **Pesca** no fim do píer: 3 minigames (barra de puxar, precisão, ritmo), um por fisgada, criatura escondida até a captura.
3. **24 criaturas com modelo 3D** (Antigravity) de Comum a Lendário, **variante Cintilante** (1/40, ×3 moedas), peso e valor por captura.
4. **Revelações** por estilo (10 estilos) e **assinatura única nos 3 lendários** (Leviatã, Kraken, Fênix).
5. **Coleção/bestiário** com modelos animados, progresso por raridade e **marcos** com recompensa.
6. **Oficina**: 5 varas em 3D (Iniciante → Astral) com bônus de controle e sorte; **loja de Robux** (VIP, boost de sorte, moedas — escondida até existirem os IDs).
7. **Treino** semi-idle na lagoa (Controle e Instinto).
8. **Desafios diários** (3 por dia), **eventos do oceano** (Maré Estelar, Tempestade, Hora Dourada), **anúncio de captura grande** pro servidor, **troféu do servidor** no pedestal da praça, placar na lista de jogadores.
9. **Sons**, **ajustes** (volume, reduzir efeitos), **PT/EN automático**, layout de celular conferido no emulador, moedas voando e sequência de capturas.
10. **Salvamento** com ProfileStore (no Studio fica simulado até você ligar o acesso às APIs).
11. **Troféu do servidor** no pedestal da praça (melhor captura do servidor), **Vô Anzol** (NPC guia com falas do tutorial e dicas), textos do mundo traduzidos no aparelho de cada jogador.
12. **Mapa otimizado pra celular** (sombras -56%, menos luzes, streaming), barreira no mar e saídas da água.
13. **Preços das varas** rebalanceados pelo ritmo estimado (~285 moedas/min): Coral 500, Cristal 3.000, Tempestade 15.000, Astral 60.000.

14. **QA de ponta a ponta** (Antigravity, 04:56): título, tutorial, 3 minigames, 10+ capturas de todas as raridades, troféu, coleção/marcos, oficina, treino, desafios, ajustes e evento — **0 erros Lua**. Achou 4 bugs visuais: balão do guia e placas em inglês (corrigidos pelo Claude), barra do treino e contraste do banner de evento (com o Codex).
15. **Madrugada final**: **modo foto** depois de Épico/Lendário (esconde a UI, câmera por arraste, moldura com nomes), troféu estilizado com giro, placas do mapa traduzidas, marcador de onde pescar na ponta do píer, polimento de menus no celular. Galeria de prints de todas as telas em `art/screens/` (Codex, em andamento).

## Testar em 5 minutos
1. Abra o Studio (place Legendary Catch) e confirme o Rojo conectado na porta **34873**.
2. **Play** → passe pela tela de título → siga o tutorial.
3. Pra ver um lendário na hora, rode na **Command Bar** durante o Play (lado servidor):
   ```lua
   game.Players:GetPlayers()[1]:SetAttribute("DevForceRarity", "Legendary")
   ```
   Outros: `DevForceMinigame` = `reel`/`precision`/`rhythm`, `DevForceVariant` = `Shiny`, `DevGrantCoins` = número, `workspace:SetAttribute("DevStartEvent", "starTide")`.

## Só você pode fazer
1. **Salvar de verdade no Studio**: Home > Game Settings > Security > Enable Studio Access to API Services > Save.
2. **Enviar os commits**: `git push` na pasta do projeto (estão todos locais na `main`).
3. **Nome da experiência** → "Legendary Catch" (Creator Hub > experiência > Configuration > Basic Info).
4. **Produtos de Robux** (se quiser vender): criar no Creator Hub > Monetization o passe VIP, o boost de sorte (produto) e 2 pacotes de moedas, e me passar os IDs (vão em `src/shared/Config/Products.luau`).
5. **Thumbnails/ícone**: `art/marketing/` (thumb-ilha, thumb-lendarios 1920×1080, icone 512) — subir no Creator Hub.
6. **Codex**: bateu o limite de uso à 02:27 (volta 05:46). Não cliquei em upgrade nem em "redefinir uso".

## Não testado
Celular de verdade (só emulador), 2+ jogadores ao mesmo tempo, jogo publicado, compras reais de Robux, salvamento real (API desligada).

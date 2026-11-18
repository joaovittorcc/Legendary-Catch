# Resumo da noite (18/11, 00:20 -> manha) - Legendary Catch

Escrito pelo Claude durante a noite; atualizado no fim. Detalhes por hora no Mural (docs/COORDENACAO.md) e o plano em docs/PLANO-NOITE-2.md.

## O que mudou no jogo
- **100 criaturas** (eram 64): 5 Comuns, 5 Incomuns, 7 Raras, 6 Epicas, 5 Lendarias, **2 Misticas** novas + 6 exclusivas de evento do oceano
  (C95-C100). Todas com partes por membro (animadas), +Z conferido, auras nas Epicas/Lendarias/Misticas.
- **Nova raridade Mistica** (acima da Lendaria): ~1 em 2.500 pescas (antes de sorte), minigame mais dificil (6o nivel), carta de revelacao cosmica,
  aviso global, aura maxima, marco `allMystic`.
- **Criaturas de evento:** so entram no sorteio (peso 3x) enquanto o evento do oceano esta ativo (cardume brilhante, mare estrelada, tempestade, hora dourada).
- **Minigames refeitos** (Codex): sem o painel ciano gigante; Ritmo em tela cheia, Precisao e Puxar novos; feedback unificado, combo, ReduceEffects.
- **Treino**: numeros de XP, combo de aneis (+10%/passo ate +50%), bonus do 1o treino do dia, moedas a cada 5o nivel, level-up com impacto.
- **Progressao e retencao (servidor)**: nivel do jogador (XP por captura), combo de pesca (+3%/passo ate +30%), bau a cada 10 capturas, peixes gigantes,
  primeira captura garantida e rapida (<40 s), 19 conquistas, codigos promocionais (BEMVINDO, LENDARIO, PESCADOR), placares globais (capturas, especies, nivel).
- **Loja/Oficina**: previas 3D girando e estados claros; 3 varas novas de late game na configuracao (Celestial 200k, Abismo 600k, Mistica 2M;
  modelos 3D com o Antigravity). A "pedra dentro da Oficina" era terreno (Terrain Rock) e foi removida.
- **HUD/UI**: proporcao da arte preservada (nada esticado), menu em grade 2x2, "Proxima meta"/presente/tutorial reposicionados, so moedas e nivel durante a pesca.
- **Audio**: 14 sons ligados (musica da ilha, ondas, stingers por raridade, level-up, moeda, bau, erro).
- **Camera da pesca**: mais afastada, sem zoom-in na luta, e na captura vai pro ombro seguindo o peixe.
- **Mapa/varas/ambiente (Antigravity C)**: 5 varas novas com malhas, ambiente da ilha (gaivotas, peixes), props corrigidos; placa fisica do Placar na praca.
- **Marketing**: icone, 3 thumbnails e banner em art/marketing/; texto da pagina em docs/PAGINA-DO-JOGO.md.

## O que depende de voce (nao fiz)
1. **Push** para o GitHub (tudo esta em commits locais; nada foi enviado).
2. IDs reais de produtos/passes Robux em `src/shared/Config/Products.luau` (hoje id=0, a loja mostra "fora de venda") e criar os Game Passes (2x moedas, auto-pesca, VIP).
3. Ligar a **API do Studio** (DataStore) para o salvamento real e para os placares funcionarem no Studio; testar placares no jogo publicado.
4. Subir icone, thumbnails e descricao na pagina do jogo; renomear a experiencia.
5. **Testar no celular real** e com **2 jogadores** (so testamos no Device Emulator e com 1 jogador).
6. O viewport 3D do Studio ficou escuro nas capturas depois do reinicio do PC: os modelos novos foram conferidos por medidas/estrutura, nao por imagem. Vale olhar no Studio.

## Pendencias conhecidas
- Anti-cheat dos minigames: o resultado vem do cliente; o servidor so confere tempo minimo e a distancia da pesca. Defesa mais forte (ex.: validar o padrao de entrada) fica para depois.
- Auto-pesca (Game Pass), Prestigio/Rebirth, eventos semanais e ver o album de outro jogador estao so no plano (docs/PLANO-NOITE-2.md, secoes C-F).
- Nao ha teste automatizado; os testes foram manuais no Play.

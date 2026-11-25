# Legendary Catch: resumo atual (20/11/2026, noite)

Resumo curto. Detalhes em `docs/JOGO-COMPLETO.md`.

## O jogo
Pesca fantástica e coleção no Roblox. Você pesca de um píer numa ilha mágica, vence um minigame sem saber o que fisgou e a criatura aparece numa revelação cada vez mais épica conforme a raridade. Mobile-first, público inclui crianças.

## O que já existe
- **Pesca completa:** 3 minigames (puxar, precisão, ritmo), mordida, captura validada pelo servidor, valor por peso, combo, peixe gigante, Cintilante (1 em 40).
- **106 criaturas, 6 raridades** (Comum a Mística), 8 varas, zonas por nível (Lagoa, Recife de Coral, Abismo Estelar com portais), 6 eventos do oceano, criaturas de evento e de Natal.
- **Progressão:** nível do jogador, baú a cada 10 capturas, 19 conquistas, códigos, desafios diários, marcos da coleção, treino semi-idle (Controle e Instinto), prestígio ("Maré Nova"), auto-pesca (passe), placar global.
- **Mundo:** ilha-hub, dia/noite, fogueira, lanternas, 3 NPCs que só conversam (Vô Anzol, Lucy, Luna), placar flutuante no oceano.
- **Interface:** HUD polida, Coleção, Oficina, Conquistas, Prestígio, Placar, Ajustes. A revelação mostra a criatura de frente, com card 3D e cinemáticas de portal.
- **Técnico:** servidor como autoridade, ProfileStore, remotes com limite, atributos Dev só no Studio.

## Onde estamos agora (trabalho em andamento)
- **Remodelagem no Blender (por raridade):** kit pronto em `tools/blender/`.
  - **Místicas:** a C93 (Ouroboros, 20 ossos, aura orbital) e a C94 (cavaleiro da Maré Primordial) já foram integradas e implantadas no place (commits de hoje às 17:03 e 17:28).
  - **Lendárias e Épicas:** só os **pilotos** estão modelados e commitados. As Épicas piloto são C09, C20 e C84 (aguardam aprovação do João; lotes 2 e 3 listados no Mural). O restante ainda não foi feito.
  - **Raras, Incomuns e Comuns:** prompts prontos, ainda não enviados. Raras ficam com o Antigravity; Incomuns e Comuns com o Codex.
- **Cutscene em vídeo para as Místicas:** vídeo da C93 e da C94 gerados no Gemini (aprovados). Falta o sistema `VideoCutscene` (preload, crossfade, fallback, pular) e conferir o limite de upload de vídeo no Creator Hub. Recomendado usar só o trecho do portal e deixar o modelo 3D real assumir.
- **Ferramentas:** Blender MCP configurado no Antigravity e no Codex (um agente por vez). Remote Control do Antigravity religado hoje.

## Pendências
**Só o João:** ativar API Access do Studio, criar produtos/passes Robux (ids estão em 0), ícone/thumbnails/descrição da página, testar no celular real e com 2 jogadores, desligar os atributos Dev antes do lançamento, salvar o place (Ctrl+S) depois do Play e fechar as janelas extras do Studio.
**Claude (quando voltar ao normal):** trocar "Marina" por "Lucy" no código, rebalancear a economia com auto-pesca, reforçar o anti-cheat do minigame, eventos semanais.
**Nunca testado:** celular real, 2+ jogadores, jogo publicado, save real, compras reais.

## Regras vivas
Claude está em modo só-prompt (gera prompts para Codex e Gemini) até o João dizer que voltou ao normal. Usar sempre o vault `fwjelaa` como base de VFX/UI/animação e creditar fwjelaa. Sem push sem o João pedir (último push: hoje, `0aa54b5`; há commits novos locais depois dele).

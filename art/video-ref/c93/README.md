# Ouroboros Cósmico · referência de vídeo

| Arquivo | Conteúdo |
| --- | --- |
| [pesca-c93-raw.mp4](pesca-c93-raw.mp4) | Tomada 1, 20,10 s |
| [pesca-c93-take-2.mp4](pesca-c93-take-2.mp4) | Tomada 2, 19,37 s |
| [frames/](frames/) · [ultimo-quadro.png](ultimo-quadro.png) | 12 quadros em ordem e último quadro da revelação na tomada 1 |
| [tempos.md](tempos.md) | Linha do tempo em segundos e cores da receita atual |
| [c93-model-sheet.pdf](c93-model-sheet.pdf) · [modelo/](modelo/) | Folha A3 de uma página e oito vistas em PNG |

As duas tomadas são pescas distintas no Play, com arremesso, mordida, resolução do minigame via `SubmitCatch`, cinemática inteira, pose final estável e retorno ao píer. `DevForceRarity=Mystic` permitiu repetir o sorteio até sair a C93 duas vezes. Houve uma captura da C94 entre as duas tomadas.

Captura da área do viewport com FFmpeg e `gdigrab`, Studio maximizado e simulador desligado. O alvo de 60 FPS teve quedas e a sessão de origem ficou em média em 40,6 FPS. Os dois cortes foram exportados a **30 FPS constantes**, **1920 × 1080**, H.264, sem áudio, com barras discretas de 58 px acima e abaixo para preservar a proporção. O cursor do Windows foi excluído com `-draw_mouse 0`. O cursor interno do Roblox apareceu na origem e foi removido de uma pequena região fixa no recorte. O primeiro rastro no PNG 02 é um meteoro da receita atual.

As oito vistas vêm do modelo clonado numa cena temporária no Workspace local do Play, com fundo cinza-escuro e luz principal, preenchimento e contraluz. PNGs com 753 px de altura nativa, cortados na horizontal para retirar o entorno da cena. A folha indica as cores das instâncias e as dimensões originais. A frente visível foi alinhada a +Z na cena. O clone e as luzes temporárias foram removidos ao concluir.

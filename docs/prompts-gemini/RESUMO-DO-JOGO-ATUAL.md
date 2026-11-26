# Legendary Catch: resumo do jogo (26/11/2026)

## O que é
Jogo de **pesca fantástica e coleção** no Roblox, para celular e PC. O público inclui crianças: nada de dificuldade cruel, flashes agressivos ou truques para fazer gastar.

Visual 3D estilizado e premium, estilo "candy": cores vivas, cristais ciano e azul brilhantes, rosa e lilás, dourado, madeira quente e lanternas âmbar.

## O ciclo principal
1. **Arremesso** no píer, com barra de força.
2. **Fisgada** e **minigame da barra lateral** (manter a faixa sobre o peixe que se move).
3. **Revelação cinematográfica**: a criatura só aparece depois que o jogador vence.
4. **Roleta** que pode mudar o tamanho e dar mutação. O jogo mostra a chance real daquela captura ("1 em N").
5. Moedas, coleção, varas melhores e mais pesca.

São **106 criaturas** em raridades que vão de Comum a Místico, com variante Cintilante e mutações.

## Sistemas
Coleção, Aquário, Oficina de Varas (Controle e Sorte), missões diárias, conquistas, prestígio ("Maré Nova"), placar, presente diário e eventos do oceano.

## Mundo
- **Ilha-hub:** praça, oficina de telhado azul, píer de pesca, cais das expedições, aquário, santuário com os portais de treino e três placares em arco sobre o mar.
- **Ilhas de treino**, acessadas por portais, em ordem de força:

| Ilha | Tema | Multiplicador | Situação |
|---|---|---|---|
| 1. Aprendiz | luz, água cristalina, árvore rosa | x1 (grátis) | pronta |
| 2. Recife | tropical, corais, águas-vivas | x3 | pronta |
| 3. Abismo Estelar | cósmico, cristais, galáxia | x12 | pronta |
| 4. Celestial | céu, nuvens, mármore e ouro | x50 | em construção |

## Treino
O jogador ganha **Poder de Pesca**, um número que só cresce. Cada ilha tem duas lagoas:
- **Lagoa do Foco** treina **Controle**: o minigame fica mais fácil e a mira melhora.
- **Lagoa do Instinto** treina **Instinto**: mais sorte para criaturas raras.

O treino é meio automático: o jogador fica no deck, o XP sobe sozinho e de vez em quando aparece um desafio rápido para ganhar bônus e aumentar o combo.

## Regras técnicas
- Luau com `--!strict`; o projeto sincroniza com o Roblox Studio pelo Rojo.
- O servidor decide moedas, capturas e raridade. O cliente só mostra.
- `StreamingEnabled` ligado. O mapa tem cerca de 25 mil peças: **desempenho em celular importa muito**.
- Existe a opção **Reduzir efeitos** (atributo `ReduceEffects` no jogador), que todo efeito novo deve respeitar.
- Textos do jogo em português e inglês. Código, nomes e comentários em inglês.

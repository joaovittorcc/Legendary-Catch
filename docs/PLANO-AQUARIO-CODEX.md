# Frente 3 — Codex · interface e integração

[Plano principal](PLANO-AQUARIO-E-PESCA.md) · [Claude](PLANO-AQUARIO-CLAUDE.md) · [Antigravity](PLANO-AQUARIO-ANTIGRAVITY.md)

Colocar os sistemas e a arte no fluxo jogável, do arremesso ao aquário. O cliente apresenta os valores do servidor e usa os elementos do cenário entregues por Antigravity. Textos em PT/EN em StringsUi. Reutilizar UiTheme, HUD, Coleção e infraestrutura de pesca.

| Lote | Natureza | Dificuldade | Resultado |
|---|---|---|---|
| C0 | Protótipo e auditoria | Média | UI do primeiro ciclo e mapa dos problemas da pesca |
| C1 | Interface e integração com dados | Alta | Renda no card e no tanque, escalação e troca |
| C2 | Animação de interface e progressão | Alta | Aquário vivo, upgrades, livro e metas |
| C3 | Interação e animação de pesca | Alta | Arremesso, luta e três minigames revisados |
| C4 | Encenação em Luau | Muito alta | Pilotos e 18 cenas ligadas à captura, eventos sincronizados |
| C5 | QA e integração final | Alta | Ciclo validado de ponta a ponta |

## C0 — Começar com UI e auditoria

- Prototipar o card da Coleção, seleção de vaga, troca e contador usando dados de demonstração. Cobrir valores baixos, rendas altas, criatura nova, variantes e aquário cheio. Depois plugar no contrato do Claude.
- Auditar desktop e toque nos três minigames atuais. Registrar duração, acerto, falha, primeira tentativa, leitura dos alvos, entrada e saída. Levar casos de balanceamento para Claude.
- Com Antigravity, definir pontos do tanque, vista de inspeção e onde aparecem rótulos, botões e transição visual de expansão.

## C1 — Primeiro ciclo jogável

1. Na Coleção, mostrar modelo, raridade, quantidade, recorde, taxa base, variante e taxa efetiva quando a criatura estiver em exibição. Distinguir renda potencial de renda recebida.
2. Sobre as criaturas, mostrar moedas/s nas cores de renda aprovadas. **Comum branco, Incomum verde, Rara azul, Épica roxa, Lendária dourada e Mística arco-íris.** Usar fundo/contorno contrastante, gradiente estático com Reduzir Efeitos e prioridade pra criatura em foco quando dois rótulos se sobrepuserem.
3. Ao expor, listar criaturas elegíveis, quantidades, vagas e estado bloqueado. Mostrar prévia confirmada pelo servidor com antes/depois por vaga, total e sinergia. Tratar confirmação, rejeição, carregamento e troca concorrente. Atualizar a taxa após receber o resultado.
4. Animar o contador quando o saldo confirmado mudar. Agrupar ticks contínuos e reservar moedas voando para capturas, metas e outros pagamentos pontuais.

**Aceite:** capturar, equipar, ver a taxa e o saldo avançarem, comparar uma troca e confirmar. Conferir ganho e perda de renda com coleção antiga, variante e tanque cheio.

## C2 — Aquário vivo e progressão

- Usar volumes do Antigravity para nado, pausas, mudanças de profundidade e reações à aproximação. Simplificar simulação distante e combinar animação com tamanho da criatura. Visualizar a sinergia com brilho curto entre participantes.
- Mostrar prévia de expansão antes de comprar. Na confirmação do servidor, animar a construção e sinalizar vagas novas. Manter as criaturas expostas visíveis durante a transição.
- Animação de descoberta no livro: silhueta, cor, carimbo e data. Variante tem estado próprio. Montar metas de renda e de sessão com requisito, progresso e prêmio, além do resumo de volta quando o contrato fornecer dados.

## C3 — Pesca jogável e minigames

| Área | Entrega e critério de aceite |
|---|---|
| Arremesso e boia | Pose, arco, linha, impacto na água e espera legíveis. Raridade real colore o sinal da captura. |
| Fisgada e luta | Movimento de vara, tensão e reação de acerto/erro. Efeitos preservam contraste do alvo e controle de toque. |
| Reel | Ensinar segurar e soltar. Tornar faixa, peixe e progresso distintos. Mostrar como recuperar a tensão. |
| Precision | Alvo e cursor contrastantes, retorno de acerto/perfeito/erro e contagem restante. |
| Rhythm | Sequência e anel de aproximação claros, espaçamento para toque e ritmo legível com som desligado. |
| Combo e conclusão | Faixa compacta, marcos e prêmios vindos do servidor. Morte, cancelamento ou escape restauram câmera, entrada e HUD. |

Medir resultado por modo, tier, equipamento e tipo de entrada. Claude ajusta parâmetros e regras do controlador. Codex ajusta o fluxo de interface, efeitos e animações de cliente conforme essas medições.

## C4 — Lendárias e eventos

- Integrar C23/C24/C64 primeiro usando as poses, efeitos e timestamps do Antigravity. Começar após a captura confirmada. Dar tempo para a pose final e voltar ao card.
- Adotar o mesmo ciclo de entrada e limpeza para as 15 cenas seguintes, com timelines por ID. Validar pulo, repetição, morte e Reduzir Efeitos. Revisar C93/C94 como regressão.
- Ligar cenografia, decoração, cor da água e faixa de evento ao estado do servidor. Exibir tempo restante, recolher efeitos ao terminar e manter a captura em andamento ligada à decisão do servidor.

## C5 — Verificação final

Testar os três modos e o ciclo do aquário em PC, celular em retrato e paisagem e, quando disponível, celular real. Em dois jogadores, conferir exibição, captura simultânea e atualização do próprio saldo. Cobrir catálogo, eventos e Natal, tela reduzida, contraste, Reduzir Efeitos, cancelamento, desempenho do tanque cheio, recuperação de câmera e animação e migração de perfil. Registrar Play, análise estática, pendências e versão de entrega no Mural.

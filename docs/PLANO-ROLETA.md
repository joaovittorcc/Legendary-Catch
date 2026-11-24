# Plano: roleta da sorte depois de cada captura

Pedido do João (23/11/2026). Toda criatura (Comum até Mística), ao ser pescada, passa por uma **roleta automática** que pode mudar o tamanho, dar uma mutação, piorar, não fazer nada ou girar de novo. Afeta o **peso** e as **moedas** daquela captura. Flag `FishingRoulette` (desligada até testar). Simulação: `node tools/roulette-sim.js`.

## 1. Fluxo

1. Ganhou o minigame.
2. "1 em N" (momento das chances, já pronto).
3. **Roleta principal** gira sozinha e para numa carta.
4. Conforme a carta: abre a **sub-roleta** (tamanho, mutação ou "encolheu") ou gira de novo ou acaba.
5. Resumo rápido ("x5 TAMANHO + DIAMANTE → x15,8 moedas") e a revelação de sempre, já com peso e valor finais.

**O servidor sorteia tudo** no momento da captura; a roleta só mostra o resultado (o cliente nunca decide). Auto-Fish também rola, mas sem animação (só o toast com o valor).

## 2. Roleta principal

| Carta | Peso | O que faz |
|---|---|---|
| NADA | 50 | nada muda |
| ENCOLHEU (pior) | 20 | abre a sub-roleta de encolher |
| TAMANHO | 18 | abre a sub-roleta de tamanho |
| GIRE DE NOVO | 8 | gira a principal de novo (no máximo 3 vezes seguidas) |
| MUTAÇÃO | 4 | abre a sub-roleta de mutação (a mais rara) |

"Quanto mais gira, mais chance de nada": cada "gire de novo" soma +25 no peso de NADA no giro seguinte.

## 3. Sub-roletas

**Tamanho** (multiplica o peso em kg):

| x2 | x3 | x5 | x10 | x25 | x50 | x100 |
|---|---|---|---|---|---|---|
| 62 | 20 | 10 | 5 | 2 | 0,8 | 0,2 |

**Encolheu** (multiplica o peso): x0,8 (50), x0,6 (35), x0,4 (15).

**Mutação** (multiplica as moedas; da mais comum à mais rara):

| Mutação | Moedas | Peso | Cor |
|---|---|---|---|
| Neon | x1,5 | 40 | verde-limão brilhante |
| Gelo | x2 | 24 | azul-gelo |
| Magma | x2,5 | 15 | laranja-lava |
| Tempestade | x3 | 10 | roxo elétrico |
| Arco-Íris | x5 | 7 | arco-íris animado |
| Diamante | x10 | 3 | branco-ciano facetado |
| Cósmica | x25 | 1 | preto com estrelas e roxo |

Uma "gire de novo" seguida de tamanho e depois mutação é possível: os efeitos **acumulam** (ex.: x5 e Diamante).

## 4. Moedas e economia

- Moedas = valor da captura (como hoje) **x raiz do multiplicador de tamanho** x mutação. Assim o x100 de tamanho vira x10 de moedas (o peso mostra x100 inteiro: "2.450 kg" vira "245.000 kg").
- Média (2 milhões de capturas simuladas): **x1,18 moedas por captura** (+18%). Proposta: aceitar como recompensa e revisar preços de vara/campo com dados reais se a economia acelerar demais.
- Raridades: x100 de tamanho ~1 em 2.800 capturas; Cósmica ~1 em 2.500.
- **Aquário não muda**: a taxa do aquário continua pela espécie e variante (Gigante/Dourada). A mutação e o tamanho ficam como **troféu** na coleção (maior peso, melhor mutação já pega).
- Recorde de peso usa o peso final (com o tamanho), então pode bater recordes absurdos de propósito. A variante "Gigante" do aquário continua vindo do peso **base**.

## 5. Interface (mesmo caminho visual da barra e do "1 em N")

- **Fita de cartas** horizontal no meio da tela (estilo "abrir caixa"): cartas coloridas grandes com ícone/palavra, marcador dourado no centro, a fita acelera e **freia com suspense** até parar na carta do resultado.
- Ao parar: a carta cresce ("pop"), brilho da cor da carta, faíscas; tremida leve nas cartas raras; "PIOR" desce com som triste e cor vermelha.
- Sub-roleta entra deslizando por cima, com as cartas daquela tabela (x2...x100 em tons crescentes; mutações com as cores da tabela; Cósmica com gradiente animado).
- Fundo escurecido com raios suaves da cor da roleta; confete só em tamanho ≥ x10 e mutação ≥ Arco-Íris.
- Rodapé com o **acumulado** ("Tamanho x5 · Diamante · Moedas x22,4").
- Tempo: NADA ~1,2 s; com sub-roleta ~2,5 s; jackpot até ~4 s. Toque acelera (pula para o resultado). `ReduceEffects`: sem tremida nem confete.
- Textos em `Strings` (PT/EN).

## 6. Dados (servidor → cliente)

`caught` ganha:

- `spins`: lista na ordem, cada item `{ wheel = "main" | "size" | "worse" | "mutation", result = string }` (ex.: `{ main/again }, { main/size }, { size/x5 }`).
- `sizeMult` (número), `mutation` (id ou nil), `coinMult` (número total aplicado nas moedas).
- `weight` e `value` já chegam finais.

Perfil: `collection[id].bestMutation` (id da melhor mutação já pega) para o bestiário.

## 7. Fases

| Fase | Quem | Entrega |
|---|---|---|
| R1 | Claude | `Config/Roulette.luau` (tabelas e sorteio puro) + `tools/roulette-sim.js` + teste de lógica |
| R2 | Claude | Servidor aplica na captura, payload, `bestMutation`, Auto-Fish sem animação |
| R3 | Claude | UI da fita de cartas (`Fishing/Roulette.luau`) e ligação no controlador, atrás da flag |
| R4 | Codex | Polimento (sons, ícones, Bestiário mostrando mutação e maior tamanho, revelação com selo da mutação) |
| R5 | Todos | Play, celular, telemetria (mix real de resultados), liga a flag |

## 8. Riscos

- **Tempo do ciclo**: mais uma etapa por captura; manter NADA curto e permitir acelerar com toque.
- **Economia**: +18% moedas em média; acompanhar.
- **Sensação de caixa-surpresa**: sem compra, sem re-roll pago, nada de Robux ligado à roleta.
- **Peso enorme** quebra layout de números: usar formatação curta (K/M) no card.


## 9. Atualização 23/11 (noite)

- **Efeitos acumulam** (tamanho + mutação etc.): a roleta principal gira de novo depois de cada efeito, até NADA ou 4 giros; o peso de NADA sobe 40 por giro. Média de moedas ~x1,28.
- **"1 em N" combinado** (ver `docs/PESCA-FORCA-CONTRATO.md` §7): bônus deixa mais raro, NADA/ENCOLHEU não.
- **Sequência na tela** (`CatchShow`): silhueta preta em cima, roleta embaixo, contador "1 em N" no fim. O tamanho muda a silhueta de verdade; o **modelo da revelação** crescer de verdade fica com o Codex.

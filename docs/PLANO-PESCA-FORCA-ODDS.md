# Plano: barra de força que evolui + "1 em N" com silhueta crescente + cutscenes

Ideia do João (23/11/2026), v2 com as respostas dele. Estado: **só planejamento, nada implementado**.
Dono: S = Claude (servidor/contrato/dados), U = Codex (visual).
Dados das criaturas (chances, análise de modelos, +100 novas): `docs/CRIATURAS-ODDS-E-LISTA.md`.

## 1. O que muda para o jogador

1. Aperta para pescar: **cutscene curta de arremesso** (câmera atrás do ombro, vara pra trás e pra frente) com a **barra de força**.
2. Um toque para a força. A faixa onde parou muda a sorte do arremesso (e a distância do lançamento, só visual).
3. Peixe morde, minigame como hoje.
4. **Ganhou:** "momento das chances": silhueta escura da criatura **crescendo** e o contador **"1 em N"** subindo. Quanto mais raro, maior a silhueta e mais longa a subida.
5. Revelação com a animação épica que já existe (cards/cinemáticas por raridade).

## 2. Barra que evolui com o treino ("nível de mira")

Faixas na barra: **vermelho** (penaliza), **amarelo** (penaliza pouco), **neutro** (sem efeito), **verde** (bônus), **roxo** (perfeito, bônus grande).

**Nível de mira (0 a 1)** = `0,7 x log10(PP de Controle) / 15 + 0,3 x (controlBonus da vara / 0,32)`. Usa o **Poder de Pesca** do novo treino (`docs/PLANO-TREINO-PODER.md`, aprovado como direção); o Controle por nível 0–25 deixa de existir. Reaproveita o bônus de Controle das varas.

| Mira | Vermelho | Amarelo | Neutro | Verde | Roxo | Leitura |
|---|---|---|---|---|---|---|
| 0 (início) | 24% | 24% | **40%** | 12% (1 faixa) | 0 | neutra grande, verde mínima |
| 0,35 | 18% | 20% | 34% | 28% | 0 | verde cresce, negativas encolhem |
| 0,60 | 12% | 16% | 30% | 36% | **6% (1 faixa)** | roxo aparece |
| 0,85 | 8% | 12% | 24% | 40% | 16% (1 faixa larga) | |
| 1,00 (topo) | 4% | 8% | 20% | 44% | **24% (2 faixas)** | duas faixas roxas |

- A tabela é interpolada entre as linhas (curva suave). Ordem na barra: vermelho e amarelo nas pontas, neutro, verde, roxo no meio ou espalhado (2 faixas). Os números são ponto de partida para testar.
- Velocidade do ponteiro fixa (~1,2 s de ida e volta), igual para todos. Quem treina ganha **área**, não reflexo.
- **Efeito na sorte** (por posto de raridade `rank`, 1 = Comum ... 6 = Mística, só de `rank >= 2`):
  `fatorForça = 1 + b x (rank - 1)`, com `b`: vermelho **-0,08**, amarelo **-0,04**, neutro **0**, verde **+0,10**, roxo **+0,25**; piso 0,2.
  Ex.: Lendário (rank 5) no roxo = x2,0; no vermelho = x0,68. Entra multiplicando em `luckyWeights`, igual treino/vara/prestígio.
- **Auto-Fish:** sempre neutro, nunca roxo.
- Sem toque em ~3 s: arremesso em vermelho (não dá para esperar a barra voltar).

## 3. Chances por criatura (resumo; detalhes na outra doc)

- Campo novo `dropWeight` por criatura (relativo dentro da raridade). Modelo mais detalhado = mais raro.
- Faixas atuais (sem sorte, com 206 criaturas): Comum 1 em 36 a 1 em 427; Incomum 60 a 715; Raro 140 a 1,7 mil; Épico 305 a 3,7 mil; Lendário 1,3 mil a 26 mil; **Mística 18 mil a 200 mil**.
- O "1 em N" mostrado é o **real** daquele arremesso (já com sorte e força). Sem número inventado.
- Degraus de silhueta (ajustáveis): `<=50`, `<=150`, `<=500`, `<=2.000`, `<=10.000`, `<=50.000`, `>50.000` (7 degraus; Comum mais comum cai no 1º, que fica rápido).

## 4. Cutscene do arremesso (U, Codex; ganchos S)

Duração total **<= 2,2 s**, pulável com toque (e desligada em `ReduceEffects`, que só mostra a barra e o arremesso normal).

1. **Preparar (0,4 s):** câmera vai para trás do ombro e levemente acima (FOV 70 → 62), personagem recua a vara (animação procedural, ombro por `AnimationConstraint`, ver armadilha 9 do AGENTS.md).
2. **Barra de força aparece** na tela; ponteiro corre. O personagem treme de leve cada vez que passa de faixa (sutil).
3. **Toque (0,1 s):** congela o ponteiro, brilho na faixa tocada; no roxo: "PERFEITO!", pausa de 0,15 s (câmera lenta) e rastro dourado.
4. **Lançamento (0,5 s):** vara vai para frente, linha corta o ar em arco (distância e altura escalam com a força), câmera segue a boia (FOV volta).
5. **Mergulho (0,4 s):** boia cai, anel d'água na cor da faixa (vermelho/amarelo/verde/roxo), som de respingo. Roxo: anel duplo e brilho sob a água.
6. Volta ao jogo normal (espera da fisgada).

Tudo por código (sem `Animation` do Studio). Ganchos documentados caso o João crie animações depois.

## 5. "Momento das chances" com a criatura crescendo (U)

Fica entre "ganhou o minigame" e a revelação (que já existe). Tudo vem do servidor, o cliente só desenha.

| Degrau | Tempo | Silhueta | Câmera / mundo | Contador |
|---|---|---|---|---|
| `<=50` | ~0,7 s | pequena, centro | fixa | sobe de 1 em 1 a N, rápido |
| `<=150` | ~1,2 s | média | leve aproximação | idem |
| `<=500` | ~1,8 s | média+ | aproximação + vinheta | tick com batida |
| `<=2.000` | ~2,6 s | grande, sobe do fundo | câmera sob a água olhando para cima | passos em escala log (1, 10, 100, 1k...) |
| `<=10.000` | ~3,6 s | muito grande, cobre meia tela | água escurece, bolhas, tremor suave | idem, com batida mais lenta |
| `<=50.000` | ~4,8 s | gigante, olhos acendem | mundo escuro, raio de luz de cima | cor do contador muda de passo |
| `>50.000` (Mística) | ~6 a 8 s | **colossal**, ocupa a tela, aura da cor da raridade | HUD some, "o mar prende a respiração" | trava no N final, pulso, flash |

- Silhueta = a **criatura real em preto** num `ViewportFrame` (mesmo modelo da revelação), escalada por degrau e subindo de baixo para cima.
- Cada vez que o contador passa de um degrau: sobe um nível de tamanho, um "bum" de graves e uma troca de cor (verde-água, azul, roxo, rosa, dourado, vermelho-rosado).
- **Segurança:** no máximo 3 pulsos de luz por segundo, sem flash agressivo; `ReduceEffects` troca por fade e tamanho fixo.
- **Pular:** sempre disponível depois da primeira vez que o jogador vê aquele degrau; mostra só o número final.
- **Orçamento:** Comum e Incomum nunca passam de 1,2 s. O espetáculo longo só vem de quem tem 1 em 2.000 ou mais raro.
- Termina em corte para a revelação atual (anel, nome, estrelas, "NOVA DESCOBERTA").

## 6. Decisões de design

| Tema | Decisão | Motivo |
|---|---|---|
| Neutro = hoje | Neutro mantém o balanço atual; verde/roxo só bonificam | Economia atual não quebra |
| Em quais raridades pesa | Só Incomum para cima, crescendo com o posto | Comum nunca some |
| Teto de sorte | **Cap** no produto total (treino, vara, prestígio, boost, força) | Evita empilhar com o boost pago |
| Mostrar o "1 em N" | Só depois de vencer o minigame | O servidor já decidiu no mordido |
| Dark pattern | Sem compra nem re-roll ligado a esse momento | Público infantil; apresentação lembra caixa-surpresa |
| Flag | `FishingPower`, desligada até Play com 2 jogadores e celular | Padrão do projeto |

## 7. Servidor e contrato (S)

- Estado novo `aiming` no arremesso. **O servidor controla o relógio da barra:** envia `barStartAt` (tempo do servidor) + parâmetros da faixa do jogador; a posição é função do tempo. O cliente só manda "toquei" (`Fishing/PowerTap`). O servidor calcula a faixa com o **seu** relógio (tolerância de latência, ex. 120 ms) e rejeita toque duplo ou fora de hora. O cliente nunca declara "fui roxo".
- Faixa vira `powerBand` e `powerFactor` no estado do cast; entra em `luckyWeights`.
- `FishingUpdate` ganha: `powerBand`, `odds` (N real), `oddsBucket` (no resultado da vitória).
- `creatureOdds(creature, ctx)` em `Config/Fishing.luau`; `rollCreature` sorteia raridade e depois criatura por `dropWeight`.
- Telemetria: `power_band`, `odds_bucket`, tempo da barra, % de roxo por jogador (detecta cheat).
- Contrato novo `docs/PESCA-FORCA-CONTRATO.md` antes de qualquer código.
- Aquário: as 100 criaturas novas exigem `RATES_CPM` e `FAMILY` (ver outra doc).

## 8. Fases

| Fase | Quem | Entrega | Depende de |
|---|---|---|---|
| P0 | João | Aprovar tabelas de mira, multiplicadores, degraus e `dropWeight` | este plano + `CRIATURAS-ODDS-E-LISTA.md` |
| P1 | Claude | `dropWeight` nas 106 atuais, `creatureOdds`, sim de drop (milhões de rolagens) | P0 |
| P2 | Claude | `aiming`, `PowerTap`, nível de mira, `powerBand` em `luckyWeights`, cap, testes de lógica, contrato | P1 |
| P3 | Codex | Barra de força + cutscene de arremesso (mock) | contrato P2 |
| P4 | Codex | "Momento das chances" com silhueta crescente (mock) | contrato P2 |
| P5 | Claude + Codex | Dados reais, Auto-Fish neutro, `ReduceEffects`, skip | P2 a P4 |
| P6 | Todos | Play com 2 jogadores, celular, simulador de rede; liga a flag | P5 |
| Paralelo | João | Gerar os modelos das 100 novas (lista em `CRIATURAS-ODDS-E-LISTA.md`) | sem bloqueio; cada uma entra no código quando o modelo chegar |

## 9. Riscos

- **Frustração:** erro no celular. Neutro é o balanço de hoje e a barra cresce com treino; no início quase ninguém é punido forte (vermelho -0,68 só em Lendário).
- **Latência:** relógio do servidor + tolerância; testar com o simulador de rede.
- **Ciclo mais longo:** cutscene (<= 2,2 s) + barra + minigame + momento das chances. Tudo pulável.
- **Número honesto:** o "1 em 200 mil" precisa bater com o sorteio. Simulação valida.
- **Vazar a raridade antes:** o Omen já avisa lendário no mordido; o N só vem depois da vitória.
- **Peso do modelo:** silhueta colossal em `ViewportFrame` precisa de orçamento mobile (um viewport, um modelo, reaproveitado).

## 10. Para o João decidir (nenhuma trava)

1. Tabela de mira e multiplicadores (seção 2) como ponto de partida?
2. Cap do produto de sorte: valor? (proposta: x6 em Lendário, x8 em Mística)
3. Aprovar as tabelas de `dropWeight` e a lista das 100 novas.

Não testado: nada (só plano). Medi os modelos no Studio (Edit, só leitura) e li `Config/Fishing`, `Training`, `Rods`, `Omen` e `server/Features/Fishing`.

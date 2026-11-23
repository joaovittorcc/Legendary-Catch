# Plano: Poder de Pesca (1 a 1 quadrilhão) + ilhas de treino + campo de treino com 10 níveis

Pedido do João (23/11/2026). Estado: **só planejamento, nada implementado**. Dono: S = Claude (servidor/dados/economia), U = Codex (visual/HUD), A = Antigravity (mapa/arte 3D).
Este plano **substitui o sistema de nível 0–25 e XP** do treino (`Config/Training.luau`). Os exercícios (Controle e Instinto) e a animação do boneco continuam como em `docs/PLANO-TREINAMENTO.md`.
Simulação: `node tools/training-sim.js [duty] [r0]` (números abaixo saem dela).

## 1. A ideia em uma frase

Você treina e vê um número gigante subindo o tempo todo: **Poder de Pesca (PP)**, de **1 até 1.000.000.000.000.000 (1 quadrilhão = 1 Qa)**. Campo de treino melhor, ilha mais forte e prestígio multiplicam o ganho. O número muda de **cor** a cada patamar, até virar arco-íris dourado no máximo.

## 2. Poder de Pesca: a escala

- Dois treinos como hoje: **Controle** e **Instinto**. Cada um tem o **seu PP**, de 1 a 1e15 (teto fixo). O número grande do HUD ("Poder de Pesca") é a **soma** dos dois.
- **Ganho por segundo** (por treino ativo):
  `g = M + PP x r0 x M^0,3`, com `M = campo x ilha x prestígio x boost` e `r0 = 0,000008`.
  - `M` é o ganho "seco" (multiplicadores). O termo `PP x r0 x M^0,3` faz o número **crescer em cima de si mesmo** (juros), por isso ele sobe sem parar e passa de milhões, bilhões, trilhões.
  - Sem melhorias o juros quase não anda (1.500 h para o teto): **campo e ilha são obrigatórios**, não enfeite.
- **Argola de ritmo** (já existe): acerto dá bônus instantâneo = **30 s do ganho atual**, com "+1,2M" aparecendo grande.
- Só ganha treinando parado no ponto (como hoje). O servidor soma a cada segundo; o cliente anima o contador.

### Multiplicadores

| Fonte | Valores |
|---|---|
| Campo de treino (nível 1 a 10) | x1, x2,5, x6, x15, x38, x95, x240, x600, x1.500, **x4.000** |
| Ilha (1 a 4) | x1, x3, x12, **x50** |
| Prestígio (0 a 10) | x(1 + 0,25 x nível), até x3,5. Não zera o PP |
| Boost pago (se existir) | x2 só no ganho, **sem** mexer na sorte (o teto de sorte do plano de pesca continua) |

## 3. O que o PP faz na pesca (equilíbrio preservado)

O número fica enorme, mas o **efeito** usa escala logarítmica, então a economia de sorte não explode:

`p = log10(PP) / 15` (0 = 1 PP, 1 = 1 Qa)

| PP | p | Controle: facilidade dos minigames | Instinto: sorte (Lendário, rank 5) | Mira da barra* |
|---|---|---|---|---|
| 1 | 0,00 | x1,00 | x1,00 | 0,00 |
| 1 K | 0,20 | x1,06 | x1,20 | 0,14 |
| 1 M | 0,40 | x1,12 | x1,40 | 0,28 |
| 1 B | 0,60 | x1,18 | x1,60 | 0,42 |
| 1 T | 0,80 | x1,24 | x1,80 | 0,56 |
| **1 Qa** | **1,00** | **x1,30** | **x2,00** | **0,70** (+0,30 da vara = 1,0) |

- Controle: `1 + 0,012 x 25 x p` (igual ao teto de hoje, +30%). Instinto: `1 + 0,01 x 25 x p x (rank - 1)` (igual ao teto de hoje).
- \*A "mira" é a do plano `docs/PLANO-PESCA-FORCA-ODDS.md` §2: passa a ser `0,7 x p_Controle + 0,3 x (controlBonus da vara / 0,32)`. As **faixas roxas aparecem por volta de mira 0,5**: vara boa + PP de bilhões. Para o roxo duplo, vara máxima + trilhões.
- Resultado: números absurdos na tela, gameplay no mesmo equilíbrio já aprovado.

## 4. Ilhas de treino (aumentam o poder)

| Ilha | Multiplicador | Libera com PP (soma) | Tempo estimado* | Visual (arte, Antigravity) |
|---|---|---|---|---|
| 1. Lagoa (hub) | x1 | grátis | 0 h | a que já existe |
| 2. Ilha do Recife | x3 | 100 K | ~10 h | corais, águas rasas turquesa, tapetes de anêmona |
| 3. Ilha Abismo Estelar | x12 | 100 M | ~61 h | rochas escuras, cristais azuis, céu de estrelas |
| 4. Ilha Celestial | x50 | 1 T | ~102 h | plataforma flutuante, nuvens, aurora, anéis de luz |

- A ilha libera por PP (não por moeda); o jogador viaja pelo barco/portal do hub. O **campo de treino (nível 1–10) vale em qualquer ilha** (é um upgrade da conta, não do lugar).
- *Tempo = horas de jogo com 50% treinando (§6).
- Mapa novo é trabalho de A; o mapa do hub está com o Antigravity, então só na fase T5 (§12).

## 5. Campo de treino: 10 níveis com melhorias visuais reais

Começa **basiquinho**. Cada upgrade custa moeda **e** exige um PP mínimo ("difícil, mas não impossível").

| Nv | Nome | Multiplicador | Custo (moedas) | Exige PP | Estimativa* | Visual que muda |
|---|---|---|---|---|---|---|
| 1 | Clareira | x1 | grátis | , | 0 h | tapete de grama, uma boia e um poste, nada mais |
| 2 | Deck simples | x2,5 | 1.500 | 1 K | 0,6 h | deck de madeira, dois postes com corda, banquinho |
| 3 | Cais de treino | x6 | 6.000 | 10 K | 2,5 h | deck maior, lanternas âmbar, barril de iscas, placa |
| 4 | Cercado de pedra | x15 | 20.000 | 100 K | 9,9 h | muro baixo de pedra, bandeirolas, alvo flutuante |
| 5 | Torre pequena | x38 | 60.000 | 1 M | 18,6 h | torre de vigia, cristais azuis nos cantos, plataforma elevada |
| 6 | Arena rúnica | x95 | 180.000 | 10 M | 37,1 h | piso de pedra com runas brilhando, anéis de cristal flutuantes |
| 7 | Jardim das fontes | x240 | 500.000 | 100 M | 60,9 h | fontes de água luminosa, estátuas de peixe, aura suave contínua |
| 8 | Arcos de cristal | x600 | 1.400.000 | 1 B | 73,9 h | arcos de cristal, pilares com chama azul, partículas contínuas |
| 9 | Plataforma flutuante | x1.500 | 3.000.000 | 10 B | 84,8 h | a arena sobe no ar, anéis orbitando, aurora ao fundo |
| 10 | Santuário do Pescador Lendário | **x4.000** | 5.000.000 | 1 T | 110,5 h | colunas douradas, coroa de cristal gigante, raios de luz, piso arco-íris |

- *Estimativa de simulação (§6). Custo total: **10,17 milhões** de moedas.
- Visual por **kit de níveis** (mesma técnica do aquário: `ReplicatedStorage.TrainingLevels` com âncoras e um builder em Studio). O jogo troca o nível ao comprar, com uma pequena cutscene de "obra" (peças subindo, brilho) pulável.
- Âncoras mínimas por nível: `TrainingSpot` (onde o jogador treina), `InspectCamera`, `UpgradeBoard`, `DecorAnchor_*`, `Lights`. O `SPOT_RADIUS` cresce junto (16 → 28).
- Sem peça com face coplanar: passar `tools/ZFightFixer.luau` em cada nível.

## 6. Economia e ritmo (simulação)

Premissas (revisar com `economy-sim` e dados reais): 50% do tempo de jogo treinando (o resto pescando, que dá as moedas); renda de pesca 30 mil/h (0–10 h), 60 mil/h (10–30 h), 120 mil/h (30–60 h), 250 mil/h (60–100 h), 500 mil/h depois (já inclui aquário e prestígio).

Horas de jogo até cada PP (um treino focado, campo e ilha comprados assim que moeda e PP permitem):

| PP | Horas | | PP | Horas |
|---|---|---|---|---|
| 1 K | 0,6 | | 1 B | 73,9 |
| 10 K | 2,5 | | 10 B | 84,8 |
| 100 K | 9,9 | | 100 B | 93,2 |
| 1 M | 18,6 | | **1 T** | **101,7** |
| 10 M | 37,1 | | 10 T | 107,2 |
| 100 M | 60,9 | | 100 T | 112,2 |
| | | | **1 Qa (teto)** | **116,3** |

- **Teto em ~116 h de jogo** (treinando 50%): é metade do jogo, "nada impossível, mas difícil". Com 70% do tempo treinando: ~96 h. Com 35%: ~163 h.
- **Sem melhorias, o teto leva ~1.580 h**: campo e ilha são o caminho.
- O nível 1 da vida: 1.000 PP em 36 min, 1 milhão em ~19 h. Os primeiros 10 minutos já mostram número subindo de 1 para centenas.
- Gargalo no fim do jogo é **moeda** (campo 10 = 5 M), disputando com varas (preço total ~1,7 M) e aquário. Se ficar apertado, ajustar custo ou renda, não o PP.

## 7. Números e cores

### Formato

`1` a `999` inteiro; depois `1,00K`, `1,23M`, `4,56B`, `7,89T`, `1,00Qa` (K mil, M milhão, B bilhão, T trilhão, Qa quadrilhão). Toque no número mostra o valor completo com pontos (ex. `1.234.567.890`). O contador **interpola a 10 Hz** (sobe suave, nunca pula seco).

### Cor por patamar (expoente do PP)

| Faixa | Cor | Efeito |
|---|---|---|
| 1 a 999 | branco-creme | sem efeito |
| K (1e3 a 1e5) | verde-água (cor da Comum) | brilho leve |
| M (1e6 a 1e8) | azul-cristal | brilho |
| B (1e9 a 1e10) | roxo | gradiente suave |
| T (1e11 a 1e12) | rosa neon (cor da Épica) | gradiente animado rosa → lilás, pulso |
| 1e13 a 1e14 | **dourado** (cor da Lendária) | brilho dourado + brilhos soltos |
| **1e15 (teto)** | **arco-íris animado + dourado** | gradiente girando, contorno neon, partículas de brilho |

- Dentro do patamar, a cor sobe de saturação conforme a mantissa (1,00 → 999).
- **Cada vez que cruza um patamar:** faixa "NOVO PATAMAR: MILHÕES!" na cor nova, confete curto, som de "level up" e o número dá um "pop". No máximo 3 pulsos de luz por segundo.
- Pop-ups "+1,2M" flutuam a cada argola acertada e ao cruzar marcos (1K, 10K, 100K...), na cor do patamar.
- `ReduceEffects`: cor fixa, sem gradiente animado, sem confete, mantém o número e o som.
- A cor mesma aparece também no ranking de PP (se o ranking entrar) e no card de perfil.

## 8. Dados e servidor (S)

- **Novo `Config/Training.luau`**: `PP_CAP = 1e15`, `R0`, tabelas `FIELD` (mult, custo, gate), `ISLAND` (mult, gate), `tier(pp)` (cor), `format(pp)`, `controlEase(pp)`, `luckMultiplier(pp, rank)`, `mira(ppControl, rod)`.
- **PlayerData**: `training = { control = number, instinct = number, field = 1..10, island = 1..4 }`. Esquema v3 + migração (ver §11).
- **Servidor** soma PP uma vez por segundo, com limite (nenhum salto maior que o ganho possível); compra do campo por remote `TrainingBuyField` (valida moeda, PP e nível atual; `requestId` + versão como no aquário); viagem de ilha valida o gate. O cliente só desenha.
- Atributos espelhados (`Train_Control_PP`, `Train_Instinct_PP`, `TrainField`, `TrainIsland`); `FishingUpdate`/cálculo de mira leem o PP no servidor.
- Telemetria: PP por hora, compras de campo, tempo parado treinando, cruzamentos de patamar.
- Precisão: PP é `double`; no teto de 1e15 a parte fracionária é desprezível; clamp no teto. Armazenar como número (não string).
- Contrato novo `docs/TREINO-PP-CONTRATO.md` antes de qualquer código.

## 9. Cliente / UI (U, Codex)

- HUD do treino: número grande do Poder (cor de patamar), abaixo "+X/s", barras separadas de Controle e Instinto, multiplicadores ("campo x95 · ilha x12 · prestígio x1,5").
- Painel do campo: nível atual, próximo (custo, PP exigido, ganho de multiplicador, prévia em 3D), botão comprar com confete.
- Pop-ups de ganho, cruzamento de patamar, argola com "+30 s de ganho".
- Preview do efeito na pesca: "Mira 56% · +1 faixa verde" com a barra de força miniatura.
- Mobile: números em `TextScaled` com `UITextSizeConstraint`; nada embaixo do botão de pular nem da hotbar.
- Strings novas em `StringsUi`.

## 10. Arte (A, Antigravity)

- Kit `TrainingLevels` (10 níveis do campo) com builder e âncoras (padrão do aquário); sem z-fighting; peças leves (≤ ~250 por nível, 2 a 5 emissores, 1 a 2 luzes).
- 3 ilhas novas de treino (Recife, Abismo, Celestial) com `TrainingSpot`, atravessáveis, longe do hub, com portal/barco.
- Só depois da aprovação e do contrato. Um MD de prompt para isso eu escrevo na fase seguinte (não pedido agora).

## 11. Migração dos jogadores atuais

`PP = 10 ^ (0,6 x nível)`: nível 0 → 1, nível 10 → 1 M, nível 25 → 1 Qa (mesmo efeito de hoje, por construção). XP parcial descartado. `field = 1`, `island = 1`. Reversível por backup do perfil antes de migrar (padrão do projeto).

## 12. Fases

| Fase | Quem | Entrega |
|---|---|---|
| T0 | João | Aprovar este plano (escala, cores, custos, ilhas) |
| T1 | Claude | `Config/Training.luau` v2 + testes de lógica + `training-sim` calibrado com o `economy-sim` |
| T2 | Claude | Servidor (ganho por segundo, compra do campo, gates, migração) + contrato |
| T3 | Codex | HUD de números, cores, pop-ups, painel do campo (com mock) |
| T4 | Antigravity | Kit do campo (10 níveis) no Studio |
| T5 | Antigravity + Claude | Ilhas 2 a 4 (depois de o hub estar estável) |
| T6 | Claude + Codex | Ligar à mira da barra de força do plano de pesca |
| T7 | Todos | Play, celular, 2 jogadores; flag `TrainingPower` desligada até lá |

## 13. Riscos

- **Frustração por moeda:** treinar para de pescar. Mitigação: ver o gargalo no §6; ajustar custo/renda.
- **Números enormes cansam:** ritmo de pop-ups limitado; só cruzamentos e argolas geram texto grande.
- **Precisão e teto:** 1e15 cabe em `double`; teto bem definido.
- **Conflito com o plano de pesca:** a "mira" passa a vir do PP (§3); P2 do plano de pesca lê isso.
- **Arte:** campo de 10 níveis é muito mapa; fazer por kit e reaproveitar peças.
- **Prestígio:** reseta algo? Decidir (recomendação: não zera PP, só multiplica o ganho).

## 14. Decisões abertas (nenhuma trava)

1. Dois PP (Controle e Instinto) com soma no HUD ok, ou prefere **um PP único**? (recomendo dois: dá escolha)
2. Custos de campo e gates de PP (§5) como ponto de partida?
3. Ilhas liberadas só por PP (sem moeda)? (recomendo sim)
4. Prestígio multiplicar o ganho, sem zerar PP?

Não testado: nada (planejamento + simulação em Node). Li `Config/Training`, `Zones`, `Rods`, `Prestige`, `docs/ECONOMIA-2026-11-18.md` e `PLANO-TREINAMENTO.md`.

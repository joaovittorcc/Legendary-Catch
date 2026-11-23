# Contrato: Poder de Pesca (treino v2)

Estado (23/11/2026): **servidor pronto, atrás da flag `TrainingPower`** (atributo do `ReplicatedStorage`, desligado). Plano: `docs/PLANO-TREINO-PODER.md`. Dono do visual: Codex.

## 1. Ligar para testar

```lua
game.ReplicatedStorage:SetAttribute("TrainingPower", true)
```

Desligada, o treino de nível 0–25 e XP continua igual. Os perfis já ganham o campo `power` (migrado do nível: `10^(0,6 x nível)`) e `trainingField = 1`, mesmo com a flag desligada.

## 2. Dados

| Onde | Campo | O que é |
|---|---|---|
| Perfil / snapshot | `training[stat].power` | Poder do treino (1 a 1e15). `stat` = `Control` ou `Instinct` |
| Perfil / snapshot | `trainingField` | Nível do campo de treino (1 a 10) |
| Atributo do jogador | `Train_Control_PP`, `Train_Instinct_PP` | Poder atual de cada treino |
| Atributo do jogador | `TrainField` | Nível do campo |
| Atributo do jogador | `Train_<stat>_Level` / `_XP` | Com a flag ligada, **derivados do poder** (para a UI antiga continuar andando) |
| Atributo da peça `TrainingSpot` | `TrainingIsland` | Ilha do ponto (1 = lagoa do hub, 2 a 4 = ilhas novas). Sem atributo = 1 |

Número do HUD ("Poder de Pesca") = soma dos dois poderes.

## 3. Eventos (`TrainingUpdate`, servidor → cliente)

| `event` | Campos | Quando |
|---|---|---|
| `power` | `stat`, `power`, `gain` | A cada segundo treinando (ganho por segundo atual em `gain`) |
| `powerMilestone` | `stat`, `power`, `milestone` | Cruzou uma potência de 10 (1e3, 1e4, ...): hora do "NOVO PATAMAR" |
| `levelUp` | `stat`, `level` | Nível derivado subiu (compatibilidade) |
| `dailyBonus` | `stat`, `gain` | Primeiro treino do dia (60 s do ganho atual) |
| `ringResult` | `stat`, `combo`, `gain` | Argola acertada (30 s do ganho x combo) |
| `islandLocked` | `island`, `gate` | Tentou treinar numa ilha sem poder suficiente (`gate` = soma exigida) |
| `fieldResult` | `ok`, `reason`, `field`, `requestId`, `gate` | Resposta da compra do campo |

`reason` do `fieldResult`: `max`, `power` (com `gate`), `coins`, `changed` (algo mudou no meio; tente de novo), `disabled` (flag desligada).

## 4. Comprar o campo (cliente → servidor)

`TrainingBuyField (requestId: number)`. O servidor confere nível, moedas e poder (soma) e cobra. Tabela em `Config/Training.luau` (`FIELD`: multiplicador, custo, poder exigido).

## 5. Funções prontas para a UI (`Config/Training.luau`)

- `formatPower(valor, ",")`: "12,3K", "1,23M", "1Qa" (arredonda antes do sufixo, nunca "1000K").
- `tier(poder)`: 1 a 7. `TIER_COLORS[tier]`: creme, verde-água, azul, roxo, rosa neon, dourado, arco-íris (o 7 é o teto: a UI desenha o gradiente).
- `progress(poder)` 0..1, `multiplier(campo, ilha, prestígio)`, `gainPerSecond(poder, mult)`, `canBuyField(nível, soma, moedas)`, `islandAllowed(ilha, soma)`.
- Contador: anime o **logaritmo** do valor (vault fwjelaa, "Big Numbers"), senão ele fica parado no sufixo final.

## 6. Regras de servidor

- Poder sempre finito, de 1 ao teto 1e15 (cabe exato num double).
- Prestígio **não zera** o poder nem o campo com a flag ligada; multiplica o ganho (x1,25 por nível de prestígio).
- Ganho só enquanto treina parado no ponto (como hoje).
- Sorte e facilidade da pesca usam `p = log10(poder) / 15` na escala antiga 0–25: o equilíbrio de hoje fica igual nas pontas.

## 7. Testes

- `tools/training-power-test.luau` passou no Studio em 23/11, com o módulo injetado (Studio sem Rojo sincronizado).
- Ritmo: `node tools/training-sim.js` (teto em ~116 h de jogo com 50% treinando).
- **Não testado em Play**: ganho por segundo, compra do campo, bloqueio de ilha, migração do perfil real, prestígio com a flag ligada.

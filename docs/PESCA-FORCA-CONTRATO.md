# Contrato: barra de força no arremesso + "1 em N" real

Estado (23/11/2026): **servidor pronto, atrás da flag `FishingPower`** (atributo do `ReplicatedStorage`, desligado). Plano: `docs/PLANO-PESCA-FORCA-ODDS.md`. Dono do visual: Codex.

## 1. Ligar para testar

No Studio, em Edit ou no Server do Play:

```lua
game.ReplicatedStorage:SetAttribute("FishingPower", true)
```

Desligada, tudo continua como antes: sem barra, sorte igual, sem teto de sorte.

## 2. Fluxo

1. O cliente manda `CastLine` (como hoje).
2. Com a flag ligada (e **fora da primeira pesca do tutorial**), o servidor responde `FishingUpdate { event = "aim", castId, aimStart, aimSweep, aimLevel, aimLayout }`.
   - `aimStart`: `workspace:GetServerTimeNow()` quando o ponteiro saiu do 0.
   - Posição do ponteiro = `FishingConfig.aimPosition(workspace:GetServerTimeNow() - aimStart)` (vai e volta, `aimSweep` = 1,1 s por passada).
   - `aimLayout`: lista `{ band, from, to }` cobrindo 0..1 da esquerda para a direita (simétrica). Bandas: `red`, `yellow`, `neutral`, `green`, `purple` (1 ou 2 faixas roxas).
   - `aimLevel` 0..1: quanto a mira está treinada (Poder de Controle + vara). Só informativo.
3. O jogador toca. Cliente manda `PowerTap (castId, workspace:GetServerTimeNow())`. O servidor aceita esse horário só se estiver entre `agora - 0,2 s` e `agora` (latência); fora disso usa o próprio relógio.
   - Sem toque em 3,5 s: arremesso em `red`.
4. Servidor responde `FishingUpdate { event = "cast", castId, powerBand }` e segue o fluxo normal (espera, `bite`, minigame).
5. Na vitória, `caught` traz `odds` = "1 em N" **real** da captura (sorte e faixa incluídas). `nil` = não mostrar (pesca do tutorial).

O cliente nunca decide a faixa. Se o jogador sair do lugar do arremesso durante a mira, o servidor manda `cancelled`.

## 3. Efeito da faixa

`fator = 1 + b x (rank - 1)`, só de Incomum (rank 2) para cima, piso 0,2.

| Faixa | b | Lendário (rank 5) |
|---|---|---|
| red | -0,08 | x0,68 |
| yellow | -0,04 | x0,84 |
| neutral | 0 | x1 (igual a hoje) |
| green | +0,10 | x1,40 |
| purple | +0,25 | x2,00 |

Com a flag ligada, a sorte total (treino x vara x prestígio x evento x zona x boost x faixa) tem teto por raridade: `LUCK_CAP = { 1, 2,5, 3,5, 4,5, 6, 8 }` (Comum .. Mística). **Isso reduz um pouco a sorte do fim de jogo com a vara Mística**: é proposital, para o empilhamento não explodir.

## 4. Anti-trapaça

- O servidor guarda as últimas 20 faixas. Se mais de 60% forem roxas, ele para de confiar no horário do cliente (usa o próprio relógio) e marca suspeita.
- Auto-Fish não usa a barra (sempre neutro).

## 5. O que o Codex faz (P3/P4)

- `src/client/Features/Fishing/PowerBar.luau` existe como **placeholder funcional** (barra simples, ponteiro, palavra da faixa). Pode restilizar ou trocar, mantendo `show(layout, aimStart)`, `result(band)` e `hide()`.
- Cutscene de arremesso (plano §4), "PERFEITO!" no roxo, anel d'água na cor da faixa (`powerBand` do evento `cast`).
- Momento das chances (plano §5): ler `odds` do `caught`. **Trocar o uso de `Fishing.baseOdds` no `RevealCard.luau`** pelo `odds` do payload (o antigo assume chance igual dentro da raridade, o que não é mais verdade).
- Textos já existem em `Strings.powerTap` e `Strings.powerBand[band]` (PT/EN).

## 6. Testes

- `tools/power-bar-test.luau` (matemática da barra) e `tools/drop-test.luau` (sorteio e odds): passaram no Studio em 23/11 com as funções injetadas, porque o Studio não estava sincronizado com o Rojo.
- **Não testado em Play**: o fluxo `aim → PowerTap → cast` e o teto de sorte rodando no servidor. Testar com a flag ligada, 2 jogadores e celular antes de liberar.

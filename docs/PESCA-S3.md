# Pesca e eventos — S3 (servidor)

[Plano Claude](PLANO-AQUARIO-CLAUDE.md) · [Economia S0](ECONOMIA-AQUARIO-S0.md) · [Contrato do aquário](AQUARIO-CONTRATO.md)

Escrito em 2026-11-22. Implementado no servidor e no controlador, **ainda sem Play** (Rojo não sincronizou no Studio). Ver "Não testado" no fim.

## 1. Decisões de regra (valem desde este commit)

| Tema | Regra |
|---|---|
| Evento que termina durante uma luta | O evento ativo **na mordida** decide o bônus de valor da captura. Se acaba durante a luta, a captura ainda paga o bônus; se começa durante a luta, não paga. A criatura (inclusive exclusiva de evento) já foi sorteada na mordida. A pesca automática trava o evento na hora do sorteio. `caught.eventId` diz qual bônus valeu. |
| Portal do evento | **Cenografia**: abre e fecha com o evento, não teletransporta. Zonas dependem de nível (`Config/Zones`), não de evento. Criaturas exclusivas = `Config/Creatures` com `event == <id>`, só rolam com aquele evento ativo. |
| Estado dos eventos | `ReplicatedStorage`: `OceanEvent` (id ou ""), `OceanEventEndsAt` (fim), e novo `OceanEventNextAt` (próximo sorteio, `GetServerTimeNow()`). Pode ser pulado se outro evento estiver rodando. |
| Combo | Só pesca manual avança. Quebra em: escape, luta perdida, tempo esgotado (45 s), cancelar. Pesca automática não mexe no combo. Bônus de moedas segue +3% por captura até +30%. |
| Marcos do combo | `caught.comboMilestone` = 3, 5 ou 8 quando a captura alcança um desses tamanhos (só efeito visual/sonoro). `escaped`/`cancelled` trazem `comboLost` (tamanho >= 3 que acabou de ser perdido). |
| Raridade na cena | Já sai na mordida (`bite.rarity`), junto com `kind` e `tier`. É o momento autorizado para pintar boia, água e linha; nada de espécie nem variante antes da captura. |

## 2. Empilhamento de multiplicadores (por captura)

Valor = `baseValue × peso (0,75–1,25) × Cintilante ×3 × evento × VIP × prestígio × (1 + combo)`.

| Fator | Máximo hoje |
|---|---:|
| Evento | ×2,0 (Hora Dourada), ×1,15 a ×1,5 nos outros |
| Passe VIP (IDs ainda 0, não vendido) | ×1,25 |
| Prestígio nível 10 | ×2,0 (+10% por nível) |
| Combo | ×1,30 |
| Cintilante (1 em 40) | ×3 |

Teto sem Cintilante: **×6,5**; com Cintilante: **×19,5**. Os tetos existentes foram mantidos; nada foi alterado. A renda do aquário **não** recebe nenhum desses multiplicadores (taxa fixa por criatura, ver Economia S0), então eles só inflam o prêmio de captura.

## 3. Pesca automática x manual (achado)

Estimativa pela mesma tabela da simulação (manual 13 s por captura e 85% de vitória **[premissa]**, auto = mordida 2–5 s + luta mínima ×1,5 + 1 s de espera, 80–85% de sucesso, sem combo, teto Épica):

| Vara | Manual (moedas/min) | Auto (moedas/min) | Auto / manual |
|---|---:|---:|---:|
| Inicial | 326 | 391 | 1,20 |
| Astral | 479 | 519 | 1,08 |
| Mística | 614 | 634 | 1,03 |

O passe de pesca automática rende **igual ou mais** que jogar, só perde Lendárias e Místicas. Isso esvazia a pesca ativa para quem comprar. O passe ainda não está à venda (ID 0), então dá para corrigir sem prejudicar ninguém. **Proposta (decisão do João):** alongar o ciclo do auto em ~7 s (por exemplo, +6 s de espera por captura) para ficar em ~60% do manual. Não alterei: mexe em produto pago.

## 4. Calibração dos minigames

**Não calibrei os números de `Config/Fishing`.** Não há medição de duração e vitória por modo/tier/dispositivo (o Codex mediu só falha total no tier 1: Reel 15,4 s, Precision 18,4 s, Rhythm 13,2 s). Calibrar sem dados seria chute. Em vez disso:

- O servidor agora registra um evento de telemetria por luta julgada: `FishingFight` (Creator Hub > Analytics > Custom Events). `value` = duração em segundos, `CustomField01` = modo (`reel`/`precision`/`rhythm`), `CustomField02` = `tier1`..`tier6`, `CustomField03` = `win` / `lose` / `timeout`.
- Com uma semana de dados dá para ler taxa de vitória e duração por modo e tier e ajustar `ZONE`/`WINDOW`/`rings` por tabela. Alvo sugerido até medir: vitória ~85% no tier 1, ~60% no tier 5, ~45% no tier 6, 8–15 s de luta.
- Para PC x toque: o servidor não sabe o dispositivo. O Codex precisa medir com toque no Studio ou eu adiciono o tipo de entrada no `SubmitCatch` (pedido no Mural se quiserem).

## 5. Correções no controlador (pedido do Codex)

- `startCast`: o aviso "aguardando" só aparece se o estado ainda é `waiting` e a linha é a mesma depois de `Line.castTo` (podia sobrar após cancelar ou morder).
- `onEscaped`: minigame, entrada e painel são limpos **no início** do escape; só a linha e o toast esperam 0,6 s. Se um `cancelled` ou novo lance chegar nesse intervalo, o `cleanup()` final é ignorado.

## 6. Não testado

Play no Studio, dois clientes, evento terminando durante uma luta e telemetria no painel. Lint (StyLua/Selene/luau-lsp) passou; os 3 erros antigos do luau-lsp (`PlayerData:382`, `Achievements`) continuam.

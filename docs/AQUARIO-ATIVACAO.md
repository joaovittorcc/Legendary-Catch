# Aquário — S4: ativação, recuperação e rollback

[Plano Claude](PLANO-AQUARIO-CLAUDE.md) · [Contrato](AQUARIO-CONTRATO.md) · [Economia S0](ECONOMIA-AQUARIO-S0.md)

Escrito em 2026-11-22. Estado: **código pronto e commitado, nada rodou em Play** (Rojo nunca sincronizou no Studio). Este documento diz o que ligar, em que ordem e como voltar atrás.

## 1. Flags (três, independentes)

| Flag | Atributo em `ReplicatedStorage` | O que controla | Padrão |
|---|---|---|---|
| UI | `AquariumUI` | `snapshot.aquarium.status = "disabled"` e todos os remotes respondem `disabled` | Studio ligado; **servidor publicado desligado** até `LIVE_ENABLED = true` |
| Crédito | `AquariumCredit` | Renda passiva online. Desligado: o intervalo é descartado, nunca pago depois | idem |
| Offline | `AquariumOffline` | Pagamento offline na entrada (25% da taxa salva na saída, até 2 h, uma vez) | **desligado em todo lugar** até o atributo ser `true` |

Um atributo booleano explícito vence o padrão. `Config/Aquarium.LIVE_ENABLED` (hoje `false`) é o padrão dos servidores publicados: ligar significa editar essa constante e publicar (ainda não há canal de configuração ao vivo; `ConfigService` é uma opção futura).

## 2. Ordem de ativação recomendada

1. **Studio, sincronizado:** rodar `tools/aquarium-test.luau` (execute_luau, Edit) e um Play com dois clientes: capturar, colocar, trocar, retirar, comprar nível, resgatar meta, reconectar.
2. **Servidor de teste publicado** com `LIVE_ENABLED = false` e os atributos ligados manualmente por um script de servidor: primeiro **UI**, depois **Crédito**.
3. **Publicar com `LIVE_ENABLED = true`** quando o Codex tiver a UI e o Antigravity o tanque físico.
4. **Offline:** só depois de duas semanas de dados reais de renda (ver seção 5).

## 3. Recuperação e rollback

| Situação | O que acontece | Como voltar |
|---|---|---|
| Crédito com bug | Desligar `AquariumCredit`: renda para; coleção, vagas, níveis, metas e cosméticos ficam intactos | Religar: a renda retoma de um relógio novo, sem retroagir |
| UI com bug | Desligar `AquariumUI`: cliente vê `disabled`; servidor recusa remotes; o perfil continua sendo atualizado (capturas seguem contando no inventário) | Religar |
| Migração suspeita | A migração é idempotente (`migrated`) e só roda se faltar; um perfil com `aquarium` válido nunca é refeito | Restaurar o perfil pelo painel de dados do Roblox |
| Perfil de versão mais nova | O carregamento recusa e kicka (já era assim) | Atualizar o servidor |
| Cliente antigo | Ignora `aquarium` (campo novo e aditivo) | Nada |

Saída inesperada: o último intervalo é pago **antes** de liberar o perfil (`PlayerData.onBeforeRelease`), e taxa e hora de saída ficam salvas. Perda possível só em queda do servidor (até um intervalo de 5 s de renda, ~0,1 moeda por vaga ativa).

## 4. Telemetria (Creator Hub > Analytics)

| Evento | Tipo | Campos |
|---|---|---|
| Moedas ganhas | Economy source | `Aquarium` (renda online), `AquariumOffline` (retorno), `AquariumSessionGoal` |
| Moedas gastas | Economy sink | `AquariumLevel` (SKU = id do nível) |
| Funil | Onboarding | passo 14 `firstTankPlace`, passo 15 `firstTankUpgrade` |
| `AquariumChange` | Custom | valor = renda total (cpm) após a mudança; campos `op`, `lvN`, `synN` (famílias presentes) |
| `AquariumUpgrade` | Custom | valor = custo; campo = id do nível |
| `FishingFight` | Custom | valor = duração (s); modo, `tierN`, resultado |

Sem dado pessoal. Cardinalidade baixa de propósito. Versão dos parâmetros: `Config.Aquarium.PARAMS_VERSION` (hoje 1); mudar taxas ou preços significa subir esse número e registrar a data aqui.

## 5. Proposta de renda offline (para o João decidir)

- **Regra:** 25% da taxa que o tanque tinha na saída, no máximo 2 horas por ausência, paga uma vez na entrada, taxa fixada na saída (nunca retroativa). Com a economia do S0 (×0,2), um tanque de 2 moedas/s rende 3.600 moedas em 2 h offline, perto de 7,5 min de pesca com Astral.
- **Risco principal:** jogadores com tanque de fim de jogo (até ~30 moedas/s) recebem até ~54 mil moedas por ausência de 2 h. Mitigar com teto de moedas por ausência (sugestão: 10 mil) ou 10% em vez de 25%.
- **Pré-requisitos antes de ligar:** teste de saída inesperada e duas sessões, dados de produção do online por duas semanas, decisão sobre o teto.

## 6. Parâmetros desta versão (registro)

`PARAMS_VERSION 1`: taxas = faixas do plano ×0,2 em cpm; níveis 3/5/8/12 vagas por 0/3.000/12.000/50.000; requisito de espécies 15/40/70 (provisório); sinergia 2 espécies +5%, 3+ +10%; metas de renda 1.000/2.500/6.000/12.000/25.000/50.000 cpm; metas de sessão 40/60/100 moedas, teto 600/dia; pagamento em lote a cada 5 s; offline 25%/2 h (desligado). Evidências: simulação em `docs/ECONOMIA-AQUARIO-S0.md`.

## 7. Ainda não verificado

Tudo acima com servidor real: Play, dois clientes, reconexão, saída inesperada, flags ao vivo, painel de telemetria. Os testes puros cobrem regras, migração, concorrência por versão, troca de taxa entre dois ticks, offline e perfis hostis, mas **não rodaram** (precisam do Rojo sincronizado).

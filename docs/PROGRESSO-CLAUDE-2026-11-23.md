# Onde o Claude parou (23/11/2026)

Parei a pedido do João porque o Antigravity assumiu o Studio. `.studio-lock` removido, Play parado, nada salvo no place (`save_place` não foi chamado).

## Entregue e commitado (tudo atrás de flags desligadas, sem push)

| Commit | O que |
|---|---|
| `cdd0888` | Chance por criatura (`dropWeight` nas 106) e "1 em N" real no `caught` |
| `5a9a4b0` | Poder de Pesca (`TrainingPower`) e barra de força no servidor (`FishingPower`) |
| `0059716` | 100 criaturas novas (C107–C206) pré-cadastradas em `Creatures.PLANNED`, com taxa/família do aquário e nomes PT/EN |
| `95de85a`, `97e7b20` | Prompts do Codex e plano visual de referência |
| `5f80ef2` | Barra vertical (`PowerBar.luau`) e momento das chances (`OddsMoment.luau`) |
| `08aba7b` | Roleta da captura (servidor + UI), flag `FishingRoulette` |
| `9863fd8` | Polimento da roleta (efeitos de tela, cores vivas) |

Docs principais: `PLANO-PESCA-FORCA-ODDS.md`, `PLANO-TREINO-PODER.md`, `PLANO-ROLETA.md`, `PLANO-VISUAL-REFERENCIA.md`, `PESCA-FORCA-CONTRATO.md`, `TREINO-PP-CONTRATO.md`, `CRIATURAS-ODDS-E-LISTA.md`, `prompts-antigravity/`.

## Não verificado

- **Roleta polida v2 não foi vista funcionando.** A gravação v2 saiu sem a roleta (o Studio ainda não tinha o módulo `Config.Roulette`, o Rojo não o criou sozinho). Recriei esse módulo à mão no Studio (Edit) e voltei ao teste real, mas parei antes de ver o resultado.
- **Fluxo real do servidor nunca rodou em Play:** `aim → PowerTap → cast`, o "1 em N" no `caught`, a roleta vinda do servidor, ganho do Poder de Pesca, compra do campo, migração de perfil.
- Celular, 2 jogadores e desempenho.

## Estado do Studio (para quem for mexer)

- `ReplicatedStorage.Shared.Config.Roulette` existe agora no place **só no Edit, sem salvar** (criado à mão). Se o Rojo sincronizar, ele substitui. Se o place for salvo sem Rojo, esse módulo fica lá igual ao arquivo do repositório.
- As flags `FishingPower`, `FishingRoulette` e `TrainingPower` ficaram **desligadas** (foram ligadas só dentro de um Play, que já terminou).
- Sem demo nem GUI de teste sobrando no Studio.

## Para retomar

1. Com o Rojo sincronizado, dar Play, ligar `FishingPower` e `FishingRoulette` no Server e pescar de verdade (`DevForceRarity`, `DevForceMinigame`). Conferir barra, contagem e roleta.
2. Regravar a roleta v2 e ajustar o que aparecer.
3. Codex: restilizar por cima (sons, cutscene do arremesso, revelação com mutação/peso) e HUD do Poder (ver `PROMPT-CODEX-PODER-E-BARRA.md`).
4. Antigravity: 4 lotes de criaturas e campo/ilhas (`prompts-antigravity/`).

Pendências de git: Mural (`docs/COORDENACAO.md`) e `art/preview/` sem commit.

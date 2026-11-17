# Plano do Claude Code — sistemas (noite de 2026-11-17)

> Prompt de trabalho do Claude. Leia junto com `docs/COORDENACAO.md` (contrato + regras com o Codex)
> e `CONTEXTO_MESTRE.md`. O Codex faz o visual em paralelo, na mesma pasta.

## Papel
Servidor, dados, economia, regras e contratos. Publicar tudo que a UI precisa (seção 4 do contrato) **antes** do Codex precisar, com tipos e mocks claros. Não mexer nos arquivos do Codex.

## Regras
- Mesmas regras do contrato: `git add` só meus arquivos, `stylua` só meus caminhos, sem push, lock do Studio.
- Servidor é autoridade; validar tudo que chega de remote (tipo, faixa, existência, posse, cooldown).
- Campo novo de perfil é aditivo; migração preenche o que falta, nunca sobrescreve.
- Definition of done: stylua + selene + luau-lsp limpos, Play no Studio quando der, commit pequeno, Mural atualizado.

## Backlog (em ordem)

| # | Entrega | Status |
|---|---|---|
| B1 | Loader de features no cliente (`order` + `start`), `shared/Types.luau`, `client/Data` (snapshot + changed), `server/Features/PlayerData` (perfil em memória com API estável) | |
| B2 | Persistência real do perfil — **aguardando OK do João para ProfileStore (Wally)**; sem OK, fica em memória | |
| B3 | Economia: `baseValue` e faixa de peso por criatura; peso sorteado no servidor; moedas creditadas; `caught` com `weight`, `value`, `isNew`, `count` | |
| B4 | Coleção no perfil (count, bestWeight, firstAt) + `stats` | |
| B5 | Varas: `Config/Rods`, `BuyRod`/`EquipRod`/`ShopResult`, bônus de Controle/Sorte da vara na pesca, `Rod` Tool reconstruído pela vara equipada, `ProximityPrompt` `OpenWorkshop` na oficina (tag `WorkshopSpot`) | |
| B6 | Treino no perfil (níveis persistem com o perfil) | |
| B7 | Eventos do oceano: `Config/Events`, agendador no servidor, `OceanEvent`/`OceanEventEndsAt`, bônus de raridade durante o evento | |
| B8 | Estado de pesca replicado para outros jogadores (atributos no Character) | |
| B9 | Anti-trapaça (rate limit em todo remote), analytics de funil (primeira pesca, primeira captura, primeira compra) | |
| B10 | `revealStyle` por criatura + lore em `Strings` | |

## Decisões em aberto (perguntar ao João)
- ProfileStore (dependência Wally) para salvar o perfil.
- Valores da economia (preços de vara, valor das criaturas) — números iniciais são chute.

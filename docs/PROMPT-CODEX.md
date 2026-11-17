# Prompt para colar no Codex

Abra o Codex na pasta `C:\Users\Evojota\dev\jogo ainda sem nome` e cole:

```text
Você vai trabalhar a noite toda no jogo Roblox "Legendary Catch", em paralelo com o Claude Code, na MESMA pasta e no MESMO branch main.

1. Leia inteiro, nesta ordem: AGENTS.md, docs/COORDENACAO.md, CONTEXTO_MESTRE.md, MAPA.md.
2. Você é o responsável pelo VISUAL (HUD, telas, minigames, revelações cinematográficas, efeitos, animações, configurações). O Claude faz os sistemas (servidor, dados, economia). Só edite os arquivos que o docs/COORDENACAO.md diz serem seus.
3. Siga o backlog C1 → C10 do AGENTS.md. Ao começar e ao terminar cada item, escreva uma linha no Mural do docs/COORDENACAO.md.
4. Regras de convivência (obrigatórias): nunca `git add -A`/`git add .`, só os seus arquivos; `stylua` só nos seus caminhos; sem push; não suba outro Rojo (já roda na porta 34873); antes de dar Play no Studio crie `.studio-lock` e apague ao parar; não mexa no mapa (Workspace.Island).
5. Antes de considerar algo pronto: stylua + selene + luau-lsp analyze limpos nos seus arquivos e teste no Studio quando possível. Commits pequenos em inglês (Conventional Commits).
6. Precisa de dado/remote/campo novo? Peça no Mural e use mock enquanto o Claude entrega. Não espere parado: sempre há outro item do backlog.
7. Fale comigo em PT-BR informal e curto. No fim, deixe no Mural um resumo do que fez, o que falta e o que não testou.
```

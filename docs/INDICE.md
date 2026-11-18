# Índice de Documentação — Legendary Catch

Mapa completo dos documentos da raiz e de `docs/` para orientar o desenvolvimento, publicação e operação pós-lançamento.

---

## Documentos da Raiz

| Documento | Status | Resumo (1 linha) |
|---|---|---|
| [README.md](../README.md) | Ativo | Visão geral do projeto, features implementadas, setup com Rokit/Rojo, estrutura e guia de extensão. |
| [CONTEXTO_MESTRE.md](../CONTEXTO_MESTRE.md) | Referência | Visão original do jogo, público-alvo, estilo visual e decisões de design iniciais. |
| [MAPA.md](../MAPA.md) | Referência | Descrição visual das áreas da ilha principal gerada por `tools/IslandGenerator.luau`. |
| [AGENTS.md](../AGENTS.md) | Referência | Regras de engenharia, armadilhas do Roblox/Luau e instruções de trabalho para agentes de código. |

## Documentos Técnicos e Operacionais (`docs/`)

| Documento | Status | Resumo (1 linha) |
|---|---|---|
| [INDICE.md](INDICE.md) | Ativo | Este índice com o resumo e status de todos os documentos do repositório. |
| [PUBLICAR.md](PUBLICAR.md) | Ativo | Checklist completo pré-publicação (API Services, Creator Hub, IDs de `Products.luau`, limpeza de `Dev*`). |
| [PAGINA-DO-JOGO.md](PAGINA-DO-JOGO.md) | Ativo | Título, descrições PT/EN, tags, checklist de artes (`art/marketing/`) e 10 ideias de divulgação. |
| [CRIATURAS-NOVAS.md](CRIATURAS-NOVAS.md) | Ativo | Fluxo padrão para criar, orientar (`+Z`), normalizar e animar novas criaturas em `ReplicatedStorage.Creatures`. |
| [AUDIO.md](AUDIO.md) | Ativo | Tabela completa dos 14 `Sound`s em `ReplicatedStorage.Audio` (`rbxassetid`, volume, loop e uso). |
| [PERFORMANCE.md](PERFORMANCE.md) | Ativo | Auditoria de cena e loops em mobile fraco (`750×381`) com otimizações aplicadas e riscos pendentes. |
| [BUGBASH.md](BUGBASH.md) | Ativo | Roteiro e resultados do Bug Bash E2E no Play (3 bugs corrigidos e pontos pendentes para aparelho real). |
| [ECONOMIA-2026-11-18.md](ECONOMIA-2026-11-18.md) | Ativo | Simulação econômica (`node tools/economy-sim.js`) cobrindo varas, místicas, auto-pesca e zonas. |
| [ATUALIZACOES.md](ATUALIZACOES.md) | Ativo | Cronograma de 8 semanas de atualizações pós-lançamento (eventos, criaturas, varas e códigos). |
| [LIMPEZA.md](LIMPEZA.md) | Ativo | Auditoria de código morto, `TODO`s, mojibake, segredos e `.gitignore` antes da abertura no GitHub. |
| [COORDENACAO.md](COORDENACAO.md) | Ativo | Divisão de arquivos entre agentes, regras de convivência e Mural cronológico de entregas. |

## Histórico de Planejamento e Prompts (Obsoletos)

> Documentos preservados apenas como registro histórico da maratona de criação (`2026-11-17` a `2026-11-18`); **não** refletem tarefas pendentes nem substituem o código atual.

| Documento | Status | Resumo (1 linha) |
|---|---|---|
| [PLANO-CLAUDE.md](PLANO-CLAUDE.md) | Histórico (obsoleto) | Plano inicial de sistemas do coordenador na primeira noite de desenvolvimento. |
| [NOITE.md](NOITE.md) | Histórico (obsoleto) | Backlog da primeira madrugada (`2026-11-17`) dividido entre os três agentes. |
| [PLANO-NOITE-2.md](PLANO-NOITE-2.md) | Histórico (obsoleto) | Plano da segunda noite (`2026-11-18`, itens de retenção, dopamina, áudio e marketing). |
| [RESUMO-MANHA.md](RESUMO-MANHA.md) | Histórico (obsoleto) | Resumo de status entregue ao final da noite 1 (`2026-11-17`). |
| [RESUMO-MANHA-2.md](RESUMO-MANHA-2.md) | Histórico (obsoleto) | Resumo de status entregue ao final da noite 2 (`2026-11-18`). |
| [PROMPT-ANTIGRAVITY.md](PROMPT-ANTIGRAVITY.md) | Histórico (obsoleto) | Prompt de recuperação e padronização usado pelos agentes 3D de criaturas. |
| [PROMPT-CODEX.md](PROMPT-CODEX.md) | Histórico (obsoleto) | Prompt inicial colado para o agente de visual/UI. |
| [URGENTE-ANTIGRAVITY.md](URGENTE-ANTIGRAVITY.md) | Histórico (obsoleto) | Instrução emergencial de recuperação de modelos após reinício inesperado do PC. |

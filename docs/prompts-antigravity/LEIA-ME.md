# Prompts das 100 criaturas novas (Antigravity)

Abra 4 conversas de agente na pasta do jogo e cole **um texto por conversa**.

| Lote | Arquivo | Criaturas |
|---|---|---|
| 1 | `CRIATURAS-LOTE-1-MISTICAS-E-LENDARIAS.md` | 30 (mais detalhado) |
| 2 | `CRIATURAS-LOTE-2-EPICAS.md` | 20 |
| 3 | `CRIATURAS-LOTE-3-RARAS-E-INCOMUNS.md` | 25 |
| 4 | `CRIATURAS-LOTE-4-INCOMUNS-E-COMUNS.md` | 25 |

Texto para colar (troque o número e o nome do arquivo):

```text
Leia docs/prompts-antigravity/<ARQUIVO>.md inteiro e execute o lote <N>. Siga as regras do cabeçalho, incluindo o .studio-lock.
```

Lembretes: só um Studio aberto (place 112666482424701); cada agente mexe só nos IDs do seu lote; `save_place` a cada 3 a 5 criaturas; se os 4 travarem esperando o lock, rode um por vez começando pelo lote 1.


## Ilhas de treino: conceitos (3 agentes, 4 imagens cada)

Etapa de **conceito**, antes de construir. Cada agente gera 4 imagens da sua ilha; o João escolhe uma e só então o agente constrói no Studio.

| Agente | Arquivo | Ilha |
|---|---|---|
| 1 | `ILHA-CONCEITO-1-RECIFE.md` | Ilha do Recife (x3) |
| 2 | `ILHA-CONCEITO-2-ABISMO-ESTELAR.md` | Ilha Abismo Estelar (x12) |
| 3 | `ILHA-CONCEITO-3-CELESTIAL.md` | Ilha Celestial (x50) |

Texto para colar (um por conversa):

```text
Leia docs/prompts-antigravity/<ARQUIVO>.md inteiro e faça só o que ele pede (4 imagens de conceito e a descrição). Não abra o Studio nem construa nada.
```


## Ilhas de treino: construir (4 agentes, um por ilha)

Conceitos escolhidos pelo João em `art/concept/escolhidas/`. Cada agente constrói a sua ilha igual à imagem.

| Agente | Arquivo |
|---|---|
| 1 | `ILHA-CONSTRUIR-1-APRENDIZ.md` |
| 2 | `ILHA-CONSTRUIR-2-RECIFE.md` |
| 3 | `ILHA-CONSTRUIR-3-ABISMO-ESTELAR.md` |
| 4 | `ILHA-CONSTRUIR-4-CELESTIAL.md` |

Texto para colar (um por conversa):

```text
Leia docs/prompts-antigravity/<ARQUIVO>.md inteiro e execute. Siga o .studio-lock à risca: outros agentes usam o mesmo Studio.
```

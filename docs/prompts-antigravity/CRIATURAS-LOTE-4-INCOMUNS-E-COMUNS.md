# Criaturas — Lote 4: Incomuns (10) e Comuns (15)

Lote 4 de 4 · **25 criaturas** · para o **Antigravity**. Cole este arquivo inteiro numa conversa aberta na pasta do projeto (`C:\Users\Evojota\dev\jogo ainda sem nome`).
Cada lote tem criaturas diferentes, então os 4 agentes podem trabalhar ao mesmo tempo sem se atropelar (leia a seção 4).

## 1. Contexto

**Legendary Catch** é um jogo de pesca e coleção no Roblox (ilha mágica, minigames, revelação cinematográfica, bestiário, aquário). Quem manda é o **João**: fale em português informal e curto; nomes de objetos e código em inglês.
Você é dono dos **modelos 3D**. **Não edite** `src/**` nem registre nada em `Config/Creatures.luau` (isso é do Claude, depois que o modelo chega).
Leia antes: `AGENTS.md`, `docs/COORDENACAO.md` (Mural no fim), **`docs/CRIATURAS-NOVAS.md` (regras obrigatórias de hierarquia, escala e orientação)** e `docs/CRIATURAS-ODDS-E-LISTA.md` (raridade e chances).
As mais simples: Comuns têm 1 a 3 peças e aparecem o tempo todo (muitas vezes por minuto). Mantenha **leve e fofo**. A graça é a personalidade na carinha e nas cores.

## 2. Regras de modelo (valem para todas)

- Modelo direto em `ReplicatedStorage.Creatures`, nome = **ID exato** (ex. `C107_Relogio_do_Abismo_Eterno`). `PrimaryPart = Body`. Filhos diretos só `BasePart`/`MeshPart`; sem sub-modelos, `Humanoid`, `Motor6D`, `Weld`, scripts.
- Em **todas** as peças: `Anchored = true`, `CanCollide = false`, `CanQuery = false`, `CanTouch = false`.
- **Nomes de peça que o `CreatureMotion` anima:** `Body`, `Head`, `Tail`, `FinL`, `FinR`, `Fins`, `Wings`, `Tentacles`, `Legs`, `Claws`, `Shell`. **Qualquer outro detalhe (olhos, gemas, coroas, anéis, fitas) se chama `Extra`** (pode haver vários `Extra`; o jogo gruda cada um no membro mais próximo).
- Orientação: **frente = +Z**, esquerda = +X, topo = +Y. Pivô no centro do `Body` (`PivotOffset`).
- **Escala** (maior lado do bounding box): Comum/Incomum/Raro até 2,95 studs; Épico ~3,0–3,2; Lendário/Místico ~3,2–3,55.
- **Quantidade de peças por raridade:** Comum 1–3 · Incomum 3–5 · Raro 5–7 · Épico 7–10 · Lendário 9–12 (≥ 3 Neon) · Místico 12–15 (≥ 6 Neon). A tabela de cada criatura abaixo já traz a lista exata; siga-a.
- Material **Neon** só nas peças marcadas **Neon**. Cores vivas, estilo estilizado "aventura Roblox premium" (cristais ciano, rosa/lilás, dourado, âmbar). Nada cinza genérico, nada sombrio demais (público infantil).
- Silhueta forte e legível de longe: ela vira uma **sombra gigante** na revelação ("1 em N" crescendo). Evite peças finas demais soltas.
- Máx. ~8.000 faces por modelo (referência: C23 tinha 7.978). Texturas até 1024 px (acima disso o Roblox reduz).
- Sem texto escrito no modelo.

## 3. Como entregar cada criatura

1. Monte as peças no Studio (`execute_luau`/`generate_mesh`/montagem manual) respeitando a tabela da criatura.
2. Confira a orientação por `execute_luau` (`Head.Position.Z - Tail.Position.Z > 0`; `FinL.Position.X > FinR.Position.X`).
3. `screen_capture` de frente (câmera em +Z olhando para a origem) e salve em `art/creatures/<ID>.png`.
4. Em Play, confira que nenhuma peça gira no eixo errado nem descola do `Body` (use `CreatureMotion.bind/pose` ou dispare uma revelação).
5. **`save_place` a cada 3 a 5 criaturas (1 a 2 se forem Lendários/Místicos).** Anote a versão salva.
6. Escreva uma linha no **Mural** de `docs/COORDENACAO.md` (somente adicionando no fim): IDs prontos, versão salva, dúvidas.

## 4. Quatro agentes ao mesmo tempo (importante)

- Só existe **um** Studio aberto. Antes de mexer nele, crie `.studio-lock` na raiz do repo (conteúdo: seu lote e a hora) e **apague quando terminar** cada sessão curta. Se o lock já existir, espere e tente de novo.
- Cada agente mexe **só nas criaturas do seu lote**; não renomeie, mova ou apague modelos de outros lotes.
- Não rode Play enquanto outro agente tiver o lock. Faça sessões curtas (1 a 3 criaturas por vez).
- Se o Studio reabrir (id muda), chame `list_roblox_studios` e use a instância do place **112666482424701**.

## 5. Critério de pronto (por criatura)

- Todas as peças da tabela existem, com os nomes certos, Neon só onde marcado, sem peça solta.
- Frente +Z, pivô no centro, escala dentro da faixa, propriedades das peças corretas.
- Print salvo, `save_place` feito, Mural atualizado.
- Reconhecível pela silhueta preta. Se ficar confusa, simplifique.

---

## 6. As criaturas deste lote

### C182_Peixe_Pedra_Camuflado — Peixe-Pedra Camuflado
**Incomum** · família do aquário **Abissal** · revelação `splash` · valor base 44 · 0.3–3.3 kg · chance sem sorte 1 em 332
**Conceito:** parece rocha com olhos.
**Forma e detalhes:** Parece uma rocha coberta de algas, com olhos que aparecem.
**Paleta:** marrom, verde, cinza.
**Partes (4, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de pedra | padrão |
| `Head` | olhos e boca | padrão |
| `Fins` | espinhos | padrão |
| `Extra` | algas | padrão |
**Movimento (CreatureMotion):** quase não se mexe.
**Entrega:** `ReplicatedStorage.Creatures.C182_Peixe_Pedra_Camuflado` · print em `art/creatures/C182_Peixe_Pedra_Camuflado.png` · tamanho até 2,95 studs no maior lado.
---
### C183_Estrela_Quebradica — Estrela Quebradiça
**Incomum** · família do aquário **Abissal** · revelação `spark` · valor base 44 · 0.3–3.3 kg · chance sem sorte 1 em 332
**Conceito:** braços finos e brilhantes.
**Forma e detalhes:** Estrela-do-mar de braços finos e brilhantes, cor rosa e branco.
**Paleta:** rosa, branco, prata.
**Partes (3, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | centro | padrão |
| `Tentacles` | cinco braços finos | padrão |
| `Extra` | pontos brilhantes | **Neon** |
**Movimento (CreatureMotion):** braços ondulam.
**Entrega:** `ReplicatedStorage.Creatures.C183_Estrela_Quebradica` · print em `art/creatures/C183_Estrela_Quebradica.png` · tamanho até 2,95 studs no maior lado.
---
### C184_Pepino_Marinho_Sorridente — Pepino-Marinho Sorridente
**Incomum** · família do aquário **Recife** · revelação `bubbles` · valor base 35 · 0.3–2.3 kg · chance sem sorte 1 em 166
**Conceito:** pepino do mar com carinha.
**Forma e detalhes:** Pepino-do-mar verde com carinha sorridente e pintinhas.
**Paleta:** verde, creme, rosa.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo comprido | padrão |
| `Head` | carinha | padrão |
| `Tentacles` | tentáculos da boca | padrão |
**Movimento (CreatureMotion):** se arrasta, balança.
**Entrega:** `ReplicatedStorage.Creatures.C184_Pepino_Marinho_Sorridente` · print em `art/creatures/C184_Pepino_Marinho_Sorridente.png` · tamanho até 2,95 studs no maior lado.
---
### C185_Cavalinha_Brilhante — Cavalinha Brilhante
**Incomum** · família do aquário **Celestial** · revelação `spark` · valor base 35 · 0.3–2.3 kg · chance sem sorte 1 em 166
**Conceito:** cardume de prata.
**Forma e detalhes:** Peixe prateado com listras azuis iridescentes, corpo esguio.
**Paleta:** prata, azul, verde.
**Partes (4, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo | padrão |
| `Head` | cabeça | padrão |
| `Tail` | cauda | padrão |
| `Fins` | barbatanas | padrão |
**Movimento (CreatureMotion):** nada rápido.
**Entrega:** `ReplicatedStorage.Creatures.C185_Cavalinha_Brilhante` · print em `art/creatures/C185_Cavalinha_Brilhante.png` · tamanho até 2,95 studs no maior lado.
---
### C186_Peixe_Lua_Prata — Peixe-Lua Prata
**Incomum** · família do aquário **Celestial** · revelação `cloud` · valor base 35 · 0.3–2.3 kg · chance sem sorte 1 em 166
**Conceito:** disco prateado calmo.
**Forma e detalhes:** Disco prateado calmo com barbatanas curtas e rosto bobo.
**Paleta:** prata, cinza-claro, branco.
**Partes (4, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | disco | padrão |
| `Head` | rosto | padrão |
| `Fins` | barbatanas curtas | padrão |
| `Tail` | cauda curta | padrão |
**Movimento (CreatureMotion):** flutua devagar.
**Entrega:** `ReplicatedStorage.Creatures.C186_Peixe_Lua_Prata` · print em `art/creatures/C186_Peixe_Lua_Prata.png` · tamanho até 2,95 studs no maior lado.
---
### C187_Caranguejo_Violinista — Caranguejo Violinista
**Incomum** · família do aquário **Recife** · revelação `splash` · valor base 35 · 0.3–2.3 kg · chance sem sorte 1 em 166
**Conceito:** uma garra enorme que toca.
**Forma e detalhes:** Caranguejo com uma garra enorme laranja que toca como violino.
**Paleta:** laranja, marrom, branco.
**Partes (4, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | casco | padrão |
| `Head` | olhos | padrão |
| `Claws` | garra grande | padrão |
| `Legs` | patas | padrão |
**Movimento (CreatureMotion):** garra toca em arco.
**Entrega:** `ReplicatedStorage.Creatures.C187_Caranguejo_Violinista` · print em `art/creatures/C187_Caranguejo_Violinista.png` · tamanho até 2,95 studs no maior lado.
---
### C188_Peixe_Sapo_Rosa — Peixe-Sapo Rosa
**Incomum** · família do aquário **Abissal** · revelação `bubbles` · valor base 48 · 0.3–3.8 kg · chance sem sorte 1 em 663
**Conceito:** peixe-sapo rosa fofo.
**Forma e detalhes:** Peixe-sapo rosa com isca na testa, boca larga e olhos redondos.
**Paleta:** rosa, lilás, branco.
**Partes (4, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo redondo | padrão |
| `Head` | boca larga | padrão |
| `Fins` | pés-barbatana | padrão |
| `Extra` | isca luminosa | **Neon** |
**Movimento (CreatureMotion):** isca balança.
**Entrega:** `ReplicatedStorage.Creatures.C188_Peixe_Sapo_Rosa` · print em `art/creatures/C188_Peixe_Sapo_Rosa.png` · tamanho até 2,95 studs no maior lado.
---
### C189_Caracol_Cone — Caracol-Cone
**Incomum** · família do aquário **Recife** · revelação `prism` · valor base 35 · 0.3–2.3 kg · chance sem sorte 1 em 166
**Conceito:** concha estampada.
**Forma e detalhes:** Caracol de concha estampada em marrom e creme, corpo laranja.
**Paleta:** marrom, creme, laranja.
**Partes (4, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | concha | padrão |
| `Head` | cabeça com olhos | padrão |
| `Shell` | espiral | padrão |
| `Legs` | pé | padrão |
**Movimento (CreatureMotion):** desliza.
**Entrega:** `ReplicatedStorage.Creatures.C189_Caracol_Cone` · print em `art/creatures/C189_Caracol_Cone.png` · tamanho até 2,95 studs no maior lado.
---
### C190_Anemona_Dancarina — Anêmona Dançarina
**Incomum** · família do aquário **Recife** · revelação `spark` · valor base 44 · 0.3–3.3 kg · chance sem sorte 1 em 332
**Conceito:** anêmona que balança.
**Forma e detalhes:** Anêmona de tentáculos rosa e verde que balançam como dança.
**Paleta:** rosa, verde, branco.
**Partes (3, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | base | padrão |
| `Tentacles` | tentáculos | padrão |
| `Extra` | pontas brilhantes | **Neon** |
**Movimento (CreatureMotion):** dança balançando.
**Entrega:** `ReplicatedStorage.Creatures.C190_Anemona_Dancarina` · print em `art/creatures/C190_Anemona_Dancarina.png` · tamanho até 2,95 studs no maior lado.
---
### C191_Peixe_Mandarim — Peixe-Mandarim
**Incomum** · família do aquário **Recife** · revelação `prism` · valor base 48 · 0.3–3.8 kg · chance sem sorte 1 em 663
**Conceito:** azul e laranja psicodélico.
**Forma e detalhes:** Peixe de padrões azuis e laranja psicodélicos, corpo pequeno.
**Paleta:** azul, laranja, verde.
**Partes (5, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo | padrão |
| `Head` | cabeça | padrão |
| `Tail` | cauda | padrão |
| `Fins` | barbatanas | padrão |
| `Extra` | padrões | **Neon** |
**Movimento (CreatureMotion):** nada devagar.
**Entrega:** `ReplicatedStorage.Creatures.C191_Peixe_Mandarim` · print em `art/creatures/C191_Peixe_Mandarim.png` · tamanho até 2,95 studs no maior lado.
---
### C192_Sardinha_Bebe — Sardinha Bebê
**Comum** · família do aquário **Recife** · revelação `splash` · valor base 10 · 0.1–0.7 kg · chance sem sorte 1 em 84
**Conceito:** sardinha minúscula, olhos enormes.
**Forma e detalhes:** Sardinha minúscula e prateada com olhos enormes.
**Paleta:** prata, azul-claro.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo | padrão |
| `Head` | olhos grandes | padrão |
| `Tail` | cauda | padrão |
**Movimento (CreatureMotion):** cauda balança.
**Entrega:** `ReplicatedStorage.Creatures.C192_Sardinha_Bebe` · print em `art/creatures/C192_Sardinha_Bebe.png` · tamanho até 2,95 studs no maior lado.
---
### C193_Tainha_Alegre — Tainha Alegre
**Comum** · família do aquário **Recife** · revelação `splash` · valor base 10 · 0.1–0.7 kg · chance sem sorte 1 em 84
**Conceito:** tainha saltitante.
**Forma e detalhes:** Tainha cinza-prateada saltitante com sorriso.
**Paleta:** prata, cinza, branco.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo | padrão |
| `Head` | sorriso | padrão |
| `Tail` | cauda | padrão |
**Movimento (CreatureMotion):** salta.
**Entrega:** `ReplicatedStorage.Creatures.C193_Tainha_Alegre` · print em `art/creatures/C193_Tainha_Alegre.png` · tamanho até 2,95 studs no maior lado.
---
### C194_Anchova_Esperta — Anchova Esperta
**Comum** · família do aquário **Recife** · revelação `splash` · valor base 13 · 0.1–1 kg · chance sem sorte 1 em 168
**Conceito:** anchova com óculos.
**Forma e detalhes:** Anchova com óculos redondos e olhar esperto.
**Paleta:** prata, azul, preto.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo | padrão |
| `Head` | óculos | padrão |
| `Tail` | cauda | padrão |
**Movimento (CreatureMotion):** cauda rápida.
**Entrega:** `ReplicatedStorage.Creatures.C194_Anchova_Esperta` · print em `art/creatures/C194_Anchova_Esperta.png` · tamanho até 2,95 studs no maior lado.
---
### C195_Cascudinho_Azul — Cascudinho Azul
**Comum** · família do aquário **Recife** · revelação `bubbles` · valor base 13 · 0.1–1 kg · chance sem sorte 1 em 168
**Conceito:** limpador do aquário.
**Forma e detalhes:** Peixe pequeno azul que limpa vidros, boca de ventosa.
**Paleta:** azul, cinza.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo achatado | padrão |
| `Head` | boca de ventosa | padrão |
| `Tail` | cauda | padrão |
**Movimento (CreatureMotion):** desliza no fundo.
**Entrega:** `ReplicatedStorage.Creatures.C195_Cascudinho_Azul` · print em `art/creatures/C195_Cascudinho_Azul.png` · tamanho até 2,95 studs no maior lado.
---
### C196_Mexilhao_Sorridente — Mexilhão Sorridente
**Comum** · família do aquário **Recife** · revelação `bubbles` · valor base 10 · 0.1–0.7 kg · chance sem sorte 1 em 84
**Conceito:** mexilhão com sorriso.
**Forma e detalhes:** Mexilhão preto-azulado com sorriso.
**Paleta:** azul-escuro, preto.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | casca | padrão |
| `Head` | rostinho | padrão |
| `Shell` | casca | padrão |
**Movimento (CreatureMotion):** casca abre.
**Entrega:** `ReplicatedStorage.Creatures.C196_Mexilhao_Sorridente` · print em `art/creatures/C196_Mexilhao_Sorridente.png` · tamanho até 2,95 studs no maior lado.
---
### C197_Ostra_Pequena — Ostra Pequena
**Comum** · família do aquário **Recife** · revelação `bubbles` · valor base 15 · 0.1–1.1 kg · chance sem sorte 1 em 336
**Conceito:** ostra com pérola de brinquedo.
**Forma e detalhes:** Ostra cinza com pérola de brinquedo dentro.
**Paleta:** cinza, branco, rosa.
**Partes (3, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | concha | padrão |
| `Shell` | tampa | padrão |
| `Extra` | pérola | **Neon** |
**Movimento (CreatureMotion):** abre e fecha.
**Entrega:** `ReplicatedStorage.Creatures.C197_Ostra_Pequena` · print em `art/creatures/C197_Ostra_Pequena.png` · tamanho até 2,95 studs no maior lado.
---
### C198_Peixe_Lapis — Peixe-Lápis
**Comum** · família do aquário **Recife** · revelação `splash` · valor base 13 · 0.1–1 kg · chance sem sorte 1 em 168
**Conceito:** peixe-lápis amarelo.
**Forma e detalhes:** Peixe fino e amarelo com ponta preta, parece um lápis.
**Paleta:** amarelo, preto, rosa.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de lápis | padrão |
| `Head` | ponta | padrão |
| `Tail` | cauda | padrão |
**Movimento (CreatureMotion):** nada reto.
**Entrega:** `ReplicatedStorage.Creatures.C198_Peixe_Lapis` · print em `art/creatures/C198_Peixe_Lapis.png` · tamanho até 2,95 studs no maior lado.
---
### C199_Camarao_Bebe — Camarão Bebê
**Comum** · família do aquário **Recife** · revelação `splash` · valor base 10 · 0.1–0.7 kg · chance sem sorte 1 em 84
**Conceito:** camarãozinho rosa.
**Forma e detalhes:** Camarãozinho rosa com olhos grandes.
**Paleta:** rosa, branco.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo | padrão |
| `Head` | olhos | padrão |
| `Tail` | cauda | padrão |
**Movimento (CreatureMotion):** pula.
**Entrega:** `ReplicatedStorage.Creatures.C199_Camarao_Bebe` · print em `art/creatures/C199_Camarao_Bebe.png` · tamanho até 2,95 studs no maior lado.
---
### C200_Concha_Espiral — Concha Espiral
**Comum** · família do aquário **Recife** · revelação `bubbles` · valor base 10 · 0.1–0.7 kg · chance sem sorte 1 em 84
**Conceito:** caracol de espiral perfeita.
**Forma e detalhes:** Caracol com espiral perfeita em creme e rosa.
**Paleta:** creme, rosa.
**Partes (2, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | concha | padrão |
| `Shell` | espiral | padrão |
**Movimento (CreatureMotion):** gira de leve.
**Entrega:** `ReplicatedStorage.Creatures.C200_Concha_Espiral` · print em `art/creatures/C200_Concha_Espiral.png` · tamanho até 2,95 studs no maior lado.
---
### C201_Alga_Viva — Alga Viva
**Comum** · família do aquário **Recife** · revelação `bubbles` · valor base 13 · 0.1–1 kg · chance sem sorte 1 em 168
**Conceito:** alga com olhinhos.
**Forma e detalhes:** Alga verde com olhinhos e braços de folha.
**Paleta:** verde, amarelo.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de alga | padrão |
| `Head` | olhinhos | padrão |
| `Tentacles` | folhas | padrão |
**Movimento (CreatureMotion):** balança.
**Entrega:** `ReplicatedStorage.Creatures.C201_Alga_Viva` · print em `art/creatures/C201_Alga_Viva.png` · tamanho até 2,95 studs no maior lado.
---
### C202_Peixe_Bola_Amarelo — Peixe-Bola Amarelo
**Comum** · família do aquário **Recife** · revelação `splash` · valor base 13 · 0.1–1 kg · chance sem sorte 1 em 168
**Conceito:** bola de borracha com nadadeiras.
**Forma e detalhes:** Bola de borracha amarela com nadadeiras e carinha.
**Paleta:** amarelo, laranja.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | bola | padrão |
| `Head` | carinha | padrão |
| `Fins` | nadadeirinhas | padrão |
**Movimento (CreatureMotion):** quica.
**Entrega:** `ReplicatedStorage.Creatures.C202_Peixe_Bola_Amarelo` · print em `art/creatures/C202_Peixe_Bola_Amarelo.png` · tamanho até 2,95 studs no maior lado.
---
### C203_Caranguejinho_Areia — Caranguejinho de Areia
**Comum** · família do aquário **Recife** · revelação `splash` · valor base 10 · 0.1–0.7 kg · chance sem sorte 1 em 84
**Conceito:** caranguejo cor de areia.
**Forma e detalhes:** Caranguejo cor de areia com pintinhas e garras pequenas.
**Paleta:** bege, marrom.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | casco | padrão |
| `Claws` | garras | padrão |
| `Legs` | patas | padrão |
**Movimento (CreatureMotion):** anda de lado.
**Entrega:** `ReplicatedStorage.Creatures.C203_Caranguejinho_Areia` · print em `art/creatures/C203_Caranguejinho_Areia.png` · tamanho até 2,95 studs no maior lado.
---
### C204_Mini_Polvo_Verde — Mini Polvo Verde
**Comum** · família do aquário **Recife** · revelação `bubbles` · valor base 13 · 0.1–1 kg · chance sem sorte 1 em 168
**Conceito:** polvinho verde tímido.
**Forma e detalhes:** Polvinho verde tímido com olhos curiosos.
**Paleta:** verde, amarelo.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | cabeça | padrão |
| `Head` | olhos | padrão |
| `Tentacles` | braços | padrão |
**Movimento (CreatureMotion):** braços balançam.
**Entrega:** `ReplicatedStorage.Creatures.C204_Mini_Polvo_Verde` · print em `art/creatures/C204_Mini_Polvo_Verde.png` · tamanho até 2,95 studs no maior lado.
---
### C205_Estrelinha_Rosa — Estrelinha Rosa
**Comum** · família do aquário **Recife** · revelação `spark` · valor base 15 · 0.1–1.1 kg · chance sem sorte 1 em 336
**Conceito:** estrela rosa de cinco pontas.
**Forma e detalhes:** Estrela rosa de cinco pontas com carinha.
**Paleta:** rosa, branco.
**Partes (3, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | estrela | padrão |
| `Head` | carinha | padrão |
| `Extra` | brilho | **Neon** |
**Movimento (CreatureMotion):** gira de leve.
**Entrega:** `ReplicatedStorage.Creatures.C205_Estrelinha_Rosa` · print em `art/creatures/C205_Estrelinha_Rosa.png` · tamanho até 2,95 studs no maior lado.
---
### C206_Lambari_Dourado — Lambari Dourado
**Comum** · família do aquário **Recife** · revelação `splash` · valor base 13 · 0.1–1 kg · chance sem sorte 1 em 168
**Conceito:** lambari de escamas de ouro.
**Forma e detalhes:** Lambari de escamas douradas e nadadeiras laranja.
**Paleta:** dourado, laranja.
**Partes (3, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo | padrão |
| `Head` | cabeça | padrão |
| `Tail` | cauda | padrão |
**Movimento (CreatureMotion):** nada rápido.
**Entrega:** `ReplicatedStorage.Creatures.C206_Lambari_Dourado` · print em `art/creatures/C206_Lambari_Dourado.png` · tamanho até 2,95 studs no maior lado.
---
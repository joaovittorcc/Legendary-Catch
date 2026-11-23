# Criaturas — Lote 2: Épicas (20)

Lote 2 de 4 · **20 criaturas** · para o **Antigravity**. Cole este arquivo inteiro numa conversa aberta na pasta do projeto (`C:\Users\Evojota\dev\jogo ainda sem nome`).
Cada lote tem criaturas diferentes, então os 4 agentes podem trabalhar ao mesmo tempo sem se atropelar (leia a seção 4).

## 1. Contexto

**Legendary Catch** é um jogo de pesca e coleção no Roblox (ilha mágica, minigames, revelação cinematográfica, bestiário, aquário). Quem manda é o **João**: fale em português informal e curto; nomes de objetos e código em inglês.
Você é dono dos **modelos 3D**. **Não edite** `src/**` nem registre nada em `Config/Creatures.luau` (isso é do Claude, depois que o modelo chega).
Leia antes: `AGENTS.md`, `docs/COORDENACAO.md` (Mural no fim), **`docs/CRIATURAS-NOVAS.md` (regras obrigatórias de hierarquia, escala e orientação)** e `docs/CRIATURAS-ODDS-E-LISTA.md` (raridade e chances).
Épicas têm 7 a 10 peças e aparecem em revelações médias (3 a 4 s). Elas precisam parecer claramente mais ricas que as Raras.

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

### C137_Arraia_Cometa — Arraia Cometa
**Épico** · família do aquário **Celestial** · revelação `cosmic` · valor base 440 · 30–190 kg · chance sem sorte 1 em 3,7 mil
**Conceito:** arraia com cauda de cometa.
**Forma e detalhes:** Arraia com corpo azul-noite e cauda de cometa de gelo e luz, pontilhada de estrelas.
**Paleta:** azul-noite, branco, ciano, lilás.
**Partes (9, Neon 2):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de arraia largo | padrão |
| `Head` | cabeça pequena de arraia | padrão |
| `Tail` | cauda de cometa | padrão |
| `FinL` | asa esquerda | padrão |
| `FinR` | asa direita | padrão |
| `Fins` | franjas das asas | padrão |
| `Extra` | cabeça do cometa na ponta da cauda | **Neon** |
| `Extra` | estrelas no dorso | **Neon** |
| `Extra` | olhos grandes | padrão |
**Movimento (CreatureMotion):** asas ondulam, cauda de cometa balança.
**Entrega:** `ReplicatedStorage.Creatures.C137_Arraia_Cometa` · print em `art/creatures/C137_Arraia_Cometa.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C138_Tubarao_Tigre_Neon — Tubarão-Tigre Neon
**Épico** · família do aquário **Recife** · revelação `spark` · valor base 413 · 30–160 kg · chance sem sorte 1 em 1,9 mil
**Conceito:** tubarão listrado fluorescente.
**Forma e detalhes:** Tubarão com listas de tigre fluorescentes em verde e laranja, barriga clara e sorriso largo.
**Paleta:** preto, laranja-neon, verde-limão, branco.
**Partes (9, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de tubarão listrado | padrão |
| `Head` | cabeça com focinho largo | padrão |
| `Tail` | cauda de lua | padrão |
| `FinL` | peitoral esquerda | padrão |
| `FinR` | peitoral direita | padrão |
| `Fins` | dorsal | padrão |
| `Extra` | listras fluorescentes | **Neon** |
| `Extra` | dentes brancos | padrão |
| `Extra` | olhos amarelos | padrão |
**Movimento (CreatureMotion):** cauda bate, listras pulsam levemente.
**Entrega:** `ReplicatedStorage.Creatures.C138_Tubarao_Tigre_Neon` · print em `art/creatures/C138_Tubarao_Tigre_Neon.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C139_Dragao_Filhote_das_Mares — Dragão Filhote das Marés
**Épico** · família do aquário **Tempestade** · revelação `storm` · valor base 413 · 30–160 kg · chance sem sorte 1 em 1,9 mil
**Conceito:** dragãozinho de água, asas curtas.
**Forma e detalhes:** Dragãozinho aquático fofo: corpo azul-turquesa, asinhas curtas, cabeça grande, chifres pequenos.
**Paleta:** turquesa, azul-claro, creme, dourado nos chifres.
**Partes (9, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo roliço | padrão |
| `Head` | cabeça grande com olhos enormes | padrão |
| `Tail` | cauda com ponta de leque | padrão |
| `Wings` | asinhas curtas | padrão |
| `Legs` | patinhas curtas | padrão |
| `Fins` | crista de barbatanas | padrão |
| `Extra` | olhos dourados | **Neon** |
| `Extra` | chifres pequenos | padrão |
| `Extra` | barriga clara | padrão |
**Movimento (CreatureMotion):** asinhas batem rápido, cauda balança, cabeça inclina.
**Entrega:** `ReplicatedStorage.Creatures.C139_Dragao_Filhote_das_Mares` · print em `art/creatures/C139_Dragao_Filhote_das_Mares.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C140_Lontra_Estelar — Lontra Estelar
**Épico** · família do aquário **Celestial** · revelação `spark` · valor base 413 · 30–160 kg · chance sem sorte 1 em 1,9 mil
**Conceito:** lontra com barriga de estrelas.
**Forma e detalhes:** Lontra de pelo azul-escuro com barriga cheia de estrelas, segura uma concha brilhante com as patas.
**Paleta:** azul-escuro, creme, dourado, branco-estrela.
**Partes (9, Neon 2):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de lontra comprido | padrão |
| `Head` | cabeça redonda com bigodes | padrão |
| `Tail` | cauda larga | padrão |
| `Legs` | patinhas dianteiras e traseiras | padrão |
| `Claws` | patas segurando a concha | padrão |
| `Fins` | pelo da barriga | padrão |
| `Extra` | estrelas na barriga | **Neon** |
| `Extra` | concha luminosa | **Neon** |
| `Extra` | bigodes | padrão |
**Movimento (CreatureMotion):** boia de costas, cauda balança, patas giram a concha.
**Entrega:** `ReplicatedStorage.Creatures.C140_Lontra_Estelar` · print em `art/creatures/C140_Lontra_Estelar.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C141_Naja_de_Coral — Naja de Coral
**Épico** · família do aquário **Recife** · revelação `prism` · valor base 413 · 30–160 kg · chance sem sorte 1 em 1,9 mil
**Conceito:** cobra de coral rosa com capuz.
**Forma e detalhes:** Cobra rosa de coral com capuz aberto e pólipos coloridos pelo corpo, olhos verdes.
**Paleta:** rosa, laranja, branco, verde-água.
**Partes (9, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo enrolado de cobra | padrão |
| `Head` | cabeça com capuz | padrão |
| `Tail` | cauda em espiral | padrão |
| `Fins` | capuz aberto | padrão |
| `Shell` | placas de coral nas costas | padrão |
| `Extra` | olhos verdes | **Neon** |
| `Extra` | pólipos coloridos | padrão |
| `Extra` | língua bifurcada | padrão |
| `Extra` | presas | padrão |
**Movimento (CreatureMotion):** capuz abre e fecha, cabeça balança, cauda enrola.
**Entrega:** `ReplicatedStorage.Creatures.C141_Naja_de_Coral` · print em `art/creatures/C141_Naja_de_Coral.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C142_Golfinho_de_Cristal — Golfinho de Cristal
**Épico** · família do aquário **Celestial** · revelação `crystal` · valor base 440 · 30–190 kg · chance sem sorte 1 em 3,7 mil
**Conceito:** golfinho de vidro, arco-íris dentro.
**Forma e detalhes:** Golfinho de vidro translúcido com arco-íris dentro do corpo, nadadeiras de cristal, sorriso gentil.
**Paleta:** cristal transparente, arco-íris suave, azul-claro.
**Partes (9, Neon 2):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de golfinho de vidro | padrão |
| `Head` | cabeça com bico longo | padrão |
| `Tail` | cauda em lua | padrão |
| `FinL` | peitoral esquerda | padrão |
| `FinR` | peitoral direita | padrão |
| `Fins` | dorsal | padrão |
| `Extra` | arco-íris interno | **Neon** |
| `Extra` | olhos de safira | **Neon** |
| `Extra` | facetas de cristal | padrão |
**Movimento (CreatureMotion):** salta em arco, cauda bate, arco-íris pulsa.
**Entrega:** `ReplicatedStorage.Creatures.C142_Golfinho_de_Cristal` · print em `art/creatures/C142_Golfinho_de_Cristal.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C143_Jubarte_Tempestade — Jubarte Tempestade
**Épico** · família do aquário **Tempestade** · revelação `storm` · valor base 440 · 30–190 kg · chance sem sorte 1 em 3,7 mil
**Conceito:** baleia de nuvem, raios nas nadadeiras.
**Forma e detalhes:** Baleia jubarte com corpo de nuvem cinza e raios nas nadadeiras longas, trovoada no dorso.
**Paleta:** cinza-nuvem, azul-elétrico, branco, amarelo.
**Partes (10, Neon 2):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de baleia de nuvem | padrão |
| `Head` | cabeça com sulcos | padrão |
| `Tail` | cauda larga | padrão |
| `FinL` | nadadeira longa esquerda | padrão |
| `FinR` | nadadeira longa direita | padrão |
| `Fins` | dorsal baixa | padrão |
| `Extra` | raios nas nadadeiras | **Neon** |
| `Extra` | trovoada no dorso | **Neon** |
| `Extra` | cracas | padrão |
| `Extra` | olhos pequenos | padrão |
**Movimento (CreatureMotion):** nadadeiras longas batem, raios pequenos pulam, cauda bate lenta.
**Entrega:** `ReplicatedStorage.Creatures.C143_Jubarte_Tempestade` · print em `art/creatures/C143_Jubarte_Tempestade.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C144_Lula_Colossal_Neon — Lula Colossal Neon
**Épico** · família do aquário **Abissal** · revelação `spark` · valor base 413 · 30–160 kg · chance sem sorte 1 em 1,9 mil
**Conceito:** lula gigante de luz azul.
**Forma e detalhes:** Lula gigante de luz azul e roxa, manto em formato de flecha, dois tentáculos longos e oito braços.
**Paleta:** azul-neon, roxo, branco, rosa.
**Partes (9, Neon 2):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | manto de lula em flecha | padrão |
| `Head` | cabeça com olhos enormes | padrão |
| `Tail` | ponta do manto | padrão |
| `Tentacles` | oito braços | padrão |
| `Fins` | nadadeiras triangulares do manto | padrão |
| `Extra` | padrões luminosos | **Neon** |
| `Extra` | olhos azuis | **Neon** |
| `Extra` | dois tentáculos de caça | padrão |
| `Extra` | ventosas | padrão |
**Movimento (CreatureMotion):** braços ondulam, padrões pulsam, manto propulsiona.
**Entrega:** `ReplicatedStorage.Creatures.C144_Lula_Colossal_Neon` · print em `art/creatures/C144_Lula_Colossal_Neon.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C145_Peixe_Espada_Carmesim — Peixe-Espada Carmesim
**Épico** · família do aquário **Abissal** · revelação `magma` · valor base 413 · 30–160 kg · chance sem sorte 1 em 1,9 mil
**Conceito:** peixe-espada em brasa.
**Forma e detalhes:** Peixe-espada vermelho-brasa com espada longa em lâmina, corpo esguio, vela dorsal em chamas.
**Paleta:** vermelho-brasa, laranja, preto, dourado.
**Partes (9, Neon 2):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo esguio | padrão |
| `Head` | cabeça com espada | padrão |
| `Tail` | cauda em lua | padrão |
| `Fins` | vela dorsal | padrão |
| `FinL` | peitoral esquerda | padrão |
| `FinR` | peitoral direita | padrão |
| `Extra` | lâmina da espada | **Neon** |
| `Extra` | chama na vela | **Neon** |
| `Extra` | olhos pretos | padrão |
**Movimento (CreatureMotion):** cauda bate rápida, vela balança, espada brilha.
**Entrega:** `ReplicatedStorage.Creatures.C145_Peixe_Espada_Carmesim` · print em `art/creatures/C145_Peixe_Espada_Carmesim.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C146_Crocodilo_de_Jade — Crocodilo de Jade
**Épico** · família do aquário **Recife** · revelação `crystal` · valor base 360 · 30–110 kg · chance sem sorte 1 em 925
**Conceito:** crocodilo de jade polido.
**Forma e detalhes:** Crocodilo de jade polido com padrões dourados, olhos de âmbar, dentes de marfim.
**Paleta:** verde-jade, dourado, âmbar, branco.
**Partes (9, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de crocodilo de jade | padrão |
| `Head` | cabeça com focinho longo | padrão |
| `Tail` | cauda grossa | padrão |
| `Legs` | quatro patas curtas | padrão |
| `Claws` | garras | padrão |
| `Shell` | placas dorsais de jade | padrão |
| `Extra` | olhos de âmbar | **Neon** |
| `Extra` | dentes | padrão |
| `Extra` | padrões dourados | padrão |
**Movimento (CreatureMotion):** cauda balança, boca abre devagar, anda lento.
**Entrega:** `ReplicatedStorage.Creatures.C146_Crocodilo_de_Jade` · print em `art/creatures/C146_Crocodilo_de_Jade.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C147_Caranguejo_Cometa — Caranguejo Cometa
**Épico** · família do aquário **Celestial** · revelação `cosmic` · valor base 360 · 30–110 kg · chance sem sorte 1 em 925
**Conceito:** caranguejo com casco de meteoro.
**Forma e detalhes:** Caranguejo de casco de meteoro rochoso com cauda de fogo-estrela, garras de pedra azulada.
**Paleta:** cinza-meteoro, azul, laranja, branco.
**Partes (9, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | casco de meteoro | padrão |
| `Head` | olhos em hastes | padrão |
| `Legs` | oito patas | padrão |
| `Claws` | duas garras | padrão |
| `Shell` | crateras do casco | padrão |
| `Tail` | cauda de estrela | padrão |
| `Extra` | chama da cauda | **Neon** |
| `Extra` | olhos | padrão |
| `Extra` | poeira de estrela | padrão |
**Movimento (CreatureMotion):** anda de lado, garras abrem, cauda faísca.
**Entrega:** `ReplicatedStorage.Creatures.C147_Caranguejo_Cometa` · print em `art/creatures/C147_Caranguejo_Cometa.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C148_Cavalo_Marinho_Dragao — Cavalo-Marinho Dragão
**Épico** · família do aquário **Recife** · revelação `prism` · valor base 440 · 30–190 kg · chance sem sorte 1 em 3,7 mil
**Conceito:** hipocampo com cabeça de dragão.
**Forma e detalhes:** Hipocampo com cabeça de dragão, chifres, barbatana dorsal de asa, cauda enrolada com ponta flamejante.
**Paleta:** verde-esmeralda, dourado, rosa-coral, branco.
**Partes (9, Neon 2):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de hipocampo | padrão |
| `Head` | cabeça de dragão | padrão |
| `Tail` | cauda enrolada | padrão |
| `Wings` | barbatana-asa dorsal | padrão |
| `Fins` | barbatana peitoral | padrão |
| `Extra` | olhos dourados | **Neon** |
| `Extra` | chama na ponta da cauda | **Neon** |
| `Extra` | chifres | padrão |
| `Extra` | bigodes | padrão |
**Movimento (CreatureMotion):** cauda enrola e desenrola, asa bate, cabeça balança.
**Entrega:** `ReplicatedStorage.Creatures.C148_Cavalo_Marinho_Dragao` · print em `art/creatures/C148_Cavalo_Marinho_Dragao.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C149_Foca_de_Gelo_Mistico — Foca de Gelo Mística
**Épico** · família do aquário **Tempestade** · revelação `frost` · valor base 360 · 30–110 kg · chance sem sorte 1 em 925
**Conceito:** foca de gelo com runas.
**Forma e detalhes:** Foca de gelo com runas azuis brilhando no corpo, bigodes de cristal, nadadeiras com gelo.
**Paleta:** azul-gelo, branco, ciano, lilás.
**Partes (9, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de foca redondo | padrão |
| `Head` | cabeça com bigodes | padrão |
| `Tail` | cauda curta | padrão |
| `FinL` | nadadeira esquerda | padrão |
| `FinR` | nadadeira direita | padrão |
| `Shell` | placas de gelo nas costas | padrão |
| `Extra` | runas azuis | **Neon** |
| `Extra` | bigodes de cristal | padrão |
| `Extra` | olhos grandes | padrão |
**Movimento (CreatureMotion):** rola de leve, bate nadadeiras, runas piscam.
**Entrega:** `ReplicatedStorage.Creatures.C149_Foca_de_Gelo_Mistico` · print em `art/creatures/C149_Foca_de_Gelo_Mistico.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C150_Tartaruga_Relampago — Tartaruga Relâmpago
**Épico** · família do aquário **Tempestade** · revelação `storm` · valor base 360 · 30–110 kg · chance sem sorte 1 em 925
**Conceito:** tartaruga de casco elétrico.
**Forma e detalhes:** Tartaruga de casco amarelo-elétrico com linhas de raio, cabeça verde, nadadeiras fortes.
**Paleta:** amarelo-elétrico, verde, azul, branco.
**Partes (9, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | casco principal | padrão |
| `Head` | cabeça de tartaruga | padrão |
| `Tail` | cauda curta | padrão |
| `FinL` | nadadeira esquerda | padrão |
| `FinR` | nadadeira direita | padrão |
| `Legs` | patas traseiras | padrão |
| `Shell` | casco de placas | padrão |
| `Extra` | linhas de raio no casco | **Neon** |
| `Extra` | olhos pretos | padrão |
**Movimento (CreatureMotion):** nadadeiras batem, raios correm no casco.
**Entrega:** `ReplicatedStorage.Creatures.C150_Tartaruga_Relampago` · print em `art/creatures/C150_Tartaruga_Relampago.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C151_Pinguim_Imperador_Cristal — Pinguim Imperador de Cristal
**Épico** · família do aquário **Tempestade** · revelação `frost` · valor base 413 · 30–160 kg · chance sem sorte 1 em 1,9 mil
**Conceito:** pinguim de cristal e gelo.
**Forma e detalhes:** Pinguim imperador de cristal e gelo com coroa de gelo, peito branco, bico dourado.
**Paleta:** azul-gelo, branco, preto, dourado.
**Partes (10, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de pinguim | padrão |
| `Head` | cabeça com bico | padrão |
| `FinL` | asa esquerda | padrão |
| `FinR` | asa direita | padrão |
| `Legs` | patas | padrão |
| `Tail` | cauda curta | padrão |
| `Extra` | coroa de gelo | **Neon** |
| `Extra` | bico dourado | padrão |
| `Extra` | peito claro | padrão |
| `Extra` | cristais nos ombros | padrão |
**Movimento (CreatureMotion):** anda balançando, asas abrem, coroa brilha.
**Entrega:** `ReplicatedStorage.Creatures.C151_Pinguim_Imperador_Cristal` · print em `art/creatures/C151_Pinguim_Imperador_Cristal.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C152_Manta_Solar — Manta Solar
**Épico** · família do aquário **Celestial** · revelação `magma` · valor base 440 · 30–190 kg · chance sem sorte 1 em 3,7 mil
**Conceito:** manta dourada, asas de luz.
**Forma e detalhes:** Manta dourada com asas de luz, manchas de sol, cauda longa de fio de luz.
**Paleta:** dourado, laranja, branco, âmbar.
**Partes (9, Neon 2):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de manta | padrão |
| `Head` | cabeça com chifres de manta | padrão |
| `Tail` | cauda longa | padrão |
| `FinL` | asa esquerda | padrão |
| `FinR` | asa direita | padrão |
| `Fins` | franjas das asas | padrão |
| `Extra` | manchas de sol | **Neon** |
| `Extra` | fio de luz na cauda | **Neon** |
| `Extra` | olhos pequenos | padrão |
**Movimento (CreatureMotion):** asas ondulam em onda, cauda balança.
**Entrega:** `ReplicatedStorage.Creatures.C152_Manta_Solar` · print em `art/creatures/C152_Manta_Solar.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C153_Peixe_Boi_Encantado — Peixe-Boi Encantado
**Épico** · família do aquário **Recife** · revelação `bubbles` · valor base 360 · 30–110 kg · chance sem sorte 1 em 925
**Conceito:** peixe-boi com flores nas costas.
**Forma e detalhes:** Peixe-boi gentil com flores luminosas crescendo nas costas, pele azul-acinzentada, olhos doces.
**Paleta:** azul-acinzentado, rosa, branco, verde-folha.
**Partes (9, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo grande de peixe-boi | padrão |
| `Head` | cabeça redonda | padrão |
| `Tail` | cauda em remo | padrão |
| `FinL` | nadadeira esquerda | padrão |
| `FinR` | nadadeira direita | padrão |
| `Fins` | nadadeiras pequenas | padrão |
| `Extra` | flores luminosas | **Neon** |
| `Extra` | olhos pequenos | padrão |
| `Extra` | folhas | padrão |
**Movimento (CreatureMotion):** remada lenta, cauda sobe e desce, flores brilham.
**Entrega:** `ReplicatedStorage.Creatures.C153_Peixe_Boi_Encantado` · print em `art/creatures/C153_Peixe_Boi_Encantado.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C154_Mamba_das_Mares — Mamba das Marés
**Épico** · família do aquário **Abissal** · revelação `spark` · valor base 413 · 30–160 kg · chance sem sorte 1 em 1,9 mil
**Conceito:** cobra-do-mar de escamas negras e verde-neon.
**Forma e detalhes:** Cobra-do-mar preta com listras verde-neon e olhos amarelos, corpo longo em S.
**Paleta:** preto, verde-neon, amarelo, branco.
**Partes (8, Neon 2):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de cobra em S | padrão |
| `Head` | cabeça com olhos amarelos | padrão |
| `Tail` | cauda fina | padrão |
| `Fins` | cauda-remo achatada | padrão |
| `Shell` | escamas dorsais | padrão |
| `Extra` | listras verde-neon | **Neon** |
| `Extra` | olhos amarelos | **Neon** |
| `Extra` | língua | padrão |
**Movimento (CreatureMotion):** ondula em S, língua pulsa.
**Entrega:** `ReplicatedStorage.Creatures.C154_Mamba_das_Mares` · print em `art/creatures/C154_Mamba_das_Mares.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C155_Siri_Samurai — Siri Samurai
**Épico** · família do aquário **Recife** · revelação `prism` · valor base 360 · 30–110 kg · chance sem sorte 1 em 925
**Conceito:** caranguejo com armadura e katana.
**Forma e detalhes:** Caranguejo azul com armadura de samurai, elmo de chifres, katana nas garras, expressão séria.
**Paleta:** azul-royal, vermelho-laca, dourado, preto.
**Partes (9, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | casco com armadura | padrão |
| `Head` | olhos sob o elmo | padrão |
| `Legs` | seis patas | padrão |
| `Claws` | garras | padrão |
| `Shell` | ombreiras | padrão |
| `Extra` | lâmina da katana | **Neon** |
| `Extra` | elmo com chifres | padrão |
| `Extra` | faixa vermelha | padrão |
| `Extra` | bainha | padrão |
**Movimento (CreatureMotion):** garras cortam em arco, patas andam, elmo balança.
**Entrega:** `ReplicatedStorage.Creatures.C155_Siri_Samurai` · print em `art/creatures/C155_Siri_Samurai.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
### C156_Albatroz_das_Nuvens — Albatroz das Nuvens
**Épico** · família do aquário **Celestial** · revelação `cloud` · valor base 360 · 30–110 kg · chance sem sorte 1 em 925
**Conceito:** ave marinha de nuvem e vento.
**Forma e detalhes:** Ave marinha de penas de nuvem branca e azul, asas muito longas, bico claro, cauda em leque.
**Paleta:** branco, azul-céu, cinza-claro, dourado no bico.
**Partes (8, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de albatroz | padrão |
| `Head` | cabeça com bico longo | padrão |
| `Tail` | cauda em leque | padrão |
| `Wings` | par de asas muito longas | padrão |
| `Legs` | patas palmadas | padrão |
| `Extra` | brilho nas pontas das asas | **Neon** |
| `Extra` | bico dourado | padrão |
| `Extra` | nuvem sob a cauda | padrão |
**Movimento (CreatureMotion):** asas planam abrindo, cauda ajusta, nuvem acompanha.
**Entrega:** `ReplicatedStorage.Creatures.C156_Albatroz_das_Nuvens` · print em `art/creatures/C156_Albatroz_das_Nuvens.png` · tamanho ~3,0 a 3,2 studs no maior lado.
---
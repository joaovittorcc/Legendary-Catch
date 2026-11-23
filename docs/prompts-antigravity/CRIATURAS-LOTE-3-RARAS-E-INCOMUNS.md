# Criaturas — Lote 3: Raras (20) e 5 Incomuns

Lote 3 de 4 · **25 criaturas** · para o **Antigravity**. Cole este arquivo inteiro numa conversa aberta na pasta do projeto (`C:\Users\Evojota\dev\jogo ainda sem nome`).
Cada lote tem criaturas diferentes, então os 4 agentes podem trabalhar ao mesmo tempo sem se atropelar (leia a seção 4).

## 1. Contexto

**Legendary Catch** é um jogo de pesca e coleção no Roblox (ilha mágica, minigames, revelação cinematográfica, bestiário, aquário). Quem manda é o **João**: fale em português informal e curto; nomes de objetos e código em inglês.
Você é dono dos **modelos 3D**. **Não edite** `src/**` nem registre nada em `Config/Creatures.luau` (isso é do Claude, depois que o modelo chega).
Leia antes: `AGENTS.md`, `docs/COORDENACAO.md` (Mural no fim), **`docs/CRIATURAS-NOVAS.md` (regras obrigatórias de hierarquia, escala e orientação)** e `docs/CRIATURAS-ODDS-E-LISTA.md` (raridade e chances).
Raras têm 5 a 7 peças; Incomuns, 3 a 5. Revelações curtas: a silhueta e a paleta precisam bater de relance.

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

### C157_Peixe_Sabre_Prata — Peixe-Sabre Prata
**Raro** · família do aquário **Abissal** · revelação `spark` · valor base 146 · 4–24.9 kg · chance sem sorte 1 em 429
**Conceito:** peixe-fita prateado.
**Forma e detalhes:** Peixe-fita longo e espelhado, boca de sabre, barbatana dorsal contínua.
**Paleta:** prata, azul-claro, branco.
**Partes (6, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de fita prateado | padrão |
| `Head` | cabeça com boca afiada | padrão |
| `Tail` | cauda fina | padrão |
| `Fins` | dorsal contínua | padrão |
| `FinL` | peitoral esquerda | padrão |
| `FinR` | peitoral direita | padrão |
**Movimento (CreatureMotion):** ondula ao longo do corpo.
**Entrega:** `ReplicatedStorage.Creatures.C157_Peixe_Sabre_Prata` · print em `art/creatures/C157_Peixe_Sabre_Prata.png` · tamanho até 2,95 studs no maior lado.
---
### C158_Moreia_Esmeralda — Moreia Esmeralda
**Raro** · família do aquário **Recife** · revelação `prism` · valor base 162 · 4–28.3 kg · chance sem sorte 1 em 859
**Conceito:** moreia de brilho verde.
**Forma e detalhes:** Moreia de pele verde-esmeralda com manchas douradas e olhos amarelos, boca entreaberta.
**Paleta:** verde-esmeralda, dourado, amarelo.
**Partes (6, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de moreia | padrão |
| `Head` | cabeça com boca aberta | padrão |
| `Tail` | cauda fina | padrão |
| `Fins` | barbatana contínua | padrão |
| `Extra` | manchas douradas | **Neon** |
| `Extra` | olhos | padrão |
**Movimento (CreatureMotion):** serpenteia, boca abre e fecha.
**Entrega:** `ReplicatedStorage.Creatures.C158_Moreia_Esmeralda` · print em `art/creatures/C158_Moreia_Esmeralda.png` · tamanho até 2,95 studs no maior lado.
---
### C159_Polvo_Mimico — Polvo Mímico
**Raro** · família do aquário **Recife** · revelação `prism` · valor base 170 · 4–30 kg · chance sem sorte 1 em 1,7 mil
**Conceito:** polvo que imita outros peixes.
**Forma e detalhes:** Polvo de listras pretas e brancas que imita outros bichos; um braço virado em cauda de peixe, outro em espinhos.
**Paleta:** preto, branco, laranja, bege.
**Partes (6, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | cabeça-manto listrada | padrão |
| `Head` | olhos grandes | padrão |
| `Tentacles` | seis braços | padrão |
| `Extra` | braço-cauda de peixe | padrão |
| `Extra` | braço de espinhos | padrão |
| `Extra` | olhos brilhantes | **Neon** |
**Movimento (CreatureMotion):** braços trocam de pose, manto pulsa.
**Entrega:** `ReplicatedStorage.Creatures.C159_Polvo_Mimico` · print em `art/creatures/C159_Polvo_Mimico.png` · tamanho até 2,95 studs no maior lado.
---
### C160_Peixe_Lanterna_Dourado — Peixe-Lanterna Dourado
**Raro** · família do aquário **Abissal** · revelação `spark` · valor base 170 · 4–30 kg · chance sem sorte 1 em 1,7 mil
**Conceito:** lanterna dourada na testa.
**Forma e detalhes:** Peixe escuro de águas profundas com lanterna dourada na testa e dentes pequenos.
**Paleta:** azul-escuro, dourado, âmbar.
**Partes (6, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo escuro | padrão |
| `Head` | cabeça com boca grande | padrão |
| `Tail` | cauda larga | padrão |
| `Fins` | barbatana | padrão |
| `Extra` | lanterna dourada | **Neon** |
| `Extra` | dentes | padrão |
**Movimento (CreatureMotion):** lanterna balança e pulsa.
**Entrega:** `ReplicatedStorage.Creatures.C160_Peixe_Lanterna_Dourado` · print em `art/creatures/C160_Peixe_Lanterna_Dourado.png` · tamanho até 2,95 studs no maior lado.
---
### C161_Lagosta_Rubi — Lagosta Rubi
**Raro** · família do aquário **Recife** · revelação `crystal` · valor base 170 · 4–30 kg · chance sem sorte 1 em 1,7 mil
**Conceito:** lagosta de casca de rubi.
**Forma e detalhes:** Lagosta de casca vermelha como rubi facetado, antenas longas, garras grandes.
**Paleta:** vermelho-rubi, laranja, branco.
**Partes (6, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | carapaça facetada | padrão |
| `Head` | olhos e antenas | padrão |
| `Tail` | cauda em leque | padrão |
| `Claws` | duas garras grandes | padrão |
| `Legs` | oito patas | padrão |
| `Extra` | gemas na carapaça | **Neon** |
**Movimento (CreatureMotion):** antenas balançam, garras abrem.
**Entrega:** `ReplicatedStorage.Creatures.C161_Lagosta_Rubi` · print em `art/creatures/C161_Lagosta_Rubi.png` · tamanho até 2,95 studs no maior lado.
---
### C162_Esponja_Guerreira — Esponja Guerreira
**Raro** · família do aquário **Recife** · revelação `bubbles` · valor base 162 · 4–28.3 kg · chance sem sorte 1 em 859
**Conceito:** esponja com elmo e escudo.
**Forma e detalhes:** Esponja amarela com elmo, escudo de concha e lança de coral; olhos determinados.
**Paleta:** amarelo, laranja, azul, prata.
**Partes (7, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de esponja | padrão |
| `Head` | rosto com olhos | padrão |
| `Legs` | duas perninhas | padrão |
| `Claws` | braços segurando escudo e lança | padrão |
| `Extra` | elmo | padrão |
| `Extra` | escudo de concha | padrão |
| `Extra` | lança de coral | padrão |
**Movimento (CreatureMotion):** balança como se marchasse.
**Entrega:** `ReplicatedStorage.Creatures.C162_Esponja_Guerreira` · print em `art/creatures/C162_Esponja_Guerreira.png` · tamanho até 2,95 studs no maior lado.
---
### C163_Tubarao_Duende — Tubarão-Duende
**Raro** · família do aquário **Abissal** · revelação `frost` · valor base 146 · 4–24.9 kg · chance sem sorte 1 em 429
**Conceito:** tubarão-duende rosa, mandíbula esticável.
**Forma e detalhes:** Tubarão-duende rosa com focinho longo e mandíbula que estica, pele translúcida, olhos pequenos.
**Paleta:** rosa, branco, lilás.
**Partes (6, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo rosa | padrão |
| `Head` | focinho em lâmina | padrão |
| `Tail` | cauda | padrão |
| `FinL` | peitoral esquerda | padrão |
| `FinR` | peitoral direita | padrão |
| `Extra` | mandíbula esticada | padrão |
**Movimento (CreatureMotion):** mandíbula abre e fecha, cauda bate.
**Entrega:** `ReplicatedStorage.Creatures.C163_Tubarao_Duende` · print em `art/creatures/C163_Tubarao_Duende.png` · tamanho até 2,95 studs no maior lado.
---
### C164_Peixe_Pedra_Vulcanico — Peixe-Pedra Vulcânico
**Raro** · família do aquário **Tempestade** · revelação `magma` · valor base 170 · 4–30 kg · chance sem sorte 1 em 1,7 mil
**Conceito:** peixe-pedra com lava nas fendas.
**Forma e detalhes:** Peixe que parece rocha vulcânica negra com fendas de lava acesas e espinhos.
**Paleta:** preto, vermelho-lava, cinza.
**Partes (6, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de rocha | padrão |
| `Head` | cabeça achatada | padrão |
| `Tail` | cauda curta | padrão |
| `Fins` | espinhos dorsais | padrão |
| `FinL` | peitoral esquerda | padrão |
| `Extra` | fendas de lava | **Neon** |
**Movimento (CreatureMotion):** quase imóvel, fendas pulsam.
**Entrega:** `ReplicatedStorage.Creatures.C164_Peixe_Pedra_Vulcanico` · print em `art/creatures/C164_Peixe_Pedra_Vulcanico.png` · tamanho até 2,95 studs no maior lado.
---
### C165_Camarao_Mantis_Arcoiris — Camarão-Mantis Arco-Íris
**Raro** · família do aquário **Recife** · revelação `prism` · valor base 170 · 4–30 kg · chance sem sorte 1 em 1,7 mil
**Conceito:** camarão-mantis, 12 cores.
**Forma e detalhes:** Camarão colorido com olhos independentes e patas-soco rosa; doze cores na carapaça.
**Paleta:** arco-íris, verde, rosa, azul.
**Partes (6, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | carapaça colorida | padrão |
| `Head` | olhos em hastes | padrão |
| `Tail` | cauda em leque | padrão |
| `Claws` | duas patas-soco | padrão |
| `Legs` | patas pequenas | padrão |
| `Extra` | olhos brilhantes | **Neon** |
**Movimento (CreatureMotion):** soco rápido, olhos giram.
**Entrega:** `ReplicatedStorage.Creatures.C165_Camarao_Mantis_Arcoiris` · print em `art/creatures/C165_Camarao_Mantis_Arcoiris.png` · tamanho até 2,95 studs no maior lado.
---
### C166_Arraia_Jaguar — Arraia Jaguar
**Raro** · família do aquário **Recife** · revelação `spark` · valor base 146 · 4–24.9 kg · chance sem sorte 1 em 429
**Conceito:** arraia pintada como onça.
**Forma e detalhes:** Arraia amarela com manchas pretas de onça, olhos verdes e cauda com anéis.
**Paleta:** amarelo, preto, verde.
**Partes (6, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de arraia | padrão |
| `Head` | cabeça | padrão |
| `Tail` | cauda com anéis | padrão |
| `FinL` | asa esquerda | padrão |
| `FinR` | asa direita | padrão |
| `Extra` | manchas | padrão |
**Movimento (CreatureMotion):** asas ondulam.
**Entrega:** `ReplicatedStorage.Creatures.C166_Arraia_Jaguar` · print em `art/creatures/C166_Arraia_Jaguar.png` · tamanho até 2,95 studs no maior lado.
---
### C167_Peixe_Gato_Eletrico — Peixe-Gato Elétrico
**Raro** · família do aquário **Tempestade** · revelação `storm` · valor base 162 · 4–28.3 kg · chance sem sorte 1 em 859
**Conceito:** bagre com bigodes de faísca.
**Forma e detalhes:** Bagre azul-acinzentado com bigodes de faísca, barbatana larga e olhos pequenos.
**Paleta:** azul-acinzentado, amarelo-faísca, branco.
**Partes (6, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de bagre | padrão |
| `Head` | cabeça larga | padrão |
| `Tail` | cauda | padrão |
| `Fins` | dorsal | padrão |
| `FinL` | peitoral | padrão |
| `Extra` | bigodes de faísca | **Neon** |
**Movimento (CreatureMotion):** bigodes faíscam, cauda balança.
**Entrega:** `ReplicatedStorage.Creatures.C167_Peixe_Gato_Eletrico` · print em `art/creatures/C167_Peixe_Gato_Eletrico.png` · tamanho até 2,95 studs no maior lado.
---
### C168_Cavala_Relampago — Cavala Relâmpago
**Raro** · família do aquário **Tempestade** · revelação `storm` · valor base 162 · 4–28.3 kg · chance sem sorte 1 em 859
**Conceito:** cavala listrada de raios.
**Forma e detalhes:** Cavala azul com listras em zigue-zague amarelo-raio, corpo veloz.
**Paleta:** azul-escuro, amarelo, prata.
**Partes (6, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo fusiforme | padrão |
| `Head` | cabeça pontuda | padrão |
| `Tail` | cauda em lua | padrão |
| `Fins` | dorsal | padrão |
| `FinL` | peitoral | padrão |
| `Extra` | listras de raio | **Neon** |
**Movimento (CreatureMotion):** cauda bate rápida, listras piscam.
**Entrega:** `ReplicatedStorage.Creatures.C168_Cavala_Relampago` · print em `art/creatures/C168_Cavala_Relampago.png` · tamanho até 2,95 studs no maior lado.
---
### C169_Caramujo_Cone_Dourado — Caramujo-Cone Dourado
**Raro** · família do aquário **Recife** · revelação `crystal` · valor base 162 · 4–28.3 kg · chance sem sorte 1 em 859
**Conceito:** caramujo com concha de ouro.
**Forma e detalhes:** Caramujo de concha cônica dourada com padrões em V e corpo creme.
**Paleta:** dourado, creme, marrom-claro.
**Partes (5, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | concha cônica | padrão |
| `Head` | cabeça com olhos | padrão |
| `Shell` | espiral da concha | padrão |
| `Legs` | pé de caramujo | padrão |
| `Extra` | brilho dourado | **Neon** |
**Movimento (CreatureMotion):** desliza, olhos balançam.
**Entrega:** `ReplicatedStorage.Creatures.C169_Caramujo_Cone_Dourado` · print em `art/creatures/C169_Caramujo_Cone_Dourado.png` · tamanho até 2,95 studs no maior lado.
---
### C170_Estrela_do_Mar_Gigante — Estrela-do-Mar Gigante
**Raro** · família do aquário **Recife** · revelação `spark` · valor base 146 · 4–24.9 kg · chance sem sorte 1 em 429
**Conceito:** estrela de nove braços.
**Forma e detalhes:** Estrela de nove braços laranja com pontas roxas, pontinhos em relevo, olho em cada ponta.
**Paleta:** laranja, roxo, creme.
**Partes (5, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | centro da estrela | padrão |
| `Head` | disco central | padrão |
| `Tentacles` | nove braços | padrão |
| `Extra` | olhos nas pontas | **Neon** |
| `Extra` | pontinhos em relevo | padrão |
**Movimento (CreatureMotion):** braços ondulam em onda.
**Entrega:** `ReplicatedStorage.Creatures.C170_Estrela_do_Mar_Gigante` · print em `art/creatures/C170_Estrela_do_Mar_Gigante.png` · tamanho até 2,95 studs no maior lado.
---
### C171_Cobra_do_Mar_Listrada — Cobra-do-Mar Listrada
**Raro** · família do aquário **Abissal** · revelação `spark` · valor base 115 · 4–18 kg · chance sem sorte 1 em 215
**Conceito:** cobra anelada preta e branca.
**Forma e detalhes:** Cobra-do-mar anelada em preto e branco com cauda achatada em remo.
**Paleta:** preto, branco, cinza.
**Partes (5, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo anelado | padrão |
| `Head` | cabeça | padrão |
| `Tail` | cauda em remo | padrão |
| `Fins` | barbatana da cauda | padrão |
| `Extra` | língua | padrão |
**Movimento (CreatureMotion):** serpenteia, língua pulsa.
**Entrega:** `ReplicatedStorage.Creatures.C171_Cobra_do_Mar_Listrada` · print em `art/creatures/C171_Cobra_do_Mar_Listrada.png` · tamanho até 2,95 studs no maior lado.
---
### C172_Raia_Veludo — Raia Veludo
**Raro** · família do aquário **Celestial** · revelação `cloud` · valor base 146 · 4–24.9 kg · chance sem sorte 1 em 429
**Conceito:** raia de veludo roxo.
**Forma e detalhes:** Raia de veludo roxo com bordas lilás, textura macia e cauda longa.
**Paleta:** roxo-veludo, lilás, branco.
**Partes (6, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de raia | padrão |
| `Head` | cabeça | padrão |
| `Tail` | cauda longa | padrão |
| `FinL` | asa esquerda | padrão |
| `FinR` | asa direita | padrão |
| `Fins` | franjas | padrão |
**Movimento (CreatureMotion):** asas flutuam como pano.
**Entrega:** `ReplicatedStorage.Creatures.C172_Raia_Veludo` · print em `art/creatures/C172_Raia_Veludo.png` · tamanho até 2,95 studs no maior lado.
---
### C173_Peixe_Remo_Prata — Peixe-Remo Prata
**Raro** · família do aquário **Abissal** · revelação `frost` · valor base 146 · 4–24.9 kg · chance sem sorte 1 em 429
**Conceito:** peixe-remo fita comprida.
**Forma e detalhes:** Peixe-remo comprido e prateado com crista vermelha e barbatanas finas.
**Paleta:** prata, vermelho, branco.
**Partes (6, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de fita | padrão |
| `Head` | cabeça pequena | padrão |
| `Tail` | cauda fina | padrão |
| `Fins` | crista vermelha | padrão |
| `FinL` | pélvica esquerda | padrão |
| `FinR` | pélvica direita | padrão |
**Movimento (CreatureMotion):** ondula lentamente.
**Entrega:** `ReplicatedStorage.Creatures.C173_Peixe_Remo_Prata` · print em `art/creatures/C173_Peixe_Remo_Prata.png` · tamanho até 2,95 studs no maior lado.
---
### C174_Baiacu_Espinho_de_Cristal — Baiacu Espinho de Cristal
**Raro** · família do aquário **Recife** · revelação `crystal` · valor base 162 · 4–28.3 kg · chance sem sorte 1 em 859
**Conceito:** baiacu com espinhos de cristal.
**Forma e detalhes:** Baiacu inflado de espinhos de cristal translúcido, olhos grandes, boca pequena.
**Paleta:** azul-claro, cristal, branco.
**Partes (6, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo inflado | padrão |
| `Head` | rosto | padrão |
| `Tail` | cauda curta | padrão |
| `FinL` | barbatana esquerda | padrão |
| `FinR` | barbatana direita | padrão |
| `Extra` | espinhos de cristal | **Neon** |
**Movimento (CreatureMotion):** infla e desinfla, barbatanas batem.
**Entrega:** `ReplicatedStorage.Creatures.C174_Baiacu_Espinho_de_Cristal` · print em `art/creatures/C174_Baiacu_Espinho_de_Cristal.png` · tamanho até 2,95 studs no maior lado.
---
### C175_Siri_Joia — Siri Joia
**Raro** · família do aquário **Recife** · revelação `prism` · valor base 162 · 4–28.3 kg · chance sem sorte 1 em 859
**Conceito:** siri com casco de pedras preciosas.
**Forma e detalhes:** Siri com casco coberto de gemas coloridas, garras brilhantes e olhos de pérola.
**Paleta:** gemas rosa, azul, verde, dourado.
**Partes (5, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | casco com gemas | padrão |
| `Head` | olhos de pérola | padrão |
| `Claws` | duas garras | padrão |
| `Legs` | seis patas | padrão |
| `Extra` | gemas brilhantes | **Neon** |
**Movimento (CreatureMotion):** anda de lado, gemas piscam.
**Entrega:** `ReplicatedStorage.Creatures.C175_Siri_Joia` · print em `art/creatures/C175_Siri_Joia.png` · tamanho até 2,95 studs no maior lado.
---
### C176_Salmao_Real_Ouro — Salmão Real Ouro
**Raro** · família do aquário **Celestial** · revelação `magma` · valor base 170 · 4–30 kg · chance sem sorte 1 em 1,7 mil
**Conceito:** salmão de escamas douradas.
**Forma e detalhes:** Salmão de escamas douradas, corpo forte, mandíbula curva e olhos escuros.
**Paleta:** dourado, âmbar, branco.
**Partes (6, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo forte | padrão |
| `Head` | cabeça com mandíbula | padrão |
| `Tail` | cauda larga | padrão |
| `Fins` | dorsal | padrão |
| `FinL` | peitoral | padrão |
| `Extra` | escamas douradas | **Neon** |
**Movimento (CreatureMotion):** cauda bate forte, salta.
**Entrega:** `ReplicatedStorage.Creatures.C176_Salmao_Real_Ouro` · print em `art/creatures/C176_Salmao_Real_Ouro.png` · tamanho até 2,95 studs no maior lado.
---
### C177_Peixe_Cirurgiao_Azul — Peixe-Cirurgião Azul
**Incomum** · família do aquário **Recife** · revelação `bubbles` · valor base 35 · 0.3–2.3 kg · chance sem sorte 1 em 166
**Conceito:** azul-royal, cauda amarela.
**Forma e detalhes:** Peixe azul-royal com cauda amarela e mancha preta, olhos grandes.
**Paleta:** azul-royal, amarelo, preto.
**Partes (4, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo oval | padrão |
| `Head` | cabeça | padrão |
| `Tail` | cauda amarela | padrão |
| `Fins` | barbatanas | padrão |
**Movimento (CreatureMotion):** cauda balança.
**Entrega:** `ReplicatedStorage.Creatures.C177_Peixe_Cirurgiao_Azul` · print em `art/creatures/C177_Peixe_Cirurgiao_Azul.png` · tamanho até 2,95 studs no maior lado.
---
### C178_Peixe_Borboleta — Peixe-Borboleta
**Incomum** · família do aquário **Recife** · revelação `prism` · valor base 35 · 0.3–2.3 kg · chance sem sorte 1 em 166
**Conceito:** listras e olho falso.
**Forma e detalhes:** Peixe amarelo com listras pretas e olho falso na cauda.
**Paleta:** amarelo, preto, branco.
**Partes (4, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo achatado | padrão |
| `Head` | cabeça de focinho | padrão |
| `Tail` | cauda | padrão |
| `Fins` | dorsal e anal | padrão |
**Movimento (CreatureMotion):** nada em zigue-zague.
**Entrega:** `ReplicatedStorage.Creatures.C178_Peixe_Borboleta` · print em `art/creatures/C178_Peixe_Borboleta.png` · tamanho até 2,95 studs no maior lado.
---
### C179_Camarao_Pistola — Camarão-Pistola
**Incomum** · família do aquário **Recife** · revelação `splash` · valor base 44 · 0.3–3.3 kg · chance sem sorte 1 em 332
**Conceito:** garra gigante que estala.
**Forma e detalhes:** Camarão laranja com uma garra gigante que estala.
**Paleta:** laranja, branco, azul.
**Partes (4, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo | padrão |
| `Head` | olhos | padrão |
| `Claws` | garra gigante | padrão |
| `Tail` | cauda em leque | padrão |
**Movimento (CreatureMotion):** garra estala.
**Entrega:** `ReplicatedStorage.Creatures.C179_Camarao_Pistola` · print em `art/creatures/C179_Camarao_Pistola.png` · tamanho até 2,95 studs no maior lado.
---
### C180_Lesma_Marinha_Pavao — Lesma-Marinha Pavão
**Incomum** · família do aquário **Recife** · revelação `prism` · valor base 48 · 0.3–3.8 kg · chance sem sorte 1 em 663
**Conceito:** lesma com penas de pavão.
**Forma e detalhes:** Lesma azul-esverdeada com penas de pavão iridescentes nas costas.
**Paleta:** azul, verde, dourado.
**Partes (4, Neon 1):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de lesma | padrão |
| `Head` | tentáculos | padrão |
| `Fins` | penas dorsais | padrão |
| `Extra` | olhos nas penas | **Neon** |
**Movimento (CreatureMotion):** penas balançam.
**Entrega:** `ReplicatedStorage.Creatures.C180_Lesma_Marinha_Pavao` · print em `art/creatures/C180_Lesma_Marinha_Pavao.png` · tamanho até 2,95 studs no maior lado.
---
### C181_Tartaruga_Jovem_Verde — Tartaruga Jovem Verde
**Incomum** · família do aquário **Recife** · revelação `bubbles` · valor base 44 · 0.3–3.3 kg · chance sem sorte 1 em 332
**Conceito:** filhote curioso.
**Forma e detalhes:** Filhote de tartaruga curioso com casco verde-claro e olhos grandes.
**Paleta:** verde-claro, amarelo, branco.
**Partes (5, Neon 0):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | casco | padrão |
| `Head` | cabeça grande | padrão |
| `FinL` | nadadeira esquerda | padrão |
| `FinR` | nadadeira direita | padrão |
| `Tail` | cauda pequena | padrão |
**Movimento (CreatureMotion):** nadadeiras batem.
**Entrega:** `ReplicatedStorage.Creatures.C181_Tartaruga_Jovem_Verde` · print em `art/creatures/C181_Tartaruga_Jovem_Verde.png` · tamanho até 2,95 studs no maior lado.
---
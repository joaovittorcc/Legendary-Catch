# Criaturas — Lote 1: Místicas e Lendárias (30)

Lote 1 de 4 · **30 criaturas** · para o **Antigravity**. Cole este arquivo inteiro numa conversa aberta na pasta do projeto (`C:\Users\Evojota\dev\jogo ainda sem nome`).
Cada lote tem criaturas diferentes, então os 4 agentes podem trabalhar ao mesmo tempo sem se atropelar (leia a seção 4).

## 1. Contexto

**Legendary Catch** é um jogo de pesca e coleção no Roblox (ilha mágica, minigames, revelação cinematográfica, bestiário, aquário). Quem manda é o **João**: fale em português informal e curto; nomes de objetos e código em inglês.
Você é dono dos **modelos 3D**. **Não edite** `src/**` nem registre nada em `Config/Creatures.luau` (isso é do Claude, depois que o modelo chega).
Leia antes: `AGENTS.md`, `docs/COORDENACAO.md` (Mural no fim), **`docs/CRIATURAS-NOVAS.md` (regras obrigatórias de hierarquia, escala e orientação)** e `docs/CRIATURAS-ODDS-E-LISTA.md` (raridade e chances).
Este é o lote **mais caprichado**: são as criaturas que aparecem em cutscenes de revelação de 6 a 8 segundos. Gaste tempo em silhueta, detalhe e brilho. Capricho vale mais que velocidade.

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

- **Extra caprichado:** Místicos e Lendários têm lore e leitura de silhueta em cada ficha. Use o padrão do **C92_Serafim_do_Mar** (15 peças, 8 Neon) como régua de qualidade (`ReplicatedStorage.Creatures.C92_Serafim_do_Mar`).
- Faça primeiro uma versão rápida (blockout) para validar a silhueta e a orientação, depois detalhe.
---

## 6. As criaturas deste lote

### C107_Relogio_do_Abismo_Eterno — Relógio do Abismo Eterno
**Místico** · família do aquário **Celestial** · revelação `cosmic` · valor base 14610 · 20000–96130 kg · chance sem sorte 1 em 125 mil
**Conceito:** baleia-relógio, ponteiros de luz orbitando o corpo.
**Forma e detalhes:** Baleia colossal cujo corpo é um relógio de bolso antigo: carcaça de bronze envelhecido, costas de vidro azul translúcido mostrando engrenagens, ponteiros de luz que giram devagar.
**Paleta:** bronze envelhecido, azul-safira translúcido, dourado e ciano luminosos, algarismos romanos prateados.
**Partes (14, Neon 6):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de baleia em bronze e vidro azul | padrão |
| `Head` | cabeça redonda com olho de safira | padrão |
| `Tail` | cauda em forma de flor de engrenagem | padrão |
| `FinL` | nadadeira peitoral com mostrador pequeno | padrão |
| `FinR` | nadadeira peitoral com mostrador pequeno | padrão |
| `Extra` | mostrador grande translúcido nas costas | **Neon** |
| `Extra` | ponteiro das horas dourado de luz | **Neon** |
| `Extra` | ponteiro dos minutos ciano de luz | **Neon** |
| `Extra` | engrenagem grande de metal | padrão |
| `Extra` | engrenagem média | padrão |
| `Extra` | anel orbital de algarismos romanos | **Neon** |
| `Extra` | anel orbital menor inclinado | **Neon** |
| `Extra` | coroa de relógio no topo | padrão |
| `Extra` | olho-lua sob a cabeça | **Neon** |
**Movimento (CreatureMotion):** ponteiros e anéis giram em sentidos opostos; engrenagens rodam lentas; cauda bate como pêndulo.
**Lore (1 linha):** Dizem que o mar só avança porque ele conta cada segundo.
**Leitura da silhueta (vira sombra na revelação):** baleia com círculo de relógio nas costas e dois anéis cortando o corpo.
**Entrega:** `ReplicatedStorage.Creatures.C107_Relogio_do_Abismo_Eterno` · print em `art/creatures/C107_Relogio_do_Abismo_Eterno.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C108_Yggdrasil_Marinha — Yggdrasil Marinha
**Místico** · família do aquário **Recife** · revelação `crystal` · valor base 14100 · 20000–90970 kg · chance sem sorte 1 em 83 mil
**Conceito:** árvore-mundo nadando, raízes feitas de peixinhos de luz.
**Forma e detalhes:** Árvore-mundo que nada: tronco largo faz de corpo, raízes viram tentáculos, copa de coral luminoso, peixinhos de luz pendurados como frutos.
**Paleta:** madeira escura com veios dourados, coral rosa e lilás, verde-musgo, dourado e azul-luz neon.
**Partes (14, Neon 6):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | tronco largo de madeira escura | padrão |
| `Head` | nó do tronco com rosto sereno | padrão |
| `Tail` | raiz-cauda longa e grossa | padrão |
| `Tentacles` | raízes frontais em leque | padrão |
| `Legs` | raízes traseiras que 'caminham' na água | padrão |
| `Shell` | copa de coral rosa e lilás ao redor do corpo | padrão |
| `Wings` | galhos laterais abertos | padrão |
| `Fins` | folhas-barbatanas pequenas | padrão |
| `Extra` | frutos de luz dourada em cacho | **Neon** |
| `Extra` | peixinhos de luz azul orbitando | **Neon** |
| `Extra` | olhos de âmbar | **Neon** |
| `Extra` | veios dourados no tronco | **Neon** |
| `Extra` | flores luminosas rosa | **Neon** |
| `Extra` | musgo brilhante nos galhos | **Neon** |
**Movimento (CreatureMotion):** raízes ondulam, galhos abrem e fecham devagar, peixinhos orbitam a copa.
**Lore (1 linha):** Cada folha dele é um mundo; cada fruto, um peixe que ainda vai nascer.
**Leitura da silhueta (vira sombra na revelação):** tronco com copa em forma de coroa e raízes caindo como um polvo.
**Entrega:** `ReplicatedStorage.Creatures.C108_Yggdrasil_Marinha` · print em `art/creatures/C108_Yggdrasil_Marinha.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C109_Fenix_do_Vazio — Fênix do Vazio
**Místico** · família do aquário **Celestial** · revelação `cosmic` · valor base 12550 · 20000–75480 kg · chance sem sorte 1 em 42 mil
**Conceito:** fênix de buraco negro e estrelas, asas de nebulosa.
**Forma e detalhes:** Fênix feita de buraco negro e estrelas: corpo vazio preto-violeta com estrelas por dentro, asas de nebulosa, núcleo com disco de acreção no peito.
**Paleta:** preto-violeta, magenta e laranja de nebulosa, branco estelar, dourado escuro no bico.
**Partes (13, Neon 6):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo esguio preto-violeta salpicado de estrelas | padrão |
| `Head` | cabeça de ave com bico escuro | padrão |
| `Tail` | cauda longa de cinco plumas | padrão |
| `Wings` | par de asas de nebulosa | padrão |
| `Legs` | patas com garras | padrão |
| `Extra` | núcleo de buraco negro no peito | **Neon** |
| `Extra` | disco de acreção laranja-rosa | **Neon** |
| `Extra` | olhos brancos | **Neon** |
| `Extra` | crista de estrelas | **Neon** |
| `Extra` | plumas ciano das asas | **Neon** |
| `Extra` | rastro de poeira estelar na cauda | **Neon** |
| `Extra` | bico escuro | padrão |
| `Extra` | anel de órbita fino | padrão |
**Movimento (CreatureMotion):** asas batem lento com atraso nas pontas, núcleo pulsa, rastro ondula.
**Lore (1 linha):** Quando o céu se apagou, ela ficou acesa por dentro.
**Leitura da silhueta (vira sombra na revelação):** ave de asas largas com um círculo vazado no peito.
**Entrega:** `ReplicatedStorage.Creatures.C109_Fenix_do_Vazio` · print em `art/creatures/C109_Fenix_do_Vazio.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C110_Rei_Dragao_do_Oceano — Rei Dragão do Oceano
**Místico** · família do aquário **Tempestade** · revelação `storm` · valor base 13580 · 20000–85810 kg · chance sem sorte 1 em 63 mil
**Conceito:** dragão oriental de água viva, coroa de relâmpago.
**Forma e detalhes:** Dragão oriental serpentino, corpo de água viva translúcida turquesa, juba de nadadeiras, coroa de relâmpago, segura uma pérola luminosa.
**Paleta:** turquesa translúcido, azul-elétrico, branco-relâmpago, pérola dourada, coral vermelho nos chifres.
**Partes (14, Neon 6):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo serpentino comprido e translúcido | padrão |
| `Head` | cabeça de dragão com bigodes | padrão |
| `Tail` | cauda com nadadeira em fita | padrão |
| `Legs` | quatro patinhas | padrão |
| `Claws` | garras que seguram a pérola | padrão |
| `Fins` | juba de nadadeiras no dorso | padrão |
| `Extra` | coroa de relâmpago | **Neon** |
| `Extra` | pérola luminosa | **Neon** |
| `Extra` | bigodes longos de luz | **Neon** |
| `Extra` | olhos dourados | **Neon** |
| `Extra` | escamas luminosas no dorso | **Neon** |
| `Extra` | arco elétrico em volta do corpo | **Neon** |
| `Extra` | chifres de coral | padrão |
| `Extra` | barba de algas | padrão |
**Movimento (CreatureMotion):** corpo faz S lento, bigodes flutuam, relâmpago estala em intervalos (sem flash forte).
**Lore (1 linha):** Governa as marés com uma só respiração.
**Leitura da silhueta (vira sombra na revelação):** S de serpente com chifres e coroa pontuda.
**Entrega:** `ReplicatedStorage.Creatures.C110_Rei_Dragao_do_Oceano` · print em `art/creatures/C110_Rei_Dragao_do_Oceano.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C111_Deusa_da_Lua_Submersa — Deusa da Lua Submersa
**Místico** · família do aquário **Celestial** · revelação `frost` · valor base 11000 · 20000–60000 kg · chance sem sorte 1 em 28 mil
**Conceito:** serpente-lua prateada, véu de marés.
**Forma e detalhes:** Serpente-lua prateada de madrepérola; atrás da cabeça uma lua cheia faz de halo; fases da lua orbitam; véu de maré cai como cortina.
**Paleta:** prata madrepérola, azul-noite, branco-lua, lilás pálido, toques de ouro rosa.
**Partes (13, Neon 6):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de serpente em madrepérola | padrão |
| `Head` | rosto sereno de olhos fechados | padrão |
| `Tail` | cauda em fita de maré | padrão |
| `Fins` | véu de barbatanas translúcidas | padrão |
| `Extra` | lua cheia atrás da cabeça | **Neon** |
| `Extra` | crescente na testa | **Neon** |
| `Extra` | anel com as oito fases da lua | **Neon** |
| `Extra` | véu de luz azul-prata | **Neon** |
| `Extra` | estrelas na cauda | **Neon** |
| `Extra` | lágrimas de luz | **Neon** |
| `Extra` | colar de pérolas | padrão |
| `Extra` | escamas de pérola em faixa | padrão |
| `Extra` | coroa de coral branco | padrão |
**Movimento (CreatureMotion):** corpo ondula como seda, véu flutua, fases orbitam devagar.
**Lore (1 linha):** Quem vê a lua refletida no fundo do mar já foi escolhido por ela.
**Leitura da silhueta (vira sombra na revelação):** serpente com disco grande atrás da cabeça.
**Entrega:** `ReplicatedStorage.Creatures.C111_Deusa_da_Lua_Submersa` · print em `art/creatures/C111_Deusa_da_Lua_Submersa.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C112_Singularidade_Estelar — Singularidade Estelar
**Místico** · família do aquário **Abissal** · revelação `cosmic` · valor base 15000 · 20000–100000 kg · chance sem sorte 1 em 200 mil
**Conceito:** esfera viva com anéis e luas, olho central.
**Forma e detalhes:** Esfera viva de vidro cósmico negro com anéis estilo Saturno, luas e um olho central; filamentos de luz saem do corpo.
**Paleta:** preto-vidro, ciano e magenta de nebulosa, dourado, branco estelar.
**Partes (14, Neon 8):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | esfera de vidro cósmico negro | padrão |
| `Head` | olho central gigante | padrão |
| `Tail` | cauda de poeira de cometa | padrão |
| `Shell` | casca de arcos de metal escuro | padrão |
| `Tentacles` | filamentos de luz | padrão |
| `Fins` | anéis finos de apoio | padrão |
| `Extra` | anel externo | **Neon** |
| `Extra` | anel médio | **Neon** |
| `Extra` | anel interno | **Neon** |
| `Extra` | lua A | **Neon** |
| `Extra` | lua B | **Neon** |
| `Extra` | estrelas internas | **Neon** |
| `Extra` | pupila que muda de cor | **Neon** |
| `Extra` | corona em volta da esfera | **Neon** |
**Movimento (CreatureMotion):** anéis giram em velocidades diferentes, pupila acompanha a câmera, filamentos ondulam.
**Lore (1 linha):** Não nasceu; sempre esteve lá, esperando alguém olhar.
**Leitura da silhueta (vira sombra na revelação):** círculo grande com anéis inclinados e cauda curta.
**Entrega:** `ReplicatedStorage.Creatures.C112_Singularidade_Estelar` · print em `art/creatures/C112_Singularidade_Estelar.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C113_Pegaso_das_Ondas — Pégaso das Ondas
**Lendário** · família do aquário **Celestial** · revelação `cloud` · valor base 1910 · 1500–7770 kg · chance sem sorte 1 em 5,1 mil
**Conceito:** cavalo alado de espuma, crina de nuvem.
**Forma e detalhes:** Cavalo alado de espuma branca e azul, crina de nuvem, cascos de bolhas, galopa sobre as ondas.
**Paleta:** branco espuma, azul-céu, prata, toques de ouro nos cascos.
**Partes (11, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de cavalo de espuma | padrão |
| `Head` | cabeça nobre de crina de nuvem | padrão |
| `Tail` | cauda de ondas | padrão |
| `Wings` | asas grandes de espuma e penas | padrão |
| `Legs` | quatro patas com cascos de bolhas | padrão |
| `Fins` | crina em ondas | padrão |
| `Extra` | olhos azul-elétricos | **Neon** |
| `Extra` | brilho dourado nos cascos | **Neon** |
| `Extra` | faixa de estrelas no peito | **Neon** |
| `Extra` | sela de coral branco | padrão |
| `Extra` | cascata de espuma nas asas | padrão |
**Movimento (CreatureMotion):** asas batem lento, crina e cauda flutuam, patas trotam no ar.
**Lore (1 linha):** Cada galope dele levanta uma onda nova.
**Leitura da silhueta (vira sombra na revelação):** cavalo com asas abertas e crina em onda.
**Entrega:** `ReplicatedStorage.Creatures.C113_Pegaso_das_Ondas` · print em `art/creatures/C113_Pegaso_das_Ondas.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C114_Quimera_Marinha — Quimera Marinha
**Lendário** · família do aquário **Abissal** · revelação `magma` · valor base 1970 · 1500–8840 kg · chance sem sorte 1 em 10 mil
**Conceito:** leão, cobra e águia em um corpo só.
**Forma e detalhes:** Três animais em um corpo: cabeça de leão, cauda de serpente, asas de águia, corpo de peixe com escamas de bronze.
**Paleta:** bronze, vermelho-magma, dourado, verde-veneno na cobra.
**Partes (12, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de peixe-leão com escamas de bronze | padrão |
| `Head` | cabeça de leão com juba | padrão |
| `Tail` | cauda de cobra marinha | padrão |
| `Wings` | asas de águia | padrão |
| `Legs` | patas dianteiras de leão | padrão |
| `Claws` | garras de águia | padrão |
| `Fins` | barbatana dorsal em chamas | padrão |
| `Extra` | olhos de magma | **Neon** |
| `Extra` | língua da cobra | **Neon** |
| `Extra` | juba de brasas | **Neon** |
| `Extra` | presas de marfim | padrão |
| `Extra` | cabeça de águia no ombro | padrão |
**Movimento (CreatureMotion):** juba ondula, cauda de cobra serpenteia, asas abrem em pares.
**Lore (1 linha):** Ninguém sabe qual cabeça manda; as três discordam sempre.
**Leitura da silhueta (vira sombra na revelação):** leão alado com cauda de serpente pontuda.
**Entrega:** `ReplicatedStorage.Creatures.C114_Quimera_Marinha` · print em `art/creatures/C114_Quimera_Marinha.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C115_Leviata_de_Cristal — Leviatã de Cristal
**Lendário** · família do aquário **Celestial** · revelação `crystal` · valor base 1970 · 1500–8840 kg · chance sem sorte 1 em 10 mil
**Conceito:** serpente gigante de vitral, luz por dentro.
**Forma e detalhes:** Serpente gigante de vitral: corpo segmentado em vidros coloridos, luz acesa por dentro, cabeça com crista de cristais.
**Paleta:** vitral rosa, azul, âmbar e verde, branco no brilho interno.
**Partes (11, Neon 4):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo central de vidro colorido | padrão |
| `Head` | cabeça de serpente com mandíbula de cristal | padrão |
| `Tail` | cauda longa afinando em ponta | padrão |
| `Fins` | barbatana dorsal de lâminas de cristal | padrão |
| `Extra` | núcleo de luz no peito | **Neon** |
| `Extra` | olhos de âmbar | **Neon** |
| `Extra` | crista de cristais | **Neon** |
| `Extra` | faixas de vitral luminosas | **Neon** |
| `Extra` | anéis de segmento | padrão |
| `Extra` | espinhos de cristal na cauda | padrão |
| `Extra` | presas de vidro | padrão |
**Movimento (CreatureMotion):** corpo ondula em S, luz interna pulsa em ondas, cristais tilintam (só visual).
**Lore (1 linha):** O sol atravessa ele e pinta a água de sete cores.
**Leitura da silhueta (vira sombra na revelação):** serpente com crista de espinhos.
**Entrega:** `ReplicatedStorage.Creatures.C115_Leviata_de_Cristal` · print em `art/creatures/C115_Leviata_de_Cristal.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C116_Fenix_Glacial — Fênix Glacial
**Lendário** · família do aquário **Tempestade** · revelação `frost` · valor base 1910 · 1500–7770 kg · chance sem sorte 1 em 5,1 mil
**Conceito:** fênix de gelo, penas de cristal azul.
**Forma e detalhes:** Fênix de gelo: penas de cristal azul, cauda longa de agulhas de gelo, chama azul-clara no peito, névoa fria.
**Paleta:** azul-gelo, branco-neve, ciano, toques de lilás.
**Partes (11, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo esguio de gelo azulado | padrão |
| `Head` | cabeça de ave com crista de cristais | padrão |
| `Tail` | cauda de oito agulhas de gelo | padrão |
| `Wings` | asas de penas de cristal | padrão |
| `Legs` | garras de gelo | padrão |
| `Extra` | chama azul no peito | **Neon** |
| `Extra` | olhos ciano | **Neon** |
| `Extra` | brilho nas pontas das penas | **Neon** |
| `Extra` | bico de cristal branco | padrão |
| `Extra` | flocos de neve orbitando | padrão |
| `Extra` | névoa de gelo na cauda | padrão |
**Movimento (CreatureMotion):** asas batem devagar com cristais tilintando, cauda balança, neve cai.
**Lore (1 linha):** Quando ela canta, o mar para de se mexer.
**Leitura da silhueta (vira sombra na revelação):** ave com cauda de agulhas e asas largas pontudas.
**Entrega:** `ReplicatedStorage.Creatures.C116_Fenix_Glacial` · print em `art/creatures/C116_Fenix_Glacial.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C117_Basilisco_de_Coral — Basilisco de Coral
**Lendário** · família do aquário **Recife** · revelação `prism` · valor base 1910 · 1500–7770 kg · chance sem sorte 1 em 5,1 mil
**Conceito:** lagarto-rei de coral, coroa de pólipos.
**Forma e detalhes:** Lagarto-rei de coral vivo: pele de pólipos coloridos, crista de coroa, olhos que brilham verde, cauda que vira galho de coral.
**Paleta:** coral rosa, laranja e roxo, verde-lima, dourado na coroa.
**Partes (12, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de lagarto coberto de coral | padrão |
| `Head` | cabeça de rei com focinho de coral | padrão |
| `Tail` | cauda de galhos de coral | padrão |
| `Legs` | quatro patas fortes | padrão |
| `Claws` | garras de madrepérola | padrão |
| `Fins` | crista de leque de coral | padrão |
| `Extra` | olhos verde-lima | **Neon** |
| `Extra` | coroa dourada | **Neon** |
| `Extra` | pólipos luminosos no dorso | **Neon** |
| `Extra` | colar de conchas | padrão |
| `Extra` | anêmonas nas costas | padrão |
| `Extra` | línguas de coral | padrão |
**Movimento (CreatureMotion):** respira com o corpo, crista abre e fecha, cauda balança como galho.
**Lore (1 linha):** Cada passo dele planta um recife novo.
**Leitura da silhueta (vira sombra na revelação):** lagarto de crista em leque e cauda ramificada.
**Entrega:** `ReplicatedStorage.Creatures.C117_Basilisco_de_Coral` · print em `art/creatures/C117_Basilisco_de_Coral.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C118_Rainha_Sereia_Imperial — Rainha Sereia Imperial
**Lendário** · família do aquário **Celestial** · revelação `prism` · valor base 2000 · 1500–9380 kg · chance sem sorte 1 em 20 mil
**Conceito:** sereia com cauda de arco-íris e tridente.
**Forma e detalhes:** Sereia majestosa de cauda de arco-íris com escamas de pérola, tridente de coral e coroa de conchas, cabelo flutuando.
**Paleta:** arco-íris suave, pérola, turquesa, dourado, rosa-coral.
**Partes (12, Neon 4):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | torso e cauda de sereia | padrão |
| `Head` | rosto altivo com cabelo longo | padrão |
| `Tail` | cauda de arco-íris com barbatana grande | padrão |
| `Fins` | barbatanas laterais da cauda | padrão |
| `Claws` | mãos segurando o tridente | padrão |
| `Extra` | coroa de conchas luminosas | **Neon** |
| `Extra` | tridente de coral | **Neon** |
| `Extra` | escamas de arco-íris na cauda | **Neon** |
| `Extra` | pérola no peito | **Neon** |
| `Extra` | capa de algas-seda | padrão |
| `Extra` | colar de pérolas | padrão |
| `Extra` | cabelo em fios | padrão |
**Movimento (CreatureMotion):** cabelo e capa flutuam, cauda ondula em S, tridente brilha ao pulsar.
**Lore (1 linha):** Seu canto organiza as correntes como um maestro.
**Leitura da silhueta (vira sombra na revelação):** sereia com coroa pontuda e tridente alto.
**Entrega:** `ReplicatedStorage.Creatures.C118_Rainha_Sereia_Imperial` · print em `art/creatures/C118_Rainha_Sereia_Imperial.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C119_Wyvern_do_Relampago — Wyvern do Relâmpago
**Lendário** · família do aquário **Tempestade** · revelação `storm` · valor base 1970 · 1500–8840 kg · chance sem sorte 1 em 10 mil
**Conceito:** dragão de duas patas, asas de nuvem negra.
**Forma e detalhes:** Dragão de duas patas com asas de nuvem escura, corpo cinza-azulado, veias de raio, cauda com ponta em seta elétrica.
**Paleta:** cinza-chumbo, azul-elétrico, branco, amarelo-relâmpago.
**Partes (11, Neon 4):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo musculoso cinza-azulado | padrão |
| `Head` | cabeça angular com chifres | padrão |
| `Tail` | cauda longa com ponta em seta | padrão |
| `Wings` | asas grandes de nuvem escura | padrão |
| `Legs` | duas patas fortes | padrão |
| `Claws` | garras afiadas | padrão |
| `Extra` | veias de raio no corpo | **Neon** |
| `Extra` | olhos amarelos | **Neon** |
| `Extra` | ponta elétrica da cauda | **Neon** |
| `Extra` | trovoada nas asas | **Neon** |
| `Extra` | chifres curvos | padrão |
**Movimento (CreatureMotion):** asas batem rápidas, relâmpagos pequenos correm nas veias, cauda chicoteia.
**Lore (1 linha):** Voa sempre um segundo antes do trovão.
**Leitura da silhueta (vira sombra na revelação):** dragão de asas de morcego e cauda em seta.
**Entrega:** `ReplicatedStorage.Creatures.C119_Wyvern_do_Relampago` · print em `art/creatures/C119_Wyvern_do_Relampago.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C120_Colosso_Tentaculado — Colosso Tentaculado
**Lendário** · família do aquário **Abissal** · revelação `cosmic` · valor base 2000 · 1500–9380 kg · chance sem sorte 1 em 20 mil
**Conceito:** cabeça de polvo gigante, olhos de galáxia.
**Forma e detalhes:** Cabeça de polvo gigante cheia de olhos de galáxia, oito tentáculos longos com ventosas luminosas, manto com estrelas.
**Paleta:** roxo-profundo, azul-noite, magenta e ciano luminosos, branco-estrela.
**Partes (12, Neon 4):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | cabeça-manto grande roxa | padrão |
| `Head` | olhos centrais de galáxia | padrão |
| `Tail` | pontas finas atrás do manto | padrão |
| `Tentacles` | oito tentáculos longos | padrão |
| `Shell` | anel de espinhos no manto | padrão |
| `Fins` | barbatanas de manto | padrão |
| `Extra` | olho esquerdo galáctico | **Neon** |
| `Extra` | olho direito galáctico | **Neon** |
| `Extra` | ventosas luminosas | **Neon** |
| `Extra` | estrelas no manto | **Neon** |
| `Extra` | bico escuro | padrão |
| `Extra` | cicatrizes de combate | padrão |
**Movimento (CreatureMotion):** tentáculos ondulam com fases diferentes, olhos giram devagar, manto pulsa.
**Lore (1 linha):** Os navios sumiam; as estrelas, também.
**Leitura da silhueta (vira sombra na revelação):** cabeça de polvo enorme com tentáculos largando em leque.
**Entrega:** `ReplicatedStorage.Creatures.C120_Colosso_Tentaculado` · print em `art/creatures/C120_Colosso_Tentaculado.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C121_Esfinge_das_Mares — Esfinge das Marés
**Lendário** · família do aquário **Abissal** · revelação `crystal` · valor base 1910 · 1500–7770 kg · chance sem sorte 1 em 5,1 mil
**Conceito:** esfinge de pedra e coral, olhos de safira.
**Forma e detalhes:** Esfinge de pedra e coral deitada, com corpo de leão e cabeça de faraó, olhos de safira, asas de pedra, pergunta antiga gravada.
**Paleta:** pedra areia, coral turquesa, azul-safira, dourado.
**Partes (12, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de leão de pedra e coral | padrão |
| `Head` | rosto de faraó | padrão |
| `Tail` | cauda de leão | padrão |
| `Wings` | asas de pedra | padrão |
| `Legs` | patas dianteiras estendidas | padrão |
| `Claws` | garras de pedra | padrão |
| `Extra` | olhos de safira | **Neon** |
| `Extra` | runas luminosas no peito | **Neon** |
| `Extra` | gema na testa | **Neon** |
| `Extra` | toca de faraó listrada | padrão |
| `Extra` | barba cerimonial | padrão |
| `Extra` | algas nas costas | padrão |
**Movimento (CreatureMotion):** respira devagar, cauda balança, runas acendem em sequência.
**Lore (1 linha):** Faz uma única pergunta, e a resposta é sempre o mar.
**Leitura da silhueta (vira sombra na revelação):** leão deitado com toca de faraó e asas curtas.
**Entrega:** `ReplicatedStorage.Creatures.C121_Esfinge_das_Mares` · print em `art/creatures/C121_Esfinge_das_Mares.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C122_Golem_de_Coral_Ancestral — Golem de Coral Ancestral
**Lendário** · família do aquário **Recife** · revelação `crystal` · valor base 1910 · 1500–7770 kg · chance sem sorte 1 em 5,1 mil
**Conceito:** gigante de coral vivo, jardim nas costas.
**Forma e detalhes:** Gigante de coral vivo e pedra: corpo cheio de nichos com peixinhos e anêmonas, braços enormes, olhos de luz verde.
**Paleta:** coral laranja e rosa, pedra cinza-azulada, verde-água, âmbar.
**Partes (12, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | tronco de coral e pedra | padrão |
| `Head` | cabeça quadrada de pedra | padrão |
| `Tail` | cauda curta de rocha | padrão |
| `Legs` | pernas grossas | padrão |
| `Claws` | punhos enormes | padrão |
| `Shell` | ombreiras de coral | padrão |
| `Fins` | leques de coral nas costas | padrão |
| `Extra` | olhos verdes | **Neon** |
| `Extra` | núcleo de luz no peito | **Neon** |
| `Extra` | musgo luminoso nos ombros | **Neon** |
| `Extra` | anêmonas nas costas | padrão |
| `Extra` | peixinhos em nichos | padrão |
**Movimento (CreatureMotion):** respira e ondula, punhos pesam, pequenos peixes entram e saem.
**Lore (1 linha):** Plantou o primeiro recife e nunca mais saiu de lá.
**Leitura da silhueta (vira sombra na revelação):** gigante curvado com ombros largos e punhos enormes.
**Entrega:** `ReplicatedStorage.Creatures.C122_Golem_de_Coral_Ancestral` · print em `art/creatures/C122_Golem_de_Coral_Ancestral.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C123_Medusa_Imperatriz — Medusa Imperatriz
**Lendário** · família do aquário **Abissal** · revelação `spark` · valor base 1970 · 1500–8840 kg · chance sem sorte 1 em 10 mil
**Conceito:** medusa com coroa de espinhos e véus de luz.
**Forma e detalhes:** Medusa gigante com sino-coroa de espinhos e véus de luz que caem como vestido, tentáculos com pérolas luminosas.
**Paleta:** lilás, rosa, azul-neon, branco, dourado na coroa.
**Partes (11, Neon 4):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | sino translúcido grande | padrão |
| `Head` | núcleo do sino com rosto sereno | padrão |
| `Tail` | véu central comprido | padrão |
| `Tentacles` | fios de tentáculos longos | padrão |
| `Fins` | babados do sino | padrão |
| `Extra` | coroa de espinhos luminosos | **Neon** |
| `Extra` | pérolas nos fios | **Neon** |
| `Extra` | véu de luz | **Neon** |
| `Extra` | núcleo brilhante | **Neon** |
| `Extra` | fitas largas | padrão |
| `Extra` | colar de cristais | padrão |
**Movimento (CreatureMotion):** sino pulsa ritmado, véus flutuam atrasados, pérolas piscam em onda.
**Lore (1 linha):** Ela não pica; ela reina.
**Leitura da silhueta (vira sombra na revelação):** sino largo com coroa e véus caindo.
**Entrega:** `ReplicatedStorage.Creatures.C123_Medusa_Imperatriz` · print em `art/creatures/C123_Medusa_Imperatriz.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C124_Lobo_do_Mar_Lunar — Lobo do Mar Lunar
**Lendário** · família do aquário **Celestial** · revelação `frost` · valor base 1800 · 1500–5630 kg · chance sem sorte 1 em 2,5 mil
**Conceito:** lobo prateado de água, cauda de maré.
**Forma e detalhes:** Lobo prateado feito de água e luz de lua, crina de maré, cauda longa, uiva para uma lua cheia pequena a seu lado.
**Paleta:** prata, azul-noite, branco-lua, ciano.
**Partes (11, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de lobo de água prateada | padrão |
| `Head` | cabeça de lobo com focinho comprido | padrão |
| `Tail` | cauda longa de maré | padrão |
| `Legs` | quatro patas de ondas | padrão |
| `Claws` | garras de gelo | padrão |
| `Fins` | crina em ondas | padrão |
| `Extra` | lua pequena ao lado | **Neon** |
| `Extra` | olhos azul-lua | **Neon** |
| `Extra` | pelagem brilhante no dorso | **Neon** |
| `Extra` | gotas flutuando | padrão |
| `Extra` | coleira de estrelas | padrão |
**Movimento (CreatureMotion):** cabeça levanta em uivo, crina e cauda ondulam, patas pisam em ondas.
**Lore (1 linha):** Seu uivo faz a maré subir.
**Leitura da silhueta (vira sombra na revelação):** lobo uivando com lua ao lado.
**Entrega:** `ReplicatedStorage.Creatures.C124_Lobo_do_Mar_Lunar` · print em `art/creatures/C124_Lobo_do_Mar_Lunar.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C125_Tigre_das_Correntes — Tigre das Correntes
**Lendário** · família do aquário **Tempestade** · revelação `storm` · valor base 1910 · 1500–7770 kg · chance sem sorte 1 em 5,1 mil
**Conceito:** tigre listrado de correntezas, olhos elétricos.
**Forma e detalhes:** Tigre listrado de correntezas azuis e brancas, corpo musculoso, olhos elétricos, rastro de redemoinho.
**Paleta:** azul-correnteza, branco-espuma, ciano elétrico, dourado nos olhos.
**Partes (11, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo musculoso de tigre | padrão |
| `Head` | cabeça rugindo | padrão |
| `Tail` | cauda de redemoinho | padrão |
| `Legs` | patas fortes | padrão |
| `Claws` | garras de espuma | padrão |
| `Fins` | listras em relevo como nadadeiras | padrão |
| `Extra` | olhos elétricos | **Neon** |
| `Extra` | listras luminosas | **Neon** |
| `Extra` | rastro de redemoinho | **Neon** |
| `Extra` | bigodes de espuma | padrão |
| `Extra` | presas brancas | padrão |
**Movimento (CreatureMotion):** cauda e listras ondulam, rosna com respiração, rastro gira.
**Lore (1 linha):** Nunca para: a água precisa dele para correr.
**Leitura da silhueta (vira sombra na revelação):** tigre em salto com cauda enrolada.
**Entrega:** `ReplicatedStorage.Creatures.C125_Tigre_das_Correntes` · print em `art/creatures/C125_Tigre_das_Correntes.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C126_Elefante_Titan_das_Mares — Elefante Titã das Marés
**Lendário** · família do aquário **Recife** · revelação `cloud` · valor base 1910 · 1500–7770 kg · chance sem sorte 1 em 5,1 mil
**Conceito:** elefante-baleia gigante, presas de pérola.
**Forma e detalhes:** Elefante-baleia gigante: corpo azul-cinza, tromba que vira esguicho, presas de pérola, orelhas-nadadeira enormes.
**Paleta:** azul-cinza, pérola, coral rosa, ciano no esguicho.
**Partes (12, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo grande azul-cinza | padrão |
| `Head` | cabeça com tromba longa | padrão |
| `Tail` | cauda de baleia | padrão |
| `FinL` | orelha-nadadeira esquerda | padrão |
| `FinR` | orelha-nadadeira direita | padrão |
| `Legs` | pernas curtas e grossas | padrão |
| `Extra` | esguicho de luz na tromba | **Neon** |
| `Extra` | olhos pequenos dourados | **Neon** |
| `Extra` | pérolas nas presas | **Neon** |
| `Extra` | presas de pérola | padrão |
| `Extra` | cracas nas costas | padrão |
| `Extra` | manto de algas | padrão |
**Movimento (CreatureMotion):** orelhas batem como asas, tromba esguicha, cauda bate lenta.
**Lore (1 linha):** Sozinho, ele faz a ilha mais próxima balançar.
**Leitura da silhueta (vira sombra na revelação):** elefante com orelhas enormes e esguicho.
**Entrega:** `ReplicatedStorage.Creatures.C126_Elefante_Titan_das_Mares` · print em `art/creatures/C126_Elefante_Titan_das_Mares.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C127_Caranguejo_Colosso — Caranguejo Colosso
**Lendário** · família do aquário **Abissal** · revelação `magma` · valor base 1800 · 1500–5630 kg · chance sem sorte 1 em 2,5 mil
**Conceito:** caranguejo-ilha, vulcão nas costas.
**Forma e detalhes:** Caranguejo do tamanho de uma ilha: casco com vulcão nas costas, lava escorrendo, garras gigantes de basalto.
**Paleta:** basalto preto, vermelho-lava, laranja, cinza-cinza.
**Partes (11, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | casco largo de basalto | padrão |
| `Head` | olhos em hastes e boca | padrão |
| `Legs` | oito patas articuladas | padrão |
| `Claws` | duas garras gigantes | padrão |
| `Shell` | vulcão nas costas | padrão |
| `Extra` | lava escorrendo | **Neon** |
| `Extra` | cratera brilhante | **Neon** |
| `Extra` | olhos laranja | **Neon** |
| `Extra` | rochas na carapaça | padrão |
| `Extra` | cracas de lava | padrão |
| `Extra` | fumaça | padrão |
**Movimento (CreatureMotion):** garras abrem e fecham, patas andam de lado, vulcão solta brasas.
**Lore (1 linha):** Um dia ele sai da água e a ilha anda junto.
**Leitura da silhueta (vira sombra na revelação):** caranguejo com cone de vulcão e duas garras gigantes.
**Entrega:** `ReplicatedStorage.Creatures.C127_Caranguejo_Colosso` · print em `art/creatures/C127_Caranguejo_Colosso.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C128_Garca_Estelar — Garça Estelar
**Lendário** · família do aquário **Celestial** · revelação `cosmic` · valor base 1970 · 1500–8840 kg · chance sem sorte 1 em 10 mil
**Conceito:** garça de constelações, pescoço de aurora.
**Forma e detalhes:** Garça de constelações: pescoço longo de aurora, penas pontilhadas de estrelas, bico fino dourado, parada em um pé.
**Paleta:** azul-noite, verde-aurora, branco-estrela, dourado.
**Partes (11, Neon 4):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo esguio de penas azul-noite | padrão |
| `Head` | cabeça fina de garça | padrão |
| `Tail` | cauda curta de estrelas | padrão |
| `Wings` | asas longas de aurora | padrão |
| `Legs` | pernas finas | padrão |
| `Extra` | pescoço de aurora luminosa | **Neon** |
| `Extra` | constelação no peito | **Neon** |
| `Extra` | olhos brancos | **Neon** |
| `Extra` | estrelas nas asas | **Neon** |
| `Extra` | bico dourado | padrão |
| `Extra` | crista de penas finas | padrão |
**Movimento (CreatureMotion):** pescoço balança como onda, asas abrem devagar, estrelas piscam.
**Lore (1 linha):** Caça estrelas que caíram no mar.
**Leitura da silhueta (vira sombra na revelação):** garça de pescoço em S e uma perna.
**Entrega:** `ReplicatedStorage.Creatures.C128_Garca_Estelar` · print em `art/creatures/C128_Garca_Estelar.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C129_Mamute_de_Gelo_Marinho — Mamute de Gelo Marinho
**Lendário** · família do aquário **Tempestade** · revelação `frost` · valor base 1800 · 1500–5630 kg · chance sem sorte 1 em 2,5 mil
**Conceito:** mamute-narval de gelo, aurora nas presas.
**Forma e detalhes:** Mamute-narval: corpo peludo de gelo azul, presa longa em espiral com aurora dentro, patas largas, vapor frio.
**Paleta:** azul-gelo, branco, verde-aurora, lilás.
**Partes (11, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo peludo de gelo | padrão |
| `Head` | cabeça com tromba curta | padrão |
| `Tail` | cauda de pelos de gelo | padrão |
| `Legs` | quatro patas largas | padrão |
| `Fins` | pelo longo lateral | padrão |
| `Extra` | presa em espiral com aurora | **Neon** |
| `Extra` | olhos azul-gelo | **Neon** |
| `Extra` | cristais nos ombros | **Neon** |
| `Extra` | orelhas pequenas | padrão |
| `Extra` | flocos de neve | padrão |
| `Extra` | vapor frio | padrão |
**Movimento (CreatureMotion):** respira com vapor, presa brilha, pelos balançam.
**Lore (1 linha):** Cada pegada dele congela um pedaço de mar.
**Leitura da silhueta (vira sombra na revelação):** mamute com presa em espiral e corcova.
**Entrega:** `ReplicatedStorage.Creatures.C129_Mamute_de_Gelo_Marinho` · print em `art/creatures/C129_Mamute_de_Gelo_Marinho.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C130_Megalodonte_Real — Megalodonte Real
**Lendário** · família do aquário **Abissal** · revelação `storm` · valor base 1910 · 1500–7770 kg · chance sem sorte 1 em 5,1 mil
**Conceito:** tubarão colossal com coroa de dentes dourados.
**Forma e detalhes:** Tubarão colossal de couro cinza-escuro, dentes dourados como coroa, cicatrizes douradas, olhos vermelhos.
**Paleta:** cinza-ardósia, dourado, vermelho-sangue nos olhos, branco.
**Partes (11, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de tubarão gigante | padrão |
| `Head` | cabeça larga com mandíbula | padrão |
| `Tail` | cauda em lua crescente | padrão |
| `FinL` | nadadeira peitoral esquerda | padrão |
| `FinR` | nadadeira peitoral direita | padrão |
| `Fins` | nadadeira dorsal grande | padrão |
| `Extra` | olhos vermelhos | **Neon** |
| `Extra` | cicatrizes douradas | **Neon** |
| `Extra` | coroa de dentes | **Neon** |
| `Extra` | dentes dourados | padrão |
| `Extra` | guelras marcadas | padrão |
**Movimento (CreatureMotion):** cauda bate larga, boca abre e fecha, nadadeiras estáveis.
**Lore (1 linha):** O rei chega sem aviso; o mar fica em silêncio.
**Leitura da silhueta (vira sombra na revelação):** tubarão grande com coroa de dentes.
**Entrega:** `ReplicatedStorage.Creatures.C130_Megalodonte_Real` · print em `art/creatures/C130_Megalodonte_Real.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C131_Naga_das_Profundezas — Naga das Profundezas
**Lendário** · família do aquário **Abissal** · revelação `prism` · valor base 1800 · 1500–5630 kg · chance sem sorte 1 em 2,5 mil
**Conceito:** cobra de sete cabeças, escamas opalinas.
**Forma e detalhes:** Cobra de sete cabeças com escamas opalinas que mudam de cor, capuz aberto, gemas nas testas, cauda enrolada.
**Paleta:** opala (rosa, verde, azul), roxo-profundo, dourado, branco.
**Partes (10, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo enrolado de escamas opalinas | padrão |
| `Head` | cabeça central de cobra | padrão |
| `Tail` | cauda em espiral | padrão |
| `Fins` | capuz aberto em leque | padrão |
| `Extra` | gemas nas testas | **Neon** |
| `Extra` | olhos dourados | **Neon** |
| `Extra` | escamas opalinas luminosas | **Neon** |
| `Extra` | seis cabeças laterais | padrão |
| `Extra` | presas finas | padrão |
| `Extra` | língua bifurcada | padrão |
**Movimento (CreatureMotion):** cabeças balançam fora de fase, capuz abre e fecha, cauda se desenrola.
**Lore (1 linha):** Sete bocas, uma só vontade.
**Leitura da silhueta (vira sombra na revelação):** cobra com sete cabeças em leque.
**Entrega:** `ReplicatedStorage.Creatures.C131_Naga_das_Profundezas` · print em `art/creatures/C131_Naga_das_Profundezas.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C132_Oraculo_do_Mar — Oráculo do Mar
**Lendário** · família do aquário **Celestial** · revelação `cosmic` · valor base 1970 · 1500–8840 kg · chance sem sorte 1 em 10 mil
**Conceito:** peixe-olho gigante, halo de runas.
**Forma e detalhes:** Peixe-olho gigante: corpo redondo com um olho enorme de íris galáctica, halo de runas, barbatanas de véu.
**Paleta:** violeta, azul-noite, dourado, branco-rúnico.
**Partes (11, Neon 4):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo redondo de peixe | padrão |
| `Head` | olho gigante | padrão |
| `Tail` | cauda de véu | padrão |
| `FinL` | barbatana esquerda de véu | padrão |
| `FinR` | barbatana direita de véu | padrão |
| `Extra` | íris galáctica | **Neon** |
| `Extra` | halo de runas | **Neon** |
| `Extra` | runas menores orbitando | **Neon** |
| `Extra` | pupila | **Neon** |
| `Extra` | cílios longos | padrão |
| `Extra` | colar de ouro | padrão |
**Movimento (CreatureMotion):** olho acompanha a câmera, runas giram, barbatanas flutuam.
**Lore (1 linha):** Ele já viu o que você vai pescar.
**Leitura da silhueta (vira sombra na revelação):** círculo com olho e halo dentado.
**Entrega:** `ReplicatedStorage.Creatures.C132_Oraculo_do_Mar` · print em `art/creatures/C132_Oraculo_do_Mar.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C133_Sol_Vivo_das_Mares — Sol Vivo das Marés
**Lendário** · família do aquário **Celestial** · revelação `magma` · valor base 1910 · 1500–7770 kg · chance sem sorte 1 em 5,1 mil
**Conceito:** peixe-sol dourado, raios como barbatanas.
**Forma e detalhes:** Peixe-sol dourado: corpo redondo, raios como barbatanas, núcleo de fogo-suave, coroa de chamas amenas.
**Paleta:** ouro, laranja, amarelo-claro, branco quente.
**Partes (11, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo redondo dourado | padrão |
| `Head` | rosto sorridente | padrão |
| `Tail` | cauda de raios | padrão |
| `Fins` | raios em coroa | padrão |
| `FinL` | barbatana-raio esquerda | padrão |
| `FinR` | barbatana-raio direita | padrão |
| `Extra` | núcleo quente | **Neon** |
| `Extra` | coroa de chamas | **Neon** |
| `Extra` | raios longos | **Neon** |
| `Extra` | olhos pretos brilhantes | padrão |
| `Extra` | bochechas rosadas | padrão |
**Movimento (CreatureMotion):** raios giram lentos, pulsa como respiração, cauda balança.
**Lore (1 linha):** Quando ele nada perto da superfície, é meio-dia o dia todo.
**Leitura da silhueta (vira sombra na revelação):** disco com raios afiados em volta.
**Entrega:** `ReplicatedStorage.Creatures.C133_Sol_Vivo_das_Mares` · print em `art/creatures/C133_Sol_Vivo_das_Mares.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C134_Vulcao_Nadador — Vulcão Nadador
**Lendário** · família do aquário **Tempestade** · revelação `magma` · valor base 1800 · 1500–5630 kg · chance sem sorte 1 em 2,5 mil
**Conceito:** ilha vulcânica que nada, lava em rios.
**Forma e detalhes:** Ilha vulcânica que nada: corpo de rocha negra com crateras, rios de lava, cauda de basalto, nadadeiras de pedra.
**Paleta:** preto-basalto, vermelho-lava, laranja, cinza.
**Partes (11, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de rocha com cratera | padrão |
| `Head` | boca de lava na frente | padrão |
| `Tail` | cauda de basalto | padrão |
| `FinL` | nadadeira de pedra esquerda | padrão |
| `FinR` | nadadeira de pedra direita | padrão |
| `Fins` | crista de pedras | padrão |
| `Extra` | lava escorrendo | **Neon** |
| `Extra` | cratera brilhante | **Neon** |
| `Extra` | olhos de brasa | **Neon** |
| `Extra` | pedras | padrão |
| `Extra` | fumaça | padrão |
**Movimento (CreatureMotion):** nada devagar balançando, solta brasas, cauda bate.
**Lore (1 linha):** Já foi confundido com uma ilha por três reinos.
**Leitura da silhueta (vira sombra na revelação):** cone de vulcão com cauda e nadadeiras.
**Entrega:** `ReplicatedStorage.Creatures.C134_Vulcao_Nadador` · print em `art/creatures/C134_Vulcao_Nadador.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C135_Imperador_Orca_Sombria — Imperador Orca Sombria
**Lendário** · família do aquário **Abissal** · revelação `frost` · valor base 1800 · 1500–5630 kg · chance sem sorte 1 em 2,5 mil
**Conceito:** orca preta com manto de aurora.
**Forma e detalhes:** Orca preta com manto de aurora flutuando atrás, cicatrizes brilhantes, coroa de gelo, olhos claros.
**Paleta:** preto, branco, verde-aurora, azul-gelo.
**Partes (11, Neon 3):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo de orca preto | padrão |
| `Head` | cabeça com mancha branca | padrão |
| `Tail` | cauda larga | padrão |
| `FinL` | nadadeira peitoral esquerda | padrão |
| `FinR` | nadadeira peitoral direita | padrão |
| `Fins` | nadadeira dorsal alta | padrão |
| `Extra` | manto de aurora | **Neon** |
| `Extra` | cicatrizes luminosas | **Neon** |
| `Extra` | olhos azul-gelo | **Neon** |
| `Extra` | coroa de gelo | padrão |
| `Extra` | dentes brancos | padrão |
**Movimento (CreatureMotion):** cauda bate forte, manto ondula, nadadeira dorsal firme.
**Lore (1 linha):** Comanda as outras orcas com um só canto grave.
**Leitura da silhueta (vira sombra na revelação):** orca com manto triangular e coroa de gelo.
**Entrega:** `ReplicatedStorage.Creatures.C135_Imperador_Orca_Sombria` · print em `art/creatures/C135_Imperador_Orca_Sombria.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
### C136_Polvo_Alquimista — Polvo Alquimista
**Lendário** · família do aquário **Recife** · revelação `prism` · valor base 1970 · 1500–8840 kg · chance sem sorte 1 em 10 mil
**Conceito:** polvo com oito frascos mágicos nos braços.
**Forma e detalhes:** Polvo sábio com chapéu de bruxo, oito braços segurando frascos coloridos e livros; óculos de latão.
**Paleta:** roxo, verde-poção, dourado, laranja, vidro.
**Partes (12, Neon 4):**
| Nome da peça | O que é | Material |
|---|---|---|
| `Body` | corpo-cabeça roxo | padrão |
| `Head` | rosto com óculos | padrão |
| `Tail` | ponta fina atrás | padrão |
| `Tentacles` | oito braços | padrão |
| `Extra` | frasco verde | **Neon** |
| `Extra` | frasco rosa | **Neon** |
| `Extra` | frasco azul | **Neon** |
| `Extra` | olhos brilhantes | **Neon** |
| `Extra` | chapéu de bruxo | padrão |
| `Extra` | óculos de latão | padrão |
| `Extra` | livro de feitiços | padrão |
| `Extra` | colher de pau | padrão |
**Movimento (CreatureMotion):** braços se mexem como quem mistura, frascos borbulham.
**Lore (1 linha):** Transformou lixo em ouro e peixe em outra coisa.
**Leitura da silhueta (vira sombra na revelação):** polvo com chapéu pontudo e braços carregando frascos.
**Entrega:** `ReplicatedStorage.Creatures.C136_Polvo_Alquimista` · print em `art/creatures/C136_Polvo_Alquimista.png` · tamanho ~3,2 a 3,55 studs no maior lado.
---
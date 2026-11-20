# Auditoria das Criaturas Épicas (21 espécies)

Auditoria completa em `Edit` no place `112666482424701` (`ReplicatedStorage.Creatures`), com folha de 6 ângulos (`1. Frente +Z`, `2. 3/4 Frontal`, `3. Perfil +X`, `4. Costas -Z`, `5. Topo +Y`, `6. 3/4 Traseiro`) e recortes individuais salvos em `art/creatures/<id>/antes/`.

- **Orçamento-alvo para Épicas (mobile-first):** até `~2.500` triângulos no total (`~800` por peça), atlas `512 × 512 px` pintado por código, escala `~3.0–3.2` studs, frente `+Z` (`Head.Z - Tail.Z > 0`), peças rígidas filhas diretas nomeadas para o `CreatureMotion` (`Body = PrimaryPart`, `Head`, `Tail`, `FinL`, `FinR`, `Fins`, `Wings`, `Tentacles`, `Legs`, `Claws`, `Shell`, `Extra`).
- **Resumo das decisões:** **10 REFAZER** (3 no Lote Piloto + 7 nos Lotes 2 e 3) e **11 MANTER** (modelos que já têm ótima leitura frontal, silhueta forte e segmentação funcional no `CreatureMotion`).

---

## 1. Tabela Geral de Auditoria (21 Épicas)

| ID | Nome | Estilo / Pool | Partes atuais (`MeshPart` + `Part`) | Bounding Box (studs) | Cores / Atlas | Silhueta (0–5) | Rosto `+Z` (0–5) | Detalhe (0–5) | Decisão | Motivo técnico e visual |
|---|---|---|---|---|---|---:|---:|---:|---|---|
| `C09_Guardiao_Cristal` | Guardião de Cristal | `crystal` · Normal | `Body, Head, Shell, Fins` (4 meshes; sem `Tail`, sem `FinL/FinR`) | `2.58 × 2.83 × 3.00` | 1 textura (`#A3A2A5`) | 3.0 | 2.0 | 2.0 | **REFAZER (Piloto #1)** | Cristais das costas derretidos/fundidos por geração de IA; rosto sob o casco sem olhos legíveis de frente; nadadeiras dianteiras presas numa peça só (`Fins`). |
| `C20_Raia_Vulcanica` | Raia Vulcânica | `magma` · Normal | `Body, Wings, Tail` (3 meshes; **sem `Head`**) | `3.00 × 1.10 × 2.63` | 1 textura (`#A3A2A5`) | 2.0 | 1.0 | 2.0 | **REFAZER (Piloto #2)** | Sem peça `Head`; de frente (`+Z`) o rosto é uma mancha escura sem olhos; a cauda tem `0.04` stud de espessura com um artefato em "T" na ponta. |
| `C21_Baleia_Nebulosa` | Baleia Nebulosa | `cloud` · Normal | `Body, Fins, Tail, Extra` (4 meshes; **sem `Head`**) | `1.99 × 2.15 × 3.00` | 1 textura (`#A3A2A5`) | 3.0 | 2.0 | 3.0 | **REFAZER (Lote 2)** | De frente (`+Z`) só aparece o queixo branco; olhos escondidos na lateral, sem `Head` e nadadeiras peitorais fundidas em `Fins`. |
| `C22_Serpente_Glacial` | Serpente Glacial | `frost` · Normal | `Body, Head, Tail` (3 meshes) | `2.50 × 3.00 × 2.65` | 1 textura (`#A3A2A5`) | 3.5 | 2.0 | 2.5 | **REFAZER (Lote 2)** | Boa pose em anel erguido, mas a crista de gelo tem pontas ruidosas de geração automática e o rosto de frente quase não tem contraste de olhos/focinho. |
| `C29_Dragao_Folha` | Dragão-Folha Esmeralda | `spark` · Normal | `Body, Head, Wings, Tail` (4 meshes) | `2.86 × 2.46 × 2.34` | 1 textura (`#A3A2A5`) | 4.5 | 4.0 | 4.0 | **MANTER** | Silhueta muito carismática (corpo esmeralda, grandes asas folha rosa-magenta, cauda espiralada e olhos grandes legíveis de frente). |
| `C33_Orca_Aurora` | Orca Aurora | `frost` · Normal | `Body, Fins, Tail` (3 meshes; **sem `Head`**) | `2.50 × 2.04 × 2.92` | 1 textura (`#A3A2A5`) | 3.5 | 3.0 | 2.5 | **REFAZER (Lote 2)** | Sem peça `Head`; dorsal e peitorais fundidas numa única peça `Fins` (entortam juntas no `CreatureMotion`); mancha de aurora na lateral pixelada. |
| `C56_Dragao_de_Coral` | Dragão de Coral | `prism` · Normal | `Body, Head, Wings, Legs, Tail, Extra` (6 meshes) | `2.31 × 2.95 × 1.86` | 6 texturas (`#A3A2A5`) | 4.0 | 4.0 | 4.5 | **MANTER** | Silhueta parruda com ombreiras e chifres de coral vivo rosa/turquesa, rosto legível de frente e 6 partes bem separadas para animação. |
| `C57_Manta_Galactica` | Manta Galáctica | `cosmic` · Normal | `Body, Head, Wings, Tail, Extra` (5 meshes) | `2.95 × 0.79 × 2.57` | 5 texturas (`#A3A2A5`) | 4.5 | 4.0 | 4.0 | **MANTER** | Asas curvadas elegantes em degradê azul-magenta, `Head` separado com lóbulos e olhos claros, boa leitura frontal e superior. |
| `C58_Tubarao_Fantasma` | Tubarão Fantasma | `frost` · Normal | `Body, Head, FinL, FinR, Fins, Tail` (6 meshes) | `2.31 × 2.61 × 2.95` | 6 texturas (`#A3A2A5`) | 4.5 | 4.5 | 4.0 | **MANTER** | Rosto frontal super expressivo (sorriso largo, olhos ciano brilhantes, barriga rosa-espectral) e todas as 6 partes de nado separadas. |
| `C59_Narval_Unicornio` | Narval Unicórnio | `crystal` · Normal | `Body, Head, FinR, FinL, Tail, Extra` (6 meshes) | `2.05 × 1.83 × 2.95` | 6 texturas (`#A3A2A5`) | 4.5 | 4.0 | 4.0 | **MANTER** | Visual cartoony candy redondo em pastel perolado/rosa, chifre espiral arco-íris (`Extra`) bem destacado e membros separados. |
| `C82_Kitsune_Aquatica` | Kitsune Aquática | `spark` · Normal | `Body, Head, FinL, FinR, Tail, Extra` + 5 `Part` Neon | `2.80 × 2.57 × 2.09` | 6 texturas + Neon (`#64F0FF`, `#FF6EE1`) | 4.5 | 4.5 | 4.5 | **MANTER** | Excelente leitura frontal: o leque de 9 caudas ciano-rosa (`Extra`) emoldura a cabeça de raposa na revelação e no card 3D. |
| `C83_Golfinho_Trovao` | Golfinho Trovão | `storm` · Normal | `Body, Head, FinR, FinL, Fins, Tail, Extra` + 4 `Part` Neon | `1.66 × 2.30 × 2.56` | 7 texturas + Neon (`#73F0FF`, `#FFE650`) | 3.5 | 2.5 | 2.5 | **REFAZER (Lote 3)** | Duas esferas `Neon` amarelas coladas na ponta do bico parecem olhos falsos brigando com os olhos reais; `Extra` na cauda parece arame solto. |
| `C84_Tubarao_Martelo_de_Cristal` | Tubarão-Martelo de Cristal | `crystal` · Normal | `Body, Head, FinL, FinR, Fins, Tail, Extra` + 4 `Part` Neon | `2.09 × 2.75 × 1.40` | 7 texturas + Neon (`#FF6EE1`, `#6EF5FF`) | 2.0 | 1.5 | 2.0 | **REFAZER (Piloto #3)** | Postura vertical torta (`1.40` stud em Z); a cabeça (`Head`) parece 3 blocos de marshmallow rosa inchados sem facetas de cristal nem cara de tubarão. |
| `C85_Lula_Galaxia` | Lula Galáxia | `cosmic` · Normal | `Body, Head, Fins, Tentacles, Extra` + 5 `Part` Neon | `1.36 × 2.95 × 0.80` | 5 texturas + Neon (`#FFE164`, `#FF6EE1`) | 2.5 | 1.0 | 2.5 | **REFAZER (Lote 3)** | **Rosto e tentáculos estão virados para `-Z` (de costas!)**: de frente (`+Z`) só aparecem as costas lisas com 2 pontinhos Neon; malha muito fina (`0.80` stud em Z). |
| `C86_Cervo_Coral` | Cervo-Coral | `splash` · Normal | `Body, Head, Legs, Fins, Tail, Extra` + 4 `Part` Neon | `1.90 × 2.95 × 2.07` | 6 texturas + Neon (`#64F5FF`, `#FF6EE1`) | 4.5 | 4.0 | 4.0 | **MANTER** | Silhueta elegante com galhada de coral vermelho-laranja (`Extra`), manto de recife rosa e boa leitura frontal (já validado no QA de revelação). |
| `C87_Salamandra_de_Lava` | Salamandra de Lava | `magma` · Normal | `Body, Head, Legs, Fins, Tail, Extra` + 4 `Part` Neon | `1.68 × 2.00 × 2.21` | 6 texturas + Neon (`#FF8232`, `#FFC346`) | 4.5 | 4.5 | 4.5 | **MANTER** | Axolote/salamandra vulcânica super expressiva de frente (olhos vermelhos, brânquias em chama, runas de lava e ponta da cauda incandescente). |
| `C96_Lua_Dourada` | Lua Dourada | `cosmic` · `starTide` | `Body, Head, FinR, FinL, Fins, Tail, Extra` + 4 `Part` Neon | `2.20 × 2.27 × 2.47` | 7 texturas + Neon (`#FFD746`, `#FFE15A`) | 3.0 | 2.5 | 2.5 | **REFAZER (Lote 3)** | Rosa-chiclete em vez de dourada; de frente (`+Z`) uma crista pontuda divide a cara ao meio, os olhos ficam escondidos de lado e há esferas Neon soltas no ar. |
| `C97_Raia_Tempestade` | Raia Tempestade | `storm` · `thunderStorm` | `Body, Head, Wings, Tail, Extra` + 4 `Part` Neon | `2.85 × 2.44 × 2.23` | 5 texturas + Neon (`#FFE150`, `#73F0FF`) | 4.0 | 4.0 | 4.0 | **MANTER** | Rosto sorridente bem visível de frente (`+Z`), asas com raios amarelos e nuvem escura fofa flutuando sobre o dorso (`Extra`). |
| `C98_Coral_Ancestral_Vivo` | Coral Ancestral Vivo | `crystal` · `goldenHour` | `Body, Head, Claws, Fins, Tail, Extra` + 5 `Part` Neon | `2.32 × 3.01 × 2.10` | 6 texturas + Neon (`#FF82D2`, `#FFD255`) | 4.0 | 4.0 | 4.0 | **MANTER** | Monstrinho de recife turquesa/dourado com braços e chifres de coral rosa (`Claws`) e algas verdes nas costas (`Fins`); boa leitura frontal. |
| `C104_Polvo_Presente` | Polvo-Presente | `spark` · `xmas` | `Body, Head, Tentacles, Extra` (4 meshes) | `3.85 × 2.60 × 3.98` | 4 texturas (`#A3A2A5`) | 3.0 | 1.5 | 3.5 | **REFAZER (Lote 3)** | **O rosto está virado para `+X` (de lado!)** — de frente (`+Z`) aparece a quina da caixa com fita; escala (`3.98` studs) e `pivot_offset` (`0.45`) fora do orçamento. |
| `C105_Estrela_do_Natal` | Estrela do Natal | `prism` · `xmas` | `Body, Head, Fins, Extra` (4 meshes) | `3.04 × 3.05 × 2.27` | 4 texturas (`#A3A2A5`) | 4.5 | 4.5 | 4.0 | **MANTER** | Estrela dourada fofa com olhinhos e bochechas rosadas voltados para `+Z` e auréola natalina no topo (`Extra`). |

---

## 2. Planejamento dos Lotes de Remodelagem (10 Épicas)

### Lote Piloto (3 Épicas de anatomias bem distintas — aguardando aprovação do João após modelagem)
1. **`C09_Guardiao_Cristal` (Guardião de Cristal)** — *Tartaruga encouraçada de cristal*:
   - Peças: `Body`, `Head`, `Shell`, `FinL`, `FinR`, `Tail`, `Extra` (drusa de cristais ciano-safira no casco + coroa frontal).
   - Assinaturas visuais: casco facetado azul-abissal com borda dourada/ciano + grande formação de cristais lapidados nas costas e rosto simpático com olhos brilhantes bem visíveis de frente (`+Z`).
2. **`C20_Raia_Vulcanica` (Raia Vulcânica)** — *Planador largo de magma*:
   - Peças: `Body`, `Head`, `Wings`, `Tail`, `Extra` (chifres/cristas de basalto e núcleo de magma dorsal).
   - Assinaturas visuais: asas curvas de basalto escuro com veias de lava laranja-ouro pintadas no atlas, cabeça expressiva (`Head`) com olhos âmbar e chifres vulcânicos, e cauda em chicote com lança de cristal incandescente (`Tail`).
3. **`C84_Tubarao_Martelo_de_Cristal` (Tubarão-Martelo de Cristal)** — *Predador hidrodinâmico de cristal*:
   - Peças: `Body`, `Head`, `FinL`, `FinR`, `Fins`, `Tail`, `Extra` (gemas facetadas nas pontas do martelo e no dorso).
   - Assinaturas visuais: cabeça em T larga e aerodinâmica com pontas de diamante rosa/ciano e olhos expressivos voltados para `+Z`, barbatana dorsal em lâmina de cristal (`Fins`) e cauda em meia-lua (`Tail`).

### Lote 2 (após aprovação do Lote Piloto)
4. **`C21_Baleia_Nebulosa`** (`Body, Head, FinL, FinR, Tail, Extra`)
5. **`C22_Serpente_Glacial`** (`Body, Head, Fins, Tail, Extra`)
6. **`C33_Orca_Aurora`** (`Body, Head, FinL, FinR, Fins, Tail`)

### Lote 3 (após aprovação do Lote Piloto)
7. **`C83_Golfinho_Trovao`** (`Body, Head, FinL, FinR, Fins, Tail, Extra`)
8. **`C85_Lula_Galaxia`** (`Body, Head, Fins, Tentacles, Extra`)
9. **`C96_Lua_Dourada`** (`Body, Head, FinL, FinR, Fins, Tail, Extra`)
10. **`C104_Polvo_Presente`** (`Body, Head, Tentacles, Extra`)

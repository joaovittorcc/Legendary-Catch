# Auditoria das Criaturas Raras (`rarity = "Rare"`)

- **Data:** 2026-11-20
- **Responsável:** Antigravity
- **Total no catálogo (`Config/Creatures.luau`):** 22 criaturas Raras (20 normais + 1 de evento `shimmerShoal` + 1 de Natal `xmas`).
- **Critério:** consistência com o estilo *Cartoony candy* (`docs/NOITE.md`), rosto legível na câmera frontal `+Z` (`Head.Z - Tail.Z > 0`), compatibilidade com `CreatureMotion` (`Body = PrimaryPart`, peças diretas sem ossos), escala até `2,95` studs e orçamento mobile (`<= 1.500` triângulos totais / `<= 500` por peça, atlas `256`–`512` px).
- **Capturas de 6 ângulos (antes):** `art/creatures/<ID>/antes/` (`6-angulos.jpg` + `01-frente.jpg` .. `06-3-4-traseiro.jpg`).

---

## Resumo das Decisões

- **`MANTER` (16):** `C07_Arraia_Prisma`, `C08_Enguia_Trovao`, `C17_Martelo_Coral`, `C18_Lula_Neon`, `C19_Peixe_Lua_Dourado`, `C28_Nautilo_Aurora`, `C32_Espadarte_Relampago`, `C51_Lanterna_Abissal`, `C52_Cavalo_Marinho_Real`, `C53_Moreia_Voltaica`, `C54_Peixe_Vela_Solar`, `C77_Cavalo_Marinho_Relogio`, `C79_Mantarraia_Vitral`, `C80_Peixe_Pavao_Eletrico`, `C81_Enguia_Fita_de_Seda`, `C95_Peixe_Vagalume_Real`.
- **`REFAZER` (6, em 2 lotes de 3):**
  - **Lote Piloto (3 bem diferentes):** `C50_Tubarao_Baleia_Estrelado`, `C55_Caranguejo_Rei_Gelo`, `C103_Boneco_de_Gelo_Marinho`.
  - **Lote 2 (após aprovação do piloto):** `C75_Leao_Marinho_Dourado`, `C76_Raia_Aurora`, `C78_Lagosta_Armadura`.

---

## Tabela Completa

| # | ID | Nome | Pool | Tamanho (X, Y, Z) | H-T_Z | Peças | Silh. | Rosto | Det. | Decisão | Motivo |
|---:|---|---|---|---|---:|---|---:|---:|---:|---|---|
| 1 | `C07_Arraia_Prisma` | Arraia Prisma | Normal | 3.00 × 2.28 × 2.18 | N/A | `Body,Wings,Tail` (3) | 4 | 5 | 4 | **MANTER** | Silhueta simpática de arraiinha com asas abertas, olhos brilhantes na frente `+Z` e padrão prismático bonito. |
| 2 | `C08_Enguia_Trovao` | Enguia Trovão | Normal | 1.80 × 1.49 × 2.69 | +2.03 | `Body,Head,FinL,FinR,Tail` (5) | 5 | 5 | 4 | **MANTER** | Curva em S limpa, olhos expressivos de frente, crista elétrica contrastante e peças 100% compatíveis. |
| 3 | `C17_Martelo_Coral` | Tubarão-Martelo de Coral | Normal | 1.61 × 1.63 × 3.00 | +2.43 | `Body,Head,Fins,Tail` (4) | 5 | 5 | 4 | **MANTER** | Corais coloridos na cabeça de martelo e dorso, sorriso amigável e leitura frontal excelente. |
| 4 | `C18_Lula_Neon` | Lula Neon | Normal | 1.77 × 3.00 × 1.63 | N/A | `Body,Tentacles` (2) | 4 | 5 | 4 | **MANTER** | Olhões neon voltados para `+Z`, listras luminosas no manto e tentáculos enrolados bem definidos. |
| 5 | `C19_Peixe_Lua_Dourado` | Peixe-Lua Dourado | Normal | 2.00 × 1.89 × 2.32 | +1.88 | `Body,Head,Fins,Tail` (4) | 5 | 5 | 4 | **MANTER** | Proporções cartoony muito fofas, bochechas rosadas, sorriso nítido e ótima leitura na revelação. |
| 6 | `C28_Nautilo_Aurora` | Náutilo Aurora | Normal | 2.85 × 2.32 × 2.99 | N/A | `Body,Shell,Tentacles` (3) | 5 | 5 | 4 | **MANTER** | Concha espiralada aurora e olhos com brilho de estrela voltados para `+Z`. |
| 7 | `C32_Espadarte_Relampago` | Espadarte Relâmpago | Normal | 1.39 × 2.12 × 2.94 | +2.09 | `Body,Head,Fins,Tail` (4) | 5 | 4 | 5 | **MANTER** | Vela dorsal com raio amarelo, bico dourado elegante e olhos legíveis. |
| 8 | `C50_Tubarao_Baleia_Estrelado` | Tubarão-Baleia Estrelado | Normal | 2.82 × 1.45 × 2.95 | +2.03 | `Body,Head,FinR,FinL,Fins,Tail` (6) | 3 | 1 | 3 | **REFAZER** | Vista frontal `+Z` mostra quase só um queixo branco liso com olhos minúsculos nas laterais; falta rosto cartoony legível de frente e constelações mais nítidas. |
| 9 | `C51_Lanterna_Abissal` | Lanterna Abissal | Normal | 2.45 × 2.62 × 2.85 | +2.02 | `Body,Head,FinR,FinL,Tail,Extra` (6) | 5 | 5 | 5 | **MANTER** | Duas lanternas ciano, expressão super simpática de frente e peças completas. |
| 10 | `C52_Cavalo_Marinho_Real` | Cavalo-Marinho Real | Normal | 1.26 × 2.85 × 1.30 | 0.00 | `Body,Head,Extra,Tail,Fins` (5) | 5 | 5 | 5 | **MANTER** | Coroa com gema safira, barriga dourada e rosto fofo olhando para `+Z`. |
| 11 | `C53_Moreia_Voltaica` | Moreia Voltaica | Normal | 1.81 × 2.71 × 2.90 | +2.12 | `Body,Head,Fins,Tail` (4) | 4 | 4 | 4 | **MANTER** | Pose enrolada carismática, crista elétrica nítida e rosto bem visível. |
| 12 | `C54_Peixe_Vela_Solar` | Peixe-Vela Solar | Normal | 1.41 × 2.21 × 2.95 | +2.32 | `Body,Head,FinR,FinL,Fins,Tail` (6) | 5 | 4 | 5 | **MANTER** | Vela dorsal solar vibrante, olhos dourados e boa leitura em todos os ângulos. |
| 13 | `C55_Caranguejo_Rei_Gelo` | Caranguejo-Rei do Gelo | Normal | 2.95 × 2.12 × 2.27 | N/A | `Body,Shell,Claws,Legs,Extra` (5) | 3 | 1 | 2 | **REFAZER** | Casco roxo plano, olhos minúsculos escondidos atrás da borda (com pontos semelhantes nas costas `-Z`), sem `Head` separado e pouca identidade de gelo/rei. |
| 14 | `C75_Leao_Marinho_Dourado` | Leão-Marinho Dourado | Normal | 2.41 × 2.81 × 2.85 | +1.76 | `Body,Head,FinL,FinR,Tail,Extra` (6) | 3 | 2 | 2 | **REFAZER** | Está rosa-salmão com gola roxa em vez de dourado com juba dourada; olhos de ponto preto com marcas estranhas atrás e boca escura vazia. |
| 15 | `C76_Raia_Aurora` | Raia Aurora | Normal | 2.85 × 1.47 × 2.40 | +1.47 | `Body,Head,Wings,Tail` (4) | 2 | 2 | 2 | **REFAZER** | Roxo chapado com "rosquinhas" arco-íris coladas nas asas e focinho/boca que destoa do tema de raia aurora. |
| 16 | `C77_Cavalo_Marinho_Relogio` | Cavalo-Marinho Relógio | Normal | 1.31 × 2.85 × 1.42 | +0.20 | `Body,Head,Fins,Tail,Extra` (5) | 5 | 5 | 5 | **MANTER** | Relógio no peito, engrenagens douradas, cartola e olhos bem legíveis de frente. |
| 17 | `C78_Lagosta_Armadura` | Lagosta Armadura | Normal | 2.02 × 0.99 × 2.58 | +1.32 | `Body,Head,Claws,Legs,Tail,Shell` (6) | 3 | 1 | 3 | **REFAZER** | Muito achatada na vista frontal (`0,99` stud de altura), sem rosto nem olhos legíveis em `+Z` entre as garras. |
| 18 | `C79_Mantarraia_Vitral` | Mantarraia Vitral | Normal | 2.85 × 1.57 × 1.60 | +0.65 | `Body,Head,Wings,Tail` (4) | 4 | 4 | 5 | **MANTER** | Asas com vitral colorido e moldura dourada bem desenhadas e olhos visíveis em `+Z`. |
| 19 | `C80_Peixe_Pavao_Eletrico` | Peixe-Pavão Elétrico | Normal | 2.28 × 2.61 × 2.85 | +1.97 | `Body,Head,FinR,FinL,Fins,Tail` (6) | 5 | 5 | 5 | **MANTER** | Cauda em leque com ocelos de pavão, cores vibrantes e rosto bem definido. |
| 20 | `C81_Enguia_Fita_de_Seda` | Enguia Fita-de-Seda | Normal | 0.60 × 2.85 × 2.56 | +1.67 | `Body,Head,Fins,Tail,Extra` (5) | 5 | 4 | 5 | **MANTER** | Silhueta elegante de fita, crista dourada e leitura limpa. |
| 21 | `C95_Peixe_Vagalume_Real` | Peixe-Vagalume Real | Evento `shimmerShoal` | 1.61 × 1.92 × 2.45 | +1.67 | `Body,Head,FinL,FinR,Fins,Tail,Extra×6` (12) | 4 | 5 | 4 | **MANTER** | Antenas luminosas, cauda em fita e rosto fofo voltado para `+Z`. |
| 22 | `C103_Boneco_de_Gelo_Marinho` | Boneco de Gelo Marinho | Natal `xmas` | 2.57 × 2.80 × 2.75 | +0.16 | `Body,Head,Tail,FinL,FinR,Extra` (6) | 4 | 1 | 4 | **REFAZER** | Rosto e nariz de cenoura estão virados **de lado para `+X`** em vez de `+Z`; na revelação aparece de perfil. Precisa olhar para `+Z`. |

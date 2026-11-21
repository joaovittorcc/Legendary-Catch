# Lote Piloto — Criaturas Raras (`rarity = "Rare"`)

- **Data:** 2026-11-20
- **Responsável:** Antigravity
- **Objetivo:** validar o estilo *Cartoony candy* leve (orçamento mobile `<= 1.500` triângulos totais / `<= 500` por peça, atlas `512×512`, escala `2,70`–`2,95` studs, frente `+Z`, sem ossos) em 3 Raras bem diferentes entre si antes de modelar o Lote 2 ou importar no pool do Studio.

---

## Modelos do Lote Piloto (validados com `tools/blender/check_creature.py`)

| ID | Nome | Triângulos totais | Peças (triângulos) | Dimensões Roblox (X, Y, Z) | H - T (Z) |
|---|---|---:|---|---|---:|
| `C50_Tubarao_Baleia_Estrelado` | Tubarão-Baleia Estrelado | **1.194** | `Body: 280`, `Head: 486`, `FinL: 96`, `FinR: 96`, `Fins: 104`, `Tail: 132` | `2.790 × 1.325 × 2.860` | `+2.055` |
| `C55_Caranguejo_Rei_Gelo` | Caranguejo-Rei do Gelo | **1.416** | `Body: 192`, `Head: 372`, `Shell: 136`, `Claws: 280`, `Legs: 264`, `Tail: 44`, `Extra: 128` | `2.860 × 1.540 × 1.981` | `+1.322` |
| `C103_Boneco_de_Gelo_Marinho` | Boneco de Gelo Marinho | **1.126** | `Body: 324`, `Head: 494`, `FinL: 76`, `FinR: 76`, `Tail: 112`, `Extra: 44` | `2.679 × 2.860 × 2.606` | `+1.339` |

## O que foi melhorado

1. **`C50_Tubarao_Baleia_Estrelado`:** olhos maiores e voltados para `+Z` (antes ficavam escondidos na lateral com um queixo branco vazio), boca sorridente visível na frente, nadadeiras peitorais/dorsal/caudal em curva e padrão estrelado com gema dourada discreta na testa.
2. **`C55_Caranguejo_Rei_Gelo`:** garras grandes levantadas e geladas enquadrando o rosto, coroa real de 3 pontas de cristal sobre aro dourado, `Head` dedicado com olhos brilhantes e sorriso em `+Z`, 6 patas articuladas e paleta glacial azul/branco (no lugar do casco roxo plano).
3. **`C103_Boneco_de_Gelo_Marinho`:** rosto, olhos, bochechas, sorriso e nariz de cenoura corrigidos para olhar **para `+Z`** (no modelo atual do jogo está virado de lado para `+X`), corpo arredondado com botões de gelo, cachecol festivo com ponta esvoaçante, nadadeiras fofas e cauda de peixe em `-Z`.

## O que NÃO foi testado ainda

- Importação no place do Studio (`112666482424701`), Play no PC, revelação face-first, Coleção, `ReduceEffects`, celular real e 2 jogadores (aguardando aprovação do João no Lote Piloto).

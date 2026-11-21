# Lote Piloto — Criaturas Raras (`rarity = "Rare"`) via `generate_mesh`

- **Data:** 2026-11-20
- **Responsável:** Antigravity
- **Mudança de rota (a pedido do João):** deixamos o Blender detalhado reservado apenas para **Lendárias e Místicas**; para as **Raras**, refizemos o Lote Piloto usando `generate_mesh` do Roblox Studio com segmentação explícita compatível com `CreatureMotion`, escala `2,86` studs e frente `+Z` (`Head.Z - Tail.Z > 0`).

---

## Modelos do Lote Piloto (estacionados em `ServerStorage._PilotRarePending` aguardando "ok")

| ID | Nome | Peças | Dimensões (X, Y, Z) | H - T (Z) |
|---|---|---:|---|---:|
| `C50_Tubarao_Baleia_Estrelado` | Tubarão-Baleia Estrelado | `Body, Head, FinL, FinR, Fins, Tail` (6) | `2.48 × 1.57 × 2.86` | `+2.13` |
| `C55_Caranguejo_Rei_Gelo` | Caranguejo-Rei do Gelo | `Body, Head, Shell, Claws, Legs, Tail, Extra` (7) | `2.86 × 2.42 × 1.92` | `+1.53` |
| `C103_Boneco_de_Gelo_Marinho` | Boneco de Gelo Marinho | `Body, Head, FinL, FinR, Tail, Extra` (6) | `2.31 × 2.86 × 1.80` | `+0.50` |

## O que NÃO foi testado ainda

- Substituição no pool (`ReplicatedStorage.Creatures` + backup em `CreaturesOld`), Play no PC, revelação face-first, Coleção, `ReduceEffects`, celular real e 2 jogadores (aguardando aprovação do João no Lote Piloto).

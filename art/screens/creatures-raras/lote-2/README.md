# Lote 2 + Entrega Final — Criaturas Raras (`rarity = "Rare"`) via `generate_mesh`

- **Data:** 2026-11-20
- **Responsável:** Antigravity
- **Place salvo na nuvem:** `112666482424701` — versão **v65** (`persistedToCloud = true`).
- **Backups:** os 6 modelos antigos foram movidos para `ReplicatedStorage.CreaturesOld.<id>` (nunca deletados).

---

## Modelos integrados em `ReplicatedStorage.Creatures` (Lote Piloto + Lote 2)

| Lote | ID | Peças | Dimensões (X, Y, Z) | H - T (Z) | `publishedAssetId` |
|---|---|---|---|---:|---|
| Piloto | `C50_Tubarao_Baleia_Estrelado` | `Body, Head, FinL, FinR, Fins, Tail` (6) | `2.48 × 1.57 × 2.86` | `+2.13` | `75045787705302` |
| Piloto | `C55_Caranguejo_Rei_Gelo` | `Body, Head, Shell, Claws, Legs, Tail, Extra` (7) | `2.86 × 2.42 × 1.92` | `+1.53` | `73453932508824` |
| Piloto | `C103_Boneco_de_Gelo_Marinho` | `Body, Head, FinL, FinR, Tail, Extra` (6) | `2.31 × 2.86 × 1.80` | `+0.50` | `119325087191162` |
| Lote 2 | `C75_Leao_Marinho_Dourado` | `Body, Head, FinL, FinR, Tail, Extra` (6) | `1.93 × 2.86 × 2.27` | `+1.02` | `71600865162138` |
| Lote 2 | `C76_Raia_Aurora` | `Body, Head, Wings, Tail` (4) | `2.86 × 1.92 × 1.76` | `+0.77` | `78258865415548` |
| Lote 2 | `C78_Lagosta_Armadura` | `Body, Head, Claws, Legs, Tail, Shell` (6) | `2.51 × 2.86 × 0.86` | `+0.13` | `71370331596757` |

*(As outras 16 Raras da auditoria foram mantidas intactas por já estarem no padrão `generate_mesh` Cartoony Candy e legíveis em `+Z`.)*

## Verificação em Play (PC)

- `CreatureMotion.bind` + `CreatureAura.attach` testados em `Play` (`Client`) nas **6 Raras substituídas** + **3 Raras não refeitas** (`C08_Enguia_Trovao`, `C19_Peixe_Lua_Dourado`, `C80_Peixe_Pavao_Eletrico`) + `ReduceEffects = true` (`C55`): **9/9 passaram (`true`) sem erros**.
- **O que NÃO foi testado:** pesca completa ponta-a-ponta com abertura do `RevealCard` / `Collection` no jogo real, celular real, 2 jogadores e cliente publicado.

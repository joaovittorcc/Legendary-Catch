# Lote Piloto · Criaturas Épicas (3 espécies)

Modelagem procedural em Blender 5.3 via `tools/blender/` (`creature_mesh.py`, `export_creature.py`, `check_creature.py`, `preview_creature.py`), seguindo o estilo **Cartoony candy** e o orçamento mobile para Épicas (`<= 2.500` triângulos totais, `<= 800` por peça, atlas `512 × 512 px` pintado por código, frente `-Y` no Blender -> `+Z` no Roblox, escala `3.14` studs).

> **Status:** PAUSA PARA APROVAÇÃO DO JOÃO (`PASSO 3`). Nenhuma criatura Épica foi substituída no place principal ainda.

---

## 1. Resumo de Orçamento e Triângulos por Peça

| ID | Nome | Bounding Box Roblox (`X × Y × Z` studs) | `Head.Z - Tail.Z` | Atlas | Total de Triângulos (teto `2.500`) | Triângulos por Peça (teto `800`) |
|---|---|---|---:|---|---:|---|
| `C09_Guardiao_Cristal` | Guardião de Cristal | `3.140 × 1.769 × 2.630` | `+1.868` | `512 × 512` | **`2.396`** | `Body: 420` · `Head: 684` · `Shell: 492` · `FinL: 138` · `FinR: 138` · `Tail: 92` · `Extra: 224` · `Extra.001: 208` |
| `C20_Raia_Vulcanica` | Raia Vulcânica | `3.140 × 0.624 × 2.798` | `+1.836` | `512 × 512` | **`2.052`** | `Body: 252` · `Head: 736` · `Wings: 348` · `Tail: 160` · `Extra: 192` · `Extra.001: 364` |
| `C84_Tubarao_Martelo_de_Cristal` | Tubarão-Martelo de Cristal | `2.721 × 1.869 × 3.140` | `+2.285` | `512 × 512` | **`1.770`** | `Body: 276` · `Head: 796` · `FinL: 86` · `FinR: 86` · `Fins: 92` · `Tail: 130` · `Extra: 252` · `Extra.001: 52` |

---

## 2. Comparativos Antes vs Depois e 6 Ângulos

### 2.1 `C09_Guardiao_Cristal` — Guardião de Cristal
- **O que mudou:**
  - **Antes:** cristais derretidos/fundidos no casco por geração automática, sem `Tail`, nadadeiras dianteiras presas numa peça só (`Fins`) e rosto escuro sem olhos legíveis de frente.
  - **Depois:** casco abobadado com aro e cravos dourados (`Shell`), grande drusa de cristais lapidados ciano-safira e lilás-prisma (`Extra` + `Extra.001`), rosto simpático voltado para `+Z` com olhos dourados brilhantes e diadema de cristal (`Head`), nadadeiras dianteiras separadas (`FinL`, `FinR`) e cauda com ponta de cristal (`Tail`).
- **Arquivos:**
  - Comparativo Antes (topo) × Depois (base): `C09_Guardiao_Cristal-antes-depois.jpg`
  - Folha de 6 ângulos: `C09_Guardiao_Cristal-6-angulos.jpg`
  - Fonte e FBX: `art/creatures/C09_Guardiao_Cristal/build_c09.py` e `art/creatures/C09_Guardiao_Cristal/model/C09_Guardiao_Cristal.fbx`

### 2.2 `C20_Raia_Vulcanica` — Raia Vulcânica
- **O que mudou:**
  - **Antes:** sem peça `Head` (rosto era uma mancha escura sem olhos), cauda com `0.04` stud de espessura e artefato em "T" na ponta.
  - **Depois:** cabeça separada (`Head`) com lóbulos cefálicos de magma, olhos âmbar brilhantes desobstruídos de frente e crista vulcânica; asas largas de basalto (`Wings`) com cristas de lava incandescente; núcleo vulcânico dorsal (`Extra`) e cauda em chicote com lança de cristal de magma (`Tail`).
- **Arquivos:**
  - Comparativo Antes (topo) × Depois (base): `C20_Raia_Vulcanica-antes-depois.jpg`
  - Folha de 6 ângulos: `C20_Raia_Vulcanica-6-angulos.jpg`
  - Fonte e FBX: `art/creatures/C20_Raia_Vulcanica/build_c20.py` e `art/creatures/C20_Raia_Vulcanica/model/C20_Raia_Vulcanica.fbx`

### 2.3 `C84_Tubarao_Martelo_de_Cristal` — Tubarão-Martelo de Cristal
- **O que mudou:**
  - **Antes:** postura vertical torta (`1.40` stud em Z) em que o martelo parecia 3 blocos de marshmallow rosa sem facetas de cristal nem feição de tubarão.
  - **Depois:** silhueta horizontal hidrodinâmica (`3.14` studs em Z, `2.72` studs de envergadura no martelo), cabeça em T (`Head`) com grandes diamantes rosa/ciano lapidados nas extremidades, chifre frontal de cristal e olhos dourados expressivos voltados para `+Z`; barbatana dorsal alta em lâmina de cristal (`Fins`), peitorais separadas (`FinL`, `FinR`) e cauda em meia-lua com lâmina cristalina (`Tail`).
- **Arquivos:**
  - Comparativo Antes (topo) × Depois (base): `C84_Tubarao_Martelo_de_Cristal-antes-depois.jpg`
  - Folha de 6 ângulos: `C84_Tubarao_Martelo_de_Cristal-6-angulos.jpg`
  - Fonte e FBX: `art/creatures/C84_Tubarao_Martelo_de_Cristal/build_c84.py` e `art/creatures/C84_Tubarao_Martelo_de_Cristal/model/C84_Tubarao_Martelo_de_Cristal.fbx`

---

## 3. O que NÃO foi testado ainda

- Como o processo exige **parar após o Lote Piloto e aguardar o "ok" do João** antes de continuar os Lotes 2 e 3 e antes de substituir modelos no pool, os FBXs ainda não foram importados para `ReplicatedStorage.Creatures` nem testados em `Play`, celular físico ou 2 jogadores.

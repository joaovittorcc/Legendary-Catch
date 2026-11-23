# Campo de Treino (10 Níveis) & Ilhas de Treino 2–4

- **Place:** `112666482424701` · **Cloud Save:** **`v100`** (`persistedToCloud = true`)
- **Builders:** `tools/TrainingFieldBuilder.luau` e `tools/TrainingIslandsBuilder.luau`
- **`TrainingOrigin` medido no hub:** `Pos = (-30.000, 10.650, -6.000)` (`DeckCollider.Y = 10.61 + 0.04`), `LookVector = (-0.923, 0, -0.385)` (`+Z` voltado para a `CentralPlaza`, entrada 100% aberta).

## 1. Os 10 Níveis (`ReplicatedStorage.TrainingLevels.Levels`)

Todos compartilham o mesmo `TrainingOrigin`, possuem as 8 âncoras (`InspectCamera`, `UpgradeBoard`, `DecorAnchor_01..06`), `Layer_00_Floor` (único com `CanCollide = true`), `Layer_01_Structure`, `Layer_02_Decor`, `Layer_03_Light`, **0 scripts**, **0 tags** e **0 pares de z-fighting** (`tools/ZFightFixer.luau`).

| Nv | ID | Nome | Peças (incl. 9 âncoras) | Orçamento | Luzes | Emissores | Z-Fight | Bounding Box (X×Y×Z) |
|---:|---|---|---:|---:|---:|---:|---:|---|
| 1 | `training_lv01` | Clareira | 22 | ≤ 25 | 0 / 0 | 0 / 0 | 0 | `21.6 × 10.7 × 26.2` |
| 2 | `training_lv02` | Deck simples | 35 | ≤ 50 | 0 / 0 | 0 / 0 | 0 | `25.1 × 14.3 × 29.5` |
| 3 | `training_lv03` | Cais de treino | 55 | ≤ 80 | 1 / 1 | 0 / 0 | 0 | `28.5 × 15.5 × 32.8` |
| 4 | `training_lv04` | Cercado de pedra | 85 | ≤ 110 | 1 / 1 | 0 / 0 | 0 | `31.8 × 13.7 × 38.3` |
| 5 | `training_lv05` | Torre pequena | 71 | ≤ 140 | 2 / 2 | 1 / 1 | 0 | `36.0 × 23.9 × 40.0` |
| 6 | `training_lv06` | Arena rúnica | 102 | ≤ 170 | 2 / 2 | 2 / 2 | 0 | `38.1 × 17.8 × 42.1` |
| 7 | `training_lv07` | Jardim das fontes | 97 | ≤ 200 | 2 / 2 | 3 / 3 | 0 | `41.3 × 18.2 × 45.2` |
| 8 | `training_lv08` | Arcos de cristal | 101 | ≤ 220 | 2 / 2 | 4 / 4 | 0 | `44.3 × 22.0 × 49.1` |
| 9 | `training_lv09` | Plataforma flutuante | 99 | ≤ 240 | 2 / 2 | 5 / 5 | 0 | `48.4 × 29.7 × 55.9` |
| 10 | `training_lv10` | Santuário do Pescador Lendário | 122 | ≤ 250 | 2 / 2 | 5 / 5 | 0 | `50.5 × 37.2 × 57.2` |

## 2. Ilhas de Treino 2 a 4 & Portais

| Ilha | Modelo no `Workspace` | Posição | `TrainingIsland` | Peças | Luzes | Emissores | Z-Fight | `Persistent` |
|---|---|---|---:|---:|---:|---:|---:|---|
| 2. Ilha do Recife (x3, 100K PP) | `TrainingIsland_Reef` | `(480, 12, 420)` | 2 | 122 | 2 | 2 | 0 | `PersistentTrainingSpot`, `PersistentSpawn` |
| 3. Ilha Abismo Estelar (x12, 100M PP) | `TrainingIsland_Abyss` | `(-520, 12, 420)` | 3 | 130 | 2 | 3 | 0 | `PersistentTrainingSpot`, `PersistentSpawn` |
| 4. Ilha Celestial (x50, 1T PP) | `TrainingIsland_Celestial` | `(0, 160, -680)` | 4 | 176 | 2 | 3 | 0 | `PersistentTrainingSpot`, `PersistentSpawn` |
| Portais de ida (hub) | `TrainingPortalsHub` | `(56, 10.37, 63)` | — | 76 | 3 | 3 | 0 | — |

## 3. Nota sobre prints (`training_lv01..10.png`)

Durante a sessão o Windows estava com a tela bloqueada (`MainWindowHandle = 0`), então `screen_capture` retornou quadro cinza (mesmo comportamento relatado pelos lotes 2 e 4 no Mural). Assim que o Studio estiver em primeiro plano, basta usar `TrainingFieldBuilder.preview(i)` com a câmera unificada `CamPos = (11.38, 30.65, -16.92)`, `LookAt = (-31.85, 17.15, -6.77)` para salvar `art/training/training_lv01.png` .. `training_lv10.png`, e depois chamar `TrainingFieldBuilder.clearPreview()`.

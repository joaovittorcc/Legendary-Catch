# Auditoria de Performance (Mobile Fraco) — Legendary Catch

Levantamento medido no **Roblox Studio (`Edit` e `Play`, viewport mobile `750×381`)** em 2026-11-18, com números antes/depois das otimizações aplicadas em scripts do cliente e riscos pendentes.

---

## 1. Inventário de Cena (`Edit` vs `Play`)

### `Edit` (mapa base + catálogo)
- **Workspace total:** `1.031` instâncias · `673` `BasePart`s (`113` `MeshPart`s) · `206` com `CastShadow = true`
- **Ilha (`Workspace.Island`):** `917` instâncias · `653` `BasePart`s
- **Luzes dinâmicas (`PointLight`):** `15` no mapa, **`0` com `Shadows = true`** (nenhuma luz dinâmica projetando sombra)
- **Emissores no mapa (`Edit`):** `1` (`Workspace.Island.TrainingLagoon.WaterfallMistSource.ParticleEmitter`, `Rate = 14.0`, `Enabled = true`)
- **Partes `Material.ForceField`:** `20` no `Workspace` (`16` `OceanBarrier`, `FishingZone`, `WorkshopSpot`, `TrainingSpot`, `TrophyPedestal`), todas com `CastShadow = false` e `Transparency = 1` em runtime (`ffOpaque = 0`, sem custo de shader de distorção)
- **Catálogo (`ReplicatedStorage.Creatures`):** `100` modelos · `586` `BasePart`s (`473` `MeshPart`s) · `0` luzes · `0` emissores

### Clonagem de Criaturas em Runtime
- Nenhuma criatura de `ReplicatedStorage.Creatures` é clonada por cliente ao entrar no jogo sem necessidade.
- Clones existem apenas sob demanda durante:
  - Revelação de captura (`Fishing/Reveal`, destruído ao terminar).
  - Pedestal local (`TrophyPresentation`, somente troféus exibidos no pedestal).
  - Prévias do Bestiário (`Collection`) e Álbum inspecionado (`Leaderboard`): ambos limitam a janela visível para no máximo **`12` `ViewportFrame`s simultâneos**, destruindo os `ViewportFrame`s fora da rolagem e limpando tudo (`0`) ao fechar o painel (`vpfClosed = 0` verificado no Play).

---

## 2. Principais Loops por Frame (`src/client/Features`)

| Feature | Evento | Frequência / Comportamento | Custo e Otimização |
| :--- | :--- | :--- | :--- |
| `Ambient` | `Heartbeat` | Gaivotas, saltos no oceano, cardume, ondas no píer, vagalumes/cristais | Desconecta 100% e remove `IslandAmbient` do Workspace quando `ReduceEffects = true` |
| `IslandLife` | `Heartbeat` | Peixes nadando na lagoa/píer, gaivotas | **Corrigido:** agora desconecta `Heartbeat` em `ReduceEffects = true` e faz *culling* por distância (`> 145` / `> 210` studs da câmera) |
| `LivingWorld` | `Heartbeat` | Atmosfera a cada `0.25 s` (`1 s` em `ReduceEffects`), NPCs a ~30 Hz | **Corrigido:** `stepNpc` pula NPCs a `> 95` studs; emissores da ilha (`Embers` e `WaterfallMistSource`) desligados em `ReduceEffects = true` |
| `Collection` | `RenderStepped` | Só conectado com `CollectionScreen` aberto, limitado a `30 Hz` (`1/30`) | Pausa atualização contínua quando `ReduceEffects = true` e zera ao fechar |
| `Shop` | `RenderStepped` | Só gira varas quando `ShopScreen` aberto e visíveis no scroll | **Corrigido:** retorna sem executar `PivotTo` todo frame quando `ReduceEffects = true` |
| `CharacterMotion` / `Pose` | `PreSimulation` | Só escreve `Transform` durante pesca/revelação (`weight > 0.002`) | Em `ReduceEffects = true` remove tremor e pulinho |
| `CreatureAura` / `Fishing/Camera` / `Line` / `Minigames` | `RenderStepped` | Ativos apenas durante luta/revelação/treino | Destruídos/desconectados ao encerrar |
| `Others` / `Leaderboard` | `Heartbeat` | `Others` a cada `0.13 s` (`<= 160` studs); `Leaderboard` apenas quando `previewsDirty` | Custo mínimo em repouso |

---

## 3. Comparação Antes vs Depois (`Play` — `ReduceEffects`)

| Métrica no `Workspace` (`Play`) | Normal (`ReduceEffects = false`) | Antes (`ReduceEffects = true`) | Depois (`ReduceEffects = true`) |
| :--- | :--- | :--- | :--- |
| Instâncias totais | `1.654` | `1.457` (`IslandAmbient` removido) | `1.603` (`-51` instâncias; variação reflete estado inicial vs com peixe/varas) |
| `BasePart`s totais | `905` | `786` | `857` (`-48` partes de `IslandAmbient`) |
| `Light`s com `Shadows = true` | `0 / 15` | `0 / 15` | `0 / 15` |
| **`ParticleEmitter`s ativos** | `10 / 10` (`rateSum = 45.0`/s) | `1 / 9` (`rateSum = 14.0`/s — `WaterfallMistSource` ficava ligado) | **`0 / 9` (`rateSum = 0.0`/s)** |
| `Heartbeat` de `IslandLife` | Ativo (com *culling* de distância) | Ativo todo frame | **Desconectado** |
| `RenderStepped` da `Shop` | Ativo só com janela aberta | Rodava `PivotTo` em `ReduceEffects` | **Em repouso sem `PivotTo`** |

---

## 4. Riscos Restantes e Próximos Passos

1. **Pastas residuais de segmentação no `Workspace` (`_SegWork1_R1`, `_SegWork1_B5`, `_SegWork1_B8`, `_SegWork1_Fix`):** somam `26` instâncias e `7` modelos extras de criaturas (`C15`, `C16`, `C18` ×3, `C26` ×2) soltos fora de `Island`. **Recomendação:** remover essas 4 pastas temporárias no `Edit` e rodar `save_place`.
2. **`CastShadow = true` em `206` `BasePart`s do mapa:** peças decorativas pequenas da ilha ainda projetam sombra; manter `CastShadow = false` em vegetação menor, pedrinhas e cercas reduz custo em GPUs mobile de entrada.
3. **Contagem de triângulos dos `MeshPart`s:** o Luau não expõe `TriangleCount` em runtime; embora haja `473` `MeshPart`s em `Creatures` e `113` no mapa, apenas no máximo `12` aparecem em `ViewportFrame` por vez no Bestiário/Álbum. Se algum dispositivo antigo engasgar ao rolar o álbum, baixar o teto de `remaining` em `Collection` e `Leaderboard` de `12` para `8` `ViewportFrame`s.
4. **Dispositivo físico real:** toda a medição foi feita no Device Emulator (`750×381`) do Roblox Studio; validar FPS e consumo térmico em celular Android/iOS real antes do lançamento (ver [PUBLICAR.md](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/docs/PUBLICAR.md)).

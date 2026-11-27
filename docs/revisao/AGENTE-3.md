# Relatório de Revisão Final — Agente 3 (Mundo, Mapa, Ilhas, Animações de Cenário e Desempenho)

Data de início: 2026-11-26  
Place: `112666482424701` (Legendary Catch)  
Escopo: Mapa (`Workspace`, `Lighting`, `Terrain`), construtores/patches em `tools/`, animações e vida de cenário (`HubAnimator`, `PondAnimator`, `Portals`, `WorldFx`, `WorldText`, `Ambient`, `LivingWorld`, `IslandLife`, `Arrival`, `Events/Scenery`), `MapStreaming`, limpeza e desempenho mobile.

---

## 1. Inventário Completo

| # | Área / Item | Arquivos / Objetos no Place | Testado como | Resultado |
|---|---|---|---|---|
| 1 | **Ilha 4 (Celestial) — Polimento visual (Prioridade 1)** | `tools/TrainingIsland4Builder.luau`, `Workspace.TrainingIslands.TrainingIsland_Celestial` | Rodadas 1 e 2 construídas e fotografadas no Edit (iluminação normal); rodada 3 (rocha esculpida Slate + cristais diagonais + aurora + barreira de borda) pronta em disco, aguardando `.studio-lock` para reconstruir, avaliar e testar em Play | `pendente` |
| 2 | **Ilha 4 — Perfil no `PondAnimator`** | `src/client/Features/PondAnimator.luau` (`CelestialFocusProfile`, `CelestialInstinctProfile`, `LegendaryFish1..4`, suporte a `Water` cilindro + `OrbitCenter`) | Implementado (`stylua`/`selene`/`luau-lsp` = 0 erros); aguardando Play | `pendente` |
| 3 | **Hub Principal (V2) — Visual e fidelidade** | `Workspace.Island`, `tools/HubBuilder_claude.luau`, `hub-patch-boards-portal.luau`, `hub-patch-2.luau` | Contagem auditada (`8.629` peças, `82` luzes, `39` emitters); inspeção visual/ZFight aguardando trava | `pendente` |
| 4 | **Hub Principal — Caminhada a pé, colisão e cair no mar** | Praça, Oficina, Píer, Cais, Santuário, Lagoa/Aprendiz, Aquário, Patamar da Luna, `WorldBounds` | Aguardando Play | `pendente` |
| 5 | **Ilha 1 (Aprendiz) — Visual, caminhada, contratos e mar** | `Workspace.TrainingIslands.TrainingIsland_Apprentice`, `tools/TrainingIsland1Builder.luau` | Auditado Server (`3.923` peças, `3.193` CanTouch, `3.160` CanQuery, `0` barreira de borda -> `TrainingSafetyBarriers.luau` + `MapPerfOptimizer.luau` prontos); aguardando Edit/Play | `pendente` |
| 6 | **Ilha 2 (Recife) — Visual, caminhada, contratos e mar** | `Workspace.TrainingIslands.TrainingIsland_Reef`, `tools/TrainingIsland2Builder.luau` | Auditado Server (`6.321` peças, `5.802` CanTouch, `5.780` CanQuery, `0` barreira de borda -> `TrainingSafetyBarriers.luau` + `MapPerfOptimizer.luau` prontos); aguardando Edit/Play | `pendente` |
| 7 | **Ilha 3 (Abismo Estelar) — Visual, caminhada, contratos e mar** | `Workspace.TrainingIslands.TrainingIsland_Abyss`, `tools/TrainingIsland3Builder.luau` | Auditado Server (`5.008` peças, `4.618` CanTouch, `4.404` CanQuery, `0` barreira de borda -> `TrainingSafetyBarriers.luau` + `MapPerfOptimizer.luau` prontos); aguardando Edit/Play | `pendente` |
| 8 | **Ilhas de Expedição (`CoralReefIsland`, `StarAbyssIsland`)** | `Workspace.ExpeditionIslands` (`986` peças, `FishingZone` com `CanQuery=true` reportado pelo Agente 4) | `MapPerfOptimizer.luau` pronto para corrigir `FishingZone` (`CanQuery=false`) e flags decorativas; aguardando Edit/Play | `pendente` |
| 9 | **Portais (todos do Hub e das 6 ilhas)** | `src/client/Features/Portals/init.luau`, tags `ZonePortal` (12) e `ZoneSpawn` (8) | Corrigido prompt dos 4 portais de treino (mostravam "Lagoa da Ilha" em vez da ilha/poder) e streaming-safety no `PortalRing`; aguardando Play | `pendente` |
| 10 | **Contratos do mapa (tags e atributos)** | `ZonePortal`, `ZoneSpawn`, `TrainingSpot`, `FishingZone`, `WorkshopSpot`, `GuideNPC`, `LeaderboardBoard`, `PlayerSpawn`, `TrophyPedestal`, `AquariumTank`, `TrainingPortalGuide` | Auditoria inicial Server completa (todos presentes e sem duplicatas óbvias); faltam `selfTest()` de cada construtor e revalidação pós-ajustes | `pendente` |
| 11 | **Streaming (`StreamingEnabled` + `MapStreaming`)** | `src/server/Features/MapStreaming/init.luau`, `Workspace.StreamingEnabled=true` (`MinR=128`, `TargetR=1024`, `Opportunistic`) | Confirmado no Server: 100% dos Models `HubSpin/Bob/Sway` estão `Atomic` (`defaultModels=0`); teste de teleporte ida e volta repetido aguardando Play | `pendente` |
| 12 | **Animações de cenário (`HubAnimator`)** | `src/client/Features/HubAnimator.luau`, tags `HubSpin/Bob/Pulse/Flicker/Sway/Wave` | Corrigido cleanup de conexões `DescendantAdded` pendentes (`pendingModels`); aguardando Play | `pendente` |
| 13 | **Animações de lagos (`PondAnimator`)** | `src/client/Features/PondAnimator.luau` (Ilhas 1, 2, 3 e 4) | Adicionado perfil da Ilha 4 Celestial + correção `Water` cilindro + `OrbitCenter` + `FishFin`; aguardando Play | `pendente` |
| 14 | **Vida e ambiente (`Ambient`, `IslandLife`, `LivingWorld`)** | `Ambient/init.luau`, `IslandLife/init.luau`, `LivingWorld/init.luau` | Corrigido distance culling em `Ambient` (>220 studs do Hub), balões da Lucy/Luna em `LivingWorld` (card limpo sem vazar texto + ocultos em revelação/chegada) e `collectLanterns` para Hub V2; aguardando Play (dia/noite + Natal + `ReduceEffects`) | `pendente` |
| 15 | **Textos no mundo (`WorldText`) e placas** | `WorldText/init.luau`, placas do Hub e ilhas | Placas da Ilha 4 corrigidas (dupla face + margem); demais placas aguardando verificação em Edit/Play | `pendente` |
| 16 | **Efeitos do mundo (`WorldFx`) e Cenário de Eventos (`Events/Scenery`)** | `WorldFx/init.luau`, `Events/Scenery.luau` | Corrigido leak de `Attachment` em `WorldFx` e falso `teleportBurst` ao trocar personagem; aguardando Play com `DevStartEvent` | `pendente` |
| 17 | **Chegada (`Arrival`)** | `Arrival/init.luau` | Revisado estaticamente (limpo); aguardando confirmação no Play | `pendente` |
| 18 | **Desempenho (MicroProfiler + `SceneAnalysisService`)** | `tools/MapPerfOptimizer.luau` + `TrainingIsland1..4Builder.luau` + `Ambient` culling | Baseline de peças/flags coletado (`30.512` BaseParts totais, `14.279` CanTouch, `15.072` CanQuery, `4.940` CastShadow); aguardando medição `SceneAnalysisService`/MicroProfiler antes e depois no Play | `pendente` |
| 19 | **Limpeza de objetos soltos/teste** | `Workspace`, `ServerStorage`, `ReplicatedStorage` | Inventário listado (ver §6 Pendências: pastas `CreaturesOld`, `MapMeshRejects`, `CreatureMeshDrafts`, `CodexNativeCreatureDrafts`, `Backup_LagoonRim`, `Archive_*`, `AquariumShowcase`) | `pendente` |
| 20 | **Segunda passada completa** | Toda área do Agente 3 após correções | Aguardando conclusão das correções | `pendente` |

---

## 2. Ilha 4 (Celestial) — Avaliação Item por Item (Meta: ≥ 9/10 em todos)

*(Em andamento — Rodada 3 pronta em disco, aguardando `.studio-lock` para reconstrução e avaliação final.)*

| Item | Rodada 1 (`d1cdc76`) | Rodada 2 | Rodada 3 (Final) | Observações |
|---|---|---|---|---|
| silhueta geral e proporções | 8.5 | 9.0 | - | Aguardando captura R3 |
| cores e clima | 8.0 | 9.0 | - | Paleta quente calibrada para iluminação normal |
| grama e vegetação | 8.5 | 8.8 | - | R3: `GrassPatch` em `Material.Grass` sem borda especular |
| borda de mármore e frisos | 8.5 | 9.5 | - | R2 selou underside verde com `RockUndersideCap` |
| rocha inferior e cristais | 5.5 | 7.0 | - | R3: penhascos facetados `Slate` (cunhas+ombros), `RockCore` recuado quente e cristais diagonais |
| cachoeiras e canais | 7.5 | 9.5 | - | Véus `Beam` com `smoke_main.dds` animados, espuma e brilhos |
| anel de luz duplo | 8.5 | 9.5 | - | Champagne-ouro com halo translúcido suave |
| ilhotas flutuantes | 8.0 | 9.0 | - | Blocos facetados + cristais |
| mar de nuvens | 7.0 | 9.0 | - | Camada baixa contínua sem furos azuis + cúmulos |
| aurora e raios | 8.5 | 7.5 | - | R3: removida `smoke_main.dds` que deixou aurora/raios fracos demais |
| portal, asas e redemoinho | 8.5 | 10.0 | - | Redemoinho arco-íris preenchendo o arco inteiro |
| caminho de runas | 9.0 | 9.0 | - | Lajes com runas douradas e laje sobre canal |
| ponte arqueada | 9.0 | 9.0 | - | Caminhável, guarda-corpos e detalhes dourados |
| lagoa do Foco | 8.0 | 9.5 | - | Halos champagne-ouro + 2 pilares + cristal na grama |
| lagoa do Instinto | 6.5 | 9.0 | - | 4 peixes/tubarões vibrantes (ouro, rosa-lilás, âmbar, arco-íris) + reflexos |
| decks, banquinhos e almofadas | 9.0 | 9.0 | - | Spots alinhados e caminháveis |
| árvore rosa | 8.0 | 9.0 | - | Cachos orgânicos sem balões + auréola e pétalas |
| coroa de cristal | 9.0 | 9.0 | - | Proporção 1.42x com gemas e coração ciano |
| estátua, estandartes, placas | 8.0 | 9.5 | - | Placas dupla face com margem segura |
| lanternas, barris, cerca de corda | 9.0 | 9.0 | - | Bem escalados e fora dos caminhos |

---

## 3. Desempenho — Antes e Depois

### Contagem base do Place (Server Edit/Play antes de `MapPerfOptimizer`)
| Área | BaseParts | Colidíveis | `CanTouch` | `CanQuery` | `CastShadow` | Luzes | Emitters | Beams |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `Workspace.Island` (Hub V2) | 8.629 | 690 | 9 | 691 | 1.196 | 82 | 39 | 1 |
| `TrainingIsland_Apprentice` | 3.923 | 770 | 3.193 | 3.160 | 1.208 | 20 | 11 | 7 |
| `TrainingIsland_Reef` | 6.321 | 566 | 5.802 | 5.780 | 774 | 13 | 5 | 3 |
| `TrainingIsland_Abyss` | 5.008 | 193 | 4.618 | 4.404 | 444 | 17 | 8 | 0 |
| `TrainingIsland_Celestial` (antiga v124) | 5.645 | 269 | 1 | 275 | 1.024 | 11 | 7 | 64 |
| `ExpeditionIslands` | 986 | 120 | 656 | 762 | 294 | 13 | 3 | 2 |
| **Total** | **30.512** | **2.608** | **14.279** | **15.072** | **4.940** | **156** | **73** | **77** |

*(Medições pós-otimização + `SceneAnalysisService` + MicroProfiler serão preenchidas assim que aplicarmos no Studio.)*

---

## 4. Bugs Encontrados e Correções

| ID | Sev. | Área / Arquivo | Causa | Correção | Commit | Prova do reteste |
|---|---|---|---|---|---|---|
| M-01 | ALTO | Ilhas de Treino 1–4 (`TrainingIsland1..4Builder.luau`, `TrainingSafetyBarriers.luau`) | Nenhuma das 4 ilhas tinha barreira de borda nem saída da água: cair da Celestial (160 studs) ou Ilhas 1–3 prendia o jogador no oceano sem volta | Adicionado perímetro invisível (`CanCollide=true`, `CanQuery=false`, `CanTouch=false`, `CastShadow=false`) em `TrainingIsland4Builder.luau` e script `tools/TrainingSafetyBarriers.luau` para Ilhas 1–3 | pendente | aguardando Studio |
| M-02 | ALTO | `src/client/Features/Portals/init.luau` | Prompts dos 4 portais de treino usavam `ZoneId="lagoon"` e mostravam "Lagoa da Ilha" em vez do nome/multiplicador/requisito de poder da ilha; `PortalRing` podia capturar pivô vazio com streaming ou brigar com `HubSpin` | Localização dedicada para `TrainingIsland` 1..4 (PT/EN + multiplicador + gate de Poder) e guarda de streaming/`HubSpin` no `PortalRing` | pendente | aguardando Play |
| M-03 | ALTO | `src/client/Features/PondAnimator.luau` | Ilha 4 (Celestial) sem perfil de animação; `updatePondGeometry` só buscava `WaterSurface` e calculava raio errado em cilindros horizontais | Adicionados `CelestialFocusProfile` e `CelestialInstinctProfile` (`LegendaryFish1..4`), suporte a `Water` cilindro horizontal, `OrbitCenter` e `FishFin` | pendente | aguardando Play |
| M-04 | MÉDIO | `src/client/Features/LivingWorld/init.luau` | Balões de fala da Lucy e Luna ainda usavam `Art.panel` (texto vazava igual ao bug anterior do Vô Anzol) e não ocultavam em `CatchRevealActive`/`IslandArrival`; `collectLanterns` ignorava lanternas `LanternGlow`/`LampGlow` do Hub V2 | Trocado para card limpo com borda colorida (padrão `GuideBubble`), ocultação durante chegada/revelação e detecção de lanternas do Hub V2 | pendente | aguardando Play |
| M-05 | MÉDIO | `src/client/Features/Ambient/init.luau` | Sem distance culling: atualizava ~35+ peças do Hub todo frame mesmo com o jogador nas ilhas de treino/expedição a >400 studs | Adicionado distance culling (`>220` studs do Hub) no `step()` | pendente | aguardando Play |
| M-06 | MÉDIO | `src/client/Features/WorldFx/init.luau` | `removePortal`/`removeAquarium` destruíam apenas o `ParticleEmitter`, vazando o `Attachment` pai; `watchTeleports` disparava burst falso ao trocar de personagem/respawn | Destruição do `Attachment` pai e rastreamento de `lastCharacter` em `watchTeleports` | pendente | aguardando Play |
| M-07 | MÉDIO | `tools/MapPerfOptimizer.luau`, `TrainingIsland1..4Builder.luau`, `ExpeditionIslands` | ~14.200 peças decorativas com `CanTouch=true` e `CanQuery=true`, nuvens/rochas com `CastShadow=true`, e `FishingZone` de Coral/Abismo com `CanQuery=true` (pedido do Agente 4) | Criado `tools/MapPerfOptimizer.luau` e atualizados `TrainingIsland1..4Builder.luau` (preservando `CanTouch`/`CanQuery` nos `ReturnPortal` e tags de contrato) | pendente | aguardando Studio |
| M-08 | BAIXO | `src/client/Features/HubAnimator.luau` | Conexão `DescendantAdded` de Model ainda vazio não era limpa em `unregisterTag`/`stop()` | Rastreado mapa `pendingModels` com desconexão garantida | pendente | aguardando Play |

---

## 5. Pedidos Enviados / Recebidos (`docs/revisao/PEDIDOS.md`)

- **Recebido do Agente 4:** `CoralReefIsland.FishingZone` e `StarAbyssIsland.FishingZone` com `CanQuery = true` → incluído no `tools/MapPerfOptimizer.luau` (vai aplicar no place e responder em `PEDIDOS.md` assim que validado no Studio).

---

## 6. Pendências que Dependem do João

1. **Portal "EM BREVE" do Cais das Expedições:** existem 2 slots "EM BREVE" ao lado dos portais de Coral e Abismo no Cais das Expedições (`HubBuilder_claude.luau:5953,6062`). **Decisão:** manter como teaser de futuras atualizações ou remover antes do lançamento?
2. **Objetos antigos/rascunho em `ReplicatedStorage` e `ServerStorage` (NÃO apagados sem autorização):**
   - `ReplicatedStorage.CreaturesOld` (replica para todo cliente/celular no join — se não for usado por nada, apagar ou mover para `ServerStorage` economiza memória e tempo de carregamento no celular!).
   - `ServerStorage`: `MapMeshRejects`, `CreatureMeshDrafts`, `CreaturePrototypes`, `RodPrototypes`, `CodexNativeCreatureDrafts`, `NpcPrototypes`, `AquariumShowcase`, `Backup_LagoonRim`, `Archive_HubTraining`, `Archive_OldHub`, `Archive_OldIslands`. (Não replicam pro cliente, mas aumentam o tamanho do place salvo; confirmar se quer arquivar/remover antes de publicar.)

---

## 7. Não Testado (Honestidade)

- Celular físico real (FPS, memória, térmica, toque real).
- 2+ jogadores simultâneos reais.
- Jogo publicado em servidor real da Roblox.

---

## 8. Sugestões (Não Implementadas)

- Mover `ReplicatedStorage.CreaturesOld` para fora de `ReplicatedStorage` (ou apagar após confirmação do João) para reduzir carga de replicação no join mobile.

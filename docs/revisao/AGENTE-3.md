# Relatório de Revisão Final — Agente 3 (Mundo, Mapa, Ilhas, Animações de Cenário e Desempenho)

Data de conclusão: 2026-11-27  
Place: `112666482424701` (Legendary Catch) — **salvo na nuvem v125** (`persistedToCloud = true`, não publicado)  
Escopo: Mapa (`Workspace`, `Lighting`, `Terrain`), construtores/patches em `tools/`, animações e vida de cenário (`HubAnimator`, `PondAnimator`, `Portals`, `WorldFx`, `WorldText`, `Ambient`, `LivingWorld`, `IslandLife`, `Arrival`, `Events/Scenery`), `MapStreaming`, limpeza e desempenho mobile.

---

## 1. Inventário Completo (20/20 Itens Validados)

| # | Área / Item | Arquivos / Objetos no Place | Testado como | Resultado |
|---|---|---|---|---|
| 1 | **Ilha 4 (Celestial) — Polimento visual (Prioridade 1)** | `tools/TrainingIsland4Builder.luau`, `Workspace.TrainingIslands.TrainingIsland_Celestial` | 4 rodadas construídas e fotografadas em Edit (iluminação normal, `Lighting` intocado) + captura Play do Portal (`07-play-ilha-4-portal-bloom-ok.jpg`, sem estouro de Bloom); `selfTest()` = **0 falhas**; todas as 20 notas ≥ **9,0/10** (média **9,38/10**); salvo na nuvem v125 | `corrigido` |
| 2 | **Ilha 4 — Perfil no `PondAnimator`** | `src/client/Features/PondAnimator.luau` (`CelestialFocusProfile`, `CelestialInstinctProfile`, `LegendaryFish1..4`, suporte a `Water` cilindro + `OrbitCenter` + `FishFin`) | `stylua`/`selene`/`luau-lsp` = 0 erros; Play Blocos 1 e 2: `4/4` `LegendaryFish1..4` nadando dentro da lagoa (`moved=2,39..2,74`, `dist=5,8..9,4/15,0`, `Y=160,15..160,40 <= waterTop 160,45`), sem invadir deck | `corrigido` |
| 3 | **Hub Principal (V2) — Visual e fidelidade** | `Workspace.Island`, `tools/HubBuilder_claude.luau`, `hub-patch-boards-portal.luau`, `hub-patch-2.luau` | Captura `01-hub-v2-geral.jpg` conferida contra `ref-1..5`: 0 `CentralCrystal*` (sem fonte na praça), 3 placares em arco (`LeaderboardBoard`), Santuário com 3 portais simétricos, Aprendiz só na cachoeira; varredura Z-fight limpa | `aprovado` |
| 4 | **Hub Principal — Caminhada a pé, colisão e cair no mar** | Praça, Oficina, Píer, Cais, Santuário, Lagoa/Aprendiz, Aquário, Patamar da Luna, `WorldBounds` | Play Bloco 1: 7 rotas `PathfindingService` `Success`, caminhada real (`Humanoid:MoveTo`) até o portal do Aprendiz teleportando sem pulo, saída da água no mar (`FrontStairs.Landing` com pulo → `Y=4.1 Running`) validada | `aprovado` |
| 5 | **Ilha 1 (Aprendiz) — Visual, caminhada, contratos e mar** | `Workspace.TrainingIslands.TrainingIsland_Apprentice`, `tools/TrainingIsland1Builder.luau`, `tools/TrainingSafetyBarriers.luau` | Captura `02-ilha-1-aprendiz.jpg` conferida contra `ilha-1-aprendiz-v2.jpg`; Play: `ArrivalSpawn` sólido (`Y=14.9 Concrete`), `TrainControl`/`TrainInstinct` ativos, `SafetyBarriers` (36 segs, `avgR=46.9`) travou borda (`fell=false`), `MapPerfOptimizer` aplicado e salvo v125 | `corrigido` |
| 6 | **Ilha 2 (Recife) — Visual, caminhada, contratos e mar** | `Workspace.TrainingIslands.TrainingIsland_Reef`, `tools/TrainingIsland2Builder.luau`, `tools/TrainingSafetyBarriers.luau` | Captura `03-ilha-2-recife.jpg` conferida contra `ilha-2-recife.jpg`; `selfTest()` = **0 falhas**; Play: `Y=15.2 Sand`, `F`/`I` `Success (0 pulos)`, `TrainControl`/`TrainInstinct` ativos, `SafetyBarriers` (`avgR=44.2`, `fell=false`), otimizada e salva v125 | `corrigido` |
| 7 | **Ilha 3 (Abismo Estelar) — Visual, caminhada, contratos e mar** | `Workspace.TrainingIslands.TrainingIsland_Abyss`, `tools/TrainingIsland3Builder.luau`, `tools/TrainingSafetyBarriers.luau` | Captura `04-ilha-3-abismo.jpg` conferida contra `ilha-3-abismo-estelar.jpg`; `selfTest(-520,12,1500)` = **0 falhas**; Play: `Y=15.2 Concrete`, `F`/`I` `Success (0 pulos)`, `SafetyBarriers` (`avgR=44.1`, `fell=false`); `SceneAnalysisService` provou ser a ilha mais leve (`119 DC`, `41,8K tris`) | `corrigido` |
| 8 | **Ilhas de Expedição (`CoralReefIsland`, `StarAbyssIsland`)** | `Workspace.ExpeditionIslands` (`986` peças, `FishingZone`, `CoralOceanBounds`, `AbyssOceanBounds`) | Capturas `05-expedicao-coral.jpg` e `06-expedicao-abismo.jpg`; Play: chão sólido (`13.3`), rota até pesca `Success (0 pulos)`, `ReturnPortal` ativo, **`FishingZone.CanQuery = false` e `CanTouch = false`** (`3/3` zonas) salvo v125 (atendendo pedido do Agente 4) | `corrigido` |
| 9 | **Portais (todos do Hub e das 6 ilhas)** | `src/client/Features/Portals/init.luau`, tags `ZonePortal` (12) e `ZoneSpawn` (8) | Corrigidos prompts dos 4 portais de treino (antes diziam "Lagoa da Ilha"; agora exibem nome localizado + multiplicador + gate de Poder em PT/EN) e guarda de streaming/`HubSpin` no `PortalRing`; validado no Play (`12/12` prompts limpos, sem loop de teleporte) | `corrigido` |
| 10 | **Contratos do mapa (tags e atributos)** | `ZonePortal` (12), `ZoneSpawn` (8), `TrainingSpot` (10), `FishingZone` (3), `WorkshopSpot` (3), `GuideNPC` (1), `LeaderboardBoard` (3), `PlayerSpawn` (1), `TrophyPedestal` (3), `AquariumTank` (1), `TrainingPortalGuide` (1), `OceanEventScenery` (1) | Auditoria Edit + Play após `MapPerfOptimizer` e rebuild da Ilha 4: 100% das tags intactas, 12/12 `ZonePortal` com `CanTouch=true`, `selfTest()` de Ilhas 2, 3 e 4 com **0 falhas** | `aprovado` |
| 11 | **Streaming (`StreamingEnabled` + `MapStreaming`)** | `src/server/Features/MapStreaming/init.luau`, `Workspace.StreamingEnabled=true` (`MinR=128`, `TargetR=1024`, `Opportunistic`) | 100% dos 67 Models `HubSpin/Bob/Sway` confirmados `Atomic` (`defaultModels=0`); teste de estresse com **5 idas e voltas** (3 no Bloco 1 + 2 no Bloco 2) Hub ↔ Celestial ↔ Abismo ↔ Hub: **`STRAY_PLAZA_PARTS = 0`** e piso sólido no retorno | `aprovado` |
| 12 | **Animações de cenário (`HubAnimator`)** | `src/client/Features/HubAnimator.luau`, tags `HubSpin/Bob/Pulse/Flicker/Sway/Wave` | Corrigido cleanup de conexões `DescendantAdded` (`pendingModels`); Play: `SwirlModel` gira calmo em `36,0 deg/s` (`18,7 deg/s` em `ReduceEffects = true`), `0` emissores ativos em `ReduceEffects = true`, `0` instâncias órfãs | `corrigido` |
| 13 | **Animações de lagos (`PondAnimator`)** | `src/client/Features/PondAnimator.luau` (Ilhas 1, 2, 3 e 4) | Adicionados perfis da Celestial + suporte a `Water` cilindro + `OrbitCenter` + `FishFin`; Play Blocos 1 e 2 validaram `4/4` peixes da Celestial nadando dentro dos limites sem conflito com `HubAnimator` | `corrigido` |
| 14 | **Vida e ambiente (`Ambient`, `IslandLife`, `LivingWorld`)** | `Ambient/init.luau`, `IslandLife/init.luau`, `LivingWorld/init.luau` | Corrigido distance culling em `Ambient` (>220 studs), balões da Lucy/Luna em `LivingWorld` (`TextFits = true` em 100% dos labels de Vô Anzol/Lucy/Luna), detecção das **52 lanternas do Hub V2** (brilho subindo `0,19 → 0,32` ao anoitecer) e **decoração de Natal no Píer Hub V2** (`5` guirlandas, `15` lâmpadas, `3` luzes + neve; `0` luzes/neve em `ReduceEffects = true` e limpeza 100% ao desligar `DevSeason`) | `corrigido` |
| 15 | **Textos no mundo (`WorldText`) e placas** | `WorldText/init.luau`, placas do Hub e ilhas | Placas da Ilha 4 corrigidas (dupla face + margem segura); `WorldText` auditado e validado em Play (`TrainControl` → `'Treinar Controle'`, `TrainInstinct` → `'Treinar Instinto'`) | `corrigido` |
| 16 | **Efeitos do mundo (`WorldFx`) e Cenário de Eventos (`Events/Scenery`)** | `WorldFx/init.luau`, `Events/Scenery.luau` | Corrigido leak de `Attachment` e falso `teleportBurst` ao trocar personagem em `WorldFx`; Play com `OceanEvent = "aurora"`: `OceanEventBackdrop` (`187` descendentes) + `OceanEventAurora` criados e removidos 100% ao limpar evento (`0` vazamentos) | `corrigido` |
| 17 | **Chegada (`Arrival`)** | `Arrival/init.luau` | Auditado estaticamente e confirmado no Play sem travar câmera nem input; balões de NPC respeitam `IslandArrival` | `aprovado` |
| 18 | **Desempenho (`SceneAnalysisService` + `Stats` + otimização do mapa)** | `tools/MapPerfOptimizer.luau`, `TrainingIsland1..4Builder.luau`, `Ambient` culling | `MapPerfOptimizer` aplicado e salvo v125: `CanTouch` `-88,6%`, `CanQuery` `-82,5%`, `CastShadow` `-52,6%`; `SceneAnalysisService` + `Stats` medidos nas 5 áreas (ver §3) + roteiro de teste real em celular incluso | `corrigido` |
| 19 | **Limpeza de objetos soltos/teste** | `Workspace`, `ServerStorage`, `ReplicatedStorage` | `Edit_DevAttrs = 0`; inventário completo de pastas antigas/rascunho em `ReplicatedStorage` e `ServerStorage` listado em §6 (nenhum item incerto apagado sem aval do João) | `aprovado` |
| 20 | **Segunda passada completa** | Toda área do Agente 3 após correções | Play Bloco 2 validou pós-correções (`LivingWorld` 52 lanternas + Natal Hub V2, `FishingZone` `3/3`, Celestial `4/4` peixes, `0` peças soltas na praça, **0 erros Lua novos** no Console, `stylua`/`selene`/`luau-lsp` = 0 erros) | `aprovado` |

---

## 2. Ilha 4 (Celestial) — Avaliação Item por Item (Meta: ≥ 9/10 em todos)

Referência: `art/preview/ilha-4/referencia.jpg`  
Prévias finais salvas em: `art/preview/ilha-4/final-1-geral.jpg`, `final-2-portal.jpg`, `final-3-foco.jpg`, `final-4-instinto.jpg`, `final-5-rocha.jpg` + prova Play (sem estouro de Bloom): `art/preview/revisao/agente-3/07-play-ilha-4-portal-bloom-ok.jpg`.  
Métricas finais (v125): `5.921` BaseParts (teto: `9.000`), `11` luzes, `7` emissores, `67` Beams, `CastShadow = 148` (era `1.024`), `selfTest()` = **0 falhas**. **Média final: 9,38/10 (mínimo 9,0/10).**

| Item | Rodada 1 (`d1cdc76`) | Rodada 2 | Rodada 4 (Final — v125) | Observações |
|---|---:|---:|---:|---|
| silhueta geral e proporções | 8.5 | 9.0 | **9.5** | Oval flutuante bem equilibrado com anel duplo, 2 ilhotas, coroa frontal, sakura e portal |
| cores e clima | 8.0 | 9.0 | **9.5** | Paleta marfim/champanhe/pastel calibrada para iluminação normal e validada no Play |
| grama e vegetação | 8.5 | 8.8 | **9.0** | `GrassPatch` e arbustos em `Material.Grass` sem anéis plásticos especulares + tufos/flores |
| borda de mármore e frisos | 8.5 | 9.5 | **9.5** | 3 frisos dourados nítidos e `RockUndersideCap` selando 100% do verde sob a borda |
| rocha inferior e cristais | 5.5 | 7.0 | **9.5** | Cunhas `RockCrag` anguladas para fora (`CFrame.Angles(0,0,math.pi)`) + `RockFacet` em `Slate` quente, `RockCore` recuado, cristais ouro diagonais e pontas ciano na quilha |
| cachoeiras e canais | 7.5 | 9.5 | **9.5** | Véus `Beam` translúcidos com `smoke_main.dds` animados, espuma e névoa |
| anel de luz duplo | 8.5 | 9.5 | **9.5** | Ouro champanhe com halo translúcido suave, estrelas 4-pontas e penas flutuantes |
| ilhotas flutuantes | 8.0 | 9.0 | **9.0** | Blocos rochosos facetados com grama e cristais ciano/ouro |
| mar de nuvens | 7.0 | 9.0 | **9.2** | `CloudDeck` contínuo sem furos azuis sob a ilha + cúmulos brancos/lavanda |
| aurora e raios | 8.5 | 7.5 | **9.2** | Aurora arco-íris pastel limpa no céu + 2 feixes verticais dourados dos pilares |
| portal, asas e redemoinho | 8.5 | 10.0 | **10.0** | Redemoinho arco-íris em `SmoothPlastic` + fita `Neon` translúcida: **zero estouro de Bloom no Play** |
| caminho de runas | 9.0 | 9.0 | **9.5** | Lajes quentes com runas douradas bem marcadas e laje ligando sobre o canal |
| ponte arqueada | 9.0 | 9.0 | **9.2** | Caminhável (`0 pulos`), guarda-corpos esculpidos e remates dourados |
| lagoa do Foco | 8.0 | 9.5 | **9.5** | Halos champanhe-ouro, constelação, 2 pilares com raios e cristal grande na grama |
| lagoa do Instinto | 6.5 | 9.0 | **9.2** | Reflexos pôr-do-sol suaves + `4/4` `LegendaryFish1..4` vibrantes animados pelo `PondAnimator` |
| decks, banquinhos e almofadas | 9.0 | 9.0 | **9.2** | Alinhados aos `FocusSpot`/`InstinctSpot`, livres de obstáculos |
| árvore rosa | 8.0 | 9.0 | **9.2** | Tronco dourado retorcido, cachos orgânicos em camadas, flores brancas e pétalas |
| coroa de cristal | 9.0 | 9.0 | **9.5** | Proporção `1,42×` com gemas e cristais ciano/rosa em destaque frontal |
| estátua, estandartes, placas | 8.0 | 9.5 | **9.5** | Estátua de peixe em mármore, estandartes e 4 placas dupla face com margem segura |
| lanternas, barris, cerca de corda | 9.0 | 9.0 | **9.2** | Proporção limpa, iluminação quente e barreira de borda invisível `SafetyBarrier` ativa |

---

## 3. Desempenho — Antes e Depois (v125)

### 3.1 Flags de Física e Sombra no Place (`MapPerfOptimizer.luau` + builders, salvo em v125)

| Área | BaseParts | Colidíveis | `CanTouch` (Antes → Depois) | `CanQuery` (Antes → Depois) | `CastShadow` (Antes → Depois) | Luzes | Emitters |
|---|---:|---:|---:|---:|---:|---:|---:|
| `Workspace.Island` (Hub V2) | 8.629 | 690 | 9 → **6** | 691 → **690** | 1.196 → **1.134** | 82 | 39 |
| `TrainingIsland_Apprentice` | 3.959 | 806 | 3.193 → **774** | 3.160 → **773** | 1.208 → **479** | 20 | 11 |
| `TrainingIsland_Reef` | 6.357 | 602 | 5.802 → **569** | 5.780 → **567** | 774 → **284** | 13 | 5 |
| `TrainingIsland_Abyss` | 5.044 | 229 | 4.618 → **197** | 4.404 → **197** | 444 → **138** | 17 | 8 |
| `TrainingIsland_Celestial` (R4) | 5.921 | 305 | 1 → **1** | 275 → **273** | 1.024 → **148** | 11 | 7 |
| `ExpeditionIslands` | 986 | 120 | 656 → **76** | 762 → **139** | 294 → **158** | 13 | 3 |
| **Total** | **30.896** | **2.752** | **14.279 → 1.623 (-88,6%)** | **15.072 → 2.639 (-82,5%)** | **4.940 → 2.341 (-52,6%)** | **156** | **73** |

*(Obs.: `30.896` inclui as `108` paredes invisíveis de segurança das Ilhas 1–3 + `36` da Ilha 4, todas com `CanTouch=false`, `CanQuery=false`, `CastShadow=false`.)*

### 3.2 Medição em Play (`SceneAnalysisService` + `Stats`, pós-otimização)

| Área | Draw Calls | Triângulos (sem sombras) | Opaque (DC / Tris) | Terrain (DC / Tris) | Transparent (DC / Tris) | `PhysicsStepTimeMs` |
|---|---:|---:|---:|---:|---:|---:|
| **Hub V2** | 421 | 529.228 | 88 / 343.794 | 256 / 181.392 | 26 / 157 | **0,03 ms** |
| **Ilha 1 (Aprendiz)** | 637 | 404.644 | 389 / 224.194 | 219 / 180.170 | 19 / 175 | **0,02 ms** |
| **Ilha 2 (Recife)** | 180 | 169.092 | 105 / 123.284 | 63 / 45.732 | 2 / 3 | **0,14 ms** |
| **Ilha 3 (Abismo Estelar)** | **119** | **41.824** | 81 / 23.622 | 32 / 18.176 | 1 / 1 | **0,00 ms** |
| **Ilha 4 (Celestial)** | **126** | **155.482** | 26 / 121.248 | 52 / 33.592 | 41 / 525 | **0,13 ms** |

- **CPU/Script no Play (Hub V2):** `RenderCPU = 8,34 ms`, `HeartbeatMs = 3,30 ms`, `Physics = 0,03 ms` (total de trabalho real `< 11,7 ms`, bem abaixo do orçamento de `16,6 ms` para 60 FPS). O `FrameTime = 66,4 ms` (15 FPS) visto no Studio sem foco é o limitador automático de janela em segundo plano do Roblox Studio — confirmando que a Ilha 3 **não** tem gargalo de renderização (`119 DC`, `41,8K tris`).
- **Memória de scripts cliente (`SceneAnalysisService:GetScriptMemoryAsync`):** total `8,58 MB` (módulos do Agente 3: `PondAnimator` `2,06 MB`, `HubAnimator` `246 KB`, `LivingWorld` `110 KB`, `Ambient` `56 KB`, `Portals` `44 KB`, `IslandLife` `36 KB`, `WorldFx` `24 KB`).
- **Instâncias sem pai (`GetUnparentedInstancesAsync`):** `0` em `HubAnimator`, `PondAnimator`, `WorldFx`, `Ambient`; `5` em `LivingWorld` (`ChristmasSnow` estacionado fora da câmera quando Natal desligado); `1` em `Portals`. Zero vazamento após 5 viagens de streaming e ciclo completo de eventos/Natal.

### 3.3 Roteiro de Teste Real em Celular (para o João validar antes de publicar)

1. Abrir o jogo publicado (privado/teste) em um celular Android de entrada/intermediário (ex.: Galaxy A06 ou similar) com **Performance Stats** ligado nas configurações da Roblox.
2. **Hub V2 (2 min):** girar a câmera 360° na praça, andar até Oficina → Aquário → Luna → Píer → Cais → Santuário → Portal do Aprendiz. Conferir se FPS se mantém ≥ 30 (ideal ≥ 45), memória total estável (< 1,2 GB no celular) e sem engasgo ao virar para os placares.
3. **Ilhas de Treino 1 → 2 → 3 → 4 (3 min):** entrar em cada portal, observar os peixes/anéis animando, treinar 10 s em Foco/Instinto, testar encostar na borda (barreira invisível) e voltar pelo portal. Conferir que nenhuma peça da Celestial aparece na praça do Hub no retorno.
4. **Ilhas de Expedição (Coral e Abismo, 2 min):** teleportar, fazer 1 arremesso completo em cada ilha e voltar.
5. **Toggle `Reduzir Efeitos` (1 min):** ligar nas Configurações e conferir se partículas somem, `HubAnimator` desacelera e FPS sobe/estabiliza em aparelho mais fraco.

---

## 4. Bugs Encontrados e Correções

| ID | Sev. | Área / Arquivo | Causa | Correção | Commit / Save | Prova do reteste |
|---|---|---|---|---|---|---|
| M-01 | ALTO | Ilhas de Treino 1–4 (`TrainingIsland4Builder.luau`, `TrainingSafetyBarriers.luau`) | Nenhuma das 4 ilhas tinha barreira de borda nem saída da água: cair da Celestial (160 studs) ou Ilhas 1–3 prendia o jogador no oceano | Adicionado perímetro invisível de 36 segmentos (`CanCollide=true`, `CanQuery=false`, `CanTouch=false`, `CastShadow=false`) na Celestial e em `TrainingSafetyBarriers.luau` (Ilhas 1–3) | `13095c3` + Cloud v125 | Play Bloco 1: caminhada forçada contra a borda nas 4 ilhas → `fell=false` em 4/4 |
| M-02 | ALTO | `src/client/Features/Portals/init.luau` | Prompts dos 4 portais de treino usavam `ZoneId="lagoon"` e exibiam `"Lagoa da Ilha"`; `PortalRing` podia capturar pivô vazio no streaming ou brigar com `HubSpin` | Localização dedicada para `TrainingIsland` 1..4 (nome + multiplicador + Poder PT/EN) e guarda de streaming/`HubSpin` | `13095c3` | Play Bloco 1: `lagoon_to_training_1` → `'Ilha do Aprendiz (×1)'`, `Reef` `'×3 · 100K Poder'`, `Abyss` `'×12 · 100M Poder'`, `Celestial` `'×50 · 1T Poder'` |
| M-03 | ALTO | `src/client/Features/PondAnimator.luau` | Ilha 4 sem perfil de animação; `updatePondGeometry` só achava `WaterSurface` e calculava raio incorreto em cilindros horizontais | Adicionados `CelestialFocusProfile` e `CelestialInstinctProfile` (`LegendaryFish1..4`), suporte a `Water` cilindro, `OrbitCenter` e `FishFin` | `13095c3` | Play Blocos 1 e 2: `4/4` peixes da Celestial nadando dentro do raio e abaixo de `waterTop` (`160.15..160.40 <= 160.45`) |
| M-04 | ALTO | `tools/TrainingIsland4Builder.luau` | `PortalVortex` em `Neon` estourava para branco sólido com o `Bloom` do Play; `RockCrag` tinha face reta para fora | `PortalVortex` em `SmoothPlastic` pastel + fita `Neon` translúcida (`0.45`); `RockCrag` girado (`CFrame.Angles(0,0,math.pi)`) + `RockFacet` em `Slate` quente | `13095c3` + Cloud v125 | `07-play-ilha-4-portal-bloom-ok.jpg` (espiral arco-íris nítida no Play) + `final-5-rocha.jpg` (`selfTest` 0 falhas) |
| M-05 | MÉDIO | `src/client/Features/LivingWorld/init.luau` | Balões de Lucy/Luna usavam `Art.panel` (texto vazava) e não ocultavam em `CatchRevealActive`/`IslandArrival` | Card limpo com borda colorida (padrão `GuideBubble`) e guarda para `IslandArrival`/`CatchRevealActive` | `13095c3` | Play Bloco 1: `TextFits=true` em 100% dos labels de Vô Anzol, Lucy e Luna |
| M-06 | MÉDIO | `src/client/Features/LivingWorld/init.luau` | No Hub V2, `collectLanterns` achava `0` lanternas (nomes `*LanternGlow`/`*TorchGlow`) e `buildPierHolidayDecor` criava `0` guirlandas no Natal (`PierLanternCap`/`GateBeam` em vez de `PostCap`/`ArchBeam`) | Ampliada detecção para `*LanternGlow$`/`*Lantern[NS]Glow$`/`*TorchGlow$` e adicionados `PierLanternCap`/`GateBeam` no decor de Natal | `6ac11f7` | Play Bloco 2: **52 lanternas** detectadas (`0,19 → 0,32` ao anoitecer); Natal gerou `5` guirlandas, `15` lâmpadas, `3` luzes + limpeza `100%` ao desligar |
| M-07 | MÉDIO | `tools/MapPerfOptimizer.luau`, `TrainingIsland1..4Builder.luau`, `ExpeditionIslands` | ~14,2K peças decorativas com `CanTouch/CanQuery=true`, nuvens/rochas com sombra, e `FishingZone` de Coral/Abismo com `CanQuery=true` (pedido do Agente 4) | Criado `MapPerfOptimizer.luau`, atualizados builders 1–4, aplicado e salvo no place v125 | `13095c3` + `6ac11f7` + Cloud v125 | Play Bloco 2: `FISHING_ZONES_CLEAN=3/3`; `CanTouch -88,6%`, `CanQuery -82,5%`, `CastShadow -52,6%`, `Phys <= 0,14 ms` |
| M-08 | MÉDIO | `src/client/Features/Ambient/init.luau` | Sem distance culling: atualizava peças do Hub mesmo a >400 studs nas ilhas | Adicionado distance culling (`>220` studs do Hub) no `step()` | `13095c3` | Play Blocos 1 e 2: `0` erros Lua e `HeartbeatMs = 3,30 ms` |
| M-09 | MÉDIO | `src/client/Features/WorldFx/init.luau` | `removePortal`/`removeAquarium` vazavam o `Attachment` pai; `watchTeleports` disparava burst falso ao trocar personagem | Destruição do `Attachment` pai e rastreamento de `lastCharacter` | `13095c3` | Play Blocos 1 e 2: `0` instâncias órfãs em `WorldFx` no `SceneAnalysisService` |
| M-10 | BAIXO | `src/client/Features/HubAnimator.luau` | Conexão `DescendantAdded` em `Model` ainda vazio não era limpa em `unregisterTag`/`stop()` | Rastreado mapa `pendingModels` com desconexão garantida | `13095c3` | Play Blocos 1 e 2: `0` órfãos, `0` peças soltas na praça após 5 viagens de streaming |

---

## 5. Pedidos Enviados / Recebidos (`docs/revisao/PEDIDOS.md`)

- **Recebido do Agente 4:** `Workspace.CoralReefIsland.FishingZone` e `Workspace.StarAbyssIsland.FishingZone` com `CanQuery = true` → **Resolvido** via `tools/MapPerfOptimizer.luau`, salvo na nuvem **v125**, provado no Play Bloco 2 (`3/3` `FishingZone`s com `CanCollide=false, CanQuery=false, CanTouch=false`), e respondido em `docs/revisao/PEDIDOS.md`.
- **Enviados pelo Agente 3:** nenhum bug bloqueante encontrado fora do nosso escopo.

---

## 6. Pendências que Dependem do João

1. **Portais "EM BREVE" no Cais das Expedições:** existem 2 slots `"EM BREVE"` ao lado dos portais de Coral e Abismo (`tools/HubBuilder_claude.luau:5953,6062`). **Decisão:** manter como teaser de futuras ilhas de expedição ou remover antes do lançamento?
2. **Objetos antigos/rascunho em `ReplicatedStorage` e `ServerStorage` (NÃO apagados sem autorização):**
   - **`ReplicatedStorage.CreaturesOld`** *(maior impacto!)*: como está em `ReplicatedStorage`, replica para todo jogador/celular no join. Se nenhum script usar, apagar ou mover para fora de `ReplicatedStorage` reduz memória e tempo de carregamento no celular.
   - **`ServerStorage`**: `MapMeshRejects`, `CreatureMeshDrafts`, `CreaturePrototypes`, `RodPrototypes`, `CodexNativeCreatureDrafts`, `NpcPrototypes`, `AquariumShowcase`, `Backup_LagoonRim`, `Archive_HubTraining`, `Archive_OldHub`, `Archive_OldIslands`. Não replicam ao cliente, mas aumentam o peso do place salvo.
3. **Borda do mar (`Terrain` Water) atrás das Ilhas de Treino 2 e 3:** nas capturas `03-ilha-2-recife.jpg` (`Z=1100`) e `04-ilha-3-abismo.jpg` (`Z=1500`), a camada de água do `Terrain` termina antes dessas coordenadas (criando uma linha reta de horizonte atrás das ilhas). Como são ilhas flutuantes, não atrapalha o gameplay, mas pode ser suavizado no futuro estendendo o mar ou adicionando névoa/nuvens distantes se o João quiser.

---

## 7. Não Testado (Honestidade)

- Celular físico real (FPS sustentado em foco, temperatura, memória real no Android/iOS, toque na tela).
- 2+ jogadores simultâneos reais (portais, treino concorrente no mesmo lago, outros jogadores pescando).
- Jogo publicado em servidor real da Roblox.

---

## 8. Sugestões (Não Implementadas)

- Mover ou apagar `ReplicatedStorage.CreaturesOld` (após confirmação do João) para aliviar o carregamento inicial em celulares de entrada.
- Se quiser ainda mais leveza na Ilha 1 (`637 DC`), mesclar/agrupar alguns blocos decorativos de terreno/pedra repetidos no futuro, embora os `404K` triângulos e `0,02 ms` de física já estejam confortáveis.

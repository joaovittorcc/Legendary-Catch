# A2 — Cenário dos Eventos do Oceano (Arte 3D, Paletas e Contrato)

> Entrega do lote **A2** ([`PLANO-AQUARIO-ANTIGRAVITY.md`](PLANO-AQUARIO-ANTIGRAVITY.md)), construído sob as diretrizes do vault `fwjelaa` (*World Budgets*, *Stylized Lighting Recipes*, *Light Sources and Shadows*, *Environment Art Styles*, *Zone and Biome Art Direction*, *Colour-Blind Safe Design* e *Motion Sensitivity and Camera Comfort*).

---

## 1. Alinhamento com Claude e Codex: Cenografia vs. Portal Utilizável

**Decisão fechada para A2:** o arco de evento no píer é **100% cenografia (não-interativo)** — **NÃO** é uma entrada de teleporte.

| Critério | Portal de Zona (`ZonePortal`, Claude) | Portal de Evento (`EventSceneryKit`, A2) |
|---|---|---|
| Função | Teleporta o jogador entre ilhas (`main`, `coral`, `abyss`) | Sinaliza e ambienta evento global ativo no oceano (`Config/Events`) |
| Localização | `PortalPlaza` (terraço de pedra) e ponto de retorno das ilhas | Ponta dos píeres de pesca (`EventSceneryAnchor`) |
| Tag / Interação | Tag `ZonePortal`, `ProximityPrompt` (`UsePortal`) e `Touched` | `PortalRole = "SceneryOnly"`, **sem `ZonePortal`**, **sem `ProximityPrompt`**, **sem `Touched`** |
| Leitura visual | Vórtice opaco no centro + placa de nível mínimo | **Centro 85% aberto** (jogador arremessa a linha através do arco), véu translúcido só na borda superior + brasão exclusivo do evento + boias flutuantes no mar |
| Colisão | Base física no santuário | `CanCollide = false`, `CanQuery = false`, `CanTouch = false` em 100% das peças |

Com isso, o jogador nunca confunde um evento ativo no píer com um portal que leva para outra ilha, e a linha de pesca/câmera nunca colidem ou clipam com o arco (vão livre de **11,5 studs de largura × 12,6 studs de altura**, acima do mínimo de 3 alturas de avatar recomendado no vault `fwjelaa`).

---

## 2. Estrutura do Kit Modular no Studio (`ReplicatedStorage.EventSceneryKit`)

Todo o conjunto já está montado, pré-carregado (`8/8` `MeshPart`s com `0` falhas) e pronto para clonagem pelo cliente em `ReplicatedStorage.EventSceneryKit`.

- **Atributos na raiz (`EventSceneryKit`):**
  - `KitVersion = "A2-v1"`
  - `PortalRole = "SceneryOnly"`
  - `DefaultPierWidth = 14`
  - `ArchClearWidth = 11.5`
  - `ArchClearHeight = 12.6`
  - `LightCount = 3`
  - `ShadowsEnabled = false`

### 2.1 Peças do Kit

| Caminho | Conteúdo | Papel no píer |
|---|---|---|
| `EventSceneryKit.BaseArch` | `Model` (`PrimaryPart = Root`, `ModelStreamingMode = Atomic`) | Estrutura base adaptável a qualquer píer |
| `BaseArch.Support_Left` / `Support_Right` | Plintos de pedra clara (`Cobblestone`) + cintas de latão + joelhos de madeira + pilares de madeira escura (`88,52,36`, igual ao `FishingPier`) + tiras de runas `Neon` frente/mar + `CrystalCluster` inclinado nos ombros | Abraça fisicamente os dois postes da ponta do píer (`±6,55` studs) |
| `BaseArch.ArchCrown` | Arco curvo em 12 segmentos (madeira + filete de latão + trim fino `Neon` dos dois lados), pedra-chave central (`KeystoneFrame`) e 2 `HangingLantern` suspensas nos ombros | Emoldura o horizonte marítimo sem bloquear a visão da água |
| `BaseArch.PierBrackets` | 2 `LanternPost` com colar de latão montados `6,2` studs atrás da ponta (sobre o penúltimo par de postes do píer) + `Beam` festivo ligando as lanternas aos pilares | Integra o arco ao comprimento do píer |
| `BaseArch.LightingRig` | **3 `PointLight`s** (`ArchCrownLight` range 36, `PierLight_L/R` range 22, todas **`Shadows = false`**), `PortalVeilRim` (`Beam` translúcido só na borda superior) e `ArchAmbientMotes` (`Rate = 5`, tag `EventVfxEmitter`) | Iluminação estilizada com orçamento seguro para celular |
| `BaseArch.OceanBeacons` | `WaterBeacon_L` e `WaterBeacon_R` em `(±11.0, -9.8, -11.5)` — boias de pedra + anel luminoso na superfície da água + obelisco de cristal + `BeaconSparks` (`Rate = 4`, tag `EventVfxEmitter`) | Estende o evento para a superfície do oceano flanqueando a faixa de arremesso |
| `EventSceneryKit.Crests` | 6 modelos `Crest_<eventId>` (`PrimaryPart = Root`) | Brasão de silhueta exclusiva encaixado em `BaseArch.Root.CrestMount` |
| `EventSceneryKit.EventProps` | 6 modelos `Props_<eventId>` (`PrimaryPart = Root`) | Peças laterais e efeitos exclusivos encaixados no `CFrame` da âncora |
| `EventSceneryKit.Palettes` | 6 `Configuration`s (`Palettes.<eventId>`) | Tokens `Color3`/`number`/`string` consumíveis direto por código |

### 2.2 `Attachment`s de Montagem em `BaseArch.Root`

| Nome | Posição local (studs) | Uso |
|---|---|---|
| `CrestMount` | `(0, 14.1, 0)` | Encaixe exato do `Crest_<eventId>:PivotTo(crestMount.WorldCFrame)` |
| `HeaderAnchor` | `(0, 17.8, 0)` | Posição do `BillboardGui` (`EventSceneryLabel`) acima do brasão, sem sobreposição |
| `LeftSupportMount` / `RightSupportMount` | `(±6.55, 0, 0)` | Base dos suportes sobre os postes de canto do píer |
| `LeftLanternMount` / `RightLanternMount` | `(±6.55, 3.6, 6.2)` | Base dos braços de lanterna no penúltimo par de postes |
| `LeftBuoyMount` / `RightBuoyMount` | `(±11.0, -9.8, -11.5)` | Posição das boias luminosas sobre a água (`Y ≈ 0,30`) |

### 2.3 Orçamento Mobile Auditado (por evento montado)

- **Partes por evento ativo:** `125–134` (`BaseArch` 113 + `Crest` 7–12 + `Props` 5–9)
- **Luzes locais:** `3` (`Shadows = false` em todas; teto do vault: `8–12`)
- **Emissores ativos:** `3–5` (taxa total ≤ `25` partículas/s; todos com tag `EventVfxEmitter`)
- **`CastShadow = true` / `CanCollide = true` / `Scripts` / `ZonePortal`:** `0` em todo o kit
- **Cobertura de `Neon`:** filetes finos (`0,16–0,26` stud) mantendo glow bem abaixo de 16% do quadro (evita estouro de bloom em celular)

---

## 3. Posições e Adaptação aos Três Píeres

Todas as âncoras usam exatamente a mesma convenção de eixos já adotada em `src/client/Features/Events/Scenery.luau`:
- **Origem `(0, 0, 0)`:** centro da ponta do deck (`topY`)
- **`+Y`:** vertical para cima
- **`±X` (`RightVector`):** largura do píer
- **`-Z` (`LookVector`):** apontando para o mar aberto (direção de arremesso)
- **`+Z` (`ZVector`):** apontando de volta pelo píer (frente voltada para o jogador)

| Ilha / Zona | Caminho no `Workspace` | Tag | `Position` | `LookVector` (mar) | `PierWidth` | `ScaleX` | Observações |
|---|---|---|---|---|---:|---:|---|
| Lagoa Inicial (`lagoon`) | `Workspace.Island.FishingPier.EventSceneryAnchor` | `OceanEventScenery` | `(84.40, 10.10, 8.00)` | `(1, 0, 0)` | `14.0` | `1.000` | Âncora primária (compatível direto com `Scenery.luau` atual). Pilares a `0,05` stud de `EndPost_1/2`; boia esquerda a `32,2` studs do `TrophyMonument`. |
| Recife de Coral (`coral`) | `Workspace.Island.CoralReefIsland.EventSceneryAnchor` | `OceanEventSceneryZone` | `(422.53, 10.45, -183.61)` | `(0.7507, 0, 0.6606)` | `13.2` | `0.943` | Pronta para o Codex ligar suporte multi-ilha quando desejar. |
| Abismo Estelar (`abyss`) | `Workspace.Island.StarAbyssIsland.EventSceneryAnchor` | `OceanEventSceneryZone` | `(-317.02, 10.45, -243.21)` | `(0.7507, 0, 0.6606)` | `13.6` | `0.971` | Pronta para o Codex ligar suporte multi-ilha quando desejar. |

> **Por que Coral e Abismo usam `OceanEventSceneryZone` por enquanto?**
> O `Scenery.luau` atual pega o primeiro resultado de `CollectionService:GetTagged("OceanEventScenery")` (cuja ordem não é garantida). Mantendo `OceanEventScenery` exclusivo no píer principal, o jogo atual já monta no píer certo 100% das vezes; quando o Codex atualizar para multi-ilha (ou por `ZoneId` onde o jogador está), basta ler ambas as tags filtrando pelo atributo `ZoneId`.

---

## 4. Documentação por Evento (Paletas, Silhuetas e Sinais Visíveis)

Cada evento possui **dois canais independentes** (cor + silhueta exclusiva do brasão + peças próprias) para permanecer identificável por jogadores daltônicos e em telas pequenas sem sombra (qualidade gráfica < 4).

### 4.1 Tabela de Paletas (idêntica a `EventSceneryKit.Palettes.<id>`)

| Evento (`id`) | Nome PT-BR | `Primary` (RGB) | `Secondary` (RGB) | `Glow` (RGB) | `Dark` (RGB) | `WaterTint` (RGB) | `LightColor` (RGB) / `Brightness` |
|---|---|---|---|---|---|---|---|
| `starTide` | Maré Estelar | `255, 110, 174` | `92, 232, 255` | `255, 200, 232` | `48, 28, 66` | `110, 92, 198` | `255, 150, 210` / `1.65` |
| `thunderStorm` | Tempestade de Trovões | `72, 224, 255` | `142, 168, 255` | `220, 250, 255` | `26, 36, 62` | `28, 72, 118` | `110, 228, 255` / `1.85` |
| `goldenHour` | Hora Dourada | `255, 206, 78` | `255, 138, 64` | `255, 244, 196` | `84, 48, 24` | `196, 156, 72` | `255, 214, 118` / `1.70` |
| `shimmerShoal` | Cardume Cintilante | `88, 255, 184` | `58, 216, 238` | `205, 255, 238` | `22, 68, 74` | `46, 196, 174` | `120, 255, 206` / `1.55` |
| `fogBank` | Banco de Nevoeiro | `165, 212, 238` | `118, 236, 224` | `232, 248, 255` | `42, 58, 74` | `92, 128, 148` | `185, 228, 248` / `1.45` |
| `aurora` | Aurora Boreal | `108, 255, 214` | `178, 124, 255` | `218, 255, 246` | `30, 32, 68` | `72, 162, 178` | `138, 255, 226` / `1.75` |

### 4.2 Identidade, Silhueta e Peças por Evento

1. **`starTide` — Maré Estelar** (`180 s`, +Raros/Épicos/Lendários, +25% moedas)
   - **Brasão (`Crest_starTide`):** estrela-bússola de 8 pontas + crescente de latão.
   - **Peças (`Props_starTide`):** cristais-estrela flutuantes ao lado dos pilares + 2 feixes celestes ascendentes (`StarStream_L/R`).
   - **Sinal visível:** contraste rosa-magenta × ciano-cristal sobre o mar violeta; feixes visíveis desde a Praça Central.
   - **Evitar ("Not this"):** dourado solar ou fumaça cinza.

2. **`thunderStorm` — Tempestade de Trovões** (`150 s`, +Raros/Épicos, +15% moedas)
   - **Brasão (`Crest_thunderStorm`):** tridente de relâmpago em zigue-zague com hastes metálicas escuras.
   - **Peças (`Props_thunderStorm`):** bobinas de latão/esfera elétrica no topo dos pilares + 2 arcos elétricos (`LightningArc_L/R`) ligando o arco às boias na água.
   - **Sinal visível:** arcos diagonais ciano-elétrico cruzando do píer ao mar + escurecimento sutil da atmosfera (`Brightness = -0.11`).
   - **Evitar:** flashes estroboscópicos (manter brilho estável/pulso lento ≤ 1,5 Hz).

3. **`goldenHour` — Hora Dourada** (`120 s`, +Incomuns, ×2 moedas)
   - **Brasão (`Crest_goldenHour`):** disco solar de latão com 7 raios em leque alternado (longo/curto).
   - **Peças (`Props_goldenHour`):** 2 estandartes solares pendurados *por fora* dos pilares (corredor 100% livre) + 2 `StoneLantern` nos degraus da base.
   - **Sinal visível:** silhueta radiante em leque + banho dourado quente na madeira e na água (`WaterTint` âmbar).
   - **Evitar:** tons roxos/frios.

4. **`shimmerShoal` — Cardume Cintilante** (`150 s`, +Incomuns/Raros, +30% moedas — evento amigável para iniciantes)
   - **Brasão (`Crest_shimmerShoal`):** dois peixes estilizados saltando em arco ao redor de uma pérola central sobre onda.
   - **Peças (`Props_shimmerShoal`):** colunas de bolhas ascendentes (`ShoalBubbles_L/R`, `Rate = 6`) + leques de coral brilhante nas bases.
   - **Sinal visível:** verde-menta vibrante + movimento vertical constante de bolhas/espirais perto da água.
   - **Evitar:** clima sombrio ou luzes vermelhas.

5. **`fogBank` — Banco de Nevoeiro** (`150 s`, +Épicos/Lendários, +35% moedas)
   - **Brasão (`Crest_fogBank`):** lanterna de farol náutico com cúpula, 4 grades metálicas escuras e halo horizontal espectral.
   - **Peças (`Props_fogBank`):** globos de farol pálidos nos suportes + névoa baixa deslizando rente ao mar (`SeaMist_L/R`, `Rate = 4`).
   - **Sinal visível:** silhueta inconfundível de farol + dessaturação fria da cena (`Saturation = -0.22`) destacando a luz pálida no píer.
   - **Evitar:** névoa densa sobre a ponta da vara/boia que atrapalhe a leitura dos minigames.

6. **`aurora` — Aurora Boreal** (`180 s`, +Lendários/Místicos, +50% moedas)
   - **Brasão (`Crest_aurora`):** coroa de 5 prismas cristalinos assimétricos sobre faixa ondulada.
   - **Peças (`Props_aurora`):** 2 cortinas verticais iridescentes (`AuroraCurtain_L/R`) subindo `26` studs acima dos pilares, conectando o arco do píer às fitas de céu (`OceanEventAurora`) do Codex.
   - **Sinal visível:** gradiente menta → violeta alto no céu, legível de qualquer ponto da ilha.
   - **Evitar:** saturar demais o branco do centro do píer.

### 4.3 Leitura em Três Distâncias (Sinal de Evento Ativo)

| Distância | O que o jogador vê |
|---|---|
| **Praça Central (65+ studs)** | Silhueta do `Crest_<id>` contra o céu + feixes/cortinas (`starTide`/`aurora`/`thunderStorm`) + tintura global do oceano/céu + banner `OceanEventHud`. |
| **Meio do Píer (25–45 studs)** | Arco completo emoldurando o horizonte + lanternas laterais (`PierBrackets`) + cordões `FestoonBeam` + placa `EventSceneryLabel` (`HeaderAnchor`). |
| **Ponta do Píer (0–15 studs)** | Vão livre de `11,5 × 12,6` studs, brilho suave nas 3 `PointLight`s, `PortalVeilRim` na borda superior e `WaterBeacon_L/R` flanqueando o alvo de arremesso no mar. |

---

## 5. Transição de Montagem e Desmontagem (Contrato para o Codex)

O servidor publica `OceanEvent` (string) e `OceanEventEndsAt` (timestamp) em `ReplicatedStorage`. Quando o cliente (`Events/init.luau` + `Events/Scenery.luau`) detectar início ou fim do evento:

### 5.1 Montagem (`1,40 s` no modo normal)

1. **T = 0,00 s → 0,40 s (Ancoragem no píer):**
   - Clonar `BaseArch`, `Crests["Crest_" .. eventId]` e `EventProps["Props_" .. eventId]`.
   - Aplicar cores a todos os descendentes com atributo `TintRole` lendo `Palettes[eventId]:GetAttribute(role)`.
   - Posicionar `Support_Left/Right`, `PierBrackets` e `OceanBeacons` com `offsetY = -2,5` studs e subir com `TweenInfo.new(0.40, Enum.EasingStyle.Back, Enum.EasingDirection.Out)`.
2. **T = 0,30 s → 0,75 s (Erguimento do arco e luzes):**
   - `ArchCrown` sobe `1,8` studs até a posição final (`Quad, Out`); as 3 `PointLight`s fazem rampa de `Brightness = 0 → alvo` em `0,45 s`.
3. **T = 0,65 s → 1,05 s (Brasão + peças do evento):**
   - `Crest_<id>` entra em `CrestMount` (escala/altura suave de `0,4 → 1,0`, `Back, Out`) acompanhado de um único pulso curto de luz na pedra-chave (`KeystoneCore`, sem flash de tela!).
   - `Props_<id>` faz fade-in de `Transparency` (`1 → original`).
4. **T = 1,00 s → 1,40 s (Véu, partículas e placa):**
   - `PortalVeilRim` e os `Beam`s dos props acendem; `EventVfxEmitter` liga (`Enabled = true`); `EventSceneryLabel` aparece em `HeaderAnchor`.

### 5.2 Desmontagem (`0,90 s` no modo normal)

1. **T = 0,00 s:** desligar todos os `ParticleEmitter`s com tag `EventVfxEmitter` (`Enabled = false`) para parar emissão nova imediatamente.
2. **T = 0,00 s → 0,45 s:** `Brightness` das 3 `PointLight`s cai para `0`, `Beam`s e `EventSceneryLabel` somem.
3. **T = 0,30 s → 0,90 s:** `Crest_<id>`, `ArchCrown` e `OceanBeacons` descem suavemente `-2,2` studs enquanto `Transparency → 1`.
4. **T = 0,90 s:** chamar `mounted:Destroy()` (limpeza total, zero resíduos no `Workspace`).

### 5.3 Modo `ReduceEffects = true` (Acessibilidade / Celular Fraco)

- **Montagem e desmontagem:** corte direto ou fade linear curto (`0,25 s`), **sem `Back`/bounce, sem pulso de luz, sem movimento de câmera**.
- **Partículas:** manter `Enabled = false` e chamar `:Clear()` em todos os descendentes com tag `EventVfxEmitter`.
- **Preservado 100%:** geometria do arco, cores da paleta, brasão de silhueta exclusiva (`Crest_<id>`), luzes estáticas (`Brightness × 0.8`) e placa `EventSceneryLabel`.

---

## 6. Resumo do Contrato para Integração no Codex (`Events/Scenery.luau`)

```lua
-- 1. Localizar kit e paleta
local kit = ReplicatedStorage:FindFirstChild("EventSceneryKit")
local pal = kit and kit.Palettes:FindFirstChild(eventId)

-- 2. Clonar BaseArch + Crest_<id> + Props_<id> no CFrame da âncora (tag OceanEventScenery)
local model = kit.BaseArch:Clone()
model:PivotTo(anchorPose)

local crestSrc = kit.Crests:FindFirstChild("Crest_" .. eventId)
if crestSrc then
    local crest = crestSrc:Clone()
    crest:PivotTo(model.PrimaryPart.CrestMount.WorldCFrame)
    crest.Parent = model
end

local propsSrc = kit.EventProps:FindFirstChild("Props_" .. eventId)
if propsSrc then
    local props = propsSrc:Clone()
    props:PivotTo(anchorPose)
    props.Parent = model
end

-- 3. Aplicar paleta por TintRole (BasePart / Light / Beam / ParticleEmitter)
-- 4. Anexar EventSceneryLabel em model.PrimaryPart.HeaderAnchor
-- 5. Se ReduceEffects == true, desligar todos os descendentes com tag "EventVfxEmitter"
```

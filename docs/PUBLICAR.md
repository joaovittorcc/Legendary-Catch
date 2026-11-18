# Checklist de Publicação — Legendary Catch

Guia prático antes de clicar em **Publish to Roblox** e liberar o jogo ao público (Place ID `112666482424701`).

---

## 1. Studio, API Services e DataStores

- [ ] No Roblox Studio: **File → Game Settings → Security → Enable Studio Access to API Services** (necessário para testar `ProfileStore` e `OrderedDataStore` reais no Studio; em servidor publicado já fica ativo).
- [ ] Conferir no [PlayerData](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/PlayerData/init.luau#L66) que `STORE_NAME` usa `"PlayerData"` fora do Studio (`RunService:IsStudio()` usa `"PlayerData_Studio"` para não misturar saves de teste com jogadores reais).
- [ ] Garantir **Place salvo na nuvem** e **sincronizado com o Rojo** antes de publicar (`rojo serve` atualizado, `save_place` confirmado).
- [ ] Testar uma sessão com saída e reentrada em servidor publicado (ou com API Services habilitado) para confirmar persistência de `coins`, `collection`, `equippedRod`, `prestige`, `daily` (`streak`, `shieldUsedAt`) e `stats`.

---

## 2. Página do Jogo e Marketing (Creator Hub)

Referência pronta: [PAGINA-DO-JOGO.md](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/docs/PAGINA-DO-JOGO.md)

- [ ] **Título:** `Legendary Catch 🎣` (ou variações listadas em `docs/PAGINA-DO-JOGO.md`).
- [ ] **Descrição curta e longa (PT-BR e EN-US):** copiar de `docs/PAGINA-DO-JOGO.md` (§2 e §3), destacando 100 criaturas, 6 raridades, 3 minigames, eventos do oceano e treino na lagoa.
- [ ] **Gênero e subgênero / Idioma principal / Localização:** ativar suporte PT-BR + EN-US (o cliente já detecta idioma em `Strings.luau` e `StringsUi.luau`).
- [ ] **Ícone (512×512):** subir `art/marketing/icon-512.png` (ou `icone.png`).
- [ ] **Thumbnails (1920×1080):** subir `art/marketing/thumb-1-island.png`, `art/marketing/thumb-2-reveal.png` e `art/marketing/thumb-3-collection.png` (na ordem: ilha → revelação lendária → coleção).
- [ ] **Banner de anúncios (1280×720):** `art/marketing/banner-1280x720.png` para futuras campanhas patrocinadas.

---

## 3. Monetização (Passes & Developer Products)

Referência: [Products.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/shared/Config/Products.luau#L21-L29)

Hoje todos os IDs estão como `0` (o servidor e a UI escondem/bloqueiam compra quando `id == 0`):

- [ ] Criar os **Developer Products** no Creator Hub (`Monetization → Developer Products`) e preencher os IDs reais em `PRODUCTS`:
  - `coins1k` (`coins = 1000`)
  - `coins6k` (`coins = 6000`)
  - `luckBoost` (`boost = "luck"`, `boostSeconds = 900`)
- [ ] Criar os **Game Passes** no Creator Hub (`Monetization → Passes`) e preencher em `PASSES`:
  - `vip` (`coinMultiplier = 1.25`)
  - `autoFish` (habilita modo Auto-pesca)
- [ ] Testar uma compra com `Test Purchase` no Studio após colocar os IDs reais, verificando recibo idempotente (`profile.purchases`) em `Monetization/init.luau`.

---

## 4. Atributos `Dev*` (desligar / limpar antes do lançamento)

Todos os flags `Dev*` abaixo já são bloqueados fora do Studio por `if RunService:IsStudio()`, **mas confira e remova qualquer atributo salvo no Place (`Workspace`) antes de publicar**:

| Atributo | Onde é colocado | Onde é lido no código | O que faz |
| :--- | :--- | :--- | :--- |
| `DevForceRarity` | `Player` | [Fishing/init.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Fishing/init.luau#L196) | Força raridade da próxima fisgada (`Common`..`Mystic`) |
| `DevForceMinigame` | `Player` | [Fishing/init.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Fishing/init.luau#L217) | Força minigame (`reel`, `precision`, `rhythm`) |
| `DevForceVariant` | `Player` | [Fishing/init.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Fishing/init.luau#L339) | Força variante `"Shiny"` na captura |
| `DevStartEvent` | `Workspace` | [OceanEvents/init.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/OceanEvents/init.luau#L65-L69) | Inicia imediatamente um evento do oceano pelo ID |
| `DevGrantCoins` | `Player` | [PlayerData/init.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/PlayerData/init.luau#L304-L309) | Concede moedas ao jogador |
| `DevGrantSpecies` | `Player` | [PlayerData/init.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/PlayerData/init.luau#L311-L333) | Desbloqueia N espécies no álbum |
| `DevDailySimulate` | `Player` | [Progress/init.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Progress/init.luau#L172-L195) | Simula dias anteriores / streak / shield do presente diário |
| `DevMockMissions` | `Players.LocalPlayer` | [Missions/init.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/client/Features/Missions/init.luau#L44) | Injeta missões mock na UI de Desafios |
| `DevMockTutorial` | `Player` | [Tutorial/init.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/client/Features/Tutorial/init.luau#L46) | Exibe cartão mock de tutorial no cliente |
| `DevAutoFish` | `Player` | [Monetization/init.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Monetization/init.luau#L33) | Simula posse do passe `autoFish` em Studio |

- [ ] No Edit do Studio, rodar `Workspace:SetAttribute("DevStartEvent", nil)` para garantir que nenhum atributo de teste ficou salvo no `.rbxl` / nuvem.
- [ ] Conferir se não há nenhum `Dev*` solto fora de `RunService:IsStudio()`.

---

## 5. QA obrigatório (Mobile real + 2 Jogadores)

- [ ] **Teste em celular real (iOS e/ou Android):**
  - Entrar pelo link privado/grupo no celular e jogar por pelo menos 10 minutos.
  - Verificar botão de pular e hotbar não cobertos pelo HUD, botões `>= 44 px`, legibilidade de textos, **Modo Foto**, **Sequência Diária (7 dias)**, **Oficina**, **Treino na Lagoa**, e **Reduzir Efeitos** nas Configurações.
  - Confirmar FPS estável em revelação Lendária/Mística e ao abrir o Bestiário (`Collection`) e Álbum de outro jogador (`Leaderboard`).
- [ ] **Teste com 2 jogadores simultâneos:**
  - Confirmar replicação de pesca de outros jogadores (`Others`: linha, boia, cor da raridade).
  - Confirmar anúncio global de captura rara (`CatchAnnounce`) e **Inspecionar Álbum** no Placar (linha online clicável → `Álbum de <nome>` sem expor moedas/varas).
  - Testar códigos promocionais em Configurações (`BEMVINDO`, `LENDARIO`, `PESCADOR`).

---

## 6. Privacidade, Idade e Classificação (Experience Questionnaire)

- [ ] Preencher o **Experience Questionnaire** no Creator Hub (classificação etária "All Ages" / livre: sem violência gráfica, sem sangue, sem loot boxes pagas ou azar pago).
- [ ] Confirmar que **Paid Random Items** está em conformidade: `Products.luau` vende apenas pacotes de moedas, VIP e boost temporário de sorte (`LUCK_BOOST_MULTIPLIER`), nunca caixas aleatórias pagas.
- [ ] Verificar uso de **AnalyticsService** (apenas funil interno `Analytics.STEPS` e economia de moedas em `Analytics.coins`, sem telemetria externa nem PII).
- [ ] Ajustar visibilidade de servidor (`Public`), máximo de jogadores por servidor (ex.: `12`–`16` para ilha leve e píer sem poluição visual) e ativar **Voice Chat / Text Chat** padrão seguro do Roblox.

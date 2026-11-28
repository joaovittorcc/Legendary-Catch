# Checklist de Publicação — Legendary Catch

Guia prático antes de clicar em **Publish to Roblox** e liberar o jogo ao público (Place ID `112666482424701`, Universe `10777276665`).

---

## 1. Studio, API Services, DataStores e Flags de Produção

- [ ] No Roblox Studio: **File → Game Settings → Security → Enable Studio Access to API Services** (necessário para testar `ProfileStore` e `OrderedDataStore` reais no Studio; em servidor publicado já fica ativo).
- [ ] Conferir separação Studio × Produção nos DataStores:
  - [PlayerData](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/PlayerData/init.luau#L76): usa `"PlayerData"` fora do Studio e `"PlayerData_Studio"` no Studio.
  - [Leaderboard](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Leaderboard/init.luau#L23): usa `"Board_<Nome>_v1"` fora do Studio e `"Board_<Nome>_Studio_v1"` no Studio (testes no Studio nunca poluem os placares públicos).
- [ ] **Conferir flags de recursos em produção (`ReplicatedStorage` e `Config/Aquarium.luau`):**
  - `Aquarium.LIVE_ENABLED` em [Config/Aquarium.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/shared/Config/Aquarium.luau#L54) está `false` por padrão (no Studio fica ligado automaticamente, mas em produção **desliga** o Aquário se não for mudado para `true` ou configurado via atributo `AquariumUI`/`AquariumCredit` em `ReplicatedStorage`). `AquariumOffline` fica desligado até o piloto com dados reais.
  - Atributos salvos em `ReplicatedStorage` no place: confirmar que `FishingPower = true`, `FishingRoulette = true` e `TrainingPower = true` estão salvos no place antes de publicar (se ausentes, esses 3 sistemas ficam desligados!).
- [ ] Garantir **Place salvo na nuvem** e **sincronizado com o Rojo** antes de publicar (`rojo serve` atualizado, `File → Save to Roblox` confirmado).
- [ ] Testar uma sessão com saída e reentrada em servidor publicado (ou com API Services habilitado) para confirmar persistência de `coins`, `collection`, `equippedRod`, `prestige`, `training`/`trainingField`, `aquarium`, `daily` (`streak`, `shieldUsedAt`) e `stats`.

---

## 2. Ilha solo e visitas por convite

- [ ] Implementar o roteamento de sessões. Na entrada normal, cada jogador começa na sua ilha. Ao aceitar um convite, o amigo entra na sessão do anfitrião.
- [ ] Ajustar `MaxPlayers` junto com o roteamento. A sessão jogável precisa ter vagas para o anfitrião e seus convidados.
- [ ] Validar com duas contas. As duas devem começar em sessões separadas. Depois de aceitar o convite, o convidado deve aparecer na ilha do anfitrião. Um convite expirado deve levar o convidado à própria ilha com aviso.

---

## 3. Página do Jogo e Marketing (Creator Hub)

Referência pronta: [PAGINA-DO-JOGO.md](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/docs/PAGINA-DO-JOGO.md)

- [ ] **Título:** `Legendary Catch 🎣` (ou variações listadas em `docs/PAGINA-DO-JOGO.md`).
- [ ] **Descrição curta e longa (PT-BR e EN-US):** copiar de `docs/PAGINA-DO-JOGO.md` (§2 e §3), destacando **106 criaturas**, **6 raridades**, **minigame da barra lateral**, **roleta de mutações**, **Aquário**, **4 ilhas de treino** e **Eventos do Oceano**.
- [ ] **Gênero e subgênero / Idioma principal / Localização:** ativar suporte PT-BR + EN-US (o cliente já detecta idioma em `Strings.luau` e `StringsUi.luau`).
- [ ] **Ícone (512×512):** subir `art/marketing/icon-512.png`.
- [ ] **Thumbnails (1920×1080):** subir `art/marketing/thumb-1-island.png`, `art/marketing/thumb-2-reveal.png` e `art/marketing/thumb-3-collection.png` (na ordem: ilha → revelação lendária → coleção).
- [ ] **Banner de anúncios (1280×720):** `art/marketing/banner-1280x720.png` para futuras campanhas patrocinadas.

---

## 4. Monetização (Passes & Developer Products)

Referência: [Products.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/shared/Config/Products.luau#L21-L30) e [Monetization](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Monetization/init.luau).

Hoje todos os **5 IDs estão como `0`** — nada trava e nenhum botão de compra aparece habilitado enquanto `id == 0`. Não há nenhum item aleatório pago (loot box).

### Passo a passo para o João criar no Creator Hub

1. Acesse [create.roblox.com](https://create.roblox.com/) → **Creations** → abra a experiência **Legendary Catch** (Universe `10777276665`).
2. **Criar os 3 Developer Products** (`Monetization → Developer Products → Create a Developer Product`):
   - `coins1k`: Nome sugerido `1,000 Coins` / descrição `+1,000 coins immediately` → defina o preço em Robux → salve e copie o **Developer Product ID**.
   - `coins6k`: Nome sugerido `6,000 Coins` / descrição `+6,000 coins immediately` → defina o preço em Robux → salve e copie o **Developer Product ID**.
   - `luckBoost`: Nome sugerido `15m Luck Boost (2x)` / descrição `2x Rare+ luck for 15 minutes` → defina o preço em Robux → salve e copie o **Developer Product ID**.
     - *Atenção (Política Roblox):* o boost altera probabilidades de pesca; confira a política de *Paid Random Items* e só habilite o botão de compra quando a divulgação de chances efetivas e elegibilidade regional (`PolicyService`) estiverem ligadas na UI (o cliente já mantém o botão travado até o servidor confirmar).
3. **Criar os 2 Game Passes** (`Monetization → Passes → Create a Pass`):
   - `vip`: Nome sugerido `VIP Fisher` / descrição `+25% coins on every catch and VIP badge` → ative **Item for Sale**, defina o preço em Robux → salve e copie o **Pass ID**.
   - `autoFish`: Nome sugerido `Auto-Fish` / descrição `Automatic fishing while standing at a fishing spot (up to Epic)` → ative **Item for Sale**, defina o preço em Robux → salve e copie o **Pass ID**.
4. Cole os 5 IDs numéricos em [src/shared/Config/Products.luau](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/shared/Config/Products.luau#L21-L30), trocando `id = 0` pelo ID real.
5. **Testar no Studio:** dê Play com API Services ligado e faça **Test Purchase** (grátis no Studio) de cada produto e passe, conferindo:
   - Moedas e `LuckBoostEndsAt` aplicados na hora e salvos em `profile.purchases` (recibo idempotente com confirmação de `LastSavedData` antes de `PurchaseGranted`).
   - Passes `Pass_vip` (+25% moedas) e `AutoFishOwned` (teto Épico) aplicados imediatamente após a compra e mantidos ao reentrar.

---

## 5. Atributos `Dev*` (conferir bloqueio e limpar do Place antes de publicar)

Todos os flags `Dev*` do servidor e a maioria dos do cliente já são bloqueados fora do Studio por `RunService:IsStudio()`. **Confira no modo Edit do Studio que nenhum deles ficou salvo no Place (`Workspace` ou `ReplicatedStorage`) antes de publicar:**

| Atributo | Onde é colocado | Onde é lido no código | Bloqueado fora do Studio? | O que faz |
| :--- | :--- | :--- | :--- | :--- |
| `DevForceRarity` | `Player` | [server/Features/Fishing](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Fishing/init.luau#L198-L204) | Sim (`RunService:IsStudio()`) | Força raridade da próxima fisgada (`Common`..`Mystic`) |
| `DevForceMinigame` | `Player` | [server/Features/Fishing](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Fishing/init.luau#L198-L204) | Sim (`RunService:IsStudio()`) | Força minigame (`reel`, `precision`, `rhythm`) |
| `DevForceVariant` | `Player` | [server/Features/Fishing](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Fishing/init.luau#L198-L204) | Sim (`RunService:IsStudio()`) | Força variante `"Shiny"` na captura |
| `DevStartEvent` | `Workspace` | [server/Features/OceanEvents](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/OceanEvents/init.luau#L69-L77) | Sim (`RunService:IsStudio()`) | Inicia imediatamente um evento do oceano pelo ID |
| `DevGrantCoins` | `Player` | [server/Features/PlayerData](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/PlayerData/init.luau#L543-L551) | Sim (`RunService:IsStudio()`) | Concede moedas ao jogador |
| `DevGrantSpecies` | `Player` | [server/Features/PlayerData](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/PlayerData/init.luau#L552-L578) | Sim (`RunService:IsStudio()`) | Desbloqueia N espécies no álbum |
| `DevGrantLevel` | `Player` | [server/Features/Journey](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Journey/init.luau#L113-L125) | Sim (`RunService:IsStudio()`) | Define o nível do jogador (`1`..`100`) |
| `DevDailySimulate` | `Player` | [server/Features/Progress](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Progress/init.luau#L177-L201) | Sim (`RunService:IsStudio()`) | Simula dias anteriores / streak / shield do presente diário |
| `DevAutoFish` | `Player` | [server/Features/Monetization](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/server/Features/Monetization/init.luau#L33) | Sim (`RunService:IsStudio()`) | Simula posse do passe `autoFish` em Studio |
| `DevSeason` | `Player` | [shared/Config/Seasons](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/shared/Config/Seasons.luau#L58-L65) | Sim (`RunService:IsStudio()`) | Ativa estação sazonal (ex.: `"xmas"`) |
| `DevOpenPanel` | `LocalPlayer` | [client/Features/Hud](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/client/Features/Hud/init.luau#L240-L247) | Sim (`RunService:IsStudio()`) | Abre painel por nome no cliente |
| `DevMockMissions` | `LocalPlayer` | [client/Features/Missions](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/client/Features/Missions/init.luau#L46) | Sim (`RunService:IsStudio()`) | Injeta missões mock na UI de Desafios |
| `DevMockTutorial` | `LocalPlayer` | [client/Features/Tutorial](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/src/client/Features/Tutorial/init.luau#L157) | Sim (`RunService:IsStudio()`) | Exibe cartão mock de tutorial no cliente |
| `DevPowerBarSkin` | `LocalPlayer` | `client/Features/Fishing/PowerBar.luau:139` e `FishingVfx/init.luau:80` | Sim (`RunService:IsStudio()`) | Força skin visual da barra de força (apenas cosmético local) |

- [ ] No Edit do Studio, rodar `Workspace:SetAttribute("DevStartEvent", nil)` para garantir que nenhum atributo de teste ficou salvo no place / nuvem.
- [ ] Conferir se não há nenhum `Dev*` salvo no place (varredura em Edit confirmou `0` atributos `Dev*` salvos).

---

## 6. QA obrigatório (Mobile real + 2 Jogadores)

- [ ] **Teste em celular real (iOS e/ou Android):**
  - Entrar pelo link privado/grupo no celular e jogar por pelo menos 10 minutos.
  - Verificar botão de pular e hotbar não cobertos pelo HUD, botões `>= 44 px`, legibilidade de textos, **barra de força**, **minigame da barra lateral**, **roleta**, **Modo Foto**, **Aquário**, **Sequência Diária (7 dias)**, **Oficina**, **Treino nas ilhas** e **Reduzir Efeitos** nas Configurações.
  - Confirmar FPS estável em revelação Lendária/Mística e ao abrir o Bestiário (`Collection`) e Álbum de outro jogador (`Leaderboard`).
- [ ] **Roteiro de teste com 2 jogadores simultâneos (`Test → Clients and Servers → 2 Players → Start` no Studio ou 2 aparelhos):**
  1. **Replicação de pesca (`Others`):** Jogador A pesca no píer → Jogador B confirma linha, boia, estado `waiting`/`fighting` e cor da raridade na luta sem erro no console.
  2. **Anúncio global (`CatchAnnounce`):** Jogador A captura uma Lendária ou Épica Cintilante → Jogador B vê o banner global (e Jogador A não vê o próprio banner duplicado).
  3. **Troféu do servidor (`TrophyPedestal`):** Jogador A captura criatura mais rara/pesada que a atual → ambos veem o modelo e a placa atualizados na praça.
  4. **Inspecionar Álbum (`InspectPlayer`):** Jogador B abre o Placar → clica no Jogador A online → vê apenas nível, prestígio, espécies, capturas, cintilantes e melhores pesos (nunca moedas, varas ou compras).
  5. **Poder de Pesca sobre a cabeça (`OverheadPower`):** Jogador A treina numa ilha e volta ao hub → Jogador B vê o valor atualizado acima da cabeça de A.
  6. **Portais e zonas:** Jogador A entra num portal (Recife/Abismo ou Ilha de Treino) → Jogador B continua pescando normalmente no hub sem perda de estado.
  7. **Isolamento de economia:** Jogador A compra vara, resgata código (`BEMVINDO`, `LENDARIO`, `PESCADOR`) e faz Prestígio → saldo, varas e coleção do Jogador B permanecem intactos.

---

## 7. Privacidade, Idade e Classificação (Experience Questionnaire)

- [ ] Preencher o **Experience Questionnaire** no Creator Hub (classificação etária "All Ages" / livre: sem violência gráfica, sem sangue, sem loot boxes pagas ou azar pago).
- [ ] Confirmar que **Paid Random Items** está em conformidade: `Products.luau` vende apenas pacotes de moedas, VIP, Auto-pesca e boost temporário de sorte (`LUCK_BOOST_MULTIPLIER`), nunca caixas aleatórias pagas.
- [ ] Verificar uso de **AnalyticsService** (apenas funil interno `Analytics.STEPS`, economia de moedas em `Analytics.coins`, telemetria agregada de lutas/barra/aquário/treino em `Analytics.custom`/`fight`, **zero PII** — nenhum nome, e-mail, chat ou dado pessoal).
- [ ] Ajustar visibilidade de servidor (`Public`), máximo de jogadores (`12`–`16`) e ativar **Voice Chat / Text Chat** padrão seguro do Roblox.

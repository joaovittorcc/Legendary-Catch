# Varredura de Limpeza, Segurança e Higiene — Legendary Catch

Relatório da inspeção estática e de segurança realizada em `2026-11-18` antes da abertura do repositório no GitHub.

---

## 1. Módulos e Submódulos (`src/`)

- **Features principais (`src/client/Features/*/init.luau` e `src/server/Features/*/init.luau`):** todas as `31` features de cliente e `16` features de servidor expõem `start()` e são descobertas automaticamente pelos loaders [init.client.luau](../src/client/init.client.luau) e [init.server.luau](../src/server/init.server.luau).
- **Submódulos auxiliares:** todos os submódulos internos (`Fishing/*`, `Fishing/Minigames/*`, `Hud/*`, `RevealStyles/*`, `Shop/*`, `AvatarVisuals/Pose`, `Server/Remotes`, `Shared/*`) possuem referências ativas por `require`.

## 2. Código Morto Removido (100% seguro)

Confirmado com `0` chamadas em `src/`, `tools/` e `docs/` via grep e revalidado no Studio Play sem erros:

| Símbolo / Trecho | Local | Motivo da remoção |
|---|---|---|
| `Ui.gloss` | `src/client/Features/Fishing/Ui.luau` | Substituída por `Theme.surface(...)`; sem chamadas em nenhum módulo. |
| `Art.slice` | `src/client/Features/Hud/Art.luau` | Resquício anterior à camada `Art` atual; sem chamadas em nenhum módulo. |

## 3. Itens Sem Uso Externo Mantidos Intencionalmente

| Item | Local | Justificativa |
|---|---|---|
| `PressInput.isHeld` | `src/client/Features/Fishing/PressInput.luau` | Parte da API pública do módulo de entrada e fora do escopo de alteração em `AGENTS.md`. |
| `Zones.boostFor` | `src/shared/Config/Zones.luau` | Helper público de configuração de zonas. |
| `tools/prototypes/CreatureBatch01.luau` | `tools/prototypes/` | Script histórico de prototipagem (`--!nocheck`) dos primeiros 10 modelos em blocos; mantido apenas como referência de origem no repositório. |

## 4. `TODO`s, Comentários e Atributos `Dev*`

- **`TODO`s em `src/`:** encontrados apenas os `5` marcadores intencionais em `src/shared/Config/Products.luau` (`L22`, `L23`, `L24`, `L28`, `L29` — `-- TODO: real id`), aguardando a criação dos **Developer Products** e **Game Passes** no Roblox Creator Hub (ver checklist em [PUBLICAR.md](PUBLICAR.md)).
- **Mojibake / acentuação quebrada:** `0` ocorrências em comentários ou strings de `src/` e `tools/`.
- **Atributos de QA (`Dev*`):** os flags de teste (`DevForceRarity`, `DevForceMinigame`, `DevForceVariant`, `DevStartEvent`, `DevSeason`, `DevGrantCoins`, `DevGrantSpecies`, `DevDailySimulate`, `DevMockMissions`, `DevMockTutorial`, `DevAutoFish`) permanecem no código protegidos por `RunService:IsStudio()`; ver [PUBLICAR.md](PUBLICAR.md) §4 para conferência antes de publicar.

## 5. Segredos e `.gitignore`

- **Busca por segredos em todos os arquivos versionados (`git ls-files`):** varredura por `api_key`/`api key`, `token`, `secret`, `cookie`, `.ROBLOSECURITY`, `password` e endereços de e-mail encontrou **`0` credenciais, cookies, tokens reais ou IDs pessoais**.
  - Únicos falsos positivos encontrados: nomes de variáveis locais de controle (`autoToken`, `bannerToken`, `armToken`, `pendingToken`, `myToken`, `token`) e textos do jogo (`"Cookie Crab"`, `"Cookie Fish"`, `"Nine tails, nine secrets, none told."`, `"Tidal Secret"`).
- **Cobertura do `.gitignore`:**
  - Já ignorava: `Packages/`, `ServerPackages/`, `sourcemap.json`, `*.rbxl`, `*.rbxlx`, `*.rbxl.lock`, `*.rbxlx.lock`, `backups/`, `VAULT-roblox.md`, `*.mp4`, `art/reference/video-frames.html`, `.studio-lock`, `art/reference/roblox-ui-kit/`, `.codex-attachments/`.
  - **Adicionado nesta limpeza:** `*.rbxm`, `*.rbxmx` e `*.tmp` para evitar subida acidental de modelos ou temporários exportados do Studio.

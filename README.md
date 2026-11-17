# Legendary Catch

Roblox fishing and creature-collecting game: one compact magical island, a pier over a huge
ocean, skill minigames and cinematic reveals that grow with rarity. Mobile-first, also PC.

Design context: [CONTEXTO_MESTRE.md](CONTEXTO_MESTRE.md) (PT-BR).

## Setup

```bash
rokit install
rojo serve --port 34873
```

In Studio, connect the Rojo plugin to `localhost:34873`.

## Layout

| Path | DataModel |
|---|---|
| `src/server` | `ServerScriptService.Server` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared` | `ReplicatedStorage.Shared` (configs, net contract, strings) |
| `tools` | `ServerStorage.DevTools` (Edit-time generators, run through the Studio MCP) |

The map, AI meshes (`ServerStorage.MapMeshes`) and creature models (`ReplicatedStorage.Creatures`)
live in the place file, not in git. `tools/IslandGenerator.luau` rebuilds the island.

## Checks

```bash
stylua src tools
selene src tools
```

Plus `luau-lsp analyze` on `src` and `tools`.

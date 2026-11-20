# Revisão Final da HUD (P0–10)

Conferência dos 10 itens do checklist em Play (PC `1502×753` + iPhone 17 Pro paisagem `750×381` e retrato `401×778`).

## Prints

- [01-antes-oficina-varas-longas-vazias.jpg](01-antes-oficina-varas-longas-vazias.jpg) — Antes: varas longas (`Celestial`, `Abismo`, `Mística`) ficavam com `ViewportFrame` vazio/cortado verticalmente.
- [02-depois-pc-hud-nivel-dourado.jpg](02-depois-pc-hud-nivel-dourado.jpg) — Depois (PC): chip de nível dourado vivo (removido `SoftShadow` interno que escurecia o fundo) + level-up coalescido sem flicker.
- [03-depois-pc-oficina-varas-longas.jpg](03-depois-pc-oficina-varas-longas.jpg) — Depois (PC): `Vara Celestial`, `Vara do Abismo` e `Vara Mística` montadas sob demanda e 100% enquadradas pelo AABB 3D real (`vpXY ∈ [0.16..0.81]`).
- [04-depois-iphone-retrato-prestigio.jpg](04-depois-iphone-retrato-prestigio.jpg) — Depois (iPhone Retrato): título `"Maré Nova (Prestígio)"` centralizado dentro do `TitleRibbon`, sem encostar no ícone da onda nem estourar a borda.
- [05-depois-iphone-retrato-oficina.jpg](05-depois-iphone-retrato-oficina.jpg) — Depois (iPhone Retrato): Oficina com varas longas inteiras e textos de bônus sem sobreposição da barra de rolagem.
- [06-depois-iphone-paisagem-oficina.jpg](06-depois-iphone-paisagem-oficina.jpg) — Depois (iPhone Paisagem): `CloseButton` 100% dentro da tela e `Vara Mística` inteira visível.
